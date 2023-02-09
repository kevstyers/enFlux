#' @title Insert data into the table
#'
#' @description This inserts data into the specified table
#'
#' @param con connection object
#' @param data data.frame/data.table port of pg server
#' @param table character, name of pg table
#' @return NA
#' @export
init_insert_into_pg = function(con = NULL, data = NULL, table = NULL){

  # query_count = glue::glue_sql('select date(time_end) as date, count(*) from dev_ecte group by date(time_end) order by  date desc',.con = con)
  # res = RPostgres::dbSendQuery(conn = con, statement = query_count)
  # count_of_rows = RPostgres::dbFetch(res)

  # We never want to overwrite, as this overwrites the whole table.
  # We will want to potentially check that we're not duping data when we append though either.
  ## Probably need to check at the download_ec level that the query itself does not intend to dupe data, filter the query down at that level once
  ## to ensure we don't double append and reduce the duplication, only download the data we need, only unzip the files we need, only inser the files we need

  RPostgres::dbAppendTable(conn = con, name = table, value = data, append = TRUE, overwrite = FALSE)

}

