#' Get points resources from the IPC API
#'
#' Accesses the points resources on the IPC API. Contains detailed area and
#' population data. If `year` and/or `type` parameters are passed, accesses
#' the **types** simplified API endpoint and pulls in all types data or filtered to
#' either `year` or `type`. To get all types for a specific analysis
#' and period, available on the **types/\{id\}/\{period\}** advanced API endpoint,
#' pass in `id` and `period`. You cannot pass in both sets of parameters.
#'
#' Points data is IPC data generated from analysis on geographic
#' entities that are smaller than the standard areas. These are typically
#' urban areas or displacement sites where food insecurity conditions might
#' differ significantly from the wider context and justify specific analysis.
#' Population estimates as well as an overall phase classification are provided
#' for each point. Data is currently output only for current
#' periods through the **points** endpoint. Use [ipc_get_population()] to get
#' detailed population data and classifications for all analysis periods. Points
#' data is contained within the `areas` dataset returned from
#' [ipc_get_population()].
#'
#' See the [IPC website](https://www.ipcinfo.org) and
#' [API documentation](https://docs.api.ipcinfo.org) for more information.
#'
#' @inheritParams ipc_get_areas
#'
#' @section Tidy:
#' When `tidy_df` is `TRUE`, the following changes are made to the initial
#' output to ensure each row represents a single point analysis, and all estimates
#' and values are stored as columns:
#'
#' 1. All columns containing `phase` or `population` are converted to numeric.
#' 2. `aar_id` is renamed to `area_id` and `anl_id` to `analysis_id`.
#'
#' @examplesIf !is.na(Sys.getenv("IPC_API_KEY", unset = NA))
#'
#' # get all areas from the simplified API
#' ipc_get_points()
#'
#' # get areas for specific analysis ID and period from advanced API
#' ipc_get_points(id = 18978466, period = "P")
#'
#' @returns
#' Data frame of IPC and CH analysis at the point level. Refer to the
#' [IPC-CH Public API documentation](https://docs.api.ipcinfo.org) for details
#' on the returned values, with variables described in full in the [extended
#' documentation](https://observablehq.com/@ipc/ipc-api-extended-documentation).
#'
#' @export
ipc_get_points <- function(
    year = NULL,
    type = NULL,
    id = NULL,
    period = NULL,
    api_key = NULL,
    tidy_df = TRUE
  ) {
  assert_id_period(id, period, year, type)
  assert_year(year)
  type <- assert_type(type)

  df <- ipc_get(
    resource = paste(c("points", id, period), collapse = "/"),
    return_format = "json",
    pass_format = FALSE,
    api_key = api_key,
    year = year,
    type = type
  )

  if (tidy_df) {
    clean_points_df(df)
  } else {
    df
  }
}

#' Clean up points data
#'
#' @noRd
clean_points_df <- function(df) {
  df  %>%
    dplyr::select(
      -dplyr::any_of("overall_phase")
    ) %>%
    tidyr::unnest(
      cols = "phases"
    ) %>%
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::matches("population|phase"),
        .fns = as.numeric
      )
    ) %>%
    dplyr::arrange(
      dplyr::across(
        .cols = dplyr::any_of(
          c(
            "country",
            "year",
            "title",
            "phase"
          )
        )
      )
    ) %>%
    dplyr::rename(
      "area_id" := "aar_id",
      "analysis_id" := "anl_id"
    )
}
