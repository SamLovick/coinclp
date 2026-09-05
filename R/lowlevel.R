## Thin bindings to the Clp callable library.
##
## These follow the C API: row and column positions are 0-based, exactly as
## in the Clp documentation.  The higher level helpers (clp_solve(),
## clp_matrix(), clp_names()) use 1-based R positions instead.

#' Version of the Clp library in use
#'
#' @return \code{clp_version()} returns a list with the version string and its
#'   major, minor and release components.  \code{clp_features()} returns a
#'   named logical vector saying which optional entry points this build of
#'   Clp provides.
#' @export
#' @examples
#' clp_version()
#' clp_features()
clp_version <- function() .Call(C_coinclp_version)

#' @rdname clp_version
#' @export
clp_features <- function() .Call(C_coinclp_features)

# ---------------------------------------------------------------------------
# building a problem
# ---------------------------------------------------------------------------

#' Load a problem into a Clp model
#'
#' Loads a complete linear program given by a column-major (compressed sparse
#' column) constraint matrix.  This is the callable library's
#' \code{Clp_loadProblem} and takes 0-based indices.
#'
#' Any of the bound and objective arguments may be \code{NULL}, in which case
#' Clp applies its defaults: columns get \code{[0, Inf)} bounds and a zero
#' objective, rows get \code{(-Inf, Inf)}.
#'
#' @param model A \code{"clp_model"} object.
#' @param ncols Number of columns (variables).
#' @param nrows Number of rows (constraints).
#' @param start Integer vector of length \code{ncols + 1} giving the 0-based
#'   position in \code{index}/\code{value} at which each column starts.
#' @param index Integer vector of 0-based row indices, one per matrix entry.
#' @param value Numeric vector of matrix entries.
#' @param collb,colub Numeric vectors of column bounds, or \code{NULL}.
#' @param obj Numeric vector of objective coefficients, or \code{NULL}.
#' @param rowlb,rowub Numeric vectors of row bounds, or \code{NULL}.
#' @return \code{NULL}, invisibly.  The model is modified in place.
#' @seealso \code{\link{clp_solve}}, which builds this representation from an
#'   ordinary R matrix.
#' @export
#' @examples
#' # maximise 2x + 3y subject to x + y <= 4, x + 3y <= 6
#' model <- clp_model()
#' clp_load_problem(model, ncols = 2, nrows = 2,
#'                  start = c(0L, 2L, 4L),
#'                  index = c(0L, 1L, 0L, 1L),
#'                  value = c(1, 1, 1, 3),
#'                  collb = c(0, 0), colub = c(clp_inf(), clp_inf()),
#'                  obj = c(-2, -3),
#'                  rowlb = c(-clp_inf(), -clp_inf()), rowub = c(4, 6))
#' clp_initial_solve(model)
#' clp_col_solution(model)
#' clp_free(model)
clp_load_problem <- function(model, ncols, nrows, start, index, value,
                             collb = NULL, colub = NULL, obj = NULL,
                             rowlb = NULL, rowub = NULL) {
    invisible(.Call(C_coinclp_load_problem, clp_ptr(model),
                    as.integer(ncols), as.integer(nrows),
                    as.integer(start), as.integer(index), as.numeric(value),
                    as_numeric_or_null(collb), as_numeric_or_null(colub),
                    as_numeric_or_null(obj),
                    as_numeric_or_null(rowlb), as_numeric_or_null(rowub)))
}

as_numeric_or_null <- function(x) if (is.null(x)) NULL else as.numeric(x)

#' Load a quadratic objective
#'
#' Attaches a quadratic term to the objective, in column-major form.  Clp
#' itself only solves such models with its quadratic simplex; most users want
#' the linear objective set by \code{\link{clp_set_objective}}.
#'
#' @param model A \code{"clp_model"} object.
#' @param ncols Number of columns in the quadratic term.
#' @param start Integer vector of 0-based column starts, length \code{ncols + 1}.
#' @param column Integer vector of 0-based column indices.
#' @param element Numeric vector of coefficients.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 0, start = c(0L, 0L), index = integer(0),
#'                  value = numeric(0))
#' clp_load_quadratic_objective(model, 1, c(0L, 1L), 0L, 2)
#' clp_free(model)
clp_load_quadratic_objective <- function(model, ncols, start, column, element) {
    invisible(.Call(C_coinclp_load_quadratic, clp_ptr(model), as.integer(ncols),
                    as.integer(start), as.integer(column), as.numeric(element)))
}

