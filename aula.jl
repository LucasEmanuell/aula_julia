# # Programação Matemática com Julia e JuMP
#
# Sumário:
#
# | min | bloco |
# |----:|-------|
# | 0-9 | 1. Por que Julia? |
# | 9-15 | 2. Instalação |
# | 15-23 | 3. Julia em poucos minutos |
# | 23-38 | 4. JuMP hands-on |
# | 38-50 | 5. Performance no mundo real |
# | 50-60 | 6. Estudo de caso: desafio Mercado Livre / SBPO 2025 |

# ## 1. Por que Julia?
#
# O problema das **duas linguagens**: prototipa-se em Python/MATLAB
# (fácil, mas lento) e reescreve-se em C++/Java (rápido, mas trabalhoso).
# Julia busca as duas coisas em uma só: sintaxe de alto nível, código
# compilado (JIT, via LLVM) com velocidade próxima de C.
#
# Para **otimização** em particular:
#
# - **JuMP** é uma linguagem de modelagem *embutida* na linguagem: o modelo
#   é código Julia, então dá para usar `if`, funções, structs e pacotes
#   normalmente. Não há uma "linguagem à parte" (como AMPL/GAMS).
# - **Um modelo, ~40 solvers**: HiGHS, Gurobi, CPLEX, Ipopt, SCS... trocando
#   uma linha.
# - **Código aberto** (MIT), e pesquisa recente (SDDP.jl, DiffOpt.jl,
#   solvers em GPU) costuma aparecer primeiro no ecossistema Julia.
#
# O que Julia **não** é: um resolvedor mais rápido. O tempo de *solve* é do
# solver (o mesmo HiGHS/Gurobi chamado do Python). A diferença está na
# modelagem, no loop em volta do solver e em não precisar de uma segunda
# linguagem. Vamos medir isso na seção 5.

# ### Julia, JuMP e solver: quem é quem
#
# Três coisas diferentes, que costumam ser confundidas:
#
# | | O que é | Analogia em Python |
# |---|---|---|
# | **Julia** | a *linguagem de programação* | Python |
# | **JuMP** | um *pacote* de Julia para escrever modelos de otimização | Pyomo, PuLP |
# | **HiGHS, Gurobi, ...** | o *solver*: o programa que resolve o modelo | o mesmo HiGHS, o mesmo Gurobi |
#
# Julia existe sem JuMP (serve para simulação, ciência de dados, etc.).
# JuMP só existe dentro de Julia. O JuMP **não resolve nada**: ele traduz o
# modelo para o solver, que é escrito em C/C++ e é o mesmo que o Python usa.
#
# ### Sobre a linguagem
#
# - **Origem**: criada no **MIT** por Jeff Bezanson, Stefan Karpinski,
#   Viral Shah e Alan Edelman; anunciada em 2012, versão 1.0 em 2018. O JuMP
#   também nasceu no MIT (Operations Research Center).
# - **Feita para computação científica**: álgebra linear, números complexos,
#   racionais e notação matemática são parte da linguagem, não de bibliotecas.
# - **Aberta** (licença MIT) e gratuita, com compilador JIT via LLVM.
#
# O que costuma surpreender quem vem de Python ou C++:
#
# | | Julia | Python | C++ |
# |---|---|---|---|
# | Índices | começam em **1** (como Fortran/MATLAB/R) | em 0 | em 0 |
# | Execução | JIT: compila na 1ª chamada | interpretada | compilada antes |
# | Símbolos matemáticos (`π`, `≤`, `∈`) | permitidos no código | só em strings | não |
# | Álgebra linear (`A \ b`) | na linguagem | NumPy | Eigen/BLAS |
# | Inteiros | 64 bits, **estouram** | ilimitados | 32/64 bits, estouram |
# | Orientação a objetos | `struct` + métodos por *dispatch* | classes | classes |
#
# Na prática, em 2 minutos:

