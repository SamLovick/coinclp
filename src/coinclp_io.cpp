/* coinclp: row and column names, MPS input and model snapshots. */

#include "coinclp.h"
#include <stdio.h>
#include <string.h>

/* Clp can hand back a name longer than lengthNames(), so leave slack in the
   buffer rather than trusting that number. */
#define COINCLP_NAME_SLACK 64

static const char *file_path(SEXP x, const char *what)
{
    if (TYPEOF(x) != STRSXP || XLENGTH(x) != 1 || STRING_ELT(x, 0) == NA_STRING)
        Rf_error("'%s' must be a single file name", what);
    return R_ExpandFileName(Rf_translateChar(STRING_ELT(x, 0)));
}

/* --- names ----------------------------------------------------------- */

extern "C" SEXP coinclp_length_names(SEXP ptr)
{ return Rf_ScalarInteger(Clp_lengthNames(coinclp_model(ptr))); }

extern "C" SEXP coinclp_drop_names(SEXP ptr)
{
    Clp_dropNames(coinclp_model(ptr));
    return R_NilValue;
}

static int name_buffer_size(Clp_Simplex *m)
{
    int len = Clp_lengthNames(m);
    if (len < 0) len = 0;
    return len + COINCLP_NAME_SLACK + 1;
}

/* A model that carries no names has an empty name vector inside Clp, and
   asking it for one indexes past the end.  Generate the name Clp itself
   would write instead of calling in. */
static SEXP default_name(char kind, int index)
{
    char buf[16];
    snprintf(buf, sizeof(buf), "%c%7.7d", kind, index);
    return Rf_mkString(buf);
}

extern "C" SEXP coinclp_row_name(SEXP ptr, SEXP index)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int i = Rf_asInteger(index);
    if (i == NA_INTEGER || i < 0 || i >= Clp_numberRows(m))
        Rf_error("row index out of range");
    if (Clp_lengthNames(m) <= 0) return default_name('R', i);
    int size = name_buffer_size(m);
    char *buf = (char *) R_alloc(size, sizeof(char));
    memset(buf, 0, (size_t) size);
    Clp_rowName(m, i, buf);
    buf[size - 1] = '\0';
    return Rf_mkString(buf);
}

extern "C" SEXP coinclp_column_name(SEXP ptr, SEXP index)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int j = Rf_asInteger(index);
    if (j == NA_INTEGER || j < 0 || j >= Clp_numberColumns(m))
        Rf_error("column index out of range");
    if (Clp_lengthNames(m) <= 0) return default_name('C', j);
    int size = name_buffer_size(m);
    char *buf = (char *) R_alloc(size, sizeof(char));
    memset(buf, 0, (size_t) size);
    Clp_columnName(m, j, buf);
    buf[size - 1] = '\0';
    return Rf_mkString(buf);
}

extern "C" SEXP coinclp_copy_names(SEXP ptr, SEXP row_names, SEXP column_names)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int nrows = Clp_numberRows(m);
    int ncols = Clp_numberColumns(m);

    if (TYPEOF(row_names) != STRSXP || XLENGTH(row_names) != nrows)
        Rf_error("'row_names' must be a character vector of length %d", nrows);
    if (TYPEOF(column_names) != STRSXP || XLENGTH(column_names) != ncols)
        Rf_error("'column_names' must be a character vector of length %d", ncols);

    const char **rn = (const char **) R_alloc(nrows > 0 ? nrows : 1, sizeof(char *));
    const char **cn = (const char **) R_alloc(ncols > 0 ? ncols : 1, sizeof(char *));
    for (int i = 0; i < nrows; i++) {
        if (STRING_ELT(row_names, i) == NA_STRING)
            Rf_error("'row_names' must not contain missing values");
        rn[i] = Rf_translateChar(STRING_ELT(row_names, i));
    }
    for (int j = 0; j < ncols; j++) {
        if (STRING_ELT(column_names, j) == NA_STRING)
            Rf_error("'column_names' must not contain missing values");
        cn[j] = Rf_translateChar(STRING_ELT(column_names, j));
    }

    Clp_copyNames(m, rn, cn);
    return R_NilValue;
}

extern "C" SEXP coinclp_problem_name(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    const int size = 1024;
    char *buf = (char *) R_alloc(size, sizeof(char));
    memset(buf, 0, (size_t) size);
    Clp_problemName(m, size - 1, buf);
    buf[size - 1] = '\0';
    return Rf_mkString(buf);
}

