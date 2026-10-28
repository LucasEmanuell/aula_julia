# Desafio Mercado Livre / SBPO 2025: seleção ótima de pedidos (wave picking).
#
# Port para Julia/JuMP do ChallengeSolver.java (Java + CPLEX), mantendo a mesma
# estrutura e a mesma matemática.
#
# Escolher pedidos (x) e corredores (y) maximizando
#
#     (itens coletados) / (corredores visitados)
#
# sujeito a LB <= itens coletados <= UB e a estoque suficiente nos corredores.
#
# Funções deste arquivo:
#   read_wave              lê a instância (equivale a `readInput` em Java)
#   wave_model             monta variáveis e restrições, sem objetivo
#   solve_wave_penalty     a solução do Java: um MIP com penalidade (heurística)
#   solve_wave             razão exata, com o método de Dinkelbach (opcional)
#   is_wave_feasible       confere viabilidade (equivale a `isSolutionFeasible`)
#   wave_ratio             calcula o objetivo (equivale a `computeObjectiveFunction`)
#   write_wave_solution    escreve a saída oficial (equivale a `writeOutput`)
using JuMP, HiGHS

# Dados do problema conforme a descrição do desafio
struct WaveInstance
    orders::Vector{Dict{Int,Int}}    # lista de pedidos: item => unidades pedidas
    aisles::Vector{Dict{Int,Int}}    # lista de corredores: item => unidades em estoque
    n_items::Int                     # número total de itens
    lb::Int                          # limite inferior do tamanho da wave (LB)
    ub::Int                          # limite superior do tamanho da wave (UB)
end

"""
Lê uma instância do desafio.

Formato: primeira linha `pedidos itens corredores`; depois uma linha por
pedido e uma por corredor (`k item1 qtd1 item2 qtd2 ...`, com `k` itens
distintos); última linha `LB UB`. No arquivo os itens começam em 0; aqui
somamos 1 para indexar direto nos vetores do Julia.
"""
function read_wave(path)
    lines = readlines(path)
    o, i, a = parse.(Int, split(lines[1]))
    # Cada linha vira um Dict item => quantidade
    rows(range) = map(range) do k
        t = parse.(Int, split(lines[k]))
        Dict(t[2j] + 1 => t[2j+1] for j in 1:t[1])
    end
    lb, ub = parse.(Int, split(lines[end]))
    return WaveInstance(rows(2:1+o), rows(2+o:1+o+a), i, lb, ub)
end

"""
Monta o modelo base (variáveis e restrições, **sem objetivo**).

O objetivo muda conforme a estratégia (penalidade ou Dinkelbach), então cada
solver define o seu e o resto do modelo é reaproveitado.
"""
function wave_model(inst::WaveInstance; time_limit = 60.0)
    O, A = length(inst.orders), length(inst.aisles)

    # Total de unidades de cada pedido
    units = [sum(values(d)) for d in inst.orders]

    # Índice por item: quais pedidos pedem o item e quais corredores o têm.
    # Montado UMA vez, para não percorrer todos os pedidos e corredores a cada
    # item (para o código não ficar lento com instâncias grandes).
    orders_of = [Tuple{Int,Int}[] for _ in 1:inst.n_items]
    aisles_of = [Tuple{Int,Int}[] for _ in 1:inst.n_items]
    for (o, d) in enumerate(inst.orders), (i, u) in d
        push!(orders_of[i], (o, u))
    end
    for (a, d) in enumerate(inst.aisles), (i, u) in d
        push!(aisles_of[i], (a, u))
    end

    model = Model(HiGHS.Optimizer)
    set_silent(model)
    set_time_limit_sec(model, time_limit)

    # ---------------------------------------------------------------
    # Variáveis
    # ---------------------------------------------------------------
    @variable(model, x[1:O], Bin)    # x[o] = 1 se o pedido o entra na wave
    @variable(model, y[1:A], Bin)    # y[a] = 1 se o corredor a é visitado

    # Total de unidades coletadas pela wave: Σ u_oi * x_o
    @expression(model, picked, sum(units[o] * x[o] for o in 1:O))

    # ---------------------------------------------------------------
    # Restrições
    # ---------------------------------------------------------------
    # Restrições (2) e (3): LB ≤ Σ u_oi * x_o ≤ UB
    @constraint(model, inst.lb <= picked <= inst.ub)

    # Restrição (4): Σ u_oi * x_o ≤ Σ u_ai * y_a, ∀ i ∈ I
    # Para cada item, a demanda da wave tem que caber na oferta dos corredores
    # visitados. Itens que nenhum pedido pede não geram restrição.
    @constraint(model, [i in 1:inst.n_items; !isempty(orders_of[i])],
        sum(u * x[o] for (o, u) in orders_of[i]) <=      # demanda do item
        sum(u * y[a] for (a, u) in aisles_of[i]),        # oferta do item
    )

    # Pelo menos um corredor (evita dividir por zero no objetivo)
    @constraint(model, sum(y) >= 1)

    return model
