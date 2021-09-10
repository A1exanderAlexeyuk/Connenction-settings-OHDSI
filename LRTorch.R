library(DatabaseConnector)
library(SqlRender)
source("C:/Users/Alex/D/study/plpCustomDemo/sql.R")
connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                             server = "testnode.arachnenetwork.com/synpuf_110k",
                                             user = "ohdsi",
                                             password = 'ohdsi',
                                             port = "5441",
                                             pathToDriver = 'c:/jdbcDrivers')


conn <- connect(connectionDetails)
DatabaseConnector::renderTranslateExecuteSql(conn, 'DROP table  alex_alexeyuk_results.PLPDEMO')
cohortDatabaseSchema <- 'alex_alexeyuk_results'
cdmDatabaseSchema <- 'cdm_531'
#============================== origination of cohorts =================================================
sql_target <- SqlRender::render(sql_target, cdmDatabaseSchema = 'cdm_531', cohortDatabaseSchema = 'alex_alexeyuk_results')
sql_outcome <- SqlRender::render(sql_outcome, cdmDatabaseSchema = 'cdm_531', cohortDatabaseSchema = 'alex_alexeyuk_results')
sql_target <- SqlRender::translate(sql = sql_target, targetDialect = "postgresql")
sql_outcome <- SqlRender::translate(sql = sql_outcome, targetDialect = "postgresql")
DatabaseConnector::executeSql(connection = conn, sql=sql_target) # define target cohort
DatabaseConnector::executeSql(connection = conn, sql=sql_outcome)# define outcome cohort
DatabaseConnector::querySql(conn, sql= 'select count(*) from alex_alexeyuk_results.plpdemo where COHORT_DEFINITION_ID = 2')
library(FeatureExtraction)
library(PatientLevelPrediction)
#============================== feature extraction =================================================


covariateSettings <- FeatureExtraction::createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup =  TRUE,
  useConditionGroupEraLongTerm = TRUE,
  longTermStartDays = -365,
  endDays = -1
)
#covariateSettings <- FeatureExtraction::createDefaultTemporalCovariateSettings()
plpData <- getPlpData(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      oracleTempSchema = NULL,
                      cohortId = 1,
                      outcomeIds = 2,
                      cohortDatabaseSchema = cohortDatabaseSchema,
                      cohortTable = 'PLPDEMO',
                      outcomeDatabaseSchema = cohortDatabaseSchema,
                      outcomeTable = 'PLPDEMO',
                      cdmVersion = 5,
                      firstExposureOnly = T,
                      washoutPeriod = 354,
                      covariateSettings = covariateSettings,
                      sampleSize = 20000
                      )

population <- createStudyPopulation(
  plpData,
  outcomeId = 2,
  binary = TRUE,
  firstExposureOnly = FALSE,
  washoutPeriod = 0,
  removeSubjectsWithPriorOutcome = FALSE,
  priorOutcomeLookback = 99999,
  requireTimeAtRisk = FALSE,
  minTimeAtRisk = 0,
  riskWindowStart = 0,
  addExposureDaysToStart = FALSE,
  riskWindowEnd = 365,
  addExposureDaysToEnd = FALSE,
  verbosity = "INFO"
)


autoencoder <- FALSE
vae <- FALSE
class_weight <- 0


# Specify the settings for Logistics regression model using Torch in Python
model <- setLRTorch(autoencoder=autoencoder, vae=vae,  class_weight=class_weight)


testFraction <- 0.2
testSplit <- 'person'
nfold <- 3
splitSeed <- 1000


results <- PatientLevelPrediction::runPlp(population = population, 
                                          plpData = plpData, 
                                          modelSettings = model,
                                          testSplit=testSplit,
                                          testFraction=testFraction,
                                          nfold=nfold, 
                                          splitSeed=splitSeed) 
