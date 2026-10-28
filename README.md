# Programação Matemática com Julia e JuMP

Material de uma aula de 1h da disciplina de Programação Matemática (Ciência da Computação,
6º semestre). Este repositório é um guia para você **reproduzir e explorar em casa**:
instale o Julia e o JuMP seguindo os passos abaixo e depois percorra a aula no seu ritmo.

| Arquivo | O que é |
|---|---|
| `aula.jl` | Fonte da aula (Literate.jl). Execute bloco a bloco no VS Code. |
| `aula.ipynb` | Notebook gerado de `aula.jl` (não editar à mão). |
| `demo_lu.jl` | Demo de fatoração LU com Gauss-Jordan. |
| `check_setup.jl` | Script que verifica se a instalação está funcionando. |
| `src/wave.jl` | Modelo JuMP + Dinkelbach do desafio Mercado Livre / SBPO 2025. |
| `bench/` | Benchmark de build/solve: Julia, Pyomo e gurobipy. Resultados em `results_*.csv` e `build_time.png`. |
| `data/` | Dados do transporte (copiados de `lawoc2026`) e instâncias do desafio. |

## Instalação

Você precisa de três coisas: **Julia**, **este repositório** e os **pacotes** (JuMP, HiGHS etc.).
O repositório já traz `Project.toml` e `Manifest.toml`, então os pacotes são instalados
exatamente nas versões usadas na aula. O material foi testado com **Julia 1.12**.

### 1. Instalar o Julia

