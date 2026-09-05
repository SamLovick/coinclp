## Row and column names, MPS files and model snapshots.

#' Row and column names
#'
#' \code{clp_row_names()} and \code{clp_col_names()} return all names as a
#' character vector; \code{clp_row_name()} and \code{clp_col_name()} fetch a
#' single one by 0-based position, as in the C API.  A model that carries no
#' names of its own reports the generated defaults \code{"R0000000"} and
#' \code{"C0000000"}; \code{clp_length_names()} is 0 in that case.
#'
#' \code{clp_set_names()} replaces every name at once and works with any Clp
#' version.  \code{clp_set_row_name()} and \code{clp_set_col_name()} change a
#' single name but need Clp 1.18 or later; see \code{\link{clp_features}}.
#'
#' @param model A \code{"clp_model"} object.
#' @param index 0-based row or column position.
#' @param name A single name.
#' @param row_names,col_names Character vectors with one entry per row or
#'   column.
#' @return The getters return character vectors or a single string;
#'   \code{clp_length_names()} an integer; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1), rowub = 1)
#' clp_set_names(model, "supply", c("x", "y"))
#' clp_col_names(model)
#' clp_free(model)
clp_row_names <- function(model) {
    ptr <- clp_ptr(model)
    n <- clp_num_rows(ptr)
    if (n == 0L) return(character(0))
    vapply(seq_len(n) - 1L, function(i) clp_row_name(ptr, i), character(1))
}

#' @rdname clp_row_names
#' @export
clp_col_names <- function(model) {
    ptr <- clp_ptr(model)
    n <- clp_num_cols(ptr)
    if (n == 0L) return(character(0))
    vapply(seq_len(n) - 1L, function(j) clp_col_name(ptr, j), character(1))
}

#' @rdname clp_row_names
#' @export
clp_row_name <- function(model, index)
    .Call(C_coinclp_row_name, clp_ptr(model), as.integer(index))

#' @rdname clp_row_names
#' @export
clp_col_name <- function(model, index)
    .Call(C_coinclp_column_name, clp_ptr(model), as.integer(index))

#' @rdname clp_row_names
#' @export
clp_set_names <- function(model, row_names, col_names) {
    invisible(.Call(C_coinclp_copy_names, clp_ptr(model),
                    as.character(row_names), as.character(col_names)))
}

#' @rdname clp_row_names
#' @export
clp_set_row_name <- function(model, index, name) {
    invisible(.Call(C_coinclp_set_row_name, clp_ptr(model), as.integer(index),
                    as.character(name)))
}

#' @rdname clp_row_names
#' @export
clp_set_col_name <- function(model, index, name) {
    invisible(.Call(C_coinclp_set_column_name, clp_ptr(model), as.integer(index),
                    as.character(name)))
}

#' @rdname clp_row_names
#' @export
clp_drop_names <- function(model) {
    invisible(.Call(C_coinclp_drop_names, clp_ptr(model)))
}

#' @rdname clp_row_names
#' @export
clp_length_names <- function(model) .Call(C_coinclp_length_names, clp_ptr(model))

#' The name of the problem
#'
#' @param model A \code{"clp_model"} object.
#' @param name A single character string.
#' @return \code{clp_problem_name()} returns a string; the setter returns
#'   Clp's integer return code, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_set_problem_name(model, "transport")
#' clp_problem_name(model)
#' clp_free(model)
clp_problem_name <- function(model) .Call(C_coinclp_problem_name, clp_ptr(model))

#' @rdname clp_problem_name
#' @export
clp_set_problem_name <- function(model, name) {
    invisible(.Call(C_coinclp_set_problem_name, clp_ptr(model), as.character(name)))
}

#' Print a model through Clp
#'
#' Asks Clp to dump the model to the console.  Useful for small problems when
#' debugging a model build.
#'
#' @param model A \code{"clp_model"} object.
#' @param prefix A string Clp puts in front of each line.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, rowub = 1)
#' clp_print_model(model)
#' clp_free(model)
clp_print_model <- function(model, prefix = "clp") {
    invisible(.Call(C_coinclp_print_model, clp_ptr(model), as.character(prefix)))
}

# ---------------------------------------------------------------------------
# files
# ---------------------------------------------------------------------------

