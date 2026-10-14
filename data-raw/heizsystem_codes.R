## Build the lookup table for EN-103 heat generator codes.
##
## Source: inst/extdata/heizsystem_codes.csv, transcribed from the EVEN
## form designer convention for "Wärmeerzeuger Heizung" and
## "Wärmeerzeuger Warmwasser" (EVEN-Formulardesigner, 16.09.2026).
## The columns kategorie, wp_typ and fossil are added for evaluation.
##
## Requires usethis (not a package dependency).

heizsystem_codes <- utils::read.csv(
  "inst/extdata/heizsystem_codes.csv",
  colClasses = c("character", "character", "character", "character", "logical"),
  na.strings = "",
  encoding = "UTF-8"
)

stopifnot(
  nrow(heizsystem_codes) == 34,
  !anyDuplicated(heizsystem_codes$code)
)

usethis::use_data(heizsystem_codes, overwrite = TRUE)
