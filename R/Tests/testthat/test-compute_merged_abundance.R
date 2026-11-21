#----------------------------------------------------------#
# Inputs -----
#----------------------------------------------------------#

testthat::test_that("compute_merged_abundance() validates arguments", {
  testthat::expect_error(
    compute_merged_abundance(vec_abundance = c("1", "2"), scale = "x_IC"),
    regexp = "vec_abundance"
  )

  testthat::expect_error(
    compute_merged_abundance(
      vec_abundance = c(1, 2),
      scale = c("x_IC", "x_SC")
    ),
    regexp = "scale"
  )

  testthat::expect_error(
    compute_merged_abundance(vec_abundance = c(1, 2), scale = NA_character_),
    regexp = "scale"
  )
})


#----------------------------------------------------------#
# Outputs and functionality -----
#----------------------------------------------------------#

testthat::test_that("compute_merged_abundance() keeps presence at 1", {
  res <-
    compute_merged_abundance(vec_abundance = c(1, 1), scale = "pa")

  testthat::expect_equal(res, 1)
})

testthat::test_that("compute_merged_abundance() combines covers as layers", {
  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(50, 50), scale = "CoverPerc"),
    75
  )

  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(100, 30), scale = "CoverPerc"),
    100
  )

  testthat::expect_equal(
    compute_merged_abundance(
      vec_abundance = c(20, NA, 50),
      scale = "CoverPerc"
    ),
    60
  )
})

testthat::test_that("compute_merged_abundance() sums the summed scales", {
  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(2, 3, NA), scale = "x_IC"),
    5
  )

  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(4, 1), scale = "x_SC"),
    5
  )

  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(0.5, 0.25), scale = "x_BA"),
    0.75
  )
})

testthat::test_that("compute_merged_abundance() keeps the largest value", {
  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(0.2, 0.7), scale = "x_IV"),
    0.7
  )

  testthat::expect_equal(
    compute_merged_abundance(vec_abundance = c(3, 1), scale = "x_PF"),
    3
  )
})

testthat::test_that("compute_merged_abundance() uses the given scale lists", {
  res <-
    compute_merged_abundance(
      vec_abundance = c(2, 5),
      scale = "count",
      vec_scales_summed = "count",
      vec_scales_maximum = base::character(0)
    )

  testthat::expect_equal(res, 7)
})


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that("compute_merged_abundance() handles missing and single", {
  testthat::expect_identical(
    compute_merged_abundance(vec_abundance = c(NA, NA), scale = "x_IC"),
    NA_real_
  )

  testthat::expect_identical(
    compute_merged_abundance(vec_abundance = c(37.3, NA), scale = "CoverPerc"),
    37.3
  )
})

testthat::test_that("compute_merged_abundance() aborts on unknown scales", {
  testthat::expect_error(
    compute_merged_abundance(vec_abundance = c(1, 2), scale = "x"),
    regexp = "no merge rule"
  )
})
