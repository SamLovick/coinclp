/* coinclp: R bindings to the COIN-OR Clp callable library.
 *
 * Copyright (C) 2026 coinclp authors
 * Licensed under the Eclipse Public License; see the file LICENSE.
 */

#ifndef COINCLP_H
#define COINCLP_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

/* On Unix the configure script writes COINCLP_CONFIGURED plus the feature
 * macros it discovered by link tests into src/Makevars.  On Windows (and any
 * other build without configure) we fall back to the version macros shipped
 * in ClpConfig.h: the entry points below were added to the callable library
 * after the 1.17 series. */

#ifdef COINCLP_COIN_SUBDIR
# include <coin/Clp_C_Interface.h>
#else
# include <Clp_C_Interface.h>
#endif

#ifndef COINCLP_CONFIGURED
# ifdef COINCLP_COIN_SUBDIR
#  include <coin/ClpConfig.h>
# else
#  include <ClpConfig.h>
# endif
# if defined(CLP_VERSION_MAJOR) && \
     (CLP_VERSION_MAJOR > 1 || (CLP_VERSION_MAJOR == 1 && CLP_VERSION_MINOR >= 18))
#  define COINCLP_HAVE_WRITEMPS 1
#  define COINCLP_HAVE_MODIFYCOEFFICIENT 1
#  define COINCLP_HAVE_SETNAMES 1
#  define COINCLP_HAVE_CLP_MAXIMUMITERATIONS 1
# endif
#endif

#ifndef COINCLP_HAVE_WRITEMPS
# define COINCLP_HAVE_WRITEMPS 0
#endif
#ifndef COINCLP_HAVE_MODIFYCOEFFICIENT
# define COINCLP_HAVE_MODIFYCOEFFICIENT 0
#endif
#ifndef COINCLP_HAVE_SETNAMES
# define COINCLP_HAVE_SETNAMES 0
#endif
#ifndef COINCLP_HAVE_CLP_MAXIMUMITERATIONS
# define COINCLP_HAVE_CLP_MAXIMUMITERATIONS 0
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* --- shared helpers (coinclp_model.cpp) ------------------------------- */

/* Extract the Clp_Simplex behind an external pointer, with validation.
   Signals an R error for anything that is not a live model. */
Clp_Simplex *coinclp_model(SEXP ptr);

/* Extract the Clp_Solve behind an external pointer, with validation. */
Clp_Solve *coinclp_options(SEXP ptr);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* COINCLP_H */
