# -----------------------------------------------------------------------------
#  final.jl  –  Simple two-city endogenous firm location choice model
# -----------------------------------------------------------------------------
#  1. 31‑point Gauss–Hermite quadrature for expectations over the Gaussian shock z.
#  2. Value‑function iteration (VFI) at each trial share α to obtain optimal relocation
#     probabilities.
#  3. Brent root‑finding on the aggregate map Φ(α) to pin down the steady‑state share α*.
#  4. Monte‑Carlo simulation of a large cross‑section for transition dynamics.
# -----------------------------------------------------------------------------
include("spline.jl")
using FastGaussQuadrature       # Gauss–Hermite nodes & weights
using Roots                     # Brent root finder
using Random, Printf, Statistics, LinearAlgebra, Plots

## -----------------------------------------------------------------------------
# 1. Parameters ---------------------------------------------------------------
## -----------------------------------------------------------------------------
const β = 0.95           # discount factor
const θ = 0.40           # congestion elasticity
const m = 0.25           # fixed moving cost
const σ_z = 0.10         # std‑dev of productivity shock z
const σ_η = 0.60         # taste‑shock scale (0 ⇒ deterministic decision)
const N_MC = 10000       # cross‑section size for simulation
Random.seed!(5555)

## -----------------------------------------------------------------------------
# 2. Gauss–Hermite quadrature -------------------------------------------------
## -----------------------------------------------------------------------------
const N_Q = 31
ξ, ω = gausshermite(N_Q)
ω ./= √π                      # normalise for N(0,1)
const z_nodes = √2 * σ_z .* ξ           # actual z‑values at nodes

profit(z, α) = exp(z) * α^(-θ)           # profit in city 1 given share α

# -----------------------------------------------------------------------------
# 3. Dynamic value‑function iteration ----------------------------------------
# -----------------------------------------------------------------------------
function solve_V(α; tol=1e-8, maxit=10000)
"""
    solve_V(α; tol=1e-8, maxit)

Main Purpose:
- Solve the Bellman equation for a representative firm given an aggregate share `α` by value-function iteration on the Gauss–Hermite nodes.

Arguments:
- `α`     : current share of firms in city 1
- `tol`   : convergence tolerance for the sup‐norm of the value update (default 1e-8)
- `maxit` : maximum iterations for the VFI loop (default 10000)

Returns:
- `V1`     : Vector of length `N_Q`, the value of staying in city 1 at each shock node
- `V2`     : Vector of length `N_Q`, the value of moving to city 2 at each shock node
- `spline1`: Cubic spline interpolant for `V1(z)` on `z_nodes`
- `spline2`: Cubic spline interpolant for `V2(z)` on `z_nodes`
"""
    # Precompute current‐period profits at each node
    π1 = @. exp(z_nodes) * α^(-θ)       # profit in city 1
    π2 = @. exp(-z_nodes) * (1-α)^(-θ)  # profit in city 2

    # Initialize value‐function guesses
    V1 = zeros(N_Q)
    V2 = zeros(N_Q)

    # Value‐function iteration
    for iter in 1:maxit
        # compute continuation values by quadrature
        EV1, EV2 = dot(ω, V1), dot(ω, V2)

        # Bellman update at each node
        V1_new = max.(π1 .+ β*EV1, π2 .- m .+ β*EV2)
        V2_new = max.(π2 .+ β*EV2, π1 .- m .+ β*EV1)

        # check convergence
        if maximum(abs, V1_new .- V1) < tol &&
            maximum(abs, V2_new .- V2) < tol
            V1, V2 = V1_new, V2_new
            break
        end

        # prepare for next iteration
        V1, V2 = V1_new, V2_new
    end

    # Build cubic‐spline interpolants for off‐grid evaluation
    spline1 = makespline(z_nodes, V1)
    spline2 = makespline(z_nodes, V2)

    return V1, V2, spline1, spline2
end
    