A forma recomendada é o [`juliaup`](https://github.com/JuliaLang/juliaup), o gerenciador
oficial de versões do Julia. Ele instala o Julia e deixa o comando `julia` no `PATH`.

#### Linux

```sh
curl -fsSL https://install.julialang.org | sh
```

Aceite as opções padrão e **abra um novo terminal** (ou rode `source ~/.bashrc`, ou o
arquivo de configuração do seu shell) para o `julia` aparecer no `PATH`.

#### macOS

```sh
curl -fsSL https://install.julialang.org | sh
```

Aceite as opções padrão e **abra um novo terminal** (ou rode `source ~/.zshrc`).
Alternativa com Homebrew: `brew install juliaup`.

#### Windows

No PowerShell ou no Prompt de Comando:

```powershell
winget install --name Julia --id 9NJNNJQ2MB1V -e -s msstore
```

Alternativa: instale pela [Microsoft Store](https://www.microsoft.com/store/apps/9NJNNJQ2MB1V)
(busque por "Julia"). Depois **feche e abra o terminal** novamente.

#### Fixar a versão 1.12 (todos os sistemas)

```sh
juliaup add 1.12
juliaup default 1.12
julia --version        # deve imprimir julia version 1.12.x
```

> Se preferir não usar o `juliaup`, baixe o instalador em <https://julialang.org/downloads/>
> e certifique-se de que o `julia` está no `PATH`.

### 2. Obter o repositório

Com `git`:

```sh
git clone <URL-DO-REPOSITORIO> aulapm
cd aulapm
```

Sem `git`: use o botão **Code → Download ZIP** no GitHub, extraia a pasta e abra o
terminal dentro dela.

### 3. Instalar JuMP e demais pacotes

Dentro da pasta do repositório (igual em Linux, macOS e Windows):

```sh
julia --project=. -e 'import Pkg; Pkg.instantiate()'
```

Isso baixa e compila JuMP, HiGHS, GLPK, MultiObjectiveAlgorithms, CSV e DataFrames.
Na primeira vez leva alguns minutos e exige internet.

> **Windows (PowerShell):** o comando acima funciona como está. No Prompt de Comando
> (`cmd.exe`), troque as aspas simples por duplas e escape as internas:
> `julia --project=. -e "import Pkg; Pkg.instantiate()"`.

#### Isso precisa ser feito sempre?

- O **Julia** você instala uma vez só.
- Os **pacotes** são instalados **por projeto** (cada pasta com `Project.toml` é um ambiente
  isolado). Rode o comando acima uma vez em cada cópia do repositório. Os arquivos baixados
  ficam num cache compartilhado em `~/.julia`, então outros projetos que usem as mesmas
  versões não baixam tudo de novo.
- Depois de instalado, basta usar `--project=.` (ou `julia --project=.` e `using JuMP`)
  dentro da pasta, sem reinstalar.

#### Usar o JuMP em um projeto seu (fora deste repositório)

Crie uma pasta, entre nela e adicione os pacotes a um ambiente local:

```sh
mkdir meu_projeto && cd meu_projeto
julia --project=.
```

```julia
julia> ]                      # entra no modo de pacotes
(meu_projeto) pkg> add JuMP HiGHS
```

Isso cria `Project.toml` e `Manifest.toml` na pasta. Nas próximas vezes, abra o Julia
sempre com `julia --project=.` dentro dela.

Se rodar `julia` **sem** `--project`, o `add` instala no ambiente global (`@v1.12`), e
`using JuMP` passa a funcionar em qualquer pasta. Funciona, mas não é recomendado: as
versões dos pacotes se misturam entre projetos e podem quebrar com o tempo.

### 4. Verificar a instalação

```sh
julia check_setup.jl
```

Deve terminar imprimindo `Setup OK!`. Se aparecer isso, está tudo pronto.

Teste completo do material (opcional, ~1 min):

```sh
julia --project=. -e 'include("aula.jl")'
```

### 5. Editor (opcional, recomendado)

1. Instale o [VS Code](https://code.visualstudio.com/).
2. Instale a extensão **Julia** (`julialang.language-julia`).
3. Abra a pasta do repositório (`File → Open Folder`) e abra `aula.jl`.
4. Execute bloco a bloco com `Shift+Enter`.

Alternativa: abrir `aula.ipynb` no VS Code (a extensão **Jupyter** é necessária) ou no
Jupyter com o kernel Julia (`using Pkg; Pkg.add("IJulia")`).

### Problemas comuns

| Sintoma | Solução |
|---|---|
| `julia: command not found` / `'julia' não é reconhecido` | Feche e abra o terminal; no Windows, reinicie a sessão. Verifique se o `juliaup` está no `PATH`. |
| `Pkg.instantiate()` falha por rede | Verifique proxy/VPN e rode novamente; o download é retomado. |
| Erro sobre `Manifest.toml` / versão do Julia | Use Julia 1.12 (`juliaup default 1.12`), a mesma do `Manifest.toml`. |
| Primeira execução muito lenta | Normal: a compilação de pacotes acontece uma vez só. |

## Como estudar

1. Abra `aula.jl` (ou `aula.ipynb`) e execute bloco a bloco, lendo os comentários.
2. Altere os dados e as restrições dos exemplos e veja como a solução muda.
3. Rode `demo_lu.jl` para ver a fatoração LU com Gauss-Jordan passo a passo.
4. Leia `src/wave.jl` e tente resolver as instâncias em `data/wave` (desafio Mercado Livre / SBPO 2025).

## Extras

Regerar o notebook: `julia --project=build build/build.jl`.

Benchmark (opcional): `julia --project=. bench/bench_julia.jl` e
`.venv/bin/python bench/bench_python.py | grep -v Restricted`. O `.venv`
precisa de `pyomo gurobipy highspy numpy pandas matplotlib`
(`python -m venv .venv && .venv/bin/pip install pyomo gurobipy highspy numpy pandas matplotlib`;
no Windows o Python fica em `.venv\Scripts\python`).

## Créditos

Material adaptado, com atribuição, de `joaquimg/lawoc` (MIT), `joaquimg/SBPO2024` (MIT) e
dos tutoriais do JuMP (MIT). Instâncias do desafio: Mercado Livre / SBPO 2025.
