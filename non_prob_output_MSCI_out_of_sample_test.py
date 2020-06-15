import pandas as pd
from matplotlib import pyplot as plt
from scipy.stats import norm
import os
import numpy as np
import pyperclip

os.chdir("/Users/sondreandersen/Desktop/new data 2")
country = 'dnk'
lag = 12
w = 0.56



# Import data
df = pd.read_csv("equal_datasets/%s_test_w_index.csv" %(country))
df['TIME'] = pd.to_datetime(df['TIME'])

# Limit data (really, just the lower limit is effective as the datasets only go up to 06-2019)
start_date = '1988-01-01'
end_date = '2020-01-01'
df = df[(df['TIME'] >= start_date) & (df['TIME'] <= end_date )]

# Coefficient from stata
if country == 'nor':
    # Norway
    beta1_L3 = -0.4700937
    beta0_L3 = 0.1033298
    beta1_L6 = -1.469654
    beta0_L6 = 0.1062222
    beta1_L12 = -2.693525
    beta0_L12 = 0.1289644
elif country == 'swe':
    beta1_L3 = -1.359483
    beta0_L3 = -0.0100019
    beta1_L6 = 1.051113
    beta0_L6 = -0.0298692
    beta1_L12 = -2.968303
    beta0_L12 = 0.0032301
elif country == 'dnk':
    beta1_L3 = -1.469781
    beta0_L3 = 0.1563786
    beta1_L6 = -1.510879
    beta0_L6 = 0.18222
    beta1_L12 = -1.848829
    beta0_L12 = 0.1909324




# Estimating forecasts
df['prob_L3'] = norm.cdf((beta0_L3 + beta1_L3 * df['stock_return_L3']))
df['prob_L6'] = norm.cdf((beta0_L6 + beta1_L6 * df['stock_return_L6']))
df['prob_L12'] = norm.cdf((beta0_L12 + beta1_L12 * df['stock_return_L12']))





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
    outputgap = np.array(df['outputgap'])

    if predictions[row] == 1 and outputgap[row] == 1:
        tp += 1
    elif predictions[row] == 1 and outputgap[row] == 0:
        fp += 1
    elif predictions[row] == 0 and outputgap[row] == 0:
        tn += 1
    elif predictions[row] == 0 and outputgap[row] == 1:
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
bias = (tp + fp) / (df['outputgap'].sum())
precision = (tp) / (tp + fp)
accuracy = (tp + tn) / (tp + fp + tn + fn)

print('-> Hit rate:     %s' %(round(hit_rate, 4)))
print('-> False alarm:  %s' %(round(false_alarm, 4)))
print('-> Bias:         %s' %(round(bias, 4)))
print('-> Precision:    %s' %(round(precision, 4)))
print('-> Accuracy:     %s' %(round(accuracy, 4)))

# Copy to clipboard
pyperclip.copy("%s \n %s \n %s \n %s \n %s \n" %(round(hit_rate, 4), round(false_alarm, 4), round(bias, 4),
round(precision, 4), round(accuracy, 4)) )











#