end

"""
Devolve os índices (base 1) das variáveis binárias que valem 1 na solução.
"""
selected(vars) = findall(>(0.5), value.(vars))

"""
A abordagem do solver em Java/CPLEX: um **único MIP** com objetivo linear
`itens + α · corredores`, com α < 0 (penalidade por corredor visitado).

É uma **heurística**: a solução não é garantidamente a que maximiza a razão.
Devolve `(; ratio, orders, aisles)`, ou `nothing` se o solver não achou solução.
"""
function solve_wave_penalty(inst::WaveInstance; time_limit = 60.0)
    model = wave_model(inst; time_limit)

    # --------------------------------------------
    # Cálculo do alpha dinâmico
    # --------------------------------------------
    # Média de unidades por pedido
    avg_units = sum(sum(values(d)) for d in inst.orders) / length(inst.orders)

    # Alpha proporcional à média de unidades por pedido e ao UB
    α = -avg_units * inst.ub / 10

    # --------------------------------------------
    # Função objetivo
    # --------------------------------------------
    # Maximizar: (total de unidades) + alpha * (número de corredores)
    @objective(model, Max, model[:picked] + α * sum(model[:y]))

    # --------------------------------------------
    # Resolução e recuperação da solução
    # --------------------------------------------
    optimize!(model)
    is_solved_and_feasible(model) || return nothing

    orders, aisles = selected(model[:x]), selected(model[:y])
    return (; ratio = value(model[:picked]) / length(aisles), orders, aisles)
end

"""
Razão **exata**, com o método de Dinkelbach (W. Dinkelbach, *On Nonlinear
Fractional Programming*, Management Science 13(7), 1967).

Para maximizar N(x)/D(y), resolve uma sequência de MIPs lineares com objetivo
`N − λ·D`, atualizando λ com a razão da solução encontrada, até λ estabilizar.
Só o objetivo muda entre as iterações.

Devolve `(; λ, history, orders, aisles)`: o λ final, o histórico de λ e a wave.
"""
function solve_wave(inst::WaveInstance; time_limit = 60.0, verbose = false)
    model = wave_model(inst; time_limit)
    picked, x, y = model[:picked], model[:x], model[:y]

    λ, history, chosen = 0.0, Float64[], (Int[], Int[])
    for _ in 1:30    # limite de iterações; na prática converge em poucas
        @objective(model, Max, picked - λ * sum(y))
        optimize!(model)
        is_solved_and_feasible(model) || break

        # Nova razão com a solução desta iteração
        new_λ = value(picked) / sum(value.(y))
        push!(history, new_λ)
        chosen = (selected(x), selected(y))
        verbose && println("  λ = ", round(new_λ; digits = 4))

        abs(new_λ - λ) < 1e-7 && break    # λ estabilizou: razão ótima
        λ = new_λ
    end
    return (; λ = isempty(history) ? NaN : last(history), history,
        orders = chosen[1], aisles = chosen[2])
end

"""
Confere se uma wave (pedidos + corredores, índices base 1) é viável.
Equivale a `isSolutionFeasible` do Java.
"""
function is_wave_feasible(inst::WaveInstance, orders, aisles)
    (isempty(orders) || isempty(aisles)) && return false

    # Total de unidades coletadas de cada item
    picked = zeros(Int, inst.n_items)
    for o in orders, (i, u) in inst.orders[o]
        picked[i] += u
    end

    # Total de unidades disponíveis de cada item nos corredores visitados
    available = zeros(Int, inst.n_items)
    for a in aisles, (i, u) in inst.aisles[a]
        available[i] += u
    end

    # O total coletado precisa estar entre LB e UB
    total = sum(picked)
    (inst.lb <= total <= inst.ub) || return false

    # O que foi coletado não pode passar do disponível
    return all(picked .<= available)
end

"""
Objetivo da wave: total de unidades coletadas dividido pelo número de
corredores visitados. Equivale a `computeObjectiveFunction` do Java.
"""
function wave_ratio(inst::WaveInstance, orders, aisles)
    (isempty(orders) || isempty(aisles)) && return 0.0
    total = sum(sum(values(inst.orders[o])) for o in orders)
    return total / length(aisles)
end

"""
Escreve a solução no formato do desafio (o mesmo de `writeOutput` em Java):
nº de pedidos, um pedido por linha, nº de corredores, um corredor por linha.
Os índices voltam a ser 0-indexados.
"""
function write_wave_solution(path, orders, aisles)
    open(path, "w") do io
        println(io, length(orders))                  # número de pedidos
        foreach(o -> println(io, o - 1), orders)     # cada pedido
        println(io, length(aisles))                  # número de corredores
        foreach(a -> println(io, a - 1), aisles)     # cada corredor
    end
end
