library(DatabaseConnector)
library(SqlRender)
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

#=======================================sql==============================================
sql_target <- "select 1 as cohort_definition_id, de.person_id as subject_id,
    drug_era_start_date as cohort_start_date,
    dateadd(day, 30, drug_era_end_date) as cohort_end_date
into @cohortDatabaseSchema.plpDemo
from
(select * from @cdmDatabaseSchema.drug_era 
  inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = @cdmDatabaseSchema.drug_era.DRUG_CONCEPT_ID
  where ca.ancestor_concept_id = 974166) as de 
inner join
(select person_id, min(drug_era_start_date) as first_date
    from @cdmDatabaseSchema.drug_era  
    inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = @cdmDatabaseSchema.drug_era.DRUG_CONCEPT_ID
    where ca.ancestor_concept_id = 974166 group by person_id) as first_dates
on de.person_id = first_dates.person_id and de.drug_era_start_date = first_dates.first_date
" 

sql_outcome <- "insert into @cohortDatabaseSchema.plpDemo(
cohort_definition_id, subject_id, cohort_start_date,
cohort_end_date)
select 2 as cohort_definition_id, co.person_id as subject_id,
condition_start_date as cohort_start_date, condition_start_date as cohort_end_date
from
@cdmDatabaseSchema.condition_occurrence co
inner join
@cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = co.condition_concept_id
where ca.ancestor_concept_id = 378253 
" 
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


# Specify the settings for Logistics regression model using Torch in Python
model <- setLRTorch(w_decay = c(5e-04, 0.005), #The l2 regularisation
                    epochs = c(20, 50, 100), # The number of epochs
                    seed = 345, # A seed for the model
                    class_weight = 0, # The class weight used for imbalanced data: 0: Inverse ratio between positives and negatives -1: Focal loss
                    autoencoder = FALSE, # First learn stakced autoencoder for input features, then train LR on the encoded features
                    vae = FALSE) # First learn stakced varational autoencoder for input features, then train LR on the encoded features.


testFraction <- 0.2
testSplit <- 'person'
nfold <- 3
splitSeed <- 1000

# ===================training patient level prediction model=======================
results <- PatientLevelPrediction::runPlp(population = population, 
                                          plpData = plpData, 
                                          modelSettings = model,
                                          testSplit = testSplit,
                                          testFraction = testFraction,
                                          nfold = nfold, 
                                          splitSeed = splitSeed) 

