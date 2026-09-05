## The model level interface.

library(coinclp)

near <- function(x, y, tol = 1e-6) all(abs(x - y) < tol)

version <- clp_version()
stopifnot(is.list(version), nzchar(version$version), version$major >= 1L)
stopifnot(is.logical(clp_features()), length(clp_features()) == 4L)

## An empty model.
model <- clp_model()
stopifnot(inherits(model, "clp_model"), clp_is_open(model),
          clp_num_rows(model) == 0L, clp_num_cols(model) == 0L)
stopifnot(is.character(format(model)))

## Load the product mix problem, minimising the negated objective.
clp_set_log_level(model, 0L)
clp_load_problem(model, ncols = 2, nrows = 3,
                 start = c(0L, 3L, 6L),
                 index = c(0L, 1L, 2L, 0L, 1L, 2L),
                 value = c(120, 110, 1, 210, 30, 1),
                 collb = c(0, 0), colub = rep(clp_inf(), 2),
                 obj = c(-143, -60),
                 rowlb = rep(-clp_inf(), 3), rowub = c(15000, 4000, 75))

stopifnot(clp_num_rows(model) == 3L, clp_num_cols(model) == 2L,
          clp_num_elements(model) == 6)
stopifnot(near(clp_objective(model), c(-143, -60)),
          near(clp_row_upper(model), c(15000, 4000, 75)),
          near(clp_col_lower(model), c(0, 0)))

## The matrix comes back as 1-based triplets.
mat <- clp_matrix(model)
stopifnot(mat$nrow == 3L, mat$ncol == 2L, length(mat$v) == 6L,
          identical(sort(unique(mat$j)), c(1L, 2L)),
          near(sum(mat$v), 120 + 110 + 1 + 210 + 30 + 1))
stopifnot(length(clp_vector_starts(model)) == 3L,
          length(clp_indices(model)) == 6L,
          length(clp_elements(model)) == 6L,
          length(clp_vector_lengths(model)) == 2L)

## Solve and read the solution back.
stopifnot(clp_initial_solve(model) == 0L)
stopifnot(clp_status(model) == 0L,
          clp_status_message(clp_status(model)) == "optimal",
          clp_is_proven_optimal(model),
          !clp_is_proven_primal_infeasible(model),
          near(clp_objective_value(model), -6315.625),
          near(clp_col_solution(model), c(21.875, 53.125)),
          near(clp_row_activity(model), c(13781.25, 4000, 75)),
          length(clp_row_price(model)) == 3L,
          length(clp_reduced_costs(model)) == 2L,
          clp_iterations(model) >= 0L)

## Warm start: keep the basis, tighten a row, re-solve with the dual simplex.
basis <- clp_status_array(model)
stopifnot(is.raw(basis), length(basis) == 5L, clp_status_exists(model))
clp_set_row_upper(model, c(15000, 4000, 70))
clp_copyin_status(model, basis)
clp_dual_simplex(model)
stopifnot(clp_is_proven_optimal(model), near(clp_objective_value(model), -6171.25))
stopifnot(clp_row_status(model, 0L) %in% 0:5, clp_col_status(model, 0L) %in% 0:5)

## Parameters round trip.
clp_set_primal_tolerance(model, 1e-8)
clp_set_dual_tolerance(model, 1e-8)
clp_set_max_iterations(model, 12345L)
clp_set_max_seconds(model, 60)
clp_set_scaling(model, 1L)
clp_set_log_level(model, 0L)
stopifnot(near(clp_primal_tolerance(model), 1e-8),
          near(clp_dual_tolerance(model), 1e-8),
          clp_max_iterations(model) == 12345L,
          clp_max_seconds(model) >= 60,   # Clp stores an absolute deadline
          clp_scaling(model) == 1L,
          clp_log_level(model) == 0L,
          is.logical(clp_hit_max_iterations(model)))

clp_set_optimization_direction(model, -1)
stopifnot(near(clp_optimization_direction(model), -1))
clp_set_optimization_direction(model, 1)

## Names.
clp_set_names(model, c("mix", "time", "capacity"), c("x", "y"))
stopifnot(identical(clp_col_names(model), c("x", "y")),
          identical(clp_row_names(model), c("mix", "time", "capacity")),
          identical(clp_row_name(model, 0L), "mix"),
          clp_length_names(model) >= 8L)
clp_set_problem_name(model, "productmix")
stopifnot(identical(clp_problem_name(model), "productmix"))

## Structural changes.
clp_add_columns(model, 1, collb = 0, colub = clp_inf(), obj = -1,
                colstarts = c(0L, 1L), rows = 2L, elements = 1)
stopifnot(clp_num_cols(model) == 3L)
clp_delete_columns(model, 2L)
stopifnot(clp_num_cols(model) == 2L)

clp_add_rows(model, 1, rowlb = -clp_inf(), rowub = 40,
             rowstarts = c(0L, 2L), columns = c(0L, 1L), elements = c(1, 1))
stopifnot(clp_num_rows(model) == 4L)
clp_delete_rows(model, 3L)
stopifnot(clp_num_rows(model) == 3L)

## Integer markers are stored but do not change the relaxation.
clp_set_integer(model, c(TRUE, FALSE))
stopifnot(identical(clp_integer_information(model), c(TRUE, FALSE)))
clp_delete_integer(model)

## Infeasibility diagnostics exist after a solve.
clp_initial_solve(model)
stopifnot(is.numeric(clp_sum_primal_infeasibilities(model)),
          is.numeric(clp_sum_dual_infeasibilities(model)),
          is.integer(clp_num_primal_infeasibilities(model)))
clp_check_solution(model)

## Freeing twice is harmless; using a freed model is an error.
clp_free(model)
stopifnot(!clp_is_open(model))
clp_free(model)
stopifnot(inherits(try(clp_num_rows(model), silent = TRUE), "try-error"))
stopifnot(inherits(try(clp_ptr("not a model"), silent = TRUE), "try-error"))

## Options objects.
options <- clp_options()
clp_options_set_solve_type(options, 1L)
clp_options_set_presolve_type(options, 1L)
clp_options_set_do_dupcol(options, 1L)
stopifnot(clp_options_get_solve_type(options) == 1L,
          clp_options_get_presolve_type(options) == 1L,
          clp_options_do_dupcol(options) == 1L,
          is.integer(clp_options_get_presolve_passes(options)))

solved <- clp_model()
clp_set_log_level(solved, 0L)
clp_load_problem(solved, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1),
                 obj = c(-1, -2), rowub = 3)
clp_initial_solve_with_options(solved, options)
stopifnot(near(clp_objective_value(solved), -6))
clp_free(solved)
clp_options_free(options)

## Unbounded and infeasible rays.
unbounded <- clp_model()
clp_set_log_level(unbounded, 0L)
clp_load_problem(unbounded, 1, 1, c(0L, 1L), 0L, 1, obj = -1,
                 colub = clp_inf(), rowub = clp_inf())
clp_initial_solve(unbounded)
stopifnot(clp_status(unbounded) == 2L, is.numeric(clp_unbounded_ray(unbounded)))
clp_free(unbounded)
