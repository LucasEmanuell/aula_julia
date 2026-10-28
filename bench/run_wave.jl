# Resolve uma instância do desafio e escreve a solução no formato oficial,
# para validar com o checker.py do desafio.
# Uso: julia --project=. bench/run_wave.jl <instância> <saída> [penalidade|dinkelbach] [tempo]
include(joinpath(@__DIR__, "..", "src", "wave.jl"))

input, output = ARGS[1], ARGS[2]
method = length(ARGS) >= 3 ? ARGS[3] : "penalidade"
tl = length(ARGS) >= 4 ? parse(Float64, ARGS[4]) : 60.0
inst = read_wave(input)
res = method == "dinkelbach" ? solve_wave(inst; time_limit = tl) :
      solve_wave_penalty(inst; time_limit = tl)
if res === nothing || isempty(res.orders)
    println("sem solução")
else
    write_wave_solution(output, res.orders, res.aisles)
    println("ok: ", method, " → ", output)
end
