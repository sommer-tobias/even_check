# evencheck

An R package to check whether numbers are even.

## Installation

```r
# install.packages("remotes")
remotes::install_github("sommer-tobias/even_check")
```

## Usage

```r
library(evencheck)
is_even(1:6)
#> [1] FALSE  TRUE FALSE  TRUE FALSE  TRUE
```

## Development

```r
devtools::document()  # regenerate NAMESPACE and man/ from roxygen comments
devtools::test()      # run the testthat suite
devtools::check()     # full R CMD check
```
