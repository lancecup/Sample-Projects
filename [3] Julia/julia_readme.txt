two_city_no_search.jl

Overview
--------
This Julia script analyzes the equilibrium relocation behavior of firms between two symmetric cities under stochastic productivity and congestion effects. It computes:
- Equilibrium fraction of firms in City 1 (α*)
- Deterministic relocation threshold z* when taste shocks are absent (σ_η = 0)
- A sample transition path of α_t over time
- Expected profits at equilibrium in each city

Requirements
------------
- Julia version 1.5 or higher
- Julia packages:
  • FastGaussQuadrature
  • Roots
  • Random
  • Statistics
  • Plots

Installation
------------
1. Install Julia from https://julialang.org/downloads/.
2. Open Julia REPL and add required packages:
   ```
   using Pkg
   Pkg.add(["FastGaussQuadrature", "Roots", "Random", "Statistics", "Plots"])
   ```

Usage
-----
1. Place `two_city_no_search.jl` in your working directory.
2. In a terminal, run:
   ```
   julia two_city_no_search.jl
   ```
3. The script will:
   - Print equilibrium shares α* for both cities.
   - (If σ_η = 0) Print the deterministic threshold z*.
   - Generate a plot of the 500-period transition path (saved in memory or can be saved as `transition_path.png`).
   - Print expected profits in each city at equilibrium.

File Structure
--------------
- `two_city_no_search.jl` : Main Julia script.
- `transition_path.png`  : (Optional) Plot of α_t over time.

Customization
-------------
- Modify parameters at the top of the script:
  • β  : Discount factor
  • θ  : Congestion elasticity
  • m  : Fixed moving cost
  • σ_z: Std. deviation of productivity shocks
  • σ_η: Taste–shock scale (set to 0 for deterministic cutoff)
- Change quadrature nodes `n_q` for accuracy/performance tradeoff.
- Adjust simulation length `T` and initial α₀ in the `simulate` function.

License
-------
This code is provided “as is” for academic and research purposes.

Author
------
Adapted from user’s Econ 417 proposal.

