# Build vs. solve de um problema de transporte denso, em escala crescente.
# Uso:  julia --project=. bench/bench_julia.jl [n1 n2 ...]
# Saída: linhas CSV  lang,n,vars,build_s,solve_s
using JuMP, HiGHS
include(joinpath(@__DIR__, "instances.jl"))

function build(n, m)
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, x[1:n, 1:m] >= 0)
    @objective(model, Min, sum(cost(i, j) * x[i, j] for i in 1:n, j in 1:m))
    @constraint(model, [i in 1:n], sum(x[i, j] for j in 1:m) <= supply(i, n, m))
    @constraint(model, [j in 1:m], sum(x[i, j] for i in 1:n) >= demand(j))
    return model
end

function run(n; solve = n <= 400)
    build(5, 5)                                   # aquece o compilador
    build_s = @elapsed model = build(n, n)
    solve_s = NaN
    if solve
        solve_s = @elapsed optimize!(model)
        @assert is_solved_and_feasible(model)
    end
    return build_s, solve_s
end

sizes = isempty(ARGS) ? [50, 100, 200, 400, 800] : parse.(Int, ARGS)
println("lang,n,vars,build_s,solve_s")
for n in sizes
    b, s = run(n)
    println("julia,$n,$(n*n),$(round(b, digits=3)),$(round(s, digits=3))")
end
