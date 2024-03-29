.PROJECTS_PATH <- "/index/projects"

.PROJECTS_DEFAULT_COLUMNS <- c(
    projectId = "hits[*].entryId",
    projectTitle = "hits[*].projects[*].projectTitle",
    genusSpecies = "hits[*].donorOrganisms[*].genusSpecies[*]", # Species
    sampleEntityType = "hits[*].samples[*].sampleEntityType[*]", # Sample Type
    specimenOrgan = "hits[*].specimens[*].organ[*]", # Anatomical Entity
    specimenOrganPart = "hits[*].specimens[*].organPart[*]", # Organ Part
    ## modelOrgan =  , # Model Organ -- organoids|cellLines
    selectedCellType =
        "hits[*].cellSuspensions[*].selectedCellType[*]", # Selected Cell Types
    libraryConstructionApproach =
        "hits[*].protocols[*].libraryConstructionApproach[*]", # Library Construction Method
    nucleicAcidSource = "hits[*].protocols[*].nucleicAcidSource[*]", # Nucleic Acid Source
    pairedEnd = "hits[*].protocols[*].pairedEnd[*]", # Paired End
    workflow = "hits[*].protocols[*].workflow[*]", # Analysis Protocol
    specimenDisease = "hits[*].specimens[*].disease[*]", # Disease Status (Specimen)
    donorDisease = "hits[*].donorOrganisms[*].disease[*]", # Disease Status (Donor)
    developmentStage = "hits[*].donorOrganisms[*].developmentStage[*]" # Development Stage
    ## Donor Count
    ## Cell Count Estimate
    ## Submission Date
    ## Update Date
)

.PROJECTS_REQUIRED_COLUMNS <- c(
    projectId = "hits[*].entryId"
)

#' @rdname projects
#'
#' @name projects
#'
#' @title HCA Project Querying
#'
#' @description `projects()` takes user input to be used to query the
#'     HCA API for information about available projects.
#'
#' @seealso `project_information()` and `project_title()` to easily
#'     summarize a project from its project id.
NULL # don't add next function to documentation

#' @param filters filter object created by `filters()`, or `NULL`
#'     (default; all projects).
#'
#' @param size integer(1) maximum number of results to return;
#'     default: all projects matching `filter`. The default (10000) is
#'     meant to be large enough to return all results.
#'
#' @param sort character(1) project facet (see `facet_options()`) to
#'     sort result; default: `"projectTitle"`.
#'
#' @param order character(1) sort order. One of `"asc"` (ascending) or
#'     `"desc"` (descending).
#'
#' @param catalog character(1) source of data. Use
#'     `catalogs()` for possible values.
#'
#' @param as character(1) return format. One of `"tibble"` (default),
#'     `"lol"`, `"list"`, or `"tibble_expanded"`, as described in the
#'     Details and Value sections of `?projects`.
#'
#' @param columns named character() indicating the paths to be used
#'     for parsing the 'lol' returned from the HCA to a tibble. The
#'     names of `columns` are used as column names in the returned
#'     tibble. If the columns are unnamed, a name is derived from the
#'     elements of `path` by removing `hits[*]` and all `[*]`, e.g., a
#'     path `hits[*].donorOrganisms[*].biologicalSex[*]` is given the
#'     name `donorOrganisms.biologicalSex`.
#'
#' @details The `as` argument determines the object returned by the
#'     function. Possible values are:
#'
#' - "tibble" (default) A tibble (data.frame) summarizing essential
#'   elements of projects, samples, bundles, or files.
#'
#' - "lol" A 'list-of-lists' representation of the JSON returned by
#'   the query as a 'list-of-lists' data structure, indexed and
#'   presented to enable convenient filtering, selection, and
#'   extraction. See `?lol`.
#'
#' - "list" An R list (typically, highly recursive) containing
#'   detailed project information, constructed from the JSON response
#'   to the original query.
#'
#' - "tibble_expanded" A tibble (data.frame) containing (almost) all
#'   information for each project, sample, bundle, or file. The
#'   exception is user-contributed matrices present in `projects()`
#'   records; these must be accessed using the `"lol"` format to
#'   extract specific paths as a standard `"tibble"`.
#'
#' @seealso `lol()` and other `lol_*()` functions for working with the
#'     list-of-list data structure returned when `as = "lol"`.
#'
#' @return When `as = "tibble"` or `as = "tibble_expanded"`, a tibble
#'     with each row representing an HCA object (project, sample,
#'     bundle, or file, depending on the function invoked), and
#'     columns summarizing the object. `"tibble_expanded"` columns
#'     contains almost all information about the object, except as
#'     noted in the Details section.
#'
#' When `as = "lol"`, a list-of-lists data structure representing
#' detailed information on each object.
#'
#' When `as = "list"`, `projects()` returns an R list, typically
#' containing other lists or atomic vectors, representing detailed
#' information on each project.
#'
#' @examples
#' projects(filters(), size = 100)
#'
#' @export
projects <-
    function(filters = NULL,
             size = 1000L,
             sort = "projectTitle",
             order = c("asc", "desc"),
             catalog = NULL,
             as = c("tibble", "lol", "list", "tibble_expanded"),
             columns = projects_default_columns("character"))
{
    if (is.null(filters)) {
        filters <- filters()
    }

    if(is.null(catalog)) {
        catalog <- catalogs()[1]
    }

    as <- match.arg(as)

    stopifnot(
        size > 0L,
        .is_character(columns)
    )

    ## project queries are limited to 100 at a time...
    remaining <- size
    query_size <- min(100L, remaining)
    response <- .index_GET(
        filters = filters,
        size = query_size,
        sort = sort,
        order = order,
        catalog = catalog,
        base_path = .PROJECTS_PATH
    )

    value <- query_value <- switch(
        as,
        tibble = .as_tbl_hca(response$content, columns, "projects_tbl_hca"),
        lol = .as_lol_hca(response$content, columns),
        list = .as_list_hca(response$content),
        tibble_expanded = .as_expanded_tbl_hca(
            response$content,
            exclude_path_pattern = "matrices",
            required_columns = .PROJECTS_REQUIRED_COLUMNS,
            type = "projects_tbl_hca"
        )
    )

    repeat {
        remaining <- remaining - query_size
        no_next_page <- is.null(.hca_pagination(query_value)[["next"]])
        if (remaining <= 0L || no_next_page)
            break

        query_size <- min(100L, remaining)
        query_value <- hca_next(query_value, query_size)
        value <- .hca_bind(value, query_value)
    }

    value
}

