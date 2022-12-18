#' @title Collect the data from an HDF5 file
#'
#' @description This opens the HDF5 file at the path and identifies what streams to pull, and grabs them from the file
#'
#' @param path character, path to the h5 file
#' @return the data in the HDF5
#' @export
collect_data = function(path = NULL){

  ec_file_listing = rhdf5::h5ls(file = path, recursive = TRUE) %>%
    dplyr::filter(grepl(x = group, pattern = paste0('/', site, '/dp01/data/'))) %>%
    tidyr::separate(col = group, into = c('empty', 'site', 'dp_level', 'type', 'sensor', 'loc_timing'), remove = FALSE, sep = '/') %>%
    dplyr::filter(!is.na(loc_timing)) %>%
    dplyr::select(-empty) %>%
    tidyr::unite(col = 'h5_path', c(group,name), sep = '/', remove = FALSE) %>%
    dplyr::select(-group) %>%
    tidyr::separate(col = loc_timing, into = c('hor', 'ver', 'timing'), sep = '_') %>% # TODO needs some work to work for all sensors
    dplyr::filter(!hor %in% c("co2Arch","co2High","co2Low","co2Med","co2Zero","h2oHigh","h2oLow","h2oMed"))

  co2Turb_ls = ec_file_listing %>%
    dplyr::filter(sensor == 'co2Turb', timing == '30m')

  data_list = c()

  for(j in base::seq_along(co2Turb_ls$h5_path)){

    data_list[[j]] <- rhdf5::h5read(file = path, name = co2Turb_ls$h5_path[j]) %>%
      dplyr::mutate(sensor = co2Turb_ls$sensor[j], location = paste0(co2Turb_ls$hor[j], '.', co2Turb_ls$ver[j]), timing = co2Turb_ls$timing[j], stream = co2Turb_ls$name[j])

  }

  data_out = data.table::rbindlist(l = data_list)

  gc()

  return(data_out)

}
