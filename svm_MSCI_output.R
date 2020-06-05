library(DataCombine)
library(ggplot2)
library(lubridate)
library(scales)
library(e1071)
setwd('/Users/sondreandersen/Desktop/new data 2/')

# Importing data
df_est <- read.csv('equal_datasets/dnk_est_w_index.csv')
df_test <- read.csv('equal_datasets/dnk_test_w_index.csv')
df_est$TIME <- ymd(df_est$TIME)
df_test$TIME <- ymd(df_test$TIME)

# Sletter hvis dato er før 1988-01, slik at alle modeller som har lag fra 1 til 12, har 
# ... like mange observasjoner. 
df_est <- df_est[df_est[['TIME']] >= '1988-01-01',] 
df_test <- df_test[df_test[['TIME']] >= '1988-01-01',] 


n_outputgap_est <- sum(df_est$outputgap)
n_outputgap_test <- sum(df_test$outputgap)

# Lager en ny dataframe med bare variabler som skal være med i analysen
# .. og konverterer output variablen til faktorer
df_estimation <- data.frame(outputgap=as.factor(df_est$outputgap),
                            stock_return_L = df_est$stock_return_L12)
df_estimation <- na.omit(df_estimation)

df_testing <- data.frame(outputgap=as.factor(df_test$outputgap),
                         stock_return_L = df_test$stock_return_L12)
df_testing <- na.omit(df_testing)




# Analysis
# Finding optimal gamma 
tune.out=tune(svm, outputgap~., data=df_estimation, kernel="radial",
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
  svmfit <- svm(outputgap~., data=df_estimation, kernel="radial", cost=i, gamma=0.01, scale=FALSE)
  ypred_insample = predict(svmfit, df_estimation)
  t <- table(predict=ypred_insample, thruth=df_estimation$outputgap)
  tp <- round(t[2,2], digits = 1)
  tn <- round(t[1,1], digits = 1)
  fp <- round(t[2,1], digits = 1)
  fn <- round(t[1,2], digits = 1)
  cost <- i
  
  hit_rate <- round(tp / (tp + fn), digits=2)
  false_alarm <- round(fp / (fp + tn), digits=2)
  bias <- round((tp + fp) / n_outputgap_est, digits=2)
  precision <- round(tp / (tp + fp), digits=2)
  accuracy <- round(   (tp + tn) / (tp + fp + tn + fn)   ,digits=2)
  
  df_roc[nrow(df_roc) + 1,] <- c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision, accuracy)
  
  print(c(cost, tp, tn, fp, fn, hit_rate, false_alarm, bias, precision))
}
df_roc <- df_roc[-c(1),]
# Export results
write.csv(df_roc,"1_analysis/stock_data_analysis/outputgap_svm/insample_nor3.csv", row.names = FALSE)
#write.csv(df_roc,"1_analysis/output_forecasting_svm/insample_12_i_nor_.csv", row.names = FALSE)












