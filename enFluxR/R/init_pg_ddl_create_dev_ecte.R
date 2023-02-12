#' @title Create dev_ecte pg table
#'
#' @description Creates dev_ecte table with proper schema, index and partitions
#'
#' @param con connection object
#' @param data data.frame/data.table port of pg server
#' @param table character, name of pg table
#' @return NA
#' @export
init_pg_ddl_create_dev_ecte = function(){
  con = enFluxR::pg_connect()
browser()
  dev_ecte_exists = RPostgres::dbExistsTable(conn = con, name = 'public.dev_ecte_no_indexno_partition')

  if(!dev_ecte_exists){
    message('creating table')
    # Create the table schema
    schema =
    '
    CREATE TABLE public.dev_ecte_no_indexno_partition (
      site text            NULL,
      timing text          NULL,
      time_bgn timestamptz NULL,
      time_end timestamptz NULL,
      "location" text      NULL,
      sensor text          NULL,
      stream text          NULL,
      mean float(2)        NULL,
      min float(2)         NULL,
      max float(2)         NULL,
      vari float(4)        NULL,
      num_samp int         NULL
    )
    -- PARTITION BY RANGE(time_end);
    ;
    '
    schema_sql = glue::glue_sql(schema, .con = con)

    RPostgres::dbSendQuery(conn = con, statement = schema_sql)

    # # Add indexes
    index_1 =
    '
    CREATE INDEX time_end_idx ON public.dev_ecte_no_index
    USING btree (time_end DESC);
    '
    index_1_sql = glue::glue_sql(index_1, .con = con)
    RPostgres::dbSendQuery(conn = con, statement = index_1_sql)



    # Create partitions
    ## Check pg_partman exists
    pg_partman_query = "select * from pg_extension where extname='pg_partman';"
    pg_partman_res = RPostgres::dbSendQuery(conn = con, statement = pg_partman_query)
    pg_partman_rows = RPostgres::dbFetch(pg_partman_res)

    if(nrow(pg_partman_rows) == 0){
      create_pg_partman = glue::glue_sql('CREATE EXTENSION pg_partman;', .con = con)
      RPostgres::dbSendQuery(statement = create_pg_partman, con)
    }

    create_partitions = glue::glue_sql("SELECT create_parent('public.dev_ecte_no_index', 'time_end', 'native', 'daily', p_start_partition := '2017-01-01');")
    RPostgres::dbSendQuery(conn = con, statement = create_partitions)


  } else {
    message(paste0(Sys.time(), ":deleting table"))

    ## Drop that
    # drop table
    if(!RPostgres::dbExistsTable(conn = con, name = 'public.dev_ecte_no_index')){
      drop_query = glue::glue_sql('drop table public.dev_ecte_no_index', .con = con)
    }
    if(!RPostgres::dbExistsTable(conn = con, name = 'public.dev_ecte_no_index')){
      RPostgres::dbSendQuery(conn = con, statement = drop_query)
    }
    # drop template
    if(!RPostgres::dbExistsTable(conn = con, name = 'public.dev_ecte_no_index')){
    drop_query = glue::glue_sql('drop table public.template_public_dev_ecte', .con = con)
      RPostgres::dbSendQuery(conn = con, statement = drop_query)
    }
    # drop partitions
    if(!RPostgres::dbExistsTable(conn = con, name = 'public.dev_ecte_no_index')){
    drop_query = glue::glue_sql('drop extension pg_partman', .con = con)
      RPostgres::dbSendQuery(conn = con, statement = drop_query)
    }


    message('creating table')
    # Create the table schema
    schema =
      '
    CREATE TABLE public.dev_ecte_no_index (
      site text            NULL,
      timing text          NULL,
      time_bgn timestamptz NULL,
      time_end timestamptz NULL,
      "location" text      NULL,
      sensor text          NULL,
      stream text          NULL,
      mean float(2)        NULL,
      min float(2)         NULL,
      max float(2)         NULL,
      vari float(4)        NULL,
      num_samp int         NULL
    ) PARTITION BY RANGE(time_end);
    '
    schema_sql = glue::glue_sql(schema, .con = con)

    RPostgres::dbSendQuery(conn = con, statement = schema_sql)

    # Add indexes
    index_1 =
      '
    CREATE INDEX time_end_idx ON public.dev_ecte_no_index
    USING btree (time_end DESC);
    '
    index_1_sql = glue::glue_sql(index_1, .con = con)
    RPostgres::dbSendQuery(conn = con, statement = index_1_sql)

    # Create partitions
    create_pg_partman = glue::glue_sql('CREATE EXTENSION pg_partman;', .con = con)
    RPostgres::dbSendQuery(statement = create_pg_partman, con)

    create_partitions = glue::glue_sql("SELECT create_parent('public.dev_ecte_no_index', 'time_end', 'native', 'daily', p_start_partition := '2017-01-01');")
    RPostgres::dbSendQuery(conn = con, statement = create_partitions)

  }

}