# Operadores aritméticos. Atenção às diferenças para Python e C++:
#
# | Operação | Julia | Observação |
# |---|---|---|
# | soma, subtração, produto | `+`  `-`  `*` | |
# | divisão | `/` | sempre devolve real: `7/2` é `3.5` |
# | divisão **exata** (fração) | `//` | `7//2` é a fração `7//2` (em Python, `//` é divisão inteira) |
# | divisão inteira | `÷` ou `div` | `7 ÷ 2` é `3` |
# | resto | `%` ou `rem`, e `mod` | `mod(-7, 3)` é `2`; `rem(-7, 3)` é `-1` |
# | potência | `^` | `2^10`. O `**` **não existe** em Julia (dá erro de sintaxe) |

7 / 2, 7 // 2, 7 ÷ 2, 7 % 2, 2^10

#-

## Julia converte os tipos sozinha quando precisa: real + fração dá real.
1/3 + 1//3, typeof(7 // 2), 2.0^0.5

# Cuidado com o `²`: ele **não** é operador. Em nomes, símbolos Unicode fazem
# parte do identificador, então `a²` seria uma variável chamada "a²" (e daria
# `UndefVarError`). Para elevar ao quadrado, use `^2`. Já `√` **é** operador.

a = 3
a^2, √a

# Unicode nos nomes e operadores. No editor digita-se `\pi` + Tab, `\alpha` + Tab,
# `\le` + Tab, `\in` + Tab.

π, 2π, √2

#-

α = 0.05
β = α^2
x = 3
x ≤ 5, x ∈ [1, 2, 3], x ≠ 4

# Números de verdade, sem importar nada: racionais e complexos.
# (`//` cria uma fração exata; `im` é a unidade imaginária.)

1//3 + 1//6, (3 + 4im) * (1 - 2im), abs(3 + 4im)

# Ponto flutuante tem erro de arredondamento em **qualquer** linguagem:
# compara-se com `≈`, não com `==`.

0.1 + 0.2 == 0.3, 0.1 + 0.2 ≈ 0.3

# Álgebra linear é nativa, com índices a partir de 1 e `end` para o último.
# `A \ b` resolve o sistema linear `A x = b`.

A = [2 1; 1 3]
b = [1, 2]
A \ b, A * b, A', b[1], b[end]

# Atenção: inteiros têm 64 bits e **estouram em silêncio** (diferente do
# Python, onde são ilimitados). Para precisão arbitrária usa-se `big`.

2^62, 2^63, big(2)^100

# Intervalos são "preguiçosos": `1:10^9` não aloca um bilhão de números.

r = 1:10^9
sum(r), Base.summarysize(r)

# Convenções que o JuMP e o resto do ecossistema seguem:
#
# - `f!(x)` (com `!`) **modifica** o argumento: `optimize!(model)`.
# - `@nome` é uma **macro** (reescreve o código): `@variable`, `@constraint`,
#   `@time`. É o que deixa o modelo JuMP parecido com a notação matemática.
# - No REPL, `?função` mostra a documentação; `]` entra no modo de pacotes.
# - Chama-se C e Python direto (`ccall`, PythonCall.jl), então não se
#   perde código antigo.

# ## 2. Instalação
#
# ```sh
# curl -fsSL https://install.julialang.org | sh      # juliaup (Linux/macOS)
# julia --project=. -e 'import Pkg; Pkg.instantiate()'
# julia check_setup.jl                              # deve imprimir "Setup OK!"
# ```
#
# - `juliaup` gerencia versões do Julia.
# - Cada projeto tem `Project.toml` + `Manifest.toml`: o ambiente é
#   reprodutível (parecido com `venv` + `requirements.txt` travado).

import Pkg

## Acha a pasta do projeto (a que contém aula.jl), mesmo que o kernel do
## notebook tenha sido iniciado em outra pasta, como uma subpasta.
raiz = @__DIR__
while !isfile(joinpath(raiz, "aula.jl")) && raiz != dirname(raiz)
    global raiz = dirname(raiz)
end
isfile(joinpath(raiz, "aula.jl")) ||
    error("Abra o notebook a partir da pasta do projeto (onde está aula.jl).")

Pkg.activate(raiz)
Pkg.instantiate()

using JuMP
using HiGHS
using CSV, DataFrames

# ## 3. Julia em poucos minutos

# ### Tipos: dinâmica, mas o compilador especializa
#
# Não é preciso declarar tipos; o compilador gera uma versão para cada um:

