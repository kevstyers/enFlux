#'
#'
#'
#'
#  = enFluxR::connect_to_pg()
site = 'PUUM'
start_date = '2019-01-01'
end_date = '2019-05-01'
package = 'expanded'
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
    , token      = .token
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
    dplyr::filter(base::grepl(full_path, pattern = 'PUUM'))

  ec_file_listing = rhdf5::h5ls(file = files_to_read$full_path[1], recursive = TRUE) %>%
    dplyr::filter(grepl(x = group, pattern = paste0('/', site, '/dp01/data/'))) %>%
    tidyr::separate(col = group, into = c('empty', 'site', 'dp_level', 'type', 'sensor', 'loc_timing'), remove = FALSE, sep = '/') %>%
    dplyr::filter(!is.na(loc_timing)) %>%
    dplyr::select(-empty) %>%
    tidyr::unite(col = 'h5_path', c(group,name), sep = '/', remove = FALSE) %>%
    dplyr::select(-group) %>%
    tidyr::separate(col = loc_timing, into = c('hor', 'ver', 'timing'), sep = '_') # TODO needs some work to work for all sensors

  # Empty table to join bind to
  data_out = data.table::data.table()
  for(i in base::seq_along(files_to_read$full_path)){
    message(i)

    ec_file_listing = rhdf5::h5ls(file = files_to_read$full_path[1], recursive = TRUE) %>%
      dplyr::filter(grepl(x = group, pattern = paste0('/', site, '/dp01/data/'))) %>%
      tidyr::separate(col = group, into = c('empty', 'site', 'dp_level', 'type', 'sensor', 'loc_timing'), remove = FALSE, sep = '/') %>%
      dplyr::filter(!is.na(loc_timing)) %>%
      dplyr::select(-empty) %>%
      tidyr::unite(col = 'h5_path', c(group,name), sep = '/', remove = FALSE) %>%
      dplyr::select(-group) %>%
      tidyr::separate(col = loc_timing, into = c('hor', 'ver', 'timing'), sep = '_') # TODO needs some work to work for all sensors

    ## Co2 Turb
    co2Turb_ls = ec_file_listing %>%
      dplyr::filter(sensor == 'co2Turb', timing == '30m')

    data_i_out = data.table::data.table()

    for(j in base::seq_along(co2Turb_ls$h5_path)){

      data_in = rhdf5::h5read(file = files_to_read$full_path[i], name = co2Turb_ls$h5_path[j]) %>%
        dplyr::mutate(sensor = co2Turb_ls$sensor[i], location = paste0(co2Turb_ls$hor[1], '.', co2Turb_ls$ver[i]), timing = co2Turb_ls$timing[i], stream = co2Turb_ls$name[i])

      data_i_out = data.table::rbindlist(l = list(data_i_out, data_in), fill = TRUE)
      rm(data_in)

    }

    data_out = data.table::rbindlist(l = list(data_out, data_i_out), fill = TRUE)

  }

  gc()
  .rs.restartR()

  # RPostgres::dbWriteTable(conn = con, name = 'enflux-dev.test-1', value = data_in)


}



