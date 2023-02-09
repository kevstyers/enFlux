#' @title Wrapper to message out during init functions
#'
#' @description This takes a char vector and applies standard messaging
#'
#' @param msg a message, character vector
#'
#' @return A standard message '2023-02-08 20:37:48 MST: This is a sample message'
#'
#' @export
init_msg = function(msg = NULL){
  if(is.null(msg)){
    message(Sys.time())
  } else {
    message(paste0(Sys.time(), ": ", msg))
  }
}