function Φ(α)
"""
    Φ(α)

Compute the expected next‐period share of firms in city 1 given current share `α`.

Main Purpose:
- Solves the firm's dynamic program at share `α` to obtain value functions `V1(z)` and `V2(z)` at the Gauss–Hermite nodes.
- Computes the deterministic surplus ΔV(z) = V2(z) – m – V1(z).
- Translates ΔV(z) into relocation probabilities via the logit formula (or a threshold rule if taste‐shock scale σ_η == 0).
- Integrates those probabilities against the normal density using the quadrature weights `ω` to form the law of motion.

# Arguments
- `α::Float64`: current aggregate share of firms in city 1

# Returns
- `α_next::Float64`: expected share of firms in city 1 next period
"""
    # Solve the dynamic program to get values at each productivity node
    V1, V2, _, _ = solve_V(α)

    # Deterministic, forward‐looking surplus from moving 1 → 2
    ΔV = V2 .- m .- V1

    # Choice probability: logit if σ_η > 0, otherwise deterministic threshold/rule
    P1 = σ_η == 0 ? (ΔV .> 0) : @. 1 / (1 + exp(-ΔV / σ_η))

    # By symmetry, probability of moving from city 2 back to city 1
    P2 = 1 .- P1

    # Aggregate using quadrature: share that end up in city 1 next period
    return sum(ω .* (α .* (1 .- P1) .+ (1 - α) .* P2))
end


# -----------------------------------------------------------------------------
# 4. Steady‑state share α* ----------------------------------------------------
# -----------------------------------------------------------------------------
# Find the steady-state (fixed point) α* by solving Φ(α) = α with Brent’s method
# The search interval [0.05, 0.95] brackets the solution.
α_star = find_zero(a -> Φ(a) - a, (0.05, 0.95); atol = 1e-10)

# Print the equilibrium shares for city 1 and city 2
@printf("\nEquilibrium share  α* = %.6f  (city 1)\n", α_star)
@printf("                       %.6f  (city 2)\n", 1 - α_star)

# Construct and plot the fixed-point map Φ(α) against the 45° line
α_grid = range(0.05, 0.95; length = 400)     # grid of candidate α values
Φ_vals  = [Φ(a) for a in α_grid]             # compute Φ(α) at each grid point

# Plot Φ(α) (solid) and the line α′ = α (dashed); mark the intersection at α*
plot(α_grid, Φ_vals;    lw = 2,    label = "Φ(α)")
plot!(α_grid, α_grid;   ls = :dash, label = "45° line")
scatter!([α_star], [α_star]; mc = :red, ms = 6, label = "α*")

# Label axes and title, then save the figure to file
xlabel!("α") 
ylabel!("α′")
title!("Fixed-point map")
savefig("fixed_map.png")


# -----------------------------------------------------------------------------
# 5. Expected profits at equilibrium -----------------------------------------
# -----------------------------------------------------------------------------
# Compute and print the expected per‐firm profits in each city at the equilibrium share α*
# Uses the Gauss–Hermite weights ω to integrate π1(z,α*) and π2(z,α*) over z∼N(0,σₓ²).
Eπ1 = sum(ω .* profit.(z_nodes, α_star))                          # E[π | city 1]
Eπ2 = sum(ω .* exp.(-z_nodes) .* (1 - α_star)^(-θ))                # E[π | city 2]

@printf("E[π | city 1] = %.4f\n", Eπ1)
@printf("E[π | city 2] = %.4f\n", Eπ2)

