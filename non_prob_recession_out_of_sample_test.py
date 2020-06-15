import pandas as pd
from matplotlib import pyplot as plt
from scipy.stats import norm
import os
import numpy as np

os.chdir("/Users/sondreandersen/Desktop/new data 2")
country = 'dnk'
lag = 12
w = 0.175


# Import data
df = pd.read_csv("equal_datasets/%s_test.csv" %(country))
df['TIME'] = pd.to_datetime(df['TIME'])

# Limit data (really, just the lower limit is effective as the datasets only go up to 06-2019)
start_date = '1988-01-01'
end_date = '2020-01-01'
df = df[(df['TIME'] >= start_date) & (df['TIME'] <= end_date )]


# Coefficient from stata
if country == 'nor':
    # Norway
    beta1_L3 = -0.1910756
    beta0_L3 = -1.501738
    beta1_L6 = -0.1544772
    beta0_L6 = -1.5004304
    beta1_L12 = -0.0857418
    beta0_L12 = -1.50089
elif country == 'swe':
    beta1_L3 = -0.6321984
    beta0_L3 = -0.5688849
    beta1_L6 = -0.8756413
    beta0_L6 = -0.5057888
    beta1_L12 = -0.3999069
    beta0_L12 = -0.756316
elif country == 'dnk':
    beta1_L3 = -0.2236813
    beta0_L3 = -0.8703304
    beta1_L6 = -0.1799431
    beta0_L6 = -0.8818978
    beta1_L12 = -0.1102153
    beta0_L12 = -0.903216



# Calculating spread variables for the three lags
df['spread_L3'] = df['long_rate_L3'] - df['short_rate_L3']
df['spread_L6'] = df['long_rate_L6'] - df['short_rate_L6']
df['spread_L12'] = df['long_rate_L12'] - df['short_rate_L12']

# ------> Estimating forecasts
# 3 lag models
df['prob_L3'] = norm.cdf((beta0_L3 + beta1_L3 * df['spread_L3']))
df['prob_L6'] = norm.cdf((beta0_L6 + beta1_L6 * df['spread_L6']))
df['prob_L12'] = norm.cdf((beta0_L12 + beta1_L12 * df['spread_L12']))




# OUT OF SAMPLE TEST


predictions = []

this_lag = 'prob_L%s' %(lag)
probability = np.array(df[this_lag])
for i in range(len(df)):
    if probability[i] >= w:
        prediction = 1
    else:
        prediction = 0
    predictions.append(prediction)

df['predictions'] = predictions

# Calculate TP, FP, TN, FN:
tp = 0
fp = 0
tn = 0
fn = 0

for row in range(len(df)):
    predictions = np.array(df['predictions'])
    recession = np.array(df['recession'])

    if predictions[row] == 1 and recession[row] == 1:
        tp += 1
    elif predictions[row] == 1 and recession[row] == 0:
        fp += 1
    elif predictions[row] == 0 and recession[row] == 0:
        tn += 1
    elif predictions[row] == 0 and recession[row] == 1:
        fn += 1


print('')
print('Results for %s with %s lags:' %(country.upper(), lag))
print('-> TP: %s' %(round(tp, 4)))
print('-> FP: %s' %(round(fp, 4)))
print('-> TN: %s' %(round(tn, 4)))
print('-> FN: %s' %(round(fn, 4)))
print('')
print('... That yields the following performance metrics:')




hit_rate = (tp) / (tp + fn)
false_alarm = (fp) / (fp + tn)
bias = (tp + fp) / (df['recession'].sum())
precision = (tp) / (tp + fp)
accuracy = (tp + tn) / (tp + fp + tn + fn)

print('-> Hit rate:     %s' %(round(hit_rate, 4)))
print('-> False alarm:  %s' %(round(false_alarm, 4)))
print('-> Bias:         %s' %(round(bias, 4)))
print('-> Precision:    %s' %(round(precision, 4)))
print('-> Accuracy:     %s' %(round(accuracy, 4)))














#
