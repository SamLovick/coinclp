## Test environments

* Windows 11, R 4.5.2, Rtools45 (Clp 1.17.0 from the toolchain)
* GitHub Actions: ubuntu-latest (R release, R devel, R oldrel-1),
  macOS-latest (R release), windows-latest (R release)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Notes for the reviewer

* The package needs the COIN-OR Clp library and its headers, declared in
  SystemRequirements. It is not bundled. On Windows the Rtools toolchain
  supplies Clp, so no download happens at build time; on other platforms
  configure locates an installed Clp through pkg-config, the CLP_CFLAGS and
  CLP_LIBS environment variables, or --with-clp-include / --with-clp-lib.
* The package replaces clpAPI, archived from CRAN on 2021-11-30. None of its
  code is reused; the *CLP functions reproduce its interface only, so that
  dependent code such as ROI.plugin.clp can be revived.
