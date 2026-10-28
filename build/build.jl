# Gera o notebook a partir de aula.jl (Literate.jl).
# Uso (na raiz do repo):  julia --project=build -e 'import Pkg; Pkg.instantiate()'
#                         julia --project=build build/build.jl
import Pkg
Pkg.activate(@__DIR__)
using Literate

const ROOT = dirname(@__DIR__)
Literate.notebook(joinpath(ROOT, "aula.jl"), ROOT; execute = false, name = "aula")
@info "Notebook gerado em aula.ipynb"
