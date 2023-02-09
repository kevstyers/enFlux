#' @title Wrapper to pull EC data from NEON portal and write it to a PG database
#'
#' @description This function pulls data, extracts data from HDF5, and saves the data out to a PG server
#'
#' @param site character, 4 letter site code
#' @param start_date character/date, yyyy-mm-dd, start date to pull
#' @param end_date character/date, yyyy-mm-dd, end date to pull
#' @param package character, extended or basic?
#' @return NA
#'
#' @import magrittr
#' @import lubridate
#' @export
init_download_ec_and_insert_into_pg = function(site = 'PUUM', start_date = '2017-01-01', end_date = Sys.Date(), package = 'basic'){

  init_msg("Connecting...")
  con = enFluxR::pg_connect()

  # Check to see if the data in the query already exists in the database
  check_not_duping = glue::glue_sql(
  "
  select
	date_trunc('month', time_end) as ym
	, site
	, count(*) as row_count
  from dev_ecte
  where mean is not null
  group by site, ym
  order by site, ym
  ", .con = con )

  init_msg("Checking for duplicates already in pg")
  res = RPostgres::dbSendQuery(conn = con, statement = check_not_duping)
  months_already_in_pg = RPostgres::dbFetch(res) %>%
    dplyr::mutate(ym = as.Date(ym)) %>%
    dplyr::pull(ym)

  # Conver to dates
  start_date = as.Date(start_date)
  end_date   = as.Date(end_date)

  `%not%` = Negate(`%in%`)

  # Filter query down to just months where we don't already have data
  months_in_query_params = data.table::data.table('ym' = as.Date(seq.Date(from = start_date, to = end_date, by = '1 month')))
  months_in_query = months_in_query_params %>%
    dplyr::filter(ym %not% months_already_in_pg) %>%
    dplyr::pull(ym)

  .token = readRDS('~/GitHub/enFlux/.keys/.neon_token.RDS')

  data_folder = tempdir()

  for(i in months_in_query){

    init_msg(msg = paste0("Testing: ", i))

    i_end =  as.character(as.Date(i) %m+% months(1))

    poss_ZBP = purrr::possibly(neonUtilities::zipsByProduct, otherwise = 'error', quiet = FALSE)

    poss_ZBP(
      dpID         = 'DP4.00200.001'
      , site       = site
      , startdate  = i
      , enddate    = i_end
      , package    = package
      , savepath   = data_folder
      , check.size = FALSE
      , token      = .token
    )

  }

  browser()

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
    data_list[[i]] = init_collect_hdf5_data(path = files_to_read$full_path[i]) %>%
      dplyr::mutate(timeBgn = lubridate::ymd_hms(timeBgn)) %>%
      dplyr::mutate(timeEnd = lubridate::ymd_hms(timeEnd)) %>%
      dplyr::mutate(site = site) %>%
      dplyr::rename(time_bgn = timeBgn, time_end = timeEnd, num_samp = numSamp)
  }

  data_out = data.table::rbindlist(l = data_list) %>%
    dplyr::select(site, timing, time_bgn, time_end, location, sensor, stream, tidyr::everything())

  names(data_out) = tolower(names(data_out))

  init_insert_into_pg(con = con, table = 'dev_ecte', data = data_out)

}