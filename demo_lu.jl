# Demo de álgebra linear em Julia puro (sem pacotes, só LinearAlgebra para conferir):
#   1. Resolver A x = b com decomposição LU
#   2. Calcular a inversa de A com Gauss-Jordan
#
# Rodar:  julia demo_lu.jl
using LinearAlgebra

## Mostra uma matriz com título, arredondada para caber na tela
function mostra(titulo, M)
    println("\n", titulo)
    show(stdout, "text/plain", round.(M; digits = 4))
    println()
end

# ---------------------------------------------------------------
# 1. Decomposição LU com pivoteamento parcial: P A = L U
# ---------------------------------------------------------------
# L é triangular inferior (com 1 na diagonal), U é triangular superior.
# O pivoteamento troca linhas para evitar dividir por números pequenos ou zero.
function lu_decomp(A)
    n = size(A, 1)
    U = float.(A)              # vira U no fim
    L = Matrix(1.0I, n, n)     # vira L no fim
    p = collect(1:n)           # permutação das linhas

    for k in 1:n-1
        ## Pivô: a linha com maior |valor| na coluna k, de k para baixo
        piv = argmax(abs.(U[k:n, k])) + k - 1
        if piv != k
            U[[k, piv], :] = U[[piv, k], :]
            p[[k, piv]] = p[[piv, k]]
            L[[k, piv], 1:k-1] = L[[piv, k], 1:k-1]
        end
        ## Zera a coluna k abaixo do pivô, guardando o multiplicador em L
        for i in k+1:n
            L[i, k] = U[i, k] / U[k, k]
            U[i, :] -= L[i, k] * U[k, :]
        end
    end
    return L, U, p
end

# Ly = Pb: de cima para baixo
function substituicao_direta(L, b)
    n = length(b)
    y = zeros(n)
    for i in 1:n
        y[i] = b[i] - sum(L[i, j] * y[j] for j in 1:i-1; init = 0.0)
    end
    return y
end

# Ux = y: de baixo para cima
function substituicao_reversa(U, y)
    n = length(y)
    x = zeros(n)
    for i in n:-1:1
        x[i] = (y[i] - sum(U[i, j] * x[j] for j in i+1:n; init = 0.0)) / U[i, i]
    end
    return x
end

function resolve_lu(A, b)
    L, U, p = lu_decomp(A)
    y = substituicao_direta(L, b[p])    # b[p] = P b
    x = substituicao_reversa(U, y)
    return x, L, U, p
end

# ---------------------------------------------------------------
# 2. Inversa por Gauss-Jordan: [A | I]  →  [I | A⁻¹]
# ---------------------------------------------------------------
function inversa_gauss_jordan(A; verbose = false)
    n = size(A, 1)
    M = hcat(float.(A), Matrix(1.0I, n, n))    # matriz aumentada [A | I]
    verbose && mostra("Matriz aumentada [A | I]:", M)

    for k in 1:n
        ## Pivô parcial
        piv = argmax(abs.(M[k:n, k])) + k - 1
        M[[k, piv], :] = M[[piv, k], :]
        ## Normaliza a linha do pivô (pivô vira 1)
        M[k, :] /= M[k, k]
        ## Zera a coluna k em TODAS as outras linhas (acima e abaixo)
        for i in 1:n
            i == k && continue
            M[i, :] -= M[i, k] * M[k, :]
        end
        verbose && mostra("Depois do passo $k (coluna $k vira da identidade):", M)
    end
    return M[:, n+1:end]       # o lado direito é a inversa
end

# ---------------------------------------------------------------
# Execução
# ---------------------------------------------------------------
A = [2.0 1.0 1.0;
     4.0 3.0 3.0;
     8.0 7.0 9.0]
b = [4.0, 10.0, 24.0]          # a solução exata é x = [1, 1, 1]

println("="^60)
println("1. Resolvendo A x = b com decomposição LU")
println("="^60)
mostra("A =", A)
println("\nb = ", b)

x, L, U, p = resolve_lu(A, b)
mostra("L (triangular inferior):", L)
mostra("U (triangular superior):", U)
println("\nPermutação das linhas p = ", p)
println("\nx (nossa solução) = ", round.(x; digits = 6))
println("x (A \\ b do Julia) = ", round.(A \ b; digits = 6))
println("Resíduo ‖A x − b‖ = ", norm(A * x - b))
println("L*U igual a P*A?   ", L * U ≈ A[p, :])

println("\n", "="^60)
println("2. Inversa de A por Gauss-Jordan")
println("="^60)
Ainv = inversa_gauss_jordan(A; verbose = true)
mostra("A⁻¹ (nossa):", Ainv)
mostra("A⁻¹ (inv do Julia):", inv(A))
mostra("A * A⁻¹ (deve ser a identidade):", A * Ainv)
println("\nIgual a inv(A)? ", Ainv ≈ inv(A))
