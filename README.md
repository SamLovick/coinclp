# coinclp

<!-- badges: start -->
[![R-CMD-check](https://github.com/SamLovick/coinclp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SamLovick/coinclp/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

An R interface to [COIN-OR Clp](https://github.com/coin-or/Clp), the simplex
and interior point linear programming solver of the COIN-OR project.

`coinclp` replaces the [clpAPI](https://cran.r-project.org/package=clpAPI)
package, which was archived from CRAN on 2021-11-30 and took
[ROI.plugin.clp](https://cran.r-project.org/package=ROI.plugin.clp) with it in
January 2022. The bindings here are written from scratch against the current
Clp callable library, use registered `.Call` entry points and external
pointers with finalizers, and build on R 4.5 and R 4.6. A compatibility layer
reproduces clpAPI's exported functions so existing code runs unchanged.

## Installation

Clp is not bundled; install the library first.

| Platform | Command |
| --- | --- |
| Windows | nothing to do: Rtools 4.3 and later ship Clp |
| Debian / Ubuntu | `sudo apt-get install coinor-libclp-dev` |
| Fedora / RHEL | `sudo dnf install coin-or-Clp-devel` |
| macOS | `brew install clp` |
| conda-forge | `conda install coin-or-clp` |

Then:

```r
# install.packages("remotes")
remotes::install_github("SamLovick/coinclp")
```

If Clp sits somewhere `pkg-config` does not look:

```sh
R CMD INSTALL coinclp \
  --configure-args='--with-clp-include=/opt/clp/include/coin --with-clp-lib=/opt/clp/lib'
```

## One call

```r
library(coinclp)

# maximise 143x + 60y subject to
#   120x + 210y <= 15000
#   110x +  30y <=  4000
#     x  +   y  <=    75
A <- rbind(c(120, 210), c(110, 30), c(1, 1))
res <- clp_solve(c(143, 60), A, "<=", c(15000, 4000, 75), max = TRUE)

res$objval      # 6315.625
res$solution    # 21.875 53.125
res$duals       # 0.000 1.0375 28.875
```

`constraints` accepts a dense matrix, a sparse `Matrix` object, a
`slam::simple_triplet_matrix`, or a list of `i`/`j`/`v` triplets. Ranged
constraints are written with `row_lower` and `row_upper` instead of
`dir`/`rhs`.

## A model you keep

The full callable library is available for building a model once and
re-solving it as it changes, which is where Clp earns its keep:

```r
model <- clp_model()
clp_load_problem(model, ncols = 2, nrows = 3,
                 start = c(0L, 3L, 6L),
                 index = c(0L, 1L, 2L, 0L, 1L, 2L),
                 value = c(120, 110, 1, 210, 30, 1),
                 obj   = c(-143, -60),
                 rowub = c(15000, 4000, 75))
clp_initial_solve(model)
clp_objective_value(model)          # -6315.625

basis <- clp_status_array(model)    # keep the optimal basis
clp_set_row_upper(model, c(15000, 4000, 70))
clp_copyin_status(model, basis)     # warm start
clp_dual_simplex(model)             # re-solves in 0 iterations
clp_free(model)
```

Also bound: presolve options (`clp_options()` and the `clp_options_*`
setters), barrier and idiot crash entry points, row and column names, MPS
input and output, model snapshots, infeasibility and unboundedness rays, and
every tolerance and limit Clp exposes.

Row and column positions in the `clp_*` bindings are 0-based, matching the
Clp documentation. `clp_solve()`, `clp_matrix()` and the name accessors use
ordinary 1-based R positions.

## Coming from clpAPI

Every function clpAPI exported is here with the same name and arguments, so
older scripts need only a new `library()` line:

```r
lp <- initProbCLP()
setLogLevelCLP(lp, 0)
loadProblemCLP(lp, 2, 3, c(0, 3, 6), c(0, 1, 2, 0, 1, 2),
               c(120, 110, 1, 210, 30, 1),
               lb = c(0, 0), ub = c(1e30, 1e30), obj_coef = c(143, 60),
               rlb = rep(-1e30, 3), rub = c(15000, 4000, 75))
setObjDirCLP(lp, -1)
solveInitialCLP(lp)
getObjValCLP(lp)     # 6315.625
delProbCLP(lp)
```

The `clpPtr` S4 class, its accessors and the `status_codeCLP()` /
`return_codeCLP()` helpers behave as before. New code should prefer the
`clp_*` interface.

## Clp versions

Clp 1.16 or later works. A few entry points were added to the C API after
the 1.17 series (`Clp_writeMps`, `Clp_modifyCoefficient`, `Clp_setRowName`,
`Clp_setColumnName`); `configure` detects them by link test, and
`clp_features()` reports what the current build has. Where `Clp_writeMps` is
missing — including the Clp 1.17.0 that Rtools ships — `clp_write_mps()`
falls back to an MPS writer implemented in R.

## Licence

The package is released under the Eclipse Public License, matching COIN-OR.
Clp itself is a separate work under EPL 2.0 and is not distributed here.

Prior art: the clpAPI package by Gabriel Gelius-Dietrich (GPL-3) defined the
`*CLP` function names that the compatibility layer reproduces; none of its
code is used here.
