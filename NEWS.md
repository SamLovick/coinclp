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
