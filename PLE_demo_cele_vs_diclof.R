library(DatabaseConnector)
library(SqlRender)
library(FeatureExtraction)
library(Andromeda)
library(CohortMethod)

connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                             server = "testnode.arachnenetwork.com/synpuf_110k",
                                             user = "ohdsi",
                                             password = 'ohdsi',
                                             port = "5441",
                                             pathToDriver = 'c:/jdbcDrivers')


conn <- connect(connectionDetails)
resultsDatabaseSchema <- 'alex_alexeyuk_results'
cdmDatabaseSchema <- 'cdm_531'
#=======================cohorts origination =============================================

sql <- readSql("VignetteOutcomes.sql")
sql <- render(sql,
              cdmDatabaseSchema = cdmDatabaseSchema,
              resultsDatabaseSchema = resultsDatabaseSchema)
sql <- translate(sql, targetDialect = connectionDetails$dbms)
connection <- connect(connectionDetails)
executeSql(connection, sql)

#  Specifying hypotheses of interest

tcos <- createTargetComparatorOutcomes(targetId = 1118084,
                                       comparatorId = 1124300,
                                       outcomeIds = c(192671, 29735, 140673, 197494,
                                                      198185, 198199, 200528, 257315,
                                                      314658, 317376, 321319, 380731,
                                                      432661, 432867, 433516, 433701,
                                                      433753, 435140, 435459, 435524,
                                                      435783, 436665, 436676, 442619,
                                                      444252, 444429, 4131756, 4134120,
                                                      4134454, 4152280, 4165112, 4174262,
                                                      4182210, 4270490, 4286201, 4289933))

targetComparatorOutcomesList <- list(tcos)


# Specifying analyses

covarSettings <- createDefaultCovariateSettings(excludedCovariateConceptIds = nsaids,
                                                addDescendantsToExclude = TRUE)
getDbCmDataArgs <- createGetDbCohortMethodDataArgs(washoutPeriod = 183,
                                                   restrictToCommonPeriod = FALSE,
                                                   firstExposureOnly = TRUE,
                                                   removeDuplicateSubjects = "remove all",
                                                   studyStartDate = "",
                                                   studyEndDate = "",
                                                   excludeDrugsFromCovariates = FALSE,
                                                   covariateSettings = covarSettings)
createStudyPopArgs <- createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                      minDaysAtRisk = 1,
                                                      riskWindowStart = 0,
                                                      startAnchor = "cohort start",
                                                      riskWindowEnd = 30,
                                                      endAnchor = "cohort end")
fitOutcomeModelArgs1 <- createFitOutcomeModelArgs(modelType = "cox")

cmAnalysis1 <- createCmAnalysis(analysisId = 1,
                                description = "No matching, simple outcome model",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs1)


createPsArgs <- createCreatePsArgs() # Use default settings only
matchOnPsArgs <- createMatchOnPsArgs(maxRatio = 100)
fitOutcomeModelArgs2 <- createFitOutcomeModelArgs(modelType = "cox",
                                                  stratified = TRUE)
cmAnalysis2 <- createCmAnalysis(analysisId = 2,
                                description = "Matching",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                matchOnPs = TRUE,
                                matchOnPsArgs = matchOnPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs1)
stratifyByPsArgs <- createStratifyByPsArgs(numberOfStrata = 5)
cmAnalysis3 <- createCmAnalysis(analysisId = 3,
                                description = "Stratification",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                stratifyByPs = TRUE,
                                stratifyByPsArgs = stratifyByPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs2)
fitOutcomeModelArgs3 <- createFitOutcomeModelArgs(modelType = "cox",
                                                  inversePtWeighting = TRUE)
cmAnalysis4 <- createCmAnalysis(analysisId = 4,
                                description = "Inverse probability weighting",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs3)
fitOutcomeModelArgs4 <- createFitOutcomeModelArgs(useCovariates = TRUE,
                                                  modelType = "cox",
                                                  stratified = TRUE)

cmAnalysis5 <- createCmAnalysis(analysisId = 5,
                                description = "Matching plus full outcome model",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                matchOnPs = TRUE,
                                matchOnPsArgs = matchOnPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs4)
interactionCovariateIds <- c(8532001, 201826210, 21600960413) # Female, T2DM, concurent use of antithrombotic agents
fitOutcomeModelArgs5 <- createFitOutcomeModelArgs(modelType = "cox",
                                                  stratified = TRUE,
                                                  interactionCovariateIds = interactionCovariateIds)
cmAnalysis6 <- createCmAnalysis(analysisId = 6,
                                description = "Stratification plus interaction terms",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                stratifyByPs = TRUE,
                                stratifyByPsArgs = stratifyByPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs5)


cmAnalysisList <- list(cmAnalysis1,
                       cmAnalysis2,
                       cmAnalysis3,
                       cmAnalysis4,
                       cmAnalysis5,
                       cmAnalysis6)


comparatorIds = list(drugInSameClass = 1124300,
                     drugWithSameIndication = 1125315)
tcos <- createTargetComparatorOutcomes(targetId = 1118084,
                                       comparatorId = comparatorIds,
                                       outcomeIds = 192671)
targetComparatorOutcomesList2 <- list(tcos)


cmAnalysis1 <- createCmAnalysis(analysisId = 1,
                                description = "Analysis using drug in same class",
                                comparatorType = "drugInSameClass",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                matchOnPs = TRUE,
                                matchOnPsArgs = matchOnPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs1)
cmAnalysis2 <- createCmAnalysis(analysisId = 2,
                                description = "Analysis using drug with same indication",
                                comparatorType = "drugWithSameIndication",
                                getDbCohortMethodDataArgs = getDbCmDataArgs,
                                createStudyPopArgs = createStudyPopArgs,
                                createPs = TRUE,
                                createPsArgs = createPsArgs,
                                matchOnPs = TRUE,
                                matchOnPsArgs = matchOnPsArgs,
                                fitOutcomeModel = TRUE,
                                fitOutcomeModelArgs = fitOutcomeModelArgs1)
cmAnalysisList2 <- list(cmAnalysis1, cmAnalysis2)





result <- runCmAnalyses(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        exposureDatabaseSchema = cdmDatabaseSchema,
                        exposureTable = "drug_era",
                        outcomeDatabaseSchema = resultsDatabaseSchema,
                        outcomeTable = "outcomes",
                        cdmVersion = 5,
                        outputFolder = getwd(),
                        cmAnalysisList = cmAnalysisList,
                        targetComparatorOutcomesList = targetComparatorOutcomesList,
                        getDbCohortMethodDataThreads = 1,
                        createPsThreads = 1,
                        psCvThreads = 10,
                        createStudyPopThreads = 4,
                        trimMatchStratifyThreads = 10,
                        fitOutcomeModelThreads = 4,
                        outcomeCvThreads = 10)



psFile <- result$psFile[result$targetId == 1118084 &
                          result$comparatorId == 1124300 &
                          result$outcomeId == 192671 &
                          result$analysisId == 5]
ps <- readRDS(file.path(outputFolder, psFile))
plotPs(ps)
