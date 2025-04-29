# Two city, endogenous firm location model 

## Loading the prerequisites
using LinearAlgebra, FastGaussQuadrature, Interpolations, Printf, Random, Plots, Statistics, Roots
include("1d-roots.jl")
## I) Setting the parameters

# Discount factor
β = 0.95

# Persistence and stochastic eror parameters
ρ = 0.8
σ_z = 0.1

# Wage congestion elasticity
θ = 0.4

# Production scale
A = 1.0

# Search and move cost (fixed)
c_move = 0.25
c_search = 0.05

# Taste shock scale for logit smoothing 
σ_η = 0.5

# Numerical parameters 
Nz = 41                     # Grid size for productivity 
n_q = 7                     # Gauss-Hermite quadrature nodes
toler_vfi = 1e-6            # Tolerance for value function iteration
toler_alpha = 1e-6          # Tolerance for α convergence
max_outer = 5               # Max fixed-point iterations

## II) Grid & gauss-hermite nodes 
σ_lr = σ_z / √(1-ρ^2)       # Long run standard deviation
zmax = 3 * σ_lr
zgrid = range(-zmax, zmax ; length = Nz)    # Grid over productivity

x,w = gausshermite(n_q)
w ./= √π                            # Normalizes weights to add up to 1
gh = (; nodes = x, weights = w)

## III) Helper functions (interpolation, profit, expect)
function interp(Vmat::AbstractMatrix)
    """
    interp(Vmat::AbstractMatrix) → GriddedInterpolation

    Main Purpose:
    - Given a matrix of values `Vmat` defined on a regular grid `zgrid×zgrid`,
      construct a smooth, natural-cubic spline approximant in two dimensions.
    - Then wrap it in a “flat” extrapolator so that any query outside the original
      grid returns the closest boundary value rather than throwing an error.

    Arguments:
    - `Vmat::AbstractMatrix` : an `Nz×Nz` array of function values corresponding
      to the equally-spaced nodes in the global `zgrid` vector along each axis.

    Returns:
    - A function-like object `itp` that can be called as `itp(z1, z2)` to obtain
      the interpolated (or extrapolated) value at any point `(z1, z2)`.

    Notes:
    - Uses B-spline basis of degree 3 with natural boundary conditions.
    - `OnGrid()` indicates the data lie exactly on the specified grid nodes.
    - `scale(...)` remaps the integer B-spline axes to the real `zgrid` coordinates.
    - `Flat()` extrapolation clamps out-of-bounds inputs to the nearest grid edge.
    """
    # 1) Build a natural-cubic B-spline interpolant on the unit index grid 1:Nz
    itp = interpolate(Vmat, BSpline(Cubic(Natural())), OnGrid())

    # 2) Rescale the two axes from 1:Nz to the actual values in `zgrid`
    itp = scale(itp, zgrid, zgrid)

    # 3) Wrap with flat extrapolation so that (z1,z2) outside [min(zgrid),max(zgrid)]
    #    returns the boundary value rather than erroring.
    return extrapolate(itp, Interpolations.Flat())
end

function profit(z, α)
    return max(A * exp(z) * (1-α^θ), 0.0) 
end

function exp_futurev(V1, V2, z1, z2, gh)
    """
    exp_futurev(V1, V2, z1, z2, gh) → (Float64, Float64)

    Main Purpose:
    - Compute the two-dimensional Gauss–Hermite quadrature approximation to
      the expected continuation values of two value‐function slices V1 and V2,
      given current shocks (z1, z2) and an AR(1) law.

    Arguments:
    - `V1, V2` : interpolant functions for the value in city 1 and city 2,
                  callable as `Vℓ(z1′, z2′)`.
    - `z1, z2` : current productivity states in city 1 and city 2.
    - `gh`     : NamedTuple with fields
                   • `gh.nodes`   = vector of Gauss–Hermite nodes ξ
                   • `gh.weights` = corresponding weights ω

    Returns:
    - `(out1, out2)` where
        • `out1` ≈ E[V1(z1′,z2′) | z1,z2]
        • `out2` ≈ E[V2(z1′,z2′) | z1,z2]

    Notes:
    - Future shocks follow z′ = ρ·z + √2·σ_z·ξ.
    - We perform a double sum over independent Gauss–Hermite nodes.
    """
    μ1, μ2 = ρ * z1, ρ * z2
    s2 = √2 * σ_z
    out1, out2 = 0.0, 0.0

    for (ω_i, ξ_i) in zip(gh.weights, gh.nodes)
        z1p = μ1 + s2 * ξ_i
        for (ω_j, ξ_j) in zip(gh.weights, gh.nodes)
            z2p = μ2 + s2 * ξ_j
            weight = ω_i * ω_j
            out1 += weight * V1(z1p, z2p)
            out2 += weight * V2(z1p, z2p)
        end 
    end 
    return out1, out2