# -----------------------------------------------------------------------------
# 6. Transition simulation (Monte‑Carlo) -------------------------------------
# -----------------------------------------------------------------------------
function simulate_path(T; α0 = α_star, N = N_MC, rng = Random.GLOBAL_RNG)
"""
    simulate_path(T; α0=α_star, N=N_MC, rng=Random.GLOBAL_RNG)

Main Purpose:
- Simulate the transition of the aggregate firm share `α_t` over `T` periods using a Monte-Carlo approximation of the forward-looking relocation rule.

# Arguments
- `T::Int`               : number of periods to simulate  
- `α0::Float64`          : initial share of firms in city 1 (default `α_star`)  
- `N::Int`               : number of firms (Monte Carlo draws) per period  
- `rng::AbstractRNG`     : random number generator  

# Returns
- `α_hist::Vector{Float64}`: simulated path of `α_t` for `t = 1,…,T`

# Process
1. Initialize `α = α0` and build the cubic-spline interpolants for `V1(z)` and `V2(z)`  
2. For each period `t`:
   - Draw `N` i.i.d. shocks `z_draw ∼ N(0,σ_z^2)`  
   - Evaluate the dynamic surplus `ΔV(z) = V2(z) − m − V1(z)` at each draw  
     using `interp(...)[1]` on the splines  
   - Convert `ΔV` into relocation probabilities via logit (or threshold if `σ_η = 0`)  
   - Update the aggregate share `α_{t+1} = α_t · (1−P_move1) + (1−α_t) · P_move2`  
   - Re-solve the Bellman equation at the new `α` and rebuild the splines  
3. Return the full path `α_hist`
"""
    # Preallocate storage for the simulated share path
    α_hist = Vector{Float64}(undef, T)
    α      = α0

    # Build initial splines for V1 and V2 at α0
    _, _, spline1, spline2 = solve_V(α)

    for t in 1:T
        # Record current share
        α_hist[t] = α

        # Draw idiosyncratic productivity shocks
        z_draw = σ_z .* randn(rng, N)

        # Compute the forward-looking surplus ΔV for each firm via the cubic splines
        ΔV_draw = [interp(z, spline2)[1] - m - interp(z, spline1)[1] for z in z_draw]

        # Compute relocation probabilities (logit if σ_η>0, else hard threshold)
        P_move1 = σ_η == 0 ? (ΔV_draw .> 0) : @. 1 / (1 + exp(-ΔV_draw / σ_η))
        P_move2 = 1 .- P_move1

        # Update the aggregate share based on realized moves
        α = α * mean(1 .- P_move1) + (1 - α) * mean(P_move2)

        # Re-solve the dynamic program at the new α and rebuild the splines
        _, _, spline1, spline2 = solve_V(α)
    end

    return α_hist
end

# Run a Monte-Carlo simulation from an initial share of 0.20 for 500 periods
α_path = simulate_path(500; α0 = 0.20)

# Plot the simulated transition path of the city-1 share over time
plot(α_path; xlabel = "t", ylabel = "share in city 1", title = "Transition path")
savefig("transition_path.png")

# Find the first period when α_t is within ±5 percentage points of the steady state
hit05 = findfirst(t -> abs(α_path[t] - α_star) < 0.05, eachindex(α_path))
# Find the first period when α_t is within ±1 percentage point of the steady state
hit01 = findfirst(t -> abs(α_path[t] - α_star) < 0.01, eachindex(α_path))

if hit05 !== nothing
    @printf("Within 5 p.p. of α* after %d periods\n", hit05)
else
    println("Never within 5 p.p. of α* during the simulation")
end

if hit01 !== nothing
    @printf("Within 1 p.p. of α* after %d periods\n", hit01)
else
    println("Never within 1 p.p. of α* during the simulation")
end

