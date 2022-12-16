#' Collect the data from an HDF5 file
#'
#' This inserts data into the specified table
#'
#' @param site character, 4 letter site code
#' @param start_date character/date, yyyy-mm-dd, start date to pull
#' @param end_date character/date, yyyy-mm-dd, end date to pull
#' @param package character, extended or basic?
#' @return NA
#'
#' @import magrittr
#' @export
download_ec = function(site = 'PUUM', start_date = '2000-01-01', end_date = Sys.Date(), package = 'expanded'){

  .token = readRDS('~/GitHub/enFlux/.keys/.neon_token.RDS')

  data_folder = tempdir()

  neonUtilities::zipsByProduct(
    dpID         = 'DP4.00200.001'
    , site       = site
    , startdate  = start_date
    , enddate    = end_date
    , package    = package
    , savepath   = data_folder
    , check.size = FALSE
    # , token      = .token
  )

  # Find the files that we downloaded
  files_to_stack = list.files(data_folder, pattern = "filesToStack", full.names = TRUE)
  # Find the actual zip we need to unzip
  files_to_unzip = list.files(files_to_stack, full.names = TRUE)

  # Set working directory to output the unzip'ed files
  setwd(data_folder)

  # Unzip the files
  for(i in files_to_unzip){
    utils::unzip(zipfile = i)
  }

  # List out all of the files from the zip, that now need to be unzipped
  files_to_unzip2 = list.files(path = data_folder, pattern = '.h5.gz', full.names = TRUE)

  # For each file, unzip it in place
  # TODO: parallelize this takes forever
  for(i in files_to_unzip2){
    message(i)
    # Unzip the i'th file
    R.utils::gunzip(filename = i)
  }

  # List of the files that are now unzipped
  files_to_read = data.table::data.table('full_path' = list.files(data_folder, pattern = '.h5', full.names = TRUE)  ) %>%
    dplyr::filter(base::grepl(full_path, pattern = site))

  # Empty table to join bind to
  data_list = c()
  for(i in base::seq_along(files_to_read$full_path)){
    data_list[[i]] = collect_data(path = files_to_read$full_path[i]) %>%
      dplyr::mutate(timeBgn = lubridate::ymd_hms(timeBgn)) %>%
      dplyr::mutate(timeEnd = lubridate::ymd_hms(timeEnd)) %>%
      dplyr::mutate(site = site) %>%
      dplyr::rename(time_bgn = timeBgn, time_end = timeEnd, num_samp = numSamp)
  }

  data_out = data.table::rbindlist(l = data_list) %>%
    dplyr::select(site, time_bgn, time_end, stream, tidyr::everything())

  con = enFluxR::connect_to_pg()

  tolower(names(data_out))

  browser()

  str(data_out)

  # RPostgres::dbWriteTable(conn = con, name = 'enflux-dev.test1', value = data_out)

  insert_into_pg(con = con, data = data_out, table = 'enflux-dev.test1')

}
