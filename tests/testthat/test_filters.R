test_that("'facet_options()' works", {
    object <- facet_options()
    expect_type(object, "character")
    expect_true(length(object) > 1L)
})

test_that("'filters()' works", {

    ## empty object
    object <- filters()
    expect_equal(length(object), 0)
    expect_equal(.filters_filters(object), setNames(list(), character()))
    expect_equal(
        .filters_encoding(object),
        URLencode('{}', reserved = TRUE)
    )

    ## empty list
    expect_error(filters(foo = list()), label = "list may not be empty")

    ## single filter
    object <- filters(organ = list(is = "pancreas"))
    expect_equal(length(object), 1L)
    expect_equal(.filters_filters(object), list(organ = list(is = "pancreas")))
    expect_equal(
        as.character(.filters_encoding(object)),
        URLencode('{"organ":{"is":["pancreas"]}}', reserved = TRUE)
    )

    ## single filter, multiple match
    object <- filters(fileFormat = list(is = c("fastq", "fastq.gz")))
    expect_equal(length(object), 1L)
    expect_equal(
        as.character(.filters_encoding(object)),
        URLencode('{"fileFormat":{"is":["fastq","fastq.gz"]}}', reserved = TRUE)
    )

    ## two filters
    object <- filters(
        organ = list(is = "pancreas"),
        genusSpecies = list(is = "Homo sapiens")
    )
    expect_equal(length(object), 2L)
    expect_equal(
        .filters_filters(object),
        list(
            organ = list(is = "pancreas"),
            genusSpecies = list(is = "Homo sapiens")
        )
    )
    expect_equal(
        as.character(.filters_encoding(object)),
        URLencode(
            '{"organ":{"is":["pancreas"]},"genusSpecies":{"is":["Homo sapiens"]}}',
            reserved = TRUE
        )
    )

})

test_that("'filters()' validates arguments", {

    ## not named lists
    expect_error(filters(organ = "bar"), ".*named lists")
    expect_error(filters(organ = c(is = "bar")), ".*named lists")
    ## invalid verbs
    expect_error(filters(organ = list(isnota = "bar")), ".*verbs must be")

    ## valid verbs: "is", "within", "contains", and "intersects"
    ## details don't need to be checked; these are satisfied in an
    ## earlier test
    class <- c("filters", "hca")
    expect_s3_class(filters(organ = list(is = "bar")), class)
    expect_s3_class(filters(organ = list(within = "bar")), class)
    expect_s3_class(filters(organ = list(contains = "bar")), class)
    expect_s3_class(filters(organ = list(intersects = "bar")), class)

    ## FIXME invalid / valid nouns ("organ", "genusSpecies", ...)
    ## valid facets checked in function validation
    expect_error(filters(testing = list(is = "pancreas")), ".*facets must be")
})
