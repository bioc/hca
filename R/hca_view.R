#' @importFrom miniUI miniPage gadgetTitleBar miniContentPanel
.hca_view_app <-
    function()
{
    miniPage(
        gadgetTitleBar("Human Cell Atlas"),
        miniContentPanel({
            dataTableOutput("hca")
        })
    )
}

#' @importFrom shiny runGadget observeEvent stopApp
#'
#' @importFrom DT renderDataTable datatable dataTableOutput
#'     formatStyle
#'
#' @importFrom utils packageVersion
.hca_view_server <-
    function(tbl)
{
    ## use this function to capture 'tbl' in the server function

    if (packageVersion("DT") >= "0.23.2") {
        ## format 'list-columns' with ', ' between elements
        is_list_column <- vapply(tbl, inherits, logical(1), "list")
        list_columns <- names(tbl)[is_list_column]
        columnDefs = list(list(
            targets = list_columns,
            render = list("_" = "[, ]")
        ))
    } else {
        columnDefs = NULL
    }    

    function(input, output) {
        output$hca = renderDataTable({
            datatable(
                tbl,
                selection = 'multiple',
                rownames = FALSE,
                options = list(
                    scrollX = TRUE,
                    scrollY = TRUE,
                    pageLength = 100,
                    columnDefs = columnDefs
                )
            ) |>
                formatStyle(colnames(tbl), 'vertical-align' = "top")
        })

        observeEvent(input$done, stopApp(tbl[input$hca_rows_selected,]))
    }
}

#' @rdname hca_view
#'
#' @title View and select table rows interactively
#'
#' @param tbl a 'tibble' of `projects()`, `samples()`, `bundles()`, or
#'     `files()`.
#'
#' @return `hca_view()` returns a tibble filtered to reflect the rows
#'     selected in the interface.
#'
#' @examples
#' if (interactive()) {
#'     p <- projects(size = 100)
#'     p1 <- hca_view(p)  # interactive table browser; filtered results
#' }
#' @export
hca_view <-
    function(tbl)
{
    suppressMessages({
        runGadget(
            app = .hca_view_app(),
            server = .hca_view_server(tbl)
        )
    })
}