end

## VI) Value function iteration

function solveV(V, α1, α2)
    """
    solveV(V, α1, α2) → Vector{Matrix}

    Main Purpose:
    - Given current congestion shares α1, α2 and a pair of value‐function matrices V,
      perform value‐function iteration to compute the new value functions Vnew
      that incorporate firms’ optimal “search vs no‐search” and “move vs stay” choices.
    - Continues until the sup‐norm difference between iterations falls below `toler_vfi`.

    Arguments:
    - `V`       : a two‐element Vector of Nz×Nz matrices, V[1] for city 1 and V[2] for city 2.
    - `α1, α2`  : current congestion shares in city 1 and city 2.

    Returns:
    - Updated Vector{Matrix} of value functions `[V1_new, V2_new]` satisfying the Bellman equation
      with search cost and moving cost.
    """
    # prepare storage for updated value functions
    Vnew = [similar(V[1]), similar(V[2])]
    # initial spline interpolants for V
    spl = [interp(V[1]), interp(V[2])]
    diff, iter = 1.0, 0

    # iterate until value‐function converges
    while diff > toler_vfi
        iter += 1
        # rebuild splines on current V
        spl[1] = interp(V[1])
        spl[2] = interp(V[2])
        diff = 0.0

        # loop over all grid points (z1,z2)
        for (i, z1) in enumerate(zgrid), (j, z2) in enumerate(zgrid)
            # --- No‐search: expected continuation values via Gauss–Hermite ---
            EV1, EV2 = exp_futurev(spl[1], spl[2], z1, z2, gh)
            stay1 = profit(z1, α1) + β * EV1
            stay2 = profit(z2, α2) + β * EV2
            move1 = profit(z2, α2) + β * EV2 - c_move
            move2 = profit(z1, α1) + β * EV1 - c_move

            vnosearch1 = max(stay1, move1)
            vnosearch2 = max(stay2, move2)

            # --- With‐search: preview both z1′ and z2′ exactly (double Gauss–Hermite) ---
            μ1, μ2 = ρ*z1, ρ*z2
            EVsearch1, EVsearch2 = 0.0, 0.0

            for (ω_i, ξ_i) in zip(gh.weights, gh.nodes), 
                (ω_j, ξ_j) in zip(gh.weights, gh.nodes)

                # exact future shocks after paying search cost
                z1p = μ1 + √2 * σ_z * ξ_i
                z2p = μ2 + √2 * σ_z * ξ_j
                wgt = ω_i * ω_j

                # if starting in city 1 today:
                stay_if1 = spl[1](z1p, z2p)
                move_if1 = spl[2](z1p, z2p) - c_move
                EVsearch1 += wgt * max(stay_if1, move_if1)

                # if starting in city 2 today:
                stay_if2 = spl[2](z1p, z2p)
                move_if2 = spl[1](z1p, z2p) - c_move
                EVsearch2 += wgt * max(stay_if2, move_if2)
            end

            # add search cost and immediate profit
            vsearch1 = -c_search + β * EVsearch1 + profit(z1, α1)
            vsearch2 = -c_search + β * EVsearch2 + profit(z2, α2)

            # --- Bellman update: choose best of search vs no‐search ---
            Vnew[1][i, j] = max(vnosearch1, vsearch1)
            Vnew[2][i, j] = max(vnosearch2, vsearch2)

            # track maximum change for convergence test
            diff = max(diff,
                       abs(Vnew[1][i,j] - V[1][i,j]),
                       abs(Vnew[2][i,j] - V[2][i,j]))
        end

        # copy updates into V for next iteration
        V[1] .= Vnew[1]
        V[2] .= Vnew[2]
        @printf("    inner iter %3d  |ΔV| = %.3e\n", iter, diff)
    end

    return V
end

## VII) Logit move probability function

function move_p(spl, α1, α2, z1, z2)
    """
    move_p(spl, α1, α2, z1, z2) → (Float64, Float64)

    Main Purpose:
    - Given current congestion shares and spline‐based value functions,
      compute the logit probabilities that a firm will move from its current
      city to the other city, after comparing “stay” vs. “move” continuation values.

    Arguments:
    - `spl`   : a two‐element Vector of interpolants for the value functions
                in city 1 and city 2.
    - `α1, α2`: current congestion shares in city 1 and city 2.
    - `z1, z2`: current productivity levels in city 1 and city 2.

    Returns:
    - `(p_move1, p_move2)` where
        • `p_move1` = Pr(move to city 2 | currently in city 1)
        • `p_move2` = Pr(move to city 1 | currently in city 2)

    Notes:
    - Uses the same Gauss–Hermite expectation via `exp_futurev` to compute
      continuation values.
    - Applies a logistic (logit) error term with scale `σ_η` to smooth the decision.
    """
    # compute expected continuation values under “no-search”
    EV1, EV2 = exp_futurev(spl[1], spl[2], z1, z2, gh)

    # value of staying vs moving (today’s profit + discounted continuation)
    stay1 = profit(z1, α1) + β * EV1
    move1 = profit(z2, α2) + β * EV2 - c_move

    stay2 = profit(z2, α2) + β * EV2
    move2 = profit(z1, α1) + β * EV1 - c_move

    # logit probabilities: higher value option more likely
    p_move1 = 1 / (1 + exp((stay1 - move1) / σ_η))
    p_move2 = 1 / (1 + exp((stay2 - move2) / σ_η))

    return p_move1, p_move2
