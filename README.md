# C template for multiple main files

For https://c-programming.aydos.de

Select a C main file and press <kbd>F5</kbd> to start your program. Examples include `CSV_FIlter.c` and `pi-estimator.c`.

## CSV filter regression tests

The tests require Clang and PowerShell 5.1 or later. From the workspace root, run:

```powershell
.\tests\test_csv_filter.ps1
```

The script compiles `src/CSV_FIlter.c` into a temporary directory and checks short rows without a trailing newline, missing and nonnumeric ages, blank rows, and minimum-age filtering. It prints a `PASS` line for each case and removes its temporary files when finished.