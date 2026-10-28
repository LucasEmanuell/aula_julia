"""Mesmo problema de transporte, em Pyomo e gurobipy.

Uso:  .venv/bin/python bench/bench_python.py [n1 n2 ...] | grep -v Restricted
Saída: linhas CSV  lang,n,vars,build_s,solve_s

O gurobipy via pip tem licença restrita (2000 variáveis): aqui ele só
CONSTRÓI o modelo (não resolve), o que basta para comparar o tempo de build.
O Pyomo resolve com o mesmo HiGHS usado no Julia (appsi_highs).
"""
import sys, math, time
import pyomo.environ as pyo
import gurobipy as gp

demand = lambda j: 10 + (5 * j) % 11
cost = lambda i, j: 1 + (7 * i + 13 * j) % 17


def supply(i, n, m):
    return math.ceil(1.5 * sum(demand(j) for j in range(1, m + 1)) / n)


def build_pyomo(n, m):
    I, J = range(1, n + 1), range(1, m + 1)
    mdl = pyo.ConcreteModel()
    mdl.x = pyo.Var(I, J, domain=pyo.NonNegativeReals)
    mdl.obj = pyo.Objective(
        expr=sum(cost(i, j) * mdl.x[i, j] for i in I for j in J), sense=pyo.minimize
    )
    mdl.sup = pyo.Constraint(
        I, rule=lambda md, i: sum(md.x[i, j] for j in J) <= supply(i, n, m)
    )
    mdl.dem = pyo.Constraint(
        J, rule=lambda md, j: sum(md.x[i, j] for i in I) >= demand(j)
    )
    return mdl


def build_gurobipy(n, m):
    I, J = range(1, n + 1), range(1, m + 1)
    mdl = gp.Model()
    mdl.Params.OutputFlag = 0
    x = mdl.addVars(I, J, lb=0.0, name="x")
    mdl.setObjective(gp.quicksum(cost(i, j) * x[i, j] for i in I for j in J))
    mdl.addConstrs(
        (gp.quicksum(x[i, j] for j in J) <= supply(i, n, m) for i in I), name="sup"
    )
    mdl.addConstrs(
        (gp.quicksum(x[i, j] for i in I) >= demand(j) for j in J), name="dem"
    )
    mdl.update()
    return mdl


sizes = [int(a) for a in sys.argv[1:]] or [50, 100, 200, 400, 800]
print("lang,n,vars,build_s,solve_s", flush=True)
for n in sizes:
    t = time.perf_counter(); mp = build_pyomo(n, n); b = time.perf_counter() - t
    s = float("nan")
    if n <= 400:
        solver = pyo.SolverFactory("appsi_highs")
        t = time.perf_counter(); solver.solve(mp); s = time.perf_counter() - t
    print(f"pyomo,{n},{n*n},{b:.3f},{s:.3f}", flush=True)
    t = time.perf_counter(); build_gurobipy(n, n); b = time.perf_counter() - t
    print(f"gurobipy,{n},{n*n},{b:.3f},nan", flush=True)
