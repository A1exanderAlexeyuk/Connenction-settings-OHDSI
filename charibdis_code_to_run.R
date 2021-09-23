library(DatabaseConnector)
library(SqlRender)
library(FeatureExtraction)
library(CohortMethod)
library(CohortDiagnostics)
install.packages("devtools")
devtools::install_github("ohdsi-studies/Covid19CharacterizationCharybdis")
library(Covid19CharacterizationCharybdis)
connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                             server = "testnode.arachnenetwork.com/synthea",
                                             user = "ohdsi",
                                             password = "ohdsi",
                                             port = "5441",
                                             pathToDriver = '/home/ohdsi/drivers')


conn <- connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(conn, 'DROP  table IF EXISTS alex_alexeyuk_results.CHARIBDIS')
DatabaseConnector::renderTranslateExecuteSql(conn, 'CREATE  SCHEMA IF NOT EXISTS alex_alexeyuk_results')

cohortDatabaseSchema <- 'alex_alexeyuk_results'
cdmDatabaseSchema <- 'cdm_531'


# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Details specific to the database:
databaseId <- "OptumEhr1351"
databaseName <- "OptumEhr1351"
databaseDescription <- "OptumEhr1351"

# Details for connecting to the CDM and storing the results
outputFolder <- "/home/ohdsi/results"
cdmDatabaseSchema <- cdmDatabaseSchema
cohortDatabaseSchema <- cohortDatabaseSchema
cohortTable <- paste0("AS_CHARYBDIS_", databaseId)
cohortStagingTable <- paste0(cohortTable, "_stg")
featureSummaryTable <- paste0(cohortTable, "_smry")
minCellCount <- 5
useBulkCharacterization <- TRUE
cohortIdsToExcludeFromExecution <- c()
cohortIdsToExcludeFromResultsExport <- NULL

# For uploading the results. You should have received the key file from the study coordinator:
#keyFileName <- "E:/CHARYBDIS/study-data-site-covid19.dat"
userName <- "study-data-site-covid19"

# Run cohort diagnostics -----------------------------------
runCohortDiagnostics(connectionDetails = connectionDetails,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     cohortDatabaseSchema = cohortDatabaseSchema,
                     cohortStagingTable = cohortStagingTable,
                     oracleTempSchema = oracleTempSchema,
                     cohortIdsToExcludeFromExecution = cohortIdsToExcludeFromExecution,
                     exportFolder = outputFolder,
                     #cohortGroupNames = c("covid", "influenza", "strata", "feature"), # Optional - will use all groups by default
                     databaseId = databaseId,
                     databaseName = databaseName,
                     databaseDescription = databaseDescription,
                     minCellCount = minCellCount)

# Use the next command to review cohort diagnostics and replace "covid" with
# one of these options: "covid", "influenza", "strata", "feature"
# CohortDiagnostics::launchDiagnosticsExplorer(file.path(outputFolder, "diagnostics", "covid"))

# When finished with reviewing the diagnostics, use the next command
# to upload the diagnostic results
#uploadDiagnosticsResults(outputFolder, keyFileName, userName)

# Use this to run the study. The results will be stored in a zip file called 
# 'Results_<databaseId>.zip in the outputFolder. 
runStudy(connectionDetails = connectionDetails,
         cdmDatabaseSchema = cdmDatabaseSchema,
         cohortDatabaseSchema = cohortDatabaseSchema,
         cohortStagingTable = cohortStagingTable,
         cohortTable = cohortTable,
         featureSummaryTable = featureSummaryTable,
         oracleTempSchema = cohortDatabaseSchema,
         exportFolder = outputFolder,
         databaseId = databaseId,
         databaseName = databaseName,
         databaseDescription = databaseDescription,
         #cohortGroups = c("covid", "influenza"), # Optional - will use all groups by default
         cohortIdsToExcludeFromExecution = cohortIdsToExcludeFromExecution,
         cohortIdsToExcludeFromResultsExport = cohortIdsToExcludeFromResultsExport,
         incremental = TRUE,
         useBulkCharacterization = useBulkCharacterization,
         minCellCount = minCellCount) 


# Use the next set of commands to compress results
# and view the output.
#preMergeResultsFiles(outputFolder)
#launchShinyApp(outputFolder)

# When finished with reviewing the results, use the next command
# upload study results to OHDSI SFTP server:
#uploadStudyResults(outputFolder, keyFileName, userName)