f(x) = 2x + 1
f(3), f(2.5), f(1//2)

# ### Multiple dispatch: "o método depende dos tipos dos argumentos"
#
# Em Python/Java, `obj.metodo()` escolhe o método pelo tipo de **um** objeto
# (o que vem antes do ponto). Em Julia, `funcao(a, b)` escolhe entre vários
# métodos com o mesmo nome olhando os tipos de **todos** os argumentos.
# Cada método é uma definição separada, marcada com `::Tipo`:

describe(x::Integer) = "inteiro $x"
describe(x::AbstractFloat) = "real $x"
describe(x::AbstractString) = "texto '$x'"
describe.([1, 2.5, "oi"])

# Três métodos, um nome: `describe`. Julia escolheu o certo para cada valor.
# Dá para ver todos os métodos de uma função:

methods(describe)

# **Por que isso importa para o JuMP?** O operador `+` também é uma função
# com muitos métodos. Um deles soma números; outro soma *variáveis de decisão*.
# Ninguém mexeu na linguagem: o JuMP só **adicionou métodos** a `+` e `*`.

m = Model()
@variable(m, z)
2 + 3, 2 + z, 2 * z + 1

# O mesmo `+` produziu um número e, depois, uma expressão linear (`AffExpr`).
# É por isso que o modelo escrito no código parece a fórmula matemática.

typeof(2 + 3), typeof(2z + 1)

# ### Broadcasting: o ponto `.` aplica a operação elemento a elemento
#
# Funções comuns esperam um valor. Para aplicar a uma lista inteira, põe-se
# um `.` depois do nome. Sem ele, dá erro (não há `sqrt` de um vetor):

v = [1, 4, 9, 16]
sqrt.(v)

#-

try
    sqrt(v)
catch e
    println("Erro (esperado): ", typeof(e))
end

# O mesmo vale para operadores: `.*`, `.+`, `.<=`. O custo de cada item vezes
# a quantidade de cada item, por exemplo:

custo = [2.0, 3.0, 5.0]
qtd = [10, 20, 30]
custo .* qtd

# **Por que isso importa para o JuMP?** Funciona com variáveis também.
# Um modelo de custo mínimo, em uma linha, sem laço:

@variable(m, q[1:3] >= 0)
custo .* q

#-

sum(custo .* q)

# Compreensões (`[expr for ... if ...]`) fazem filtro e transformação juntos:
# aqui, o quadrado só dos números pares.

[i^2 for i in 1:6 if iseven(i)]

# Loops simples são rápidos (sem "vetorizar para ficar rápido" como no
# NumPy). Meça a **segunda** chamada: a primeira inclui a compilação.

function soma_loop(n)
    s = 0.0
    for i in 1:n
        s += sqrt(i)
    end
    return s
end

soma_loop(10)                       ## aquece
@time soma_loop(10^8)

# ## 4. JuMP hands-on
#
# ```
# seu código  →  JuMP  →  MathOptInterface  →  solver (HiGHS, Gurobi, ...)
# ```
#
# O **MathOptInterface (MOI)** é o tradutor no meio: cada solver tem uma API
# própria, e o MOI define uma descrição comum de problema (variáveis,
# restrições, objetivo, status). O JuMP traduz o modelo para o MOI uma vez, e
# um pacote adaptador de cada solver converte o MOI para a API dele. É por isso
# que o mesmo modelo roda em vários solvers.
#
# ### Mochila (knapsack)
#
# ```math
# \max \sum_i v_i x_i \quad \text{s.a.} \quad \sum_i w_i x_i \le C,\; x_i \in \{0,1\}
# ```

itens = ["martelo", "chave", "chave_de_fenda", "toalha"]
valor = Dict(zip(itens, [8.0, 3.0, 6.0, 11.0]))
peso = Dict(zip(itens, [5.0, 7.0, 4.0, 3.0]))
capacidade = 14.0;

# (`valor` e `peso`, e não `value`, para não sobrescrever `value()` do JuMP.)

mochila = Model(HiGHS.Optimizer)
set_silent(mochila)
@variable(mochila, x[i in itens], Bin)
@constraint(mochila, sum(peso[i] * x[i] for i in itens) <= capacidade)
@objective(mochila, Max, sum(valor[i] * x[i] for i in itens))
print(mochila)

#-

optimize!(mochila)
solution_summary(mochila)

# **Sempre** cheque o status antes de ler a solução:

@assert is_solved_and_feasible(mochila)
objective_value(mochila), [i for i in itens if value(x[i]) > 0.5]

# ### Transporte, lendo dados de CSV
#
# Plantas com oferta, mercados com demanda, custo por arco.

plantas = CSV.read(joinpath(raiz, "data", "plants.csv"), DataFrame)
mercados = CSV.read(joinpath(raiz, "data", "markets.csv"), DataFrame)
frete = CSV.read(joinpath(raiz, "data", "shipping_costs.csv"), DataFrame)
first(frete, 4)

#-

oferta = Dict(plantas.plant .=> plantas.supply)
demanda = Dict(mercados.market .=> mercados.demand)
custo = Dict((r.plant, r.market) => r.cost for r in eachrow(frete))
P, M = collect(keys(oferta)), collect(keys(demanda))

transp = Model(HiGHS.Optimizer)
set_silent(transp)
@variable(transp, fluxo[p in P, m in M] >= 0)
@constraint(transp, c_oferta[p in P], sum(fluxo[p, m] for m in M) <= oferta[p])
@constraint(transp, c_demanda[m in M], sum(fluxo[p, m] for p in P) >= demanda[m])
@objective(transp, Min, sum(custo[p, m] * fluxo[p, m] for p in P, m in M))
optimize!(transp)
@assert is_solved_and_feasible(transp)
objective_value(transp)

# Duais (preço-sombra): quanto custa a mais atender 1 unidade extra de demanda?

Dict(m => dual(c_demanda[m]) for m in M)

# ### Trocar de solver é uma linha
#
# ```julia
# using Gurobi            # precisa de licença (gratuita para academia)
# set_optimizer(transp, Gurobi.Optimizer)
# ```
#
# O **modelo não muda**. Isso é MathOptInterface: HiGHS (LP/MIP, aberto),
# Ipopt (não linear), SCS/Clarabel (cônico), Gurobi/CPLEX/COPT/Xpress
# (comerciais, em geral mais rápidos em MIPs grandes).

# ### Modificar e re-resolver
#
# Alterar um dado e resolver de novo é mais barato do que reconstruir: o
# solver parte da solução anterior.

set_normalized_rhs(c_demanda[first(M)], demanda[first(M)] + 100)
optimize!(transp)
objective_value(transp)

# ## 5. Performance no mundo real
#
# Duas fontes de lentidão, bem diferentes:
#
# 1. **Build**: seu código criando o modelo (lado JuMP/linguagem).
# 2. **Solve**: o algoritmo do solver (lado HiGHS/Gurobi).
#
# ### Medição: transporte denso, mesma fórmula em Julia, Pyomo e gurobipy
#
# Scripts em `bench/` (`bench_julia.jl`, `bench_python.py`), rodados em uma
# máquina de 12 núcleos, uma execução por ponto, HiGHS como solver:

results = vcat(
    CSV.read(joinpath(raiz, "bench", "results_julia.csv"), DataFrame),
    CSV.read(joinpath(raiz, "bench", "results_python.csv"), DataFrame),
)
## `NaN` = não medido: o gurobipy (licença restrita do pip) só constrói o
## modelo, e o solve do Pyomo com 640 mil variáveis não foi medido.
results.solve_s = replace(results.solve_s, NaN => missing)
sort(results, [:n, :lang])

# Leitura honesta dos números:
#
# - **Build**: nesse caso, JuMP fica na casa de 3-4× mais rápido que
#   Pyomo/gurobipy em centenas de milhares de variáveis. Não é
#   "ordens de grandeza", e isso é bom saber.
# - **Solve**: dominado pelo HiGHS, praticamente o mesmo em qualquer
#   linguagem (as diferenças aqui incluem a transferência do modelo ao solver).
# - Código bem escrito em Python é competitivo. A vantagem do JuMP é
#   real, mas moderada: o que muda a vida é escrever o modelo, o laço em volta
#   do solver e o pré-processamento na mesma linguagem.

# ## 6. Estudo de caso: desafio Mercado Livre / SBPO 2025
#
# ### O problema
#
# Num armazém, os itens ficam em **corredores**. Chegam **pedidos** de
# clientes, cada um com uma lista de itens e quantidades. Coletar um pedido de
# cada vez é ineficiente; o melhor é agrupar vários pedidos numa **wave** e
# coletá-los juntos, visitando poucos corredores.
#
# Decidir:
#
# - quais pedidos entram na wave ($x_o \in \{0,1\}$);
# - quais corredores serão visitados ($y_a \in \{0,1\}$).
#
# Maximizar a produtividade: **itens coletados por corredor visitado**.
#
# ```math
# \max \frac{\sum_{o} \sum_{i} u_{oi}\, x_o}{\sum_a y_a}
# \quad \text{s.a.} \quad
# LB \le \sum_{o}\sum_{i} u_{oi}\, x_o \le UB, \qquad
# \sum_o u_{oi}\, x_o \le \sum_a u_{ai}\, y_a \;\; \forall i
# ```
#
# - $u_{oi}$: unidades do item $i$ pedidas no pedido $o$;
# - $u_{ai}$: unidades do item $i$ disponíveis no corredor $a$;
# - $LB, UB$: limites do tamanho da wave (total de unidades);
# - a última restrição diz: o que a wave pede de cada item tem que existir
#   nos corredores visitados.
#
# ### O formato dos arquivos `.txt`
#
# Exemplo (`data/wave/instance_0020.txt`, o exemplo do enunciado):
#
# ```
# 5 5 5              <- nº de pedidos, nº de itens, nº de corredores
# 2 0 3 2 1          <- pedido 0: 2 itens distintos: item 0 (3 un.), item 2 (1 un.)
# 2 1 1 3 1          <- pedido 1: item 1 (1 un.), item 3 (1 un.)
# 2 2 1 4 2          <- pedido 2: item 2 (1 un.), item 4 (2 un.)
# 4 0 1 2 2 3 1 4 1  <- pedido 3: 4 itens distintos ...
# 1 1 1              <- pedido 4: item 1 (1 un.)
# 4 0 2 1 1 2 1 4 1  <- corredor 0: 4 itens distintos, com as unidades em estoque
# ...                   (mais 4 linhas de corredores)
# 5 12               <- LB e UB (total de unidades da wave)
# ```
#
# Regras: cada linha começa com **quantos itens distintos** há nela,
# seguida de pares `item quantidade`. As primeiras linhas são os pedidos, as
# seguintes são os corredores. A última linha é `LB UB`. Os itens são
# numerados a partir de 0 (em Julia, somamos 1).
#
# Lendo o arquivo e transformando em tabelas (linhas = pedidos ou
# corredores, colunas = itens), reproduzimos as Tabelas 1 e 2 do enunciado:

include(joinpath(raiz, "src", "wave.jl"))

toy = read_wave(joinpath(raiz, "data", "wave", "instance_0020.txt"))
pedidos = [get(d, i, 0) for d in toy.orders, i in 1:toy.n_items]

#-

corredores = [get(d, i, 0) for d in toy.aisles, i in 1:toy.n_items]

# ### O objetivo é uma fração: como resolver?
#
# O objetivo é $N(x)/D(y)$ (itens dividido por corredores), que **não é
# linear**, então um solver de MIP não aceita direto. Há duas saídas.
#
# **Saída 1: penalidade (a da minha solução na competição).** Troca a
# fração por um objetivo linear: $\text{itens} - \alpha \cdot \text{corredores}$,
# onde $\alpha$ é uma penalidade por corredor visitado (na minha solução,
# $\alpha = (\text{média de unidades por pedido}) \cdot UB / 10$).
# É **um único MIP**, então é rápido, mas é uma *heurística*: não há garantia
# de achar a melhor razão.
#
# Na instância do enunciado (resposta conhecida: 5,0):

pen = solve_wave_penalty(toy)
pen.ratio, pen.orders .- 1, pen.aisles .- 1

# A wave usa os pedidos 0, 1, 2 e 4 e os corredores 1 e 3: 10 unidades em 2
# corredores, razão 5. É a mesma solução do enunciado.
#
# Numa instância maior (61 pedidos, 116 corredores, 155 itens):

inst = read_wave(joinpath(raiz, "data", "wave", "instance_0001.txt"))
length(inst.orders), length(inst.aisles), inst.n_items, (inst.lb, inst.ub)

#-

solve_wave_penalty(inst).ratio

# **Saída 2: razão exata, com o método de Dinkelbach.** É uma técnica
# clássica de *programação fracionária* (W. Dinkelbach, "On Nonlinear
# Fractional Programming", *Management Science*, 13(7), 1967). A ideia é
# resolver uma sequência de MIPs lineares, cada um com
# $\text{itens} - \lambda \cdot \text{corredores}$, e a cada passo atualizar
# $\lambda$ com a razão da solução encontrada. Quando $\lambda$ para de mudar,
# esse é o valor da razão ótima.
#
# Só o objetivo muda entre as iterações, e o JuMP reaproveita o resto do modelo:

res = solve_wave(toy; verbose = true)
res.λ

# Aqui terminou em poucas iterações (λ = 2,4 → 5,0 → 5,0). Nas instâncias 01 e
# 20, as duas saídas dão o mesmo valor. Mas nem sempre: na instância 03
# (82 pedidos), a penalidade fica abaixo do ótimo.

inst3 = read_wave(joinpath(raiz, "data", "wave", "instance_0003.txt"))
solve_wave_penalty(inst3).ratio, solve_wave(inst3).λ

# A penalidade acha 11,67 e o Dinkelbach acha 12,0: é o preço de trocar a
# fração por um único MIP. Para esta aula, a ideia central é que o JuMP deixa
# trocar a estratégia de modelagem mudando poucas linhas, e não o Dinkelbach em si.
#
# ### Validando a solução
#
# O Java tem `isSolutionFeasible` e `computeObjectiveFunction`; em Julia são
# `is_wave_feasible` e `wave_ratio` (em `src/wave.jl`). Conferindo a wave que
# a penalidade achou na instância do enunciado:

is_wave_feasible(toy, pen.orders, pen.aisles), wave_ratio(toy, pen.orders, pen.aisles)

# O desafio também tem um verificador oficial (`checker.py`). O script
# `bench/run_wave.jl` escreve a solução no formato oficial:
#
# ```sh
# julia --project=. bench/run_wave.jl data/wave/instance_0001.txt saida.txt penalidade
# python checker.py data/wave/instance_0001.txt saida.txt
# # Is solution feasible: True / Objective function value: 15.0
# ```
#
# ### Comparação com a solução em Java + CPLEX
#
# A solução em Java (`ChallengeSolver.java`) é a **Saída 1**: um único MIP com
# penalidade por corredor. A versão em Julia é `solve_wave_penalty`
# (em `src/wave.jl`), a mesma ideia e o mesmo modelo.
#
# | | Java + CPLEX | Julia + JuMP |
# |---|---|---|
# | Linhas do modelo | ~110 (com comentários) | ~35 (`wave_model`, com comentários) |
# | Variáveis | `IloIntVar[] x = new ...; cplex.boolVar(...)` em laço | `@variable(model, x[1:O], Bin)` |
# | Soma de termos | `IloLinearNumExpr` + `addTerm` em laços aninhados | `sum(u * x[o] for (o, u) in ...)` |
# | Restrição de estoque | laço sobre itens, pedidos e corredores, com `containsKey` | `@constraint(model, [i in itens], ...)` |
# | Trocar o solver | reescrever com outra API | trocar `HiGHS.Optimizer` |
# | Tratamento de erro | `try/catch` de `IloException` | `is_solved_and_feasible` |
#
# A diferença de linhas vem do código de infraestrutura do CPLEX
# (expressões, tipos, exceções), e **não** da matemática, que é a mesma.
# Não estamos comparando velocidade: o CPLEX é um solver comercial e o HiGHS
# é aberto, então o tempo de *solve* depende do solver, não da linguagem.
#
# ### E em escala?
#
# Com HiGHS e a penalidade, as instâncias pequenas e médias do desafio
# (por exemplo, 02, 03 e 04, com até 82 pedidos) resolvem em poucos segundos
# e o checker as aceita. As grandes (`datasets/a`, até milhares de pedidos)
# **não** resolvem em 30-60 s: nas instâncias 05 e 10, o MIP da penalidade nem
# acha solução. Com um solver comercial, ou com uma heurística em cima do
# modelo, o caminho muda. É por isso que "trocar de solver em uma linha" não é
# detalhe: o *modelo* continua o mesmo.

# ## Extras (se sobrar tempo)
#
# ### Callbacks: restrições adicionadas durante a busca
#
# Às vezes o modelo tem restrições demais para listar de antemão (por exemplo,
# eliminação de sub-rotas no TSP). Com um **callback** (*lazy constraint*), o
# solver pergunta ao seu código sempre que acha uma solução inteira, e o código
# adiciona só as restrições violadas.
#
# Exemplo mínimo: maximizar $y$ com $x, y$ inteiros em $[0, 2{,}5]$. As
# restrições $y - x \le 1$ e $y + x \le 3$ **não** estão no modelo: o callback
# as adiciona quando necessário.

using GLPK

modelo_cb = Model(GLPK.Optimizer)
set_silent(modelo_cb)
@variable(modelo_cb, 0 <= xc <= 2.5, Int)
@variable(modelo_cb, 0 <= yc <= 2.5, Int)
@objective(modelo_cb, Max, yc)

chamadas = Ref(0)
function restricoes_preguicosas(cb_data)
    chamadas[] += 1
    x_val = callback_value(cb_data, xc)
    y_val = callback_value(cb_data, yc)
    status = callback_node_status(cb_data, modelo_cb)
    if status == MOI.CALLBACK_NODE_STATUS_INTEGER
        if y_val - x_val > 1 + 1e-6
            con = @build_constraint(yc - xc <= 1)
            MOI.submit(modelo_cb, MOI.LazyConstraint(cb_data), con)
        elseif y_val + x_val > 3 + 1e-6
            con = @build_constraint(yc + xc <= 3)
            MOI.submit(modelo_cb, MOI.LazyConstraint(cb_data), con)
        end
    end
    return
end

set_attribute(modelo_cb, MOI.LazyConstraintCallback(), restricoes_preguicosas)
optimize!(modelo_cb)
@assert is_solved_and_feasible(modelo_cb)
value(xc), value(yc), chamadas[]

# Nem todo solver suporta callbacks: o GLPK suporta, o HiGHS (que usamos no
# resto da aula) não. Trocar de solver é uma linha, mas é preciso conferir o
# que ele suporta.
#
# ### Multiobjetivo: um conjunto de compromissos
#
# Com dois objetivos conflitantes (lucro e "desejo" de um conjunto de itens na
# mochila), não existe uma única solução ótima. O que se obtém é o conjunto de
# soluções de compromisso (fronteira de Pareto), e a pessoa escolhe uma.

import MultiObjectiveAlgorithms as MOA

lucro = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91]
desejo = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92]
peso_mo = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93]

mochila_mo = Model()
@variable(mochila_mo, z[1:10], Bin)
@constraint(mochila_mo, sum(peso_mo[i] * z[i] for i in 1:10) <= 500)
@expression(mochila_mo, lucro_total, sum(lucro[i] * z[i] for i in 1:10))
@expression(mochila_mo, desejo_total, sum(desejo[i] * z[i] for i in 1:10))
@objective(mochila_mo, Max, [lucro_total, desejo_total])
set_optimizer(mochila_mo, () -> MOA.Optimizer(HiGHS.Optimizer))
set_silent(mochila_mo)
set_attribute(mochila_mo, MOA.Algorithm(), MOA.EpsilonConstraint())
optimize!(mochila_mo)
@assert termination_status(mochila_mo) == OPTIMAL
result_count(mochila_mo)

# Cada solução da lista é um compromisso diferente entre lucro e desejo:

DataFrame(
    solucao = 1:result_count(mochila_mo),
    lucro = [value(lucro_total; result = k) for k in 1:result_count(mochila_mo)],
    desejo = [value(desejo_total; result = k) for k in 1:result_count(mochila_mo)],
)

# Quem sobe em lucro perde em desejo, e vice-versa. O solver devolve os
# compromissos e quem decide é a pessoa.