end


## VIII) Fixed point iteration of firm shares of locations

function update_share(α1, α2, V)
    """
    update_share(α1, α2, V) → (α1_new::Float64, α2_new::Float64)

    Main Purpose:
    - Given the current congestion shares (α1, α2) and the pair of value‐function
      matrices V, compute the next‐period shares implied by firms’ move probabilities.
    - This implements the “aggregate” step in the fixed-point iteration α = Φ(α).

    Arguments:
    - `α1, α2` : current mass of firms in city 1 and city 2 (sum to 1).
    - `V`      : Vector of two Nz×Nz value‐function matrices, V[1] for city 1, V[2] for city 2.

    Returns:
    - `(α1_new, α2_new)` : updated shares, normalized to sum to 1.

    Notes:
    - Uses Gauss–Hermite quadrature (gh.nodes, gh.weights) to integrate over the
      stationary distribution of (z1,z2).
    - Uses `move_p` (logit) to compute the fraction of firms moving from each city.
    """
    # build 2-D spline interpolants of the value functions
    spl = [interp(V[1]), interp(V[2])]

    # accumulators for the new shares
    α1_new = 0.0
    α2_new = 0.0

    # loop over Gauss–Hermite nodes (approximate ergodic z1,z2 distribution)
    for (ω_i, ξ_i) in zip(gh.weights, gh.nodes)
        z1 = √2 * σ_lr * ξ_i
        for (ω_j, ξ_j) in zip(gh.weights, gh.nodes)
            z2 = √2 * σ_lr * ξ_j
            wgt = ω_i * ω_j

            # compute move probabilities from each city at (z1,z2)
            p_move1, p_move2 = move_p(spl, α1, α2, z1, z2)

            # law of motion: fraction staying + fraction arriving
            α1_new += wgt * (α1 * (1 - p_move1) + α2 * p_move2)
            α2_new += wgt * (α2 * (1 - p_move2) + α1 * p_move1)
        end
    end

    # normalize so shares sum to 1
    norm = α1_new + α2_new
    return α1_new / norm, α2_new / norm
end

## IX) Master fixed-point solve
V = [zeros(Nz, Nz), zeros(Nz, Nz)]

function α_residual(α1)
    α2 = 1.0 - α1                       # shares must sum to 1
    V .= solveV(V, α1, α2)              # Bellman solve in-place
    α1_new, _ = update_share(α1, α2, V) # implied next-period share
    return α1_new - α1                  # zero at fixed point
end

α1_star, fval, xm = zbrent(α_residual, 0.05, 0.95;
                           rtol = 1e-6, ftol = 1e-6)

α2_star = 1.0 - α1_star                 # other city’s share
@printf("\nEQUILIBRIUM α* = (%.4f , %.4f)\n", α1_star, α2_star)

## Welfare
function average_value(α1_star::Float64, V)::Float64
    α2_star = 1.0 - α1_star
    spl = [interp(V[1]), interp(V[2])]
    σ_lr_local = σ_z / sqrt(1 - ρ^2)

    total = 0.0
    for (ω_i, ξ_i) in zip(gh.weights, gh.nodes)
        z1 = √2 * σ_lr_local * ξ_i
        for (ω_j, ξ_j) in zip(gh.weights, gh.nodes)
            z2 = √2 * σ_lr_local * ξ_j
            w   = ω_i * ω_j
            total += w * (α1_star * spl[1](z1, z2) +
                          α2_star * spl[2](z1, z2))
        end
    end
    return total
end

# Value 3D Plots 
surface(zgrid, zgrid, V[1], title = "Value in City 1 at Equilibrium")
surface(zgrid, zgrid, V[2], title = "Value in City 2 at Equilibrium")

