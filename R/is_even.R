#' Check whether numbers are even
#'
#' @param x A numeric vector of whole numbers.
#'
#' @return A logical vector the same length as `x`. `NA` inputs give `NA`.
#' @export
#'
#' @examples
#' is_even(1:6)
#' is_even(c(-2, 0, NA))
is_even <- function(x) {
  if (!is.numeric(x)) {
    stop("`x` must be numeric.", call. = FALSE)
  }
  if (any(!is.na(x) & x != trunc(x))) {
    stop("`x` must contain whole numbers only.", call. = FALSE)
  }
  x %% 2 == 0
}