#' @rdname projects
#'
#' @description `projects_facets()` summarizes facets and terms used by
#'     all records in the projects index.
#'
#' @param facet character() of valid facet names. Summary results (see
#'     'Value', below) are returned when missing or length greater
#'     than 1; details are returned when a single facet is specified.
#'
#' @return `projects_facets()` invoked with no `facet=` argument returns a
#'     tibble summarizing terms available as `projects()` return
#'     values, and for use in filters. The tibble contains columns
#'
#' - `facet`: the name of the facet.
#' - `n_terms`: the number of distinct values the facet can take.
#' - `n_values`: the number of occurrences of the facet term in the
#'    entire catalog.
#'
#' `projects_facets()` invoked with a scalar value for `facet=`
#' returns a tibble summarizing terms used in the facet, and the
#' number of occurrences of the term in the entire catalog.
#'
#' @examples
#' projects_facets()
#' projects_facets("genusSpecies")
#'
#' @export
projects_facets <-
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
    lst <- projects(size = 1L, catalog = catalog, as = "list")
    .term_facets(lst, facet)
}

#' @rdname projects
#'
#' @description `*_columns()` returns a tibble or named
#'     character vector describing the content of the tibble returned
#'     by `projects()`, `files()`, `samples()`, or `bundles()`.
#'
#' @return `*_columns()` returns a tibble with column `name`
#'     containing the column name used in the tibble returned by
#'     `projects()`, `files()`, `samples()`, or `bundles()`, and
#'     `path` the path (see `lol_hits()`) to the data in the
#'     list-of-lists by the same functions when `as = "lol"`. When `as
#'     = "character"`, the return value is a named list with paths as
#'     elements and abbreviations as names.
#'
#' @examples
#' projects_default_columns()
#'
#' @export
projects_default_columns <-
    function(as = c("tibble", "character"))
{
    .default_columns("projects", as)
}

#' @rdname projects
#'
#' @name projects_detail
#'
#' @description `projects_detail()` takes a unique project_id and catalog for
#' the project, and returns details about the specified project as a
#' list-of-lists
#'
#' @description See `project_information()` and `project_title()` to
#'     easily summarize a project from its project id.
#'
#' @param uuid character() unique identifier (e.g., `projectId`) of
#'     the object.
#'
#' @param catalog character(1) source of data. Use
#'     `catalogs()` for possible values.
#'
#' @return list-of-lists containing relevant details about the project.
#'
#' @examples
#' project <- projects(size = 1, as = "list")
#' project_uuid <- project[["hits"]][[1]][["entryId"]]
#' projects_detail(uuid = project_uuid)
#'
#' @export
projects_detail <-
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
    .details(uuid = uuid, catalog = catalog, view = "projects")
}