extern "C" SEXP coinclp_set_problem_name(SEXP ptr, SEXP name)
{
    Clp_Simplex *m = coinclp_model(ptr);
    if (TYPEOF(name) != STRSXP || XLENGTH(name) != 1 || STRING_ELT(name, 0) == NA_STRING)
        Rf_error("'name' must be a single character string");
    const char *src = Rf_translateChar(STRING_ELT(name, 0));
    size_t len = strlen(src);
    char *buf = (char *) R_alloc(len + 1, sizeof(char));
    memcpy(buf, src, len + 1);
    return Rf_ScalarInteger(Clp_setProblemName(m, (int) len, buf));
}

extern "C" SEXP coinclp_set_row_name(SEXP ptr, SEXP index, SEXP name)
{
#if COINCLP_HAVE_SETNAMES
    Clp_Simplex *m = coinclp_model(ptr);
    if (TYPEOF(name) != STRSXP || XLENGTH(name) != 1 || STRING_ELT(name, 0) == NA_STRING)
        Rf_error("'name' must be a single character string");
    const char *src = Rf_translateChar(STRING_ELT(name, 0));
    size_t len = strlen(src);
    char *buf = (char *) R_alloc(len + 1, sizeof(char));
    memcpy(buf, src, len + 1);
    Clp_setRowName(m, Rf_asInteger(index), buf);
    return R_NilValue;
#else
    (void) ptr; (void) index; (void) name;
    Rf_error("this Clp build has no Clp_setRowName(); it needs COIN-OR Clp >= 1.18. "
             "Use clp_copy_names() to set all names at once");
    return R_NilValue;
#endif
}

extern "C" SEXP coinclp_set_column_name(SEXP ptr, SEXP index, SEXP name)
{
#if COINCLP_HAVE_SETNAMES
    Clp_Simplex *m = coinclp_model(ptr);
    if (TYPEOF(name) != STRSXP || XLENGTH(name) != 1 || STRING_ELT(name, 0) == NA_STRING)
        Rf_error("'name' must be a single character string");
    const char *src = Rf_translateChar(STRING_ELT(name, 0));
    size_t len = strlen(src);
    char *buf = (char *) R_alloc(len + 1, sizeof(char));
    memcpy(buf, src, len + 1);
    Clp_setColumnName(m, Rf_asInteger(index), buf);
    return R_NilValue;
#else
    (void) ptr; (void) index; (void) name;
    Rf_error("this Clp build has no Clp_setColumnName(); it needs COIN-OR Clp >= 1.18. "
             "Use clp_copy_names() to set all names at once");
    return R_NilValue;
#endif
}

/* --- files ----------------------------------------------------------- */

extern "C" SEXP coinclp_read_mps(SEXP ptr, SEXP filename, SEXP keep_names,
                                 SEXP ignore_errors)
{
    Clp_Simplex *m = coinclp_model(ptr);
    const char *path = file_path(filename, "filename");
    int status = Clp_readMps(m, path,
                             Rf_asLogical(keep_names) == TRUE ? 1 : 0,
                             Rf_asLogical(ignore_errors) == TRUE ? 1 : 0);
    return Rf_ScalarInteger(status);
}

extern "C" SEXP coinclp_write_mps(SEXP ptr, SEXP filename, SEXP format_type,
                                  SEXP number_across, SEXP obj_sense)
{
#if COINCLP_HAVE_WRITEMPS
    Clp_Simplex *m = coinclp_model(ptr);
    const char *path = file_path(filename, "filename");
    int status = Clp_writeMps(m, path, Rf_asInteger(format_type),
                              Rf_asInteger(number_across), Rf_asReal(obj_sense));
    return Rf_ScalarInteger(status);
#else
    (void) ptr; (void) filename; (void) format_type;
    (void) number_across; (void) obj_sense;
    Rf_error("this Clp build has no Clp_writeMps(); it needs COIN-OR Clp >= 1.18. "
             "clp_write_mps() falls back to an R implementation");
    return R_NilValue;
#endif
}

extern "C" SEXP coinclp_save_model(SEXP ptr, SEXP filename)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return Rf_ScalarInteger(Clp_saveModel(m, file_path(filename, "filename")));
}

extern "C" SEXP coinclp_restore_model(SEXP ptr, SEXP filename)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return Rf_ScalarInteger(Clp_restoreModel(m, file_path(filename, "filename")));
}

extern "C" SEXP coinclp_print_model(SEXP ptr, SEXP prefix)
{
    Clp_Simplex *m = coinclp_model(ptr);
    if (TYPEOF(prefix) != STRSXP || XLENGTH(prefix) != 1 ||
        STRING_ELT(prefix, 0) == NA_STRING)
        Rf_error("'prefix' must be a single character string");
    Clp_printModel(m, Rf_translateChar(STRING_ELT(prefix, 0)));
    return R_NilValue;
}