#' Read an MPS file
#'
#' Reads a problem in MPS format into a model, using Clp's own reader.
#' Gzipped files are handled by Clp when it was built with zlib.
#'
#' @param model A \code{"clp_model"} object.
#' @param file Path to the MPS file.
#' @param keep_names Keep the row and column names from the file.
#' @param ignore_errors Carry on after errors in the file.
#' @return Clp's integer return code, invisibly: 0 on success.
#' @export
#' @examples
#' model <- clp_model()
#' path <- system.file("extdata", "productmix.mps", package = "coinclp")
#' if (nzchar(path)) {
#'   clp_read_mps(model, path)
#'   clp_num_rows(model)
#' }
#' clp_free(model)
clp_read_mps <- function(model, file, keep_names = TRUE, ignore_errors = FALSE) {
    status <- .Call(C_coinclp_read_mps, clp_ptr(model), path.expand(file),
                    as.logical(keep_names), as.logical(ignore_errors))
    invisible(status)
}

#' Write an MPS file
#'
#' Writes the model in MPS format.  Clp gained \code{Clp_writeMps} in its C
#' API after the 1.17 series, so where that entry point is missing (see
#' \code{\link{clp_features}}) this falls back to an MPS writer implemented
#' in R, which writes the same problem in fixed-column MPS format.
#'
#' A row that is unbounded on both sides is written as a second N row.  The
#' format has no other way to say so, and readers, Clp's included, keep only
#' the first N row as the objective and drop the rest.
#'
#' @param model A \code{"clp_model"} object.
#' @param file Path of the file to write.
#' @param format_type Passed to Clp: 0 normal, 1 extra accuracy, 2 IEEE hex.
#'   Ignored by the R fallback, which always writes full precision.
#' @param number_across Passed to Clp: 1 or 2 pairs of entries per line.
#' @param obj_sense 1 to write the objective as it stands, -1 to negate it so
#'   that a reader minimising the file maximises the original objective.
#' @param force_r Use the R writer even when Clp provides its own.
#' @return The path written, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1),
#'                  obj = c(1, 2), rowub = 4)
#' path <- tempfile(fileext = ".mps")
#' clp_write_mps(model, path)
#' readLines(path)[1:3]
#' clp_free(model)
#' unlink(path)
clp_write_mps <- function(model, file, format_type = 0L, number_across = 2L,
                          obj_sense = 1, force_r = FALSE) {
    ptr <- clp_ptr(model)
    if (!force_r && isTRUE(clp_features()[["write_mps"]])) {
        status <- .Call(C_coinclp_write_mps, ptr, path.expand(file),
                        as.integer(format_type), as.integer(number_across),
                        as.numeric(obj_sense))
        if (!identical(as.integer(status), 0L))
            stop("Clp failed to write '", file, "' (return code ", status, ")",
                 call. = FALSE)
    } else {
        write_mps_r(ptr, path.expand(file), obj_sense)
    }
    invisible(file)
}

