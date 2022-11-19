#' #' Connect to the Postgres server
#'
#' This connects to the PG server, acting as a wrapper
#'
#' @param host character, host name of pg server
#' @param port character, port of pg server
#' @param user character, username for pg server
#' @param pass character, password for pg server
#' @return Connection object for pg queries
#' @export
connect_to_pg = function(host = NULL, port = NULL, user = NULL, pass = NULL){

  .creds = readRDS(file = '~/GitHub/enFlux/.keys/.pg_server.RDS')

  host = .creds['host']

  con = DBI::dbConnect(
    drv = RPostgres::Postgres(),
    host = .creds[['host']],
    port = .creds[['port']],
    user = .creds[['user']],
    password = .creds[['pass']]
  )

  return(con)

}
