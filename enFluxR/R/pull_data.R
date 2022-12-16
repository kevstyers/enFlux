#' Grab EC data from pg
#'
#' This inserts data into the specified table
#'
#' @param site character, 4 letter site code
#' @param start_date character/date, yyyy-mm-dd, start date to pull
#' @param end_date character/date, yyyy-mm-dd, end date to pull
#' @param verbose logical, TRUE if you want your query back
#' @return NA
#' @export
pull_data = function(site = NULL, start_date = NULL, end_date = NULL, verbose = TRUE) {

  start_time = Sys.time()
  # Check conn

  # Check query
  con = enFluxR::connect_to_pg()

  query = glue::glue_sql(paste0("select * from \"enflux-dev.test1\" where site = '", site, "' and time_bgn >= '", start_date, "' and time_end <= '", end_date, "'"), .con = con)

  # Pull data
  if(verbose){
    message(query)
  }

  res = RPostgres::dbSendQuery(conn = con, statement = query)

  data_back = RPostgres::dbFetch(res)

  end_time = Sys.time()

  message(paste0(Sys.time(), ": query lasted ", round(difftime(end_time, start_time, units = 'sec'),2), " seconds"))

  return(data_back)

}
