library(DataCombine)
library(ggplot2)
library(lubridate)
library(scales)
library(e1071)
setwd('/Users/sondreandersen/Desktop/new data 2/')

# Importing data
df_est <- read.csv('equal_datasets/swe_est.csv')
df_test <- read.csv('equal_datasets/swe_test.csv')
df_est$TIME <- ymd(df_est$TIME)
df_test$TIME <- ymd(df_test$TIME)
df_est$spread <- df_est$long_rate - df_est$short_rate
df_test$spread <- df_test$long_rate - df_test$short_rate

# Sletter hvis dato er før 1988-01, slik at alle modeller som har lag fra 1 til 12, har 
# ... like mange observasjoner. 
df_est <- df_est[df_est[['TIME']] >= '1988-01-01',] 
df_test <- df_test[df_test[['TIME']] >= '1988-01-01',] 

n_recessions_est <- sum(df_est$recession)
n_recessions_test <- sum(df_test$recession)




# Testing a lag of 1 months
df_est1 <- data.frame(recession=as.factor(df_est$recession),
                      short_rate1 = df_est$short_rate_L1, long_rate1 = df_est$long_rate_L1)
df_est1 <- na.omit(df_est1)

df_test1 <- data.frame(recession=as.factor(df_test$recession),
                       short_rate1 = df_test$short_rate_L1, long_rate1 = df_test$long_rate_L1)
df_test1 <- na.omit(df_test1)


# Testing a lag of 2 months
df_est2 <- data.frame(recession=as.factor(df_est$recession),
                      short_rate2 = df_est$short_rate_L2, long_rate2 = df_est$long_rate_L2)
df_est2 <- na.omit(df_est2)

df_test2 <- data.frame(recession=as.factor(df_test$recession),
                       short_rate2 = df_test$short_rate_L2, long_rate2 = df_test$long_rate_L2)
df_test2 <- na.omit(df_test2)


# Testing a lag of 3 months
df_est3 <- data.frame(recession=as.factor(df_est$recession),
                      short_rate3 = df_est$short_rate_L3, long_rate3 = df_est$long_rate_L3)
df_est3 <- na.omit(df_est3)

df_test3 <- data.frame(recession=as.factor(df_test$recession),
                       short_rate3 = df_test$short_rate_L3, long_rate3 = df_test$long_rate_L3)
df_test3 <- na.omit(df_test3)


# Testing a lag of 6 months
df_est6 <- data.frame(recession=as.factor(df_est$recession),
                      short_rate6 = df_est$short_rate_L6, long_rate6 = df_est$long_rate_L6)
df_est6 <- na.omit(df_est6)

df_test6 <- data.frame(recession=as.factor(df_test$recession),
                       short_rate6 = df_test$short_rate_L6, long_rate6 = df_test$long_rate_L6)
df_test6 <- na.omit(df_test6)


# Testing a lag of 12 months
df_est12 <- data.frame(recession=as.factor(df_est$recession),
                       short_rate12 = df_est$short_rate_L12, long_rate12 = df_est$long_rate_L12)
df_est12 <- na.omit(df_est12)

df_test12 <- data.frame(recession=as.factor(df_test$recession),
                        short_rate12 = df_test$short_rate_L12, long_rate12 = df_test$long_rate_L12)
df_test12 <- na.omit(df_test12)














# ------ Analysis ------

# -----> 1 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est1, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)


# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est1, kernel="radial", cost=i, gamma=1, scale=FALSE)
  ypred_insample = predict(svmfit, df_est1)
  t <- table(predict=ypred_insample, thruth=df_est1$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_1_nor.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est1, kernel="radial", cost=6000, gamma=1, scale=FALSE)
plot(svmfit, df_est1) # Insample plot

ypred = predict(svmfit, df_test1)
table(predict=ypred, thruth=df_test1$recession)

























# -----> 2 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est2, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)


# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est2, kernel="radial", cost=i, gamma=0.5, scale=FALSE)
  ypred_insample = predict(svmfit, df_est2)
  t <- table(predict=ypred_insample, thruth=df_est2$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_2_nor.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est2, kernel="radial", cost=400, gamma=0.5, scale=FALSE)
plot(svmfit, df_est2) # Insample plot

ypred = predict(svmfit, df_test2)
table(predict=ypred, thruth=df_test2$recession)
























# -----> 3 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est3, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)


# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est3, kernel="radial", cost=i, gamma=2.0, scale=FALSE)
  ypred_insample = predict(svmfit, df_est3)
  t <- table(predict=ypred_insample, thruth=df_est3$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_3_dnk.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est3, kernel="radial", cost=1200, gamma=2.0, scale=FALSE)
plot(svmfit, df_est3) # Insample plot

ypred = predict(svmfit, df_test3)
table(predict=ypred, thruth=df_test3$recession)



























# -----> Six month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est6, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)


# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
              1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
              2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
              6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est6, kernel="radial", cost=i, gamma=0.75, scale=FALSE)
  ypred_insample = predict(svmfit, df_est6)
  t <- table(predict=ypred_insample, thruth=df_est6$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_6_dnk.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est6, kernel="radial", cost=1900, gamma=0.75, scale=FALSE)
plot(svmfit, df_est6) # Insample plot

ypred = predict(svmfit, df_test6)
table(predict=ypred, thruth=df_test6$recession)


















# -----> 12 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est12, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)


# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est12, kernel="radial", cost=i, gamma=0.25, scale=FALSE)
  ypred_insample = predict(svmfit, df_est12)
  t <- table(predict=ypred_insample, thruth=df_est12$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_12_dnk.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est12, kernel="radial", cost=10000, gamma=0.25, scale=FALSE)
plot(svmfit, df_est12) # Insample plot

ypred = predict(svmfit, df_test12)
table(predict=ypred, thruth=df_test12$recession)






# ------------------------------------------------------






































































# Testing the spread as the explanatory variable
# Testing a lag of 3 months
df_est3_s <- data.frame(recession=as.factor(df_est$recession),
                        spread3 = df_est$long_rate_L3 - df_est$short_rate_L3)
df_est3_s <- na.omit(df_est3_s)

df_test3_s <- data.frame(recession=as.factor(df_test$recession),
                         spread3 = df_test$long_rate_L3 - df_test$short_rate_L3)
df_test3_s <- na.omit(df_test3_s)
# -----> 3 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est3_s, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)

# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est3_s, kernel="radial", cost=i, gamma=0.01, scale=FALSE)
  ypred_insample = predict(svmfit, df_est3_s)
  t <- table(predict=ypred_insample, thruth=df_est3_s$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_3s_dnkF.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est3_s, kernel="radial", cost=1, gamma=0.01, scale=FALSE)
plot(svmfit, df_est3_s) # Insample plot

ypred = predict(svmfit, df_test3_s)
table(predict=ypred, thruth=df_test3_s$recession)

























# Testing the spread as the explanatory variable
# Testing a lag of 6 months
df_est6_s <- data.frame(recession=as.factor(df_est$recession),
                       spread6 = df_est$long_rate_L6 - df_est$short_rate_L6)
df_est6_s <- na.omit(df_est6_s)

df_test6_s <- data.frame(recession=as.factor(df_test$recession),
                        spread6 = df_test$long_rate_L6 - df_test$short_rate_L6)
df_test6_s <- na.omit(df_test6_s)
# -----> 6 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est6_s, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)

# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est6_s, kernel="radial", cost=i, gamma=0.025, scale=FALSE)
  ypred_insample = predict(svmfit, df_est6_s)
  t <- table(predict=ypred_insample, thruth=df_est6_s$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_6s_sweF.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est6_s, kernel="radial", cost=1, gamma=0.01, scale=FALSE)
plot(svmfit, df_est6_s) # Insample plot

ypred = predict(svmfit, df_test6_s)
table(predict=ypred, thruth=df_test6_s$recession)
















# Testing the spread as the explanatory variable
# Testing a lag of 12 months
df_est12_s <- data.frame(recession=as.factor(df_est$recession),
                        spread12 = df_est$long_rate_L12 - df_est$short_rate_L12)
df_est12_s <- na.omit(df_est12_s)

df_test12_s <- data.frame(recession=as.factor(df_test$recession),
                         spread12 = df_test$long_rate_L12 - df_test$short_rate_L12)
df_test12_s <- na.omit(df_test12_s)
# -----> 12 month lag 
# Finding optimal gamma 
tune.out=tune(svm, recession~., data=df_est12_s, kernel="radial",
              ranges=list(cost=c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                                 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                                 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                                 6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000),
                          gamma=c(0.01, 0.025, 0.05, 0.75, 0.1, 0.25, 0.5, 0.75,1,2)))
summary(tune.out)

# Creating in-sample ROC curve
df_roc <- data.frame(cost=NA, true_pos=NA, true_neg=NA, false_pos=NA, false_neg=NA,
                     hit_rate=NA, false_alarm=NA, bias=NA, precision=NA, accuracy=NA)
cost_intervals = c(1:100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,
                   1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
                   2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000,
                   6500, 7000, 7500, 8000, 8500, 9000, 9500, 10000)
for (i in cost_intervals){
  svmfit <- svm(recession~., data=df_est12_s, kernel="radial", cost=i, gamma=0.25, scale=FALSE)
  ypred_insample = predict(svmfit, df_est12_s)
  t <- table(predict=ypred_insample, thruth=df_est12_s$recession)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_recessions_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
#df_roc <- na.omit(df_roc)
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/recession_forecasting_svm/insample_12s_sweF.csv", row.names = FALSE)

# ---> Out of sample test 
svmfit <- svm(recession~., data=df_est12_s, kernel="radial", cost=2500, gamma=1.0, scale=FALSE)
plot(svmfit, df_est12_s) # Insample plot

ypred = predict(svmfit, df_test12_s)
table(predict=ypred, thruth=df_test12_s$recession)