function solve_V_generic(α, θp, mp, σzp; tol=1e-8, maxit=10_000)
"""
    solve_V_generic(α, θp, mp, σzp; tol=1e-8, maxit=10_000)

Main Purpose: 
- Solve the Bellman equation for a representative firm when parameters (θ, m, σ_z) are overridden by (θp, mp, σzp). Returns the value functions and cubic-spline interpolants for off-grid evaluation. 
- Helper that solves VFI with arbitrary (θ, m, σz) without touching global constants.

# Arguments
- `α::Float64`        : current share of firms in city 1  
- `θp::Float64`       : congestion elasticity override  
- `mp::Float64`       : moving cost override  
- `σzp::Float64`      : productivity shock std. dev. override  
- `tol::Float64`      : convergence tolerance for VFI (default 1e-8)  
- `maxit::Int`        : maximum iterations for VFI (default 10000)  

# Returns
- `V1::Vector{Float64}`    : values of staying in city 1 at each shock node  
- `V2::Vector{Float64}`    : values of moving to city 2 at each shock node  
- `spline1::spline`        : cubic-spline interpolant for V1(z)  
- `spline2::spline`        : cubic-spline interpolant for V2(z)  

# Process
This routine replicates `solve_V`, but:
  - Constructs its own Gauss–Hermite nodes via `σzp`.  
  - Uses Bellman iteration to find `V1` and `V2` on those nodes.  
  - Builds cubic splines `spline1` and `spline2` for dynamic surplus calculations.
"""
    # Build Gauss–Hermite nodes for the given σzp
    z_nodes_p = √2 * σzp .* ξ

    # Compute current-period profits at each node
    π1 = @. exp(z_nodes_p)   * α^(-θp)    # stay in city 1
    π2 = @. exp(-z_nodes_p)  * (1-α)^(-θp) # move to city 2

    # Initialize value-function guesses
    V1 = zeros(N_Q)
    V2 = zeros(N_Q)

    # Bellman iteration loop
    for _ in 1:maxit
        # Continuation values via quadrature
        EV1, EV2 = dot(ω, V1), dot(ω, V2)

        # Bellman update at each node
        V1_new = max.(π1 .+ β * EV1,   π2 .- mp .+ β * EV2)
        V2_new = max.(π2 .+ β * EV2,   π1 .- mp .+ β * EV1)

        # Check for convergence in sup-norm
        if maximum(abs, V1_new .- V1) < tol &&
           maximum(abs, V2_new .- V2) < tol
            V1, V2 = V1_new, V2_new
            break
        end

        # Prepare for next iteration
        V1, V2 = V1_new, V2_new
    end

    # Build cubic-spline interpolants for off-grid evaluation
    spline1 = makespline(z_nodes_p, V1)
    spline2 = makespline(z_nodes_p, V2)

    return V1, V2, spline1, spline2
end

function alpha_star_for(θp, mp, σzp)
"""
    alpha_star_for(θp, mp, σzp)


Main Purpose:
- Compute the stationary equilibrium share `α*` in city 1 when the model parameters (congestion elasticity, moving cost, shock volatility) are set to `(θp, mp, σzp)`.

This routine defines a local law‐of‐motion function `Φ_local(α)` that:
- Solves the Bellman equation with `solve_V_generic(α, θp, mp, σzp)`  
- Computes the forward‐looking surplus ΔV = V2 – mp – V1  
- Converts ΔV into relocation probabilities (logit or threshold)  
- Integrates those probabilities via Gauss–Hermite weights `ω`  
- It then finds the fixed point of `Φ_local(α) = α` on the interval [0.05, 0.95]
using Brent’s method.

# Arguments
- `θp::Float64`   : congestion elasticity  
- `mp::Float64`   : moving cost  
- `σzp::Float64`  : standard deviation of the productivity shock  

# Returns
- `α_star::Float64` : steady‐state share of firms in city 1 for the given parameters
"""
    # Local law‐of‐motion for a given α
    Φ_local(α) = begin
        # Solve dynamic program under (θp, mp, σzp)
        V1, V2, _, _ = solve_V_generic(α, θp, mp, σzp)

        # Forward-looking surplus
        ΔV = V2 .- mp .- V1

        # Relocation probabilities
        P1 = σ_η == 0 ? (ΔV .> 0) : @. 1 / (1 + exp(-ΔV / σ_η))
        P2 = 1 .- P1

        # Aggregate next-period share
        sum(ω .* (α .* (1 .- P1) .+ (1 - α) .* P2))
    end

    # Find α such that Φ_local(α) = α
    find_zero(a -> Φ_local(a) - a, (0.05, 0.95))
end

# parameter sweeps: 50%–150% of each baseline
θ_vals = θ .* (0.5:0.5:1.5)
m_vals = m .* (0.5:0.5:1.5)
σ_vals = σ_z .* (0.5:0.5:1.5)

# compute steady‐state share α* for each sweep
αθ = [alpha_star_for(θv, m, σ_z) for θv in θ_vals]
αm = [alpha_star_for(θ, mv, σ_z) for mv in m_vals]
ασ = [alpha_star_for(θ, m, σv) for σv in σ_vals]

# display the results
println("θ sweep  → ", αθ)
println("m sweep  → ", αm)
println("σ_z sweep→ ", ασ)

