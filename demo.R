# library(tidyverse)
library(enFluxR)

site = 'CPER'
start_date = '2016-01-01'
end_date = '2023-01-01'
package = 'basic'


# enFluxR::init_pg_ddl_create_dev_ecte()

enFluxR::init_download_ec_and_insert_into_pg(site = site, start_date = start_date, end_date = end_date, package = package)

con = enFluxR::pg_connect()

query_count = glue::glue_sql(
  '
  SELECT
    DATE(time_end) AS date
    , COUNT(*)
  FROM dev_ecte
  GROUP BY DATE(time_end)
  ORDER BY date DESC'
  ,.con = con)

res = RPostgres::dbSendQuery(conn = con, statement = query_count)
count_of_rows = RPostgres::dbFetch(res)

con = enFluxR::pg_connect()
enFluxR::pg_pull_data(site = "CPER", start_date = "2001-12-01", end_date = "2023-12-31", table = 'dev_ecte_no_indexno_partition', con = con) %>%
  dplyr::filter(stream == 'rtioMoleDryCo2') %>%
  ggplot(., aes(x = time_end, y = mean, color = location)) +
  geom_point() +
  facet_wrap(~site) +
  theme_bw()

con = enFluxR::pg_connect()

query = glue::glue_sql('select * from dev_ecte where mean is not null limit 1')
# query = glue::glue_sql("drop table \"enflux-dev.test1\" '", .con = con)

res = RPostgres::dbSendQuery(conn = con, statement = query)

data = RPostgres::dbFetch(res)

RPostgres::dbListTables(conn = con)

enFluxR::init_pg_ddl_create_dev_ecte()



##################################################################
################# Testing Indexed vs non-Indexed  ################
##################################################################
con = enFluxR::pg_connect()




message("Non-Indexed, non-partitioned")
for(i in 1:10){
  enFluxR::pg_pull_data(table = "dev_ecte_no_indexno_partition",site = "PUUM", start_date = "2001-12-01", end_date = "2021-12-31", con = con) %>%
    dplyr::filter(stream == 'rtioMoleDryCo2')
}
message("Non-Indexed")
for(i in 1:10){
  enFluxR::pg_pull_data(table = "dev_ecte_no_index",site = "PUUM", start_date = "2001-12-01", end_date = "2021-12-31", con = con) %>%
    dplyr::filter(stream == 'rtioMoleDryCo2')
}
message("Indexed")
for(i in 1:10){
  enFluxR::pg_pull_data(table = "dev_ecte", site = "PUUM", start_date = "2001-12-01", end_date = "2021-12-31", con = con) %>%
    dplyr::filter(stream == 'rtioMoleDryCo2')
}
