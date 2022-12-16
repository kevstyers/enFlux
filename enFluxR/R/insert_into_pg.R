#' #' Insert data into the table
#'
#' This inserts data into the specified table
#'
#' @param con connection object
#' @param data data.frame/data.table port of pg server
#' @param table character, name of pg table
#' @return NA
#' @export
insert_into_pg = function(con = NULL, data = NULL, table = NULL){


  # RPostgres::db

  RPostgres::dbAppendTable(conn = con, name = table, value = data)

}

