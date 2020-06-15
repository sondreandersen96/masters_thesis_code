import pandas as pd
from matplotlib import pyplot as plt
from scipy.stats import norm
import os
import numpy as np

os.chdir("/Users/sondreandersen/Desktop/new data 2")
country = 'dnk'
lag = 12

# Import data
df = pd.read_csv("equal_datasets/%s_est.csv" %(country))
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



# Testing different thresholds
w_s = []
tp_L = []
fp_L = []
tn_L = []
fn_L = []



df_results = pd.DataFrame()

for i in range(200):
    # w is the percentage threshold that separates yes and no forecasts
    w = (i + 1)/200
    w_s.append(w)
    p = []
    # Make predictions with each w
    this_lag = 'prob_L%s' %(lag)
    probability = np.array(df[this_lag])
    for n in range(len(df['TIME'])):
        if probability[n] >= w:
            prediction = 1
        else:
            prediction = 0
        p.append(prediction)

    df['temp_prediction'] = p

    # Calculate TP, FP, TN, FN:
    tp = 0
    fp = 0
    tn = 0
    fn = 0

    for row in range(len(df['TIME'])):
        temp_prediction = np.array(df['temp_prediction'])
        recession = np.array(df['recession'])

        if temp_prediction[row] == 1 and recession[row] == 1:
            tp += 1
        elif temp_prediction[row] == 1 and recession[row] == 0:
            fp += 1
        elif temp_prediction[row] == 0 and recession[row] == 0:
            tn += 1
        elif temp_prediction[row] == 0 and recession[row] == 1:
            fn += 1

    # Store results for a certain value of w

    tp_L.append(tp)
    fp_L.append(fp)
    tn_L.append(tn)
    fn_L.append(fn)





df_results['w'] = w_s
df_results['tp'] = tp_L
df_results['fp'] = fp_L
df_results['tn'] = tn_L
df_results['fn'] = fn_L

df_results['hit_rate'] = (df_results['tp']) / (df_results['tp'] + df_results['fn'])
df_results['false_alarm'] = (df_results['fp']) / (df_results['fp'] + df_results['tn'])
df_results['bias'] = (df_results['tp'] + df_results['fp']) / (df['recession'].sum())

precisions = []
'''
for i in range(len(df_results)):
    tp = df_results['tp']
    tn = df_results['tn']
    fp = df_results['fp']
    fn = df_results['fn']
    try:
        precision = (tp) / (tp + fp)
    except ZeroDivisionError:
        precision = 'nan'
    precisions.append(precision)
'''

#df_results['precision'] = precisions
df_results['precision'] = df_results['tp'] / (df_results['tp'] + df_results['fp'])

df_results['accuracy'] = (df_results['tp'] + df_results['tn']) / (df_results['tp'] + df_results['tn'] + df_results['fp'] + df_results['fn'])

df_results.to_csv('/Users/sondreandersen/Desktop/new data 2/1_analysis/recession_forecasting_probit/insample_threshold/%s_L%s.csv' %(country, lag))

#print(precisions)





print(df_results)
