# Gerador determinístico de instâncias de transporte (sem RNG, para que o
# Julia e o Python usem EXATAMENTE os mesmos dados, só pela fórmula).
#
#   n origens, m destinos, grafo denso (n*m arcos)
#   demanda  d_j = 10 + (5j mod 11)
#   custo    c_ij = 1 + (7i + 13j) mod 17
#   oferta   s_i = ceil(1.5 * D / n)   (folga de 50%: sempre viável)

demand(j) = 10 + mod(5j, 11)
cost(i, j) = 1 + mod(7i + 13j, 17)
supply(i, n, m) = ceil(Int, 1.5 * sum(demand, 1:m) / n)