#' Change the size of a model
#'
#' @param model A \code{"clp_model"} object.
#' @param nrows,ncols New numbers of rows and columns.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_resize(model, 2, 3)
#' clp_num_cols(model)
#' clp_free(model)
clp_resize <- function(model, nrows, ncols) {
    invisible(.Call(C_coinclp_resize, clp_ptr(model),
                    as.integer(nrows), as.integer(ncols)))
}

#' Add or delete rows and columns
#'
#' \code{clp_add_rows()} and \code{clp_add_columns()} extend a model with
#' entries given in compressed sparse form; \code{clp_delete_rows()} and
#' \code{clp_delete_columns()} remove them.  All indices are 0-based.
#'
#' @param model A \code{"clp_model"} object.
#' @param number Number of rows or columns being added.
#' @param rowlb,rowub Numeric vectors of bounds for the new rows, or \code{NULL}.
#' @param collb,colub Numeric vectors of bounds for the new columns, or \code{NULL}.
#' @param obj Objective coefficients for the new columns, or \code{NULL}.
#' @param rowstarts Integer vector of length \code{number + 1}, where each new
#'   row's entries start.
#' @param colstarts Integer vector of length \code{number + 1}, where each new
#'   column's entries start.
#' @param columns Integer vector of 0-based column indices of the new entries.
#' @param rows Integer vector of 0-based row indices of the new entries.
#' @param elements Numeric vector of matrix entries.
#' @param which Integer vector of 0-based positions to delete.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 0, start = c(0L, 0L, 0L),
#'                  index = integer(0), value = numeric(0),
#'                  obj = c(1, 1))
#' clp_add_rows(model, 1, rowlb = -clp_inf(), rowub = 5,
#'              rowstarts = c(0L, 2L), columns = c(0L, 1L), elements = c(1, 1))
#' clp_num_rows(model)
#' clp_free(model)
clp_add_rows <- function(model, number, rowlb = NULL, rowub = NULL,
                         rowstarts, columns, elements) {
    invisible(.Call(C_coinclp_add_rows, clp_ptr(model), as.integer(number),
                    as_numeric_or_null(rowlb), as_numeric_or_null(rowub),
                    as.integer(rowstarts), as.integer(columns),
                    as.numeric(elements)))
}

#' @rdname clp_add_rows
#' @export
clp_add_columns <- function(model, number, collb = NULL, colub = NULL,
                            obj = NULL, colstarts, rows, elements) {
    invisible(.Call(C_coinclp_add_columns, clp_ptr(model), as.integer(number),
                    as_numeric_or_null(collb), as_numeric_or_null(colub),
                    as_numeric_or_null(obj),
                    as.integer(colstarts), as.integer(rows),
                    as.numeric(elements)))
}

#' @rdname clp_add_rows
#' @export
clp_delete_rows <- function(model, which) {
    invisible(.Call(C_coinclp_delete_rows, clp_ptr(model), as.integer(which)))
}

#' @rdname clp_add_rows
#' @export
clp_delete_columns <- function(model, which) {
    invisible(.Call(C_coinclp_delete_columns, clp_ptr(model), as.integer(which)))
}

# ---------------------------------------------------------------------------
# dimensions, bounds and objective
# ---------------------------------------------------------------------------

#' Size of a model
#'
#' @param model A \code{"clp_model"} object.
#' @return The number of rows, columns or stored matrix entries.
#'   \code{clp_num_elements()} returns a double, since Clp counts entries in a
#'   type that may exceed the range of an R integer.
#' @export
#' @examples
#' model <- clp_model()
#' clp_resize(model, 3, 4)
#' c(clp_num_rows(model), clp_num_cols(model))
#' clp_free(model)
clp_num_rows <- function(model) .Call(C_coinclp_number_rows, clp_ptr(model))

#' @rdname clp_num_rows
#' @export
clp_num_cols <- function(model) .Call(C_coinclp_number_columns, clp_ptr(model))

#' @rdname clp_num_rows
#' @export
clp_num_elements <- function(model) .Call(C_coinclp_number_elements, clp_ptr(model))

#' Bounds and objective coefficients
#'
#' Read or replace the objective coefficients and the row and column bounds
#' of a model.  The getters return Clp's own values, in which an infinite
#' bound is \code{\link{clp_inf}()} rather than \code{Inf}.
#'
#' @param model A \code{"clp_model"} object.
#' @param value A numeric vector with one entry per column (objective and
#'   column bounds) or per row (row bounds).
#' @return The getters return a numeric vector; the setters return \code{NULL}
#'   invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 0, start = c(0L, 0L, 0L),
#'                  index = integer(0), value = numeric(0), obj = c(1, 2))
#' clp_objective(model)
#' clp_set_objective(model, c(3, 4))
#' clp_objective(model)
#' clp_free(model)
clp_objective <- function(model) .Call(C_coinclp_objective, clp_ptr(model))

