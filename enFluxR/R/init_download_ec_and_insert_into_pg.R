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
    paste0(
      "
      select
    	date_trunc('month', time_end) as ym
    	, site
    	, count(*) as row_count
      from dev_ecte_no_indexno_partition
      where site = '", site,"'",
      "
      and mean is not null
      group by site, ym
      order by site, ym
      "
    )
  , .con = con )

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

  # Specify the tempdir
  data_folder = tempdir()

  num_months_in_query = length(months_in_query_params$ym)
  num_months_already_in_pg = length(months_already_in_pg)
  num_months_new_to_pg = num_months_in_query - num_months_already_in_pg # Count is not always right

  init_msg(paste0("\n\tMonths in query: \t", num_months_in_query,
                  "\n\tMonths already in pg: \t", num_months_already_in_pg,
                  "\n\tNew months to pull: \t", num_months_new_to_pg))

  if(length(months_in_query) == 0){
    "All months were already in pg."
  }

  for(i in seq_along(months_in_query)){

    init_msg(msg = paste0("Pulling ", months_in_query[i], " --- ", 100*round(i/length(months_in_query),2), "% done"))

    # Well maybe I'm crazy, but the way zipsByProduct handles pulling months with a start end date, is bizare
    # basically the following gives us the expect month ie if months_in_query[i] = '2022-01-01' then we pull the month of January 2022
    i_start = as.character(as.Date(months_in_query[i] - days(1)))
    i_end   = as.character(as.Date(months_in_query[i], origin = '1970-01-01') %m+% months(1) - days(1))

    poss_ZBP = purrr::possibly(neonUtilities::zipsByProduct, otherwise = 'error', quiet = FALSE)

    poss_ZBP(
      dpID         = 'DP4.00200.001'
      , site       = site
      , startdate  = i_start
      , enddate    = i_end
      , package    = package
      , savepath   = data_folder
      , check.size = FALSE
      , token      = .token
    )

  }

  # Find the files that we downloaded
  files_to_stack = list.files(data_folder, pattern = "filesToStack", full.names = TRUE)

  # Check if any files were available
  if(length(files_to_stack) == 0){
    stop(
      "No files not in pg were available for download"
    )
  }

  # Find the actual zip we need to unzip
  files_to_unzip = list.files(files_to_stack, full.names = TRUE)

  # Set working directory to output the unzip'ed files
  setwd(data_folder)

  init_msg("Unzipping files now.")
  # Unzip the files
  for(i in files_to_unzip){
    utils::unzip(zipfile = i)
  }

  # List out all of the files from the zip, that now need to be unzipped
  files_to_unzip2 = list.files(path = data_folder, pattern = '.h5.gz', full.names = TRUE)

  # For each file, unzip it in place
  # TODO: parallelize this takes forever
  for(i in files_to_unzip2){

    init_msg(paste0(" Unzipping - ", i))
    # Unzip the i'th file
    R.utils::gunzip(filename = i)
  }

  # List of the files that are now unzipped
  files_to_read = data.table::data.table('full_path' = list.files(data_folder, pattern = '.h5', full.names = TRUE)  ) %>%
    dplyr::filter(base::grepl(full_path, pattern = site))

  init_msg("Ripping data")

  # Empty table to join bind to
  data_list = c()
  for(i in base::seq_along(files_to_read$full_path)){
    # browser()
    data_list[[i]] = init_collect_hdf5_data(path = files_to_read$full_path[i]) %>%
      dplyr::mutate(timeBgn = lubridate::ymd_hms(timeBgn)) %>%
      dplyr::mutate(timeEnd = lubridate::ymd_hms(timeEnd)) %>%
      dplyr::mutate(site = site) %>%
      dplyr::rename(time_bgn = timeBgn, time_end = timeEnd, num_samp = numSamp)
  }

  data_out = data.table::rbindlist(l = data_list) %>%
    dplyr::select(site, timing, time_bgn, time_end, location, sensor, stream, tidyr::everything())

  names(data_out) = tolower(names(data_out))

  init_msg(paste0("Inserting ", nrow(data_out), " rows."))
  init_insert_into_pg(con = con, table = 'dev_ecte_no_indexno_partition', data = data_out)


  init_msg("Deleting files from pull")

  file_types_to_delete = c('.txt', '.h5', '.xml')

  all_files_in_temp = data.table::data.table(files = list.files(data_folder)) %>%
    dplyr::filter(
      grepl(pattern = file_types_to_delete[1],x = files)
      | grepl(pattern = file_types_to_delete[2],x = files)
      | grepl(pattern = file_types_to_delete[3],x = files)
    )

  lapply(X = all_files_in_temp$files, FUN = file.remove)

  # Delete the zips from earlier
  if(length(list.files(data_folder, pattern = 'filesToStack')) == 1){

    lapply(X = list.files(paste0(data_folder,'\\filesToStack00200'), full.names = TRUE), file.remove)

  }


}
