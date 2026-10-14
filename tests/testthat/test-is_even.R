test_that("is_even identifies even and odd numbers", {
  expect_equal(is_even(1:6), c(FALSE, TRUE, FALSE, TRUE, FALSE, TRUE))
  expect_true(is_even(0))
  expect_true(is_even(-4))
  expect_false(is_even(-3))
})

test_that("is_even propagates NA", {
  expect_equal(is_even(c(2, NA)), c(TRUE, NA))
})

test_that("is_even rejects invalid input", {
  expect_error(is_even("a"), "must be numeric")
  expect_error(is_even(2.5), "whole numbers")
})
