library(DatabaseConnector)
library(SqlRender)
connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                             server = "testnode.arachnenetwork.com/synpuf_2m",
                                             user = "ohdsi",
                                             password = 'ohdsi',
                                             port = "5441",
                                             pathToDriver = 'c:/jdbcDrivers' # path to installed driver
                                             )
conn <- connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(conn, 'CREATE SCHEMA IF NOT EXISTS alex_alexeyuk_results') # create own schema using @name_surname_results pattern
