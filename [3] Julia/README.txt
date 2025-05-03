Two-City Endogenous Firm Location Choice Model
==================================================

This repository contains the Julia implementation for a dynamic model of firm location decisions under stochastic productivity shocks, congestion effects, and relocation costs. The model and accompanying code are part of the final project for *Econ 561 – Spatial Economics*.

Overview
--------
Firms choose between two symmetric cities, adjusting their location each period in response to changing productivity, congestion, and idiosyncratic taste shocks. The key features of the model include:

- Endogenous firm sorting driven by forward-looking relocation decisions.
- Natural cubic spline interpolation to evaluate value functions off-grid.
- Gauss–Hermite quadrature for accurate expectation computations over shocks.
- Monte Carlo simulation to analyze transition dynamics.
- Sensitivity analysis to key structural parameters.

Files
-----
**final.jl**  
Main script containing the model implementation and simulation routines. Key components:
- Value-function iteration (VFI) using Gauss–Hermite nodes.
- Steady-state equilibrium computation using Brent's root-finding method.
- Monte Carlo simulation of firm relocations.
- Parameter sensitivity analysis and comparative statics.
- Visualization of equilibrium and transition paths.

**spline.jl**  
Contains a custom spline struct and supporting functions to:
- Construct a natural cubic spline given points and values.
- Evaluate spline and its derivatives at any point using efficient binary search.
- Solve tridiagonal systems as part of the spline construction.

**Econ561_Final_Paper.pdf**  
A full write-up of the economic model, numerical strategy, and results. It includes:
- Economic motivation and literature background.
- Mathematical formulation of the decision problem.
- Bellman equation, logit choice modeling, and aggregation logic.
- Simulation results and comparative statics.
- Interpretation of results and real-world relevance.

How to Run
----------
1. Ensure you have Julia installed (version ≥ 1.6 recommended).
2. Install the required packages:
   using Pkg
   Pkg.add(["FastGaussQuadrature", "Roots", "Plots"])
3. Place `final.jl` and `spline.jl` in the same directory.
4. Run the model:
   include("final.jl")

Output
------
Running the code will generate:
- `fixed_map.png`: Plot of the fixed-point function Φ(α) and its intersection.
- `transition_path.png`: Simulation of the transition from an initial misallocation.
- `alpha_comparative.pdf`: Comparative statics of the equilibrium share α*.
- `beta_comp.pdf`: Relocation probability functions under varying discount factors.

Author
------
Lance Cu Pangilinan  
May 2025 — Yale Econ 561 Final Project