## Move probability heatmap
Z1 = repeat(zgrid', Nz, 1)
Z2 = Z1'
moveprob = zeros(Nz, Nz)
spl = [interp(V[1]), interp(V[2])]

α1_init, α2_init = 0.3, 0.7

# For each grid point (z₁, z₂), compute P(move from city 1 → city 2)
for i in 1:Nz, j in 1:Nz
    z1, z2 = zgrid[i], zgrid[j]                        # current shocks
    p_move1, _ = move_p(spl, α1_init, α2_init, z1, z2)         # logit move probability
    moveprob[i, j] = p_move1                           # store in matrix
end

# Draw heatmap: color ~ P(move)
heatmap(
    zgrid, zgrid, moveprob,                           # axes and data
    xlabel          = "z₁ (current city)",             # x‐axis label
    ylabel          = "z₂ (other city)",               # y‐axis label
    title           = "Probability of moving (from city 1) (Equilibrium shares)",  # plot title
    colorbar_title  = "P(move)"                        # legend title
)

# -- Recompute value functions using *initial* shares
α1_init, α2_init = 0.3, 0.7
V_init = solveV([zeros(Nz, Nz), zeros(Nz, Nz)], α1_init, α2_init)
spl_init = [interp(V_init[1]), interp(V_init[2])]

# -- Preallocate for initial move probabilities
moveprob_init = zeros(Nz, Nz)

# -- Loop over (z1, z2) and compute move prob from city 1 → city 2 at initial shares
for i in 1:Nz, j in 1:Nz
    z1, z2 = zgrid[i], zgrid[j]
    p_move1_init, _ = move_p(spl_init, α1_init, α2_init, z1, z2)
    moveprob_init[i, j] = p_move1_init
end

# -- Plot initial move probability heatmap
heatmap(
    zgrid, zgrid, moveprob_init,
    xlabel = "z₁ (current city)",
    ylabel = "z₂ (other city)",
    title = "Initial move probability (α₁ = 0.3, α₂ = 0.7)",
    colorbar_title = "P(move)"
)


## Transition-path simulation
function simulate_path(T;
    α1₀   = α1_init,      # Start from equilibrium α1*
    z1₀   = 0.0,
    z2₀   = 0.0,
    Nsim  = 1,       # Number of simulation paths
    stochastic = true,
    rng   = Random.GLOBAL_RNG)

    # Storage across all paths
    α1_hist_all = zeros(Nsim, T)
    α2_hist_all = zeros(Nsim, T)
    move_hist_all = zeros(Nsim, T)
    search_hist_all = zeros(Nsim, T)

    # Build spline interpolants from equilibrium value functions
    spl = [interp(V[1]), interp(V[2])]

    for n in 1:Nsim
        α1, α2 = α1₀, 1 - α1₀
        z1, z2 = z1₀, z2₀

        for t in 1:T
            α1_hist_all[n, t] = α1
            α2_hist_all[n, t] = α2

            # Compute move probabilities
            p_move1, p_move2 = move_p(spl, α1, α2, z1, z2)

            # Share of firms moving and searching
            move_share = α1 * p_move1 + α2 * p_move2
            search_share = c_search > 0 ? 1.0 : 0.0

            move_hist_all[n, t] = move_share
            search_hist_all[n, t] = search_share

            # Update firm shares
            α1_new = α1 * (1 - p_move1) + α2 * p_move2
            α2_new = 1 - α1_new
            α1, α2 = α1_new, α2_new

            # Evolve shocks
            ε1 = stochastic ? randn(rng) : 0.0
            ε2 = stochastic ? randn(rng) : 0.0
            z1 = ρ * z1 + σ_z * ε1
            z2 = ρ * z2 + σ_z * ε2
        end
    end

    # If Nsim > 1, return average across simulations
    return Dict(
        :α1     => Nsim == 1 ? vec(α1_hist_all) : vec(mean(α1_hist_all, dims=1)),
        :α2     => Nsim == 1 ? vec(α2_hist_all) : vec(mean(α2_hist_all, dims=1)),
        :move   => Nsim == 1 ? vec(move_hist_all) : vec(mean(move_hist_all, dims=1)),
        :search => Nsim == 1 ? vec(search_hist_all) : vec(mean(search_hist_all, dims=1))
    )
end

# ----------------- Example: simulate and plot 200 periods -----------------
Tsim = 200
sim_result = simulate_path(Tsim; Nsim=1000)

plot(1:Tsim, [sim_result[:α1] sim_result[:α2]],
    label=["α₁ (city 1)" "α₂ (city 2)"],
    xlabel="Time", ylabel="Share",
    title="Average Congestion Shares (1000 simulations)")
plot!(1:Tsim, sim_result[:move],
    label="Share moving", linestyle=:dash, color=:black)

sim_result1 = simulate_path(Tsim; Nsim=100)

plot(1:Tsim, [sim_result1[:α1] sim_result1[:α2]],
    label=["α₁ (city 1)" "α₂ (city 2)"],
    xlabel="Time", ylabel="Share",
    title="Average Congestion Shares (100 simulations)")
plot!(1:Tsim, sim_result[:move],
    label="Share moving", linestyle=:dash, color=:black)

    