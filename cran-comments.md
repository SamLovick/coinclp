## coinclp 0.1.1

This update responds to the valgrind report listed under "Additional issues"
for coinclp 0.1.0, flagged for fixing before 2026-10-07.

### The valgrind finding

    Syscall param write(buf) points to uninitialised byte(s)
       by ClpSimplex::saveModel(char const*)   Clp/src/ClpSimplex.cpp:6860
       by coinclp_save_model                    src/coinclp_io.cpp:201
     Address ... is 204 bytes inside a block of size 4,096

Clp's saveModel() declares a Clp_scalars struct on the stack, assigns each
of its fields, and fwrite()s the struct whole. The fields occupy 204 bytes
and the struct is padded to 208; the four padding bytes at offset 204 are
never assigned, and those are the bytes valgrind reports. The value is
harmless, since padding is never read back by restoreModel(), and the write
is inside the Clp library, so nothing in this package can initialise it.
The same code is in Clp's current development branch.

coinclp 0.1.1 therefore stops exercising that entry point in CRAN's checks:
the example on the clp_save_model help page is in \dontrun, with a comment
saying why, and the test that round-trips a snapshot runs only where
NOT_CRAN is set. The functions themselves are unchanged and remain
documented, with the finding described on their help page.

### Other changes

* src/Makevars.win honours the CLP_CFLAGS and CLP_LIBS environment
  variables, matching what configure offers on Unix.
* The documentation states which Rtools versions have been verified to ship
  Clp rather than making a blanket claim.

## Test environments

* Windows 11, R 4.5.2, Rtools45 (Clp 1.17.0)
* GitHub Actions: ubuntu-latest (R release, R devel, R oldrel-1),
  macOS-latest (R release), windows-latest (R release)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

None on CRAN at the time of submission. ROI.plugin.coinclp, currently in
the incoming queue, imports coinclp (>= 0.1.0) and is unaffected.
