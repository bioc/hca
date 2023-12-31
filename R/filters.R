## @rdname is used to document more than one function in the same file
## the syntax convention for naming class methods is <generic>.<class>
## where a generic function is just an intermediary which determines which
## implementation of a function to call based on the class of its input
#' @rdname filters
#'
#' @name filters
#'
#' @title HCA Filter Construction
#'
#' @description `facet_options()` returns a character vector of possible facets
#'     to use during filtering.
#'
#' @return `facet_options()` returns a vector of all permissible query
#'     facets for the HCA api.
#'
#' @importFrom jsonlite read_json
#'
#' @examples
#' facet_options()
#'
#' @export
facet_options <- function() {
    json <- .hca_openapi()
    parameters <- json$paths[["/index/{entity_type}"]]$get$parameters
    parameter_names <- vapply(parameters, `[[`, character(1), "name")
    filter_parameter_idx <- which(!is.na(match(parameter_names, "filters")))
    filter_parameter <- parameters[[filter_parameter_idx]]
    names(filter_parameter$content[["application/json"]]$schema$properties)
}

## internal only
.filters_validate <- function(x) {
    ## allowed verbs
    verbs <- c("is", "within", "intersects", "contains")
    ## facets and verbs are the same for index/files and index/samples
    stopifnot(
        ## 'filter' must be a list
        is.list(x),
        ## length 0 or elements must have names
        length(x) == 0L || !is.null(names(x)),
        ## Docs: Backticks are used for non-standard variable names.
        ## each element in the list must also be a list
        `'filters()' arguments must be named lists` =
            all(vapply(x, inherits, logical(1), "list")),
        ## each list element must not be empty
        `'filters()' arguments must be non-empty lists` =
            all(vapply(x, function(x){length(x) >= 1L}, logical(1))),
        ## allowed verbs only
        `'filters()' verbs must be 'is', 'within', 'intersects' or 'contains'` =
            all(vapply(x, names, character(1)) %in% verbs),
        ## allowed facets only
        ## `'filters()' facets must be in permissible list` =
            ## all(names(x) %in% facets),
        ## do no allow values to have line breaks (i.e. newline or return chars)
        `'filters()' facets values must not contain line breaks` =
            !any(vapply(unlist(x), function(x) grepl("\n", x), logical(1)))
    )

    ## allowed facets
    facets <- facet_options()
    if (!all(names(x) %in% facets)) {
        ## invalid facet message
        facet_msg <- .wrap_lines(c(
            "'filters()' facets must be one of: ",
            paste(facets, collapse = ", ")
        ))
        stop(facet_msg)
    }

    x
}

#' @rdname filters
#'
#' @description `filters()` takes user input to be used as query
#'     filters. Each named argument is a list with a name specifying a
#'     verb (e.g., `"is"`) and a character vector of allowed values,
#'     as in the examples. This input is then validated, reformatted
#'     to JSON, and encoded into a properly formatted URL.
#'
#' @param ... named arguments, each of which is a `list()` specifying
#'     a query facet and its corresponding value to be used in the
#'     query
#'
#' @return `filters()` returns a `filters` object representing
#'     validated filters in a format suitable for use in `projects()`
#'     and related functions.
#'
#' @examples
#' filters()
#'
#' filters(
#'     organ = list(is = "pancreas")
#' )
#'
#' filters(
#'     organ = list(is = "pancreas"),
#'     genusSpecies = list(is = "Homo sapiens")
#' )
#'
#' filters(
#'     fileFormat = list(is = c("fastq", "fastq.gz"))
#' )
#'
#' @importFrom jsonlite toJSON
#' @importFrom utils URLencode
#'
#' @export
filters <- function(...) {
    filters_list <- list(...)

    ## make sure zero-length filters have names
    if (length(filters_list) == 0L) {
        names(filters_list) <- character()
    }

    ## validate list of filters
    valid_filters <- .filters_validate(filters_list)
    ## transform to json, via toJSON()
    ## do elements of `filters` need to be wrapped in `list()`?
    ## ??? filters <- lapply(filters list) ???
    json <- toJSON(valid_filters)
    encoding <- URLencode(json, reserved = TRUE)

    ## create a 'filters' object (S3 for now)
    ## S3 classes have simple linear inheritance, and `c("filters","hca")`
    ## says that the `filters` class is a subclass of `hca`.
    ## It doesn't matter that `hca` is not defined anywhere.
    result <- list(encoding = encoding, filters = valid_filters)
    class(result) <- c("filters", "hca")

    ## return result
    result
}

## internal only
## class accessors, not exported
.filters_encoding <- function(x) x$encoding

.filters_filters <- function(x) x$filters

.filters_json <-  function(x) {
    toJSON(.filters_filters(x), pretty = TRUE)
}

#' @rdname filters
#'
#' @param x for `length()` and `print()`, an object of class `filters`.
#'
#' @export
length.filters <- function(x) {
    ## length() is a generic which chooses its implementation based on the class
    ## of its input
    length(.filters_filters(x))
}

#' @rdname filters
#'
#' @export
print.filters <- function(x, ...) {
    ## cat() is an internal function which concatenates inputs and prints
    ## print() is also a generic which chooses its implementation based
    ## on the class of its input

    json <- paste(
        strsplit(as.character(.filters_json(x)), "\n")[[1]],
        collapse = "\n  "
    )

    cat(
        "class: ", paste(class(x), collapse = ", "), "\n",
        "length: ", length(x), "\n",
        "json:\n",
        "  ", json, "\n",
        sep = ""
    )
}
