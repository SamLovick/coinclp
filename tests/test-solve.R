## The one-call interface.

library(coinclp)

near <- function(x, y, tol = 1e-6) all(abs(x - y) < tol)

## A small product mix problem with a known optimum:
##   max 143x + 60y  s.t.  120x + 210y <= 15000
##                         110x +  30y <=  4000
##                           x +    y  <=    75
A <- rbind(c(120, 210), c(110, 30), c(1, 1))
b <- c(15000, 4000, 75)

res <- clp_solve(c(143, 60), A, "<=", b, max = TRUE)
stopifnot(inherits(res, "clp_solution"),
          res$status == 0L,
          isTRUE(res$optimal),
          near(res$objval, 6315.625),
          near(res$solution, c(21.875, 53.125)),
          near(res$row_activity, c(13781.25, 4000, 75)),
          length(res$duals) == 3L,
          length(res$reduced_costs) == 2L,
          res$direction == "max")

## The same problem stated as a minimisation of the negated objective.
resmin <- clp_solve(c(-143, -60), A, "<=", b)
stopifnot(near(resmin$objval, -6315.625), near(resmin$solution, res$solution))

## Every algorithm, with and without presolve, finds the same optimum.
for (alg in c("auto", "primal", "dual", "barrier", "barrier_nocross")) {
    for (presolve in c(TRUE, FALSE)) {
        r <- clp_solve(c(143, 60), A, "<=", b, max = TRUE,
                       control = clp_control(algorithm = alg,
                                             presolve = presolve))
        stopifnot(near(r$objval, 6315.625, 1e-4))
    }
}

## Ranged rows, free variables, equality rows.
ranged <- clp_solve(c(1, 1), rbind(c(1, 1)), row_lower = 2, row_upper = 5,
                    lower = -Inf, upper = Inf)
stopifnot(isTRUE(ranged$optimal), near(ranged$objval, 2))

eq <- clp_solve(c(1, 2), rbind(c(1, 1)), "==", 4)
stopifnot(isTRUE(eq$optimal), near(eq$objval, 4), near(eq$solution, c(4, 0)))

## "=", "<" and ">" are accepted as aliases.
alias <- clp_solve(c(1, 2), rbind(c(1, 1)), "=", 4)
stopifnot(near(alias$objval, eq$objval))

## Infeasible and unbounded problems report their status rather than erroring.
infeasible <- clp_solve(1, rbind(1, 1), c("<=", ">="), c(1, 5))
stopifnot(infeasible$status == 1L, !infeasible$optimal)

unbounded <- clp_solve(-1, NULL, upper = Inf)
stopifnot(unbounded$status == 2L, !unbounded$optimal)

## Bounds-only problems need no constraint matrix.
bounded <- clp_solve(c(-1, 1), NULL, lower = c(0, -2), upper = c(3, 5))
stopifnot(near(bounded$objval, -5), near(bounded$solution, c(3, -2)))

## Sparse representations agree with the dense matrix.
set.seed(42)
Ad <- matrix(rbinom(60, 1, 0.4) * runif(60, 1, 2), nrow = 6)
rhs <- rep(3, 6)
obj <- runif(10)
dense <- clp_solve(obj, Ad, ">=", rhs)

nz <- which(Ad != 0, arr.ind = TRUE)
triplet <- clp_solve(obj, list(i = nz[, 1], j = nz[, 2], v = Ad[Ad != 0],
                               nrow = 6, ncol = 10), ">=", rhs)
stopifnot(near(dense$objval, triplet$objval, 1e-9))

if (requireNamespace("Matrix", quietly = TRUE)) {
    fromMatrix <- clp_solve(obj, Matrix::Matrix(Ad, sparse = TRUE), ">=", rhs)
    stopifnot(near(dense$objval, fromMatrix$objval, 1e-9))
}

if (requireNamespace("slam", quietly = TRUE)) {
    fromSlam <- clp_solve(obj, slam::as.simple_triplet_matrix(Ad), ">=", rhs)
    stopifnot(near(dense$objval, fromSlam$objval, 1e-9))
}

## Names are carried through to the result.
named <- clp_solve(c(143, 60), A, "<=", b, max = TRUE,
                   col_names = c("x", "y"),
                   row_names = c("mix", "time", "capacity"))
stopifnot(identical(names(named$solution), c("x", "y")),
          identical(names(named$duals), c("mix", "time", "capacity")))

## Argument checking.
stopifnot(inherits(try(clp_solve(c(1, 2), rbind(1), "<=", 1), silent = TRUE),
                   "try-error"),
          inherits(try(clp_solve(c(1, 1), rbind(c(1, 1))), silent = TRUE),
                   "try-error"),
          inherits(try(clp_solve(c(1, 1), rbind(c(1, 1)), "!=", 1),
                       silent = TRUE), "try-error"),
          inherits(try(clp_solve(numeric(0)), silent = TRUE), "try-error"))

## Iteration limits are honoured.
limited <- clp_solve(c(143, 60), A, "<=", b, max = TRUE,
                     control = clp_control(max_iterations = 0L,
                                           presolve = FALSE))
stopifnot(limited$status != 0L || limited$iterations == 0L)
