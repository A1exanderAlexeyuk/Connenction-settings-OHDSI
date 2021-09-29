library(PatientLevelPrediction)
data(plpDataSimulationProfile)
set.seed(1234)
sampleSize <- 2000
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
names(population)



model1 <- setLassoLogisticRegression()
model2 <- setRandomForest()
testFraction <- 0.2
ensembleStrategy <- 'stacked'
testSplit <- 'person'
ensembleResults <- PatientLevelPrediction::runEnsembleModel(population,
                                                            dataList = list(plpData, plpData),
                                                            modelList = list(model1, model2),
                                                            testSplit=testSplit,
                                                            testFraction=testFraction,
                                                            nfold=3, splitSeed=1000,
                                                            ensembleStrategy = ensembleStrategy)
saveEnsemblePlpModel(ensembleResults$model, dirPath = file.path(getwd(), "model"))
ensembleModel <- loadEnsemblePlpModel(getwd(), "model")


plpData <- loadPlpData("<data file>")
populationSettings <- ensembleModel$populationSettings
populationSettings$plpData <- plpData
population <- do.call(createStudyPopulation, populationSettings)

# Show all demos in our package:
demo(package = "PatientLevelPrediction")
# Run the learning curve
demo("EnsembleModelDemo", package = "PatientLevelPrediction")
