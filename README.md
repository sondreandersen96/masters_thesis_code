# Code used in Master's Thesis in Economics/Finance

## About this repository
This repository contains the code used in the analysis section of my master's thesis: *Forecasting Economic Downturns in the
Scandinavian Countries using The Yield Curve*. 

## What does this repository contain?
I have tried to name the files in order to make their contents as understandable as possible. The list below should 
help understanding the purpose of each file. 

* **Non_prob:** All the files that start with **non_prob** are the Python files used to create and test the non-probabilistic
models based on a probit regression.

  * **Recession/output**: This part of the filename describes whether the non-probabilistic model atempted to forecast
  recessions or output gaps. 

  * **MSCI**: This part of the filename if included describes the files that take the stock index as explanatory variable. 
  if this term is not included then the models take the spread as the explanatory variable. 
  
  * **threshold_insample/out_of_sample_test**: If the filename contains the first this keyword then its purpose is to 
  find the optimal, threshold, W. If it contains the second keyword, then its purpose is to test, given a threshold W, how well
  the model performs in pseudo out-of-sample tests. 

* **SVM:** The four files that start with this keyword are the R scripts that are used to create and test the SVM models. 

  * **MSCI:** As before, the files that contain this keyword are the files that take the stock indexes as explanatory 
 variables. The other files take either the spread or the interest rate pair (long and short) as explanatory variables. 
 
  * **Recession/output:** These keywords describe whether the models attempts to forecast recessions or output gaps. 
 

*(Note that in some of the **R** files the lag length and also (for the non MSCI files) the explanatory variable must be changed depending on the model of interest.)*
 
  
