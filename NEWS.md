# coinclp 0.1.0.9000 (development version)

Held for a 0.1.1 release once 0.1.0 is through CRAN; 0.1.0 is the version
that was submitted, and none of this changes what it does.

* `src/Makevars.win` now honours the `CLP_CFLAGS` and `CLP_LIBS`
  environment variables, so a Clp installed outside the Rtools tree can be
  built against on Windows too. They take precedence over pkg-config, which
  in turn precedes the Rtools library tree, matching the order `configure`
  uses on Unix.
* The claim that Rtools ships Clp is now stated as what has been verified
  (Rtools 4.5, with 4.3 and 4.4 using the same library tree) rather than as
  a blanket one. Rtools 4.2 and earlier do not carry Clp, so source builds
  on R 4.2 or older need `CLP_CFLAGS` and `CLP_LIBS`.
* README says what a Windows user actually needs: nothing at all for a CRAN
  binary, since Clp is static and ends up inside `coinclp.dll`; Rtools only
  for a source build.

# coinclp 0.1.0

* First release.
* `clp_solve()` solves a linear program in one call, from a dense matrix, a
  `Matrix` sparse matrix, a `slam::simple_triplet_matrix` or `i`/`j`/`v`
  triplets, with one-sided or ranged rows.
* Complete bindings to the Clp callable library: problem construction,
  bounds, objective, matrix access, all six solve entry points, presolve
  options, basis access and warm starts, tolerances and limits, status
  queries, names, MPS input and output, and model snapshots.
* `initProbCLP()` and the other `*CLP` functions reproduce the interface of
  the archived clpAPI package, including the `clpPtr` S4 class.
* `configure` finds Clp through `--with-clp-*`, `CLP_CFLAGS`/`CLP_LIBS`,
  `pkg-config` or the default compiler paths, and detects optional Clp entry
  points by link test. On Windows the Clp that Rtools ships is used.
