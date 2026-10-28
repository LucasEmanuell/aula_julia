# Setup verification script.
# Run from the repo root with:  julia check_setup.jl

const ROOT = @__DIR__

println("Julia version: ", VERSION)

import Pkg
Pkg.activate(ROOT)
Pkg.instantiate()

println("Loading JuMP and HiGHS (first time may take a minute)...")
using JuMP, HiGHS

model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, 0 <= x <= 2)
@variable(model, 0 <= y <= 2)
@constraint(model, x + y <= 3)
@objective(model, Max, 2x + y)
optimize!(model)

@assert is_solved_and_feasible(model)
@assert isapprox(objective_value(model), 5.0; atol = 1e-6)

println()
println("Setup OK!")