# plot comparative‐statics
xgrid = 0.5:0.5:1.5
plot(xgrid, αθ; lw=2,    label="vary θ")
plot!(xgrid, αm; lw=2,   ls=:dash,   label="vary m")
plot!(xgrid, ασ; lw=2,   marker=:circle, label="vary σ_z")
xlabel!("parameter (× baseline)")
ylabel!("α* (city 1)")
savefig("alpha_comparative.pdf")

# -----------------------------------------------------------------------------
# 7. Movement with varying β -------------------------------------------------
# -----------------------------------------------------------------------------
# Choose a representative α (e.g. the steady state)
α = α_star

# Grid of productivity‐shock realizations to evaluate
z_grid = range(-3*σ_z, 3*σ_z; length = 300)

# List of discount factors to compare
beta_list = [0.20, 0.50, 0.80, 0.90, 0.95, 0.99]

# Helper: solve VFI at fixed α and β, return the two splines
function splines_for_beta(α, β_val)
    # Precompute profits at Gauss–Hermite nodes
    π1 = @. exp(z_nodes) * α^(-θ)
    π2 = @. exp(-z_nodes) * (1-α)^(-θ)

    V1 = zeros(N_Q)
    V2 = zeros(N_Q)
    tol, maxit = 1e-8, 10_000

    for iter in 1:maxit
        EV1, EV2 = dot(ω, V1), dot(ω, V2)
        V1_new = max.(π1 .+ β_val*EV1, π2 .- m .+ β_val*EV2)
        V2_new = max.(π2 .+ β_val*EV2, π1 .- m .+ β_val*EV1)
        if maximum(abs, V1_new .- V1) < tol && maximum(abs, V2_new .- V2) < tol
            V1, V2 = V1_new, V2_new
            break
        end
        V1, V2 = V1_new, V2_new
    end

    spline1 = makespline(z_nodes, V1)
    spline2 = makespline(z_nodes, V2)
    return spline1, spline2
end

# Initialize the plot
plt = plot(
    xlabel = "Productivity shock z",
    ylabel = "P_move(z,α)",
    title  = "Firm's relocation probability vs. z for different β"
)

# Overlay P_move curves for each β
for β_val in beta_list
    s1, s2 = splines_for_beta(α, β_val)
    ΔV_vals = [ interp(z, s2)[1] - m - interp(z, s1)[1] for z in z_grid ]
    P_move  = @. 1 / (1 + exp(-ΔV_vals / σ_η))
    plot!(plt, z_grid, P_move, label = "β = $(β_val)")
end
savefig("beta_comp.pdf")
display(plt)


# -----------------------------------------------------------------------------
# 8. Deterministic Case (σ_η=0) ----------------------------------------------
# -----------------------------------------------------------------------------

σ_η = 0.0

# 1) Baseline steady state α_star_det
α_star_det = find_zero(a -> Φ(a) - a, (0.05, 0.95))
@printf("\nDeterministic α★ = %.6f\n", α_star_det)

# Helper for the pure‐deterministic surplus Δ_det(z; α, θ, m)
Δ_det(z, α, θp, mp) = exp(-z)*(1-α)^(-θp) - exp(z)*α^(-θp) - mp

# 2) Baseline cutoff
z_star_base = find_zero(z -> Δ_det(z, α_star_det, θ, m), (-2σ_z, 2σ_z))
@printf("Baseline threshold z* = %.4f  → move if z < z*\n", z_star_base)

# 3) Cutoff when doubling moving cost to m = 0.50
m2 = 2m
z_star_m2 = find_zero(z -> Δ_det(z, α_star_det, θ, m2), (-2σ_z, 2σ_z))
@printf("With m = %.2f, threshold z* = %.4f\n", m2, z_star_m2)

# 4) Cutoff when halving congestion elasticity to θ = 0.20
θ2 = θ/2
z_star_θ2 = find_zero(z -> Δ_det(z, α_star_det, θ2, m), (-2σ_z, 2σ_z))
@printf("With θ = %.2f, threshold z* = %.4f\n", θ2, z_star_θ2)