## Fixed-column MPS writer, used when the Clp build has no Clp_writeMps.
write_mps_r <- function(model, file, obj_sense = 1) {
    nrows <- clp_num_rows(model)
    ncols <- clp_num_cols(model)
    rlb <- clp_row_lower(model)
    rub <- clp_row_upper(model)
    clb <- clp_col_lower(model)
    cub <- clp_col_upper(model)
    obj <- clp_objective(model)
    if (obj_sense < 0) obj <- -obj
    mat <- clp_matrix(model)

    rname <- if (nrows > 0L) clp_row_names(model) else character(0)
    cname <- if (ncols > 0L) clp_col_names(model) else character(0)
    rname <- make_mps_names(rname, "R")
    cname <- make_mps_names(cname, "C")
    objname <- "COST"
    while (objname %in% rname) objname <- paste0(objname, "_")

    big <- clp_inf()
    num <- function(x) sprintf("%.12g", x)

    ## row types
    type <- character(nrows)
    rhs <- rep(NA_real_, nrows)
    range <- rep(NA_real_, nrows)
    for (i in seq_len(nrows)) {
        lo <- rlb[i]; up <- rub[i]
        if (lo <= -big && up >= big) {
            type[i] <- "N"
        } else if (isTRUE(all.equal(lo, up))) {
            type[i] <- "E"; rhs[i] <- lo
        } else if (lo <= -big) {
            type[i] <- "L"; rhs[i] <- up
        } else if (up >= big) {
            type[i] <- "G"; rhs[i] <- lo
        } else {
            type[i] <- "L"; rhs[i] <- up; range[i] <- up - lo
        }
    }

    ## Clp reads MPS in fixed format: the second field must start in column 5
    ## and the third in column 15, so pad every name to at least 8 characters.
    card <- function(a, b, v = NULL) {
        if (is.null(v)) sprintf("    %-8s  %-8s", a, b)
        else sprintf("    %-8s  %-8s  %s", a, b, v)
    }
    bound_card <- function(kind, name, v = NULL) {
        if (is.null(v)) sprintf(" %-2s %-8s  %-8s", kind, "BND", name)
        else sprintf(" %-2s %-8s  %-8s  %s", kind, "BND", name, v)
    }

    out <- c(sprintf("NAME          %s", nzchar_or(clp_problem_name(model), "COINCLP")),
             "ROWS",
             sprintf(" %-2s %s", "N", objname))
    if (nrows > 0L) out <- c(out, sprintf(" %-2s %s", type, rname))

    out <- c(out, "COLUMNS")
    ord <- order(mat$j, mat$i)
    mi <- mat$i[ord]; mj <- mat$j[ord]; mv <- mat$v[ord]
    for (j in seq_len(ncols)) {
        entries <- character(0)
        if (obj[j] != 0)
            entries <- c(entries, card(cname[j], objname, num(obj[j])))
        sel <- which(mj == j)
        if (length(sel))
            entries <- c(entries, card(cname[j], rname[mi[sel]], num(mv[sel])))
        if (!length(entries))  # keep the column in the file
            entries <- card(cname[j], objname, "0")
        out <- c(out, entries)
    }

    out <- c(out, "RHS")
    has_rhs <- which(!is.na(rhs) & rhs != 0)
    if (length(has_rhs))
        out <- c(out, card("RHS", rname[has_rhs], num(rhs[has_rhs])))

    has_range <- which(!is.na(range))
    if (length(has_range))
        out <- c(out, "RANGES",
                 card("RNG", rname[has_range], num(range[has_range])))

    bounds <- character(0)
    for (j in seq_len(ncols)) {
        lo <- clb[j]; up <- cub[j]
        if (lo <= -big && up >= big) {
            bounds <- c(bounds, bound_card("FR", cname[j]))
        } else if (isTRUE(all.equal(lo, up))) {
            bounds <- c(bounds, bound_card("FX", cname[j], num(lo)))
        } else {
            if (lo <= -big) {
                bounds <- c(bounds, bound_card("MI", cname[j]))
            } else if (lo != 0) {
                bounds <- c(bounds, bound_card("LO", cname[j], num(lo)))
            }
            if (up < big)
                bounds <- c(bounds, bound_card("UP", cname[j], num(up)))
        }
    }
    if (length(bounds)) out <- c(out, "BOUNDS", bounds)

    out <- c(out, "ENDATA")
    writeLines(out, file)
    invisible(file)
}

nzchar_or <- function(x, default) if (length(x) && nzchar(x)) x else default

## MPS names must be unique and free of blanks.
make_mps_names <- function(x, prefix) {
    if (!length(x)) return(x)
    x <- gsub("[[:space:]]+", "_", x)
    empty <- !nzchar(x)
    x[empty] <- sprintf("%s%d", prefix, which(empty))
    make.unique(x, sep = "_")
}

#' Save and restore a model
#'
#' Writes or reads Clp's own binary snapshot of a model.  The format is
#' Clp's internal one: it is not portable between Clp versions or machines,
#' but it is a fast way to hand a model back to the same solver later.
#' \code{clp_restore_model()} replaces whatever the model held.
#'
#' @param model A \code{"clp_model"} object.
#' @param file Path of the snapshot file.
#' @return Clp's integer return code, invisibly: 0 on success.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = 1, rowub = 2)
#' path <- tempfile()
#' clp_save_model(model, path)
#' clp_restore_model(model, path)
#' clp_free(model)
#' unlink(path)
clp_save_model <- function(model, file) {
    invisible(.Call(C_coinclp_save_model, clp_ptr(model), path.expand(file)))
}

#' @rdname clp_save_model
#' @export
clp_restore_model <- function(model, file) {
    invisible(.Call(C_coinclp_restore_model, clp_ptr(model), path.expand(file)))
}
