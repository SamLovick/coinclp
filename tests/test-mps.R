## MPS input and output.

library(coinclp)

near <- function(x, y, tol = 1e-6) all(abs(x - y) < tol)

## The example shipped with the package.
example <- system.file("extdata", "productmix.mps", package = "coinclp")
stopifnot(nzchar(example))

model <- clp_model()
clp_set_log_level(model, 0L)
stopifnot(clp_read_mps(model, example) == 0L,
          clp_num_rows(model) == 3L,
          clp_num_cols(model) == 2L,
          identical(clp_col_names(model), c("x", "y")))
clp_initial_solve(model)
stopifnot(clp_is_proven_optimal(model),
          near(clp_objective_value(model), -6315.625),
          near(clp_col_solution(model), c(21.875, 53.125)))

## Write it out again with the R writer and read the result back: every kind
## of row and bound should survive the round trip.
roundtrip <- clp_model()
clp_set_log_level(roundtrip, 0L)
clp_load_problem(roundtrip, ncols = 3, nrows = 4,
                 start = c(0L, 2L, 4L, 6L),
                 index = c(0L, 1L, 1L, 2L, 2L, 3L),
                 value = c(1, 2, 3, 4, 5, 6),
                 collb = c(0, -clp_inf(), 2),
                 colub = c(10, clp_inf(), 2),
                 obj = c(1, -2, 3),
                 rowlb = c(-clp_inf(), 5, 1, 7),
                 rowub = c(20, clp_inf(), 4, 7))
clp_set_names(roundtrip, c("less", "greater", "ranged", "equal"),
              c("bounded", "freevar", "fixed"))

path <- tempfile(fileext = ".mps")
clp_write_mps(roundtrip, path, force_r = TRUE)
stopifnot(file.exists(path))

back <- clp_model()
clp_set_log_level(back, 0L)
stopifnot(clp_read_mps(back, path) == 0L,
          clp_num_rows(back) == 4L,
          clp_num_cols(back) == 3L,
          identical(clp_col_names(back), c("bounded", "freevar", "fixed")),
          near(clp_objective(back), c(1, -2, 3)),
          near(clp_row_lower(back), clp_row_lower(roundtrip)),
          near(clp_row_upper(back), clp_row_upper(roundtrip)),
          near(clp_col_lower(back), clp_col_lower(roundtrip)),
          near(clp_col_upper(back), clp_col_upper(roundtrip)),
          near(sort(clp_matrix(back)$v), sort(clp_matrix(roundtrip)$v)))

## A row that is free on both sides becomes an extra N row, which MPS readers
## drop: the file keeps only the first N row, as the objective.
free_row <- clp_model()
clp_set_log_level(free_row, 0L)
clp_load_problem(free_row, 1, 2, c(0L, 2L), c(0L, 1L), c(1, 1),
                 rowlb = c(-clp_inf(), 0), rowub = c(clp_inf(), 3))
free_path <- tempfile(fileext = ".mps")
clp_write_mps(free_row, free_path, force_r = TRUE)
stopifnot(sum(grepl("^ N ", readLines(free_path))) == 2L)
free_back <- clp_model()
clp_set_log_level(free_back, 0L)
clp_read_mps(free_back, free_path)
stopifnot(clp_num_rows(free_back) == 1L)
unlink(free_path)
clp_free(free_row); clp_free(free_back)

## Negating the objective on the way out.
negated <- tempfile(fileext = ".mps")
clp_write_mps(roundtrip, negated, obj_sense = -1, force_r = TRUE)
flipped <- clp_model()
clp_set_log_level(flipped, 0L)
stopifnot(clp_read_mps(flipped, negated) == 0L,
          near(clp_objective(flipped), c(-1, 2, -3)))

## Whatever writer the Clp build provides is also usable.
written <- tempfile(fileext = ".mps")
clp_write_mps(roundtrip, written)
stopifnot(file.exists(written))

## Reading a file that does not exist is reported, not silently ignored.
## Clp prints its own Clp6001E line here; that message is the point.
missing_status <- suppressWarnings(
    clp_read_mps(clp_model(), tempfile(fileext = ".mps"), ignore_errors = TRUE))
stopifnot(missing_status != 0L)

unlink(c(path, negated, written))
clp_free(model); clp_free(roundtrip); clp_free(back); clp_free(flipped)