#' @rdname clp_objective
#' @export
clp_col_lower <- function(model) .Call(C_coinclp_column_lower, clp_ptr(model))

#' @rdname clp_objective
#' @export
clp_col_upper <- function(model) .Call(C_coinclp_column_upper, clp_ptr(model))

#' @rdname clp_objective
#' @export
clp_row_lower <- function(model) .Call(C_coinclp_row_lower, clp_ptr(model))

#' @rdname clp_objective
#' @export
clp_row_upper <- function(model) .Call(C_coinclp_row_upper, clp_ptr(model))

#' @rdname clp_objective
#' @export
clp_set_objective <- function(model, value) {
    invisible(.Call(C_coinclp_chg_objective, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_objective
#' @export
clp_set_col_lower <- function(model, value) {
    invisible(.Call(C_coinclp_chg_column_lower, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_objective
#' @export
clp_set_col_upper <- function(model, value) {
    invisible(.Call(C_coinclp_chg_column_upper, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_objective
#' @export
clp_set_row_lower <- function(model, value) {
    invisible(.Call(C_coinclp_chg_row_lower, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_objective
#' @export
clp_set_row_upper <- function(model, value) {
    invisible(.Call(C_coinclp_chg_row_upper, clp_ptr(model), as.numeric(value)))
}

#' Change one matrix coefficient
#'
#' Needs a Clp build that provides \code{Clp_modifyCoefficient} (1.18 or
#' later); check with \code{clp_features()}.
#'
#' @param model A \code{"clp_model"} object.
#' @param row,col 0-based row and column position.
#' @param value New coefficient.
#' @param keep_zero Keep the entry in the sparse structure when \code{value}
#'   is zero.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' if (isTRUE(clp_features()[["modify_coefficient"]])) {
#'   model <- clp_model()
#'   clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, rowub = 1)
#'   clp_modify_coefficient(model, 0, 0, 2)
#'   clp_free(model)
#' }
clp_modify_coefficient <- function(model, row, col, value, keep_zero = TRUE) {
    invisible(.Call(C_coinclp_modify_coefficient, clp_ptr(model),
                    as.integer(row), as.integer(col), as.numeric(value),
                    as.logical(keep_zero)))
}

# ---------------------------------------------------------------------------
# the constraint matrix
# ---------------------------------------------------------------------------

#' The constraint matrix
#'
#' \code{clp_matrix()} returns the constraint matrix as triplets with 1-based
#' positions, which is convenient in R.  The other functions expose Clp's own
#' column-major arrays unchanged, with 0-based indices; note that the stored
#' matrix may contain gaps, so \code{clp_vector_lengths()} rather than the
#' differences of \code{clp_vector_starts()} gives the entries per column.
#'
#' @param model A \code{"clp_model"} object.
#' @return \code{clp_matrix()} returns a list with components \code{i},
#'   \code{j}, \code{v}, \code{nrow} and \code{ncol}.  The others return the
#'   corresponding Clp array.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 2), rowub = 3)
#' clp_matrix(model)
#' clp_free(model)
clp_matrix <- function(model) .Call(C_coinclp_matrix_triplets, clp_ptr(model))

#' @rdname clp_matrix
#' @export
clp_vector_starts <- function(model) .Call(C_coinclp_vector_starts, clp_ptr(model))

#' @rdname clp_matrix
#' @export
clp_vector_lengths <- function(model) .Call(C_coinclp_vector_lengths, clp_ptr(model))

#' @rdname clp_matrix
#' @export
clp_indices <- function(model) .Call(C_coinclp_indices, clp_ptr(model))

#' @rdname clp_matrix
#' @export
clp_elements <- function(model) .Call(C_coinclp_elements, clp_ptr(model))

# ---------------------------------------------------------------------------
# solutions
# ---------------------------------------------------------------------------

#' Solution vectors
#'
#' After a solve, these return the primal and dual solution.
#' \code{clp_col_solution()} is the primal solution, \code{clp_reduced_costs()}
#' the dual values on the columns, \code{clp_row_activity()} the row activities
#' and \code{clp_row_price()} the dual values (shadow prices) on the rows.
#'
#' @param model A \code{"clp_model"} object.
#' @param value Numeric starting solution, one entry per column.
#' @return A numeric vector, or \code{NULL} invisibly for the setter.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1),
#'                  obj = c(-1, -1), rowub = 1)
#' clp_initial_solve(model)
#' clp_col_solution(model)
#' clp_row_price(model)
#' clp_free(model)
clp_col_solution <- function(model)
    .Call(C_coinclp_primal_column_solution, clp_ptr(model))

#' @rdname clp_col_solution
#' @export
clp_reduced_costs <- function(model)
    .Call(C_coinclp_dual_column_solution, clp_ptr(model))

#' @rdname clp_col_solution
#' @export
clp_row_activity <- function(model)
    .Call(C_coinclp_primal_row_solution, clp_ptr(model))

#' @rdname clp_col_solution
#' @export
clp_row_price <- function(model)
    .Call(C_coinclp_dual_row_solution, clp_ptr(model))

#' @rdname clp_col_solution
#' @export
clp_set_col_solution <- function(model, value) {
    invisible(.Call(C_coinclp_set_column_solution, clp_ptr(model),
                    as.numeric(value)))
}

#' Rays certifying unboundedness or infeasibility
#'
#' @param model A \code{"clp_model"} object.
#' @return A numeric vector, empty when Clp holds no such ray.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = -1, rowub = clp_inf())
#' clp_initial_solve(model)
#' clp_unbounded_ray(model)
#' clp_free(model)
clp_unbounded_ray <- function(model) .Call(C_coinclp_unbounded_ray, clp_ptr(model))

#' @rdname clp_unbounded_ray
#' @export
clp_infeasibility_ray <- function(model)
    .Call(C_coinclp_infeasibility_ray, clp_ptr(model))

# ---------------------------------------------------------------------------
# basis / warm starts
# ---------------------------------------------------------------------------

#' Basis status for warm starts
#'
#' \code{clp_status_array()} returns Clp's packed basis, rows first, which can
#' be handed back to a model of the same size with
#' \code{clp_copyin_status()} to warm start it.  The per-variable accessors
#' use Clp's codes: 0 free, 1 basic, 2 at upper bound, 3 at lower bound,
#' 4 superbasic, 5 fixed.
#'
#' @param model A \code{"clp_model"} object.
#' @param status A raw vector previously returned by \code{clp_status_array()}.
#' @param index 0-based row or column position.
#' @param value New status code.
#' @return \code{clp_status_exists()} a logical, \code{clp_status_array()} a
#'   raw vector, the accessors an integer status code, the setters
#'   \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1),
#'                  obj = c(-1, -1), rowub = 1)
#' clp_initial_solve(model)
#' basis <- clp_status_array(model)
#' clp_copyin_status(model, basis)
#' clp_free(model)
clp_status_exists <- function(model) .Call(C_coinclp_status_exists, clp_ptr(model))

#' @rdname clp_status_exists
#' @export
clp_status_array <- function(model) .Call(C_coinclp_status_array, clp_ptr(model))

#' @rdname clp_status_exists
#' @export
clp_copyin_status <- function(model, status) {
    invisible(.Call(C_coinclp_copyin_status, clp_ptr(model), status))
}

#' @rdname clp_status_exists
#' @export
clp_row_status <- function(model, index)
    .Call(C_coinclp_get_row_status, clp_ptr(model), as.integer(index))

#' @rdname clp_status_exists
#' @export
clp_col_status <- function(model, index)
    .Call(C_coinclp_get_column_status, clp_ptr(model), as.integer(index))

#' @rdname clp_status_exists
#' @export
clp_set_row_status <- function(model, index, value) {
    invisible(.Call(C_coinclp_set_row_status, clp_ptr(model),
                    as.integer(index), as.integer(value)))
}

#' @rdname clp_status_exists
#' @export
clp_set_col_status <- function(model, index, value) {
    invisible(.Call(C_coinclp_set_column_status, clp_ptr(model),
                    as.integer(index), as.integer(value)))
}

# ---------------------------------------------------------------------------
# integer markers
# ---------------------------------------------------------------------------

#' Mark columns as integer
#'
#' Clp is a linear programming solver and always solves the continuous
#' relaxation; these markers exist so that a model can be handed on to a
#' branch and bound code such as Cbc.
#'
#' @param model A \code{"clp_model"} object.
#' @param is_integer Logical vector with one entry per column.
#' @return \code{clp_integer_information()} returns a logical vector (empty
#'   when no markers are set); the others return \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 0, c(0L, 0L, 0L), integer(0), numeric(0))
#' clp_set_integer(model, c(TRUE, FALSE))
#' clp_integer_information(model)
#' clp_free(model)
clp_set_integer <- function(model, is_integer) {
    invisible(.Call(C_coinclp_copy_in_integer_information, clp_ptr(model),
                    as.logical(is_integer)))
}

#' @rdname clp_set_integer
#' @export
clp_delete_integer <- function(model) {
    invisible(.Call(C_coinclp_delete_integer_information, clp_ptr(model)))
}

#' @rdname clp_set_integer
#' @export
clp_integer_information <- function(model)
    .Call(C_coinclp_integer_information, clp_ptr(model))
