library(PatientLevelPrediction)
set.seed(1234)
data(plpDataSimulationProfile)
sampleSize <- 12000

plpData <- simulatePlpData(
  plpDataSimulationProfile,
  n = sampleSize
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




settings <- createTemporalCovariateSettings(useConditionEraStart = FALSE,
                                            useConditionEraOverlap = FALSE,
                                            useConditionOccurrence = FALSE,
                                            useConditionEraGroupStart = FALSE,
                                            useConditionEraGroupOverlap = FALSE,
                                            useDrugExposure = FALSE,
                                            useDrugEraStart = FALSE,
                                            useDrugEraOverlap = FALSE,
                                            useMeasurement = FALSE,
                                            useMeasurementValue = TRUE,
                                            useMeasurementRangeGroup = FALSE,
                                            useProcedureOccurrence = FALSE,
                                            useDeviceExposure = FALSE,
                                            useObservation = FALSE,
                                            excludedCovariateConceptIds = c(316866),
                                            addDescendantsToExclude = TRUE,
                                            temporalStartDays = seq(from = -365, 
                                                                    to = -1, by = 12), 
                                            temporalEndDays = c(seq(from = -353, 
                                                                    to = 0, by = 12), 0))

plpData <- getPlpData(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      cohortDatabaseSchema = "results",
                      cohortTable = "cohort",
                      cohortId = 11,
                      covariateSettings = settings,
                      outcomeDatabaseSchema = resultsDatabaseSchema,
                      outcomeTable = "cohort",
                      outcomeIds = 25,
                      cdmVersion = 5)
