.SAMPLES_PATH <- "/index/samples"

.SAMPLES_DEFAULT_COLUMNS <- c(
    entryId = "hits[*].entryId",
    projectTitle = "hits[*].projects[*].projectTitle[*]",
    genusSpecies = "hits[*].donorOrganisms[*].genusSpecies[*]",
    disease = "hits[*].donorOrganisms[*].disease[*]",
    format = "hits[*].fileTypeSummaries[*].format",
    count = "hits[*].fileTypeSummaries[*].count"
)

.SAMPLES_REQUIRED_COLUMNS <- c(
    entryId = "hits[*].entryId"
)

#' @rdname samples
#'
#' @name samples
#'
#' @title HCA Sample Querying
#'
#' @description `samples()` takes a list of user provided project titles
#'     to be used to query the HCA API for information about available samples.
NULL # don't add next function to documentation

#' @inheritParams projects
#'
#' @examples
#' title <- paste(
#'     "Tabula Muris: Transcriptomic characterization of 20 organs and",
#'     "tissues from Mus musculus at single cell resolution"
#' )
#' filters <- filters( projectTitle = list(is = title) )
#' samples(filters = filters)
#'
#' @export
samples <-
    function(filters = NULL,
             size = 1000L,
             sort = "projectTitle",
             order = c("asc", "desc"),
             catalog = NULL,
             as = c("tibble", "lol", "list", "tibble_expanded"),
             columns = samples_default_columns("character"))
{
    if (is.null(catalog)) {
        catalog <- catalogs()[1]
    }

    if (is.null(filters)) {
        filters <- filters()
    }

    as <- match.arg(as) # defaults from argument

    stopifnot(
        .is_character(columns)
    )

    response <- .index_GET(
        filters = filters,
        size = size,
        sort = sort,
        order = order,
        catalog = catalog,
        base_path = .SAMPLES_PATH
    )

    switch(
        as,
        tibble = .as_tbl_hca(response$content, columns, "samples_tbl_hca"),
        lol = .as_lol_hca(response$content, columns),
        list = response$content,
        tibble_expanded = .as_expanded_tbl_hca(
            response$content,
            exclude_path_pattern = character(),
            required_columns = .SAMPLES_REQUIRED_COLUMNS,
            type = "samples_tbl_hca"
        )
    )
}

#' @rdname samples
#'
#' @examples
#' samples_facets()
#'
#' @export
samples_facets <-
    function(
        facet = character(),
        catalog = NULL
    )
{
    if(is.null(catalog)){
        catalog <- catalogs()[1]
    }

    stopifnot(
        is.character(facet),
        !anyNA(facet),
        ## catalog validation
        `catalog must be a character scalar returned by catalogs()` =
            .is_catalog(catalog)
    )
    lst <- samples(size = 1L, catalog = catalog, as = "list")
    .term_facets(lst, facet)
}

#' @rdname samples
#'
#' @export
samples_default_columns <-
    function(as = c("tibble", "character"))
{
    .default_columns("samples", as)
}

#' @rdname samples
#'
#' @name samples_detail
#'
#' @description `samples_detail()` takes a unique sample_id and catalog for
#' the sample, and returns details about the specified sample as a
#' list-of-lists
#'
#' @return `samples_detail()` returns a list-of-lists containing
#'     relevant details about the sample
#'
#' @examples
#' sample <- samples(size = 1, as = "list")
#' sample_uuid <- sample[["hits"]][[1]][["entryId"]]
#' samples_detail(uuid = sample_uuid)
#'
#' @export
samples_detail <-
    function (uuid, catalog = NULL)
{
    if(is.null(catalog)){
        catalog <- catalogs()[1]
    }

    stopifnot(
        ## catalog validation
        `catalog must be a character scalar returned by catalogs()` =
            .is_catalog(catalog)
    )
    .details(uuid = uuid, catalog = catalog, view = "samples")
}
