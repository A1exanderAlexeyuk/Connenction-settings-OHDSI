#=====================================set SVM==================================================

model.svm <- setSVM(kernel='rbf', C=c(0.9,2), degree=c(1,5), 
                   gamma=c(1e-04, 3e-05, 0.25),
                   shrinking = T, coef0=0.0,
                   classWeight = 'balanced', varImp = F, seed = NULL)
results <- PatientLevelPrediction::runPlp(population = population, 
                                          plpData = plpData, 
                                          modelSettings = model.svm,
                                          testSplit=testSplit,
                                          testFraction=testFraction,
                                          nfold=nfold, 
                                          splitSeed=splitSeed) 
