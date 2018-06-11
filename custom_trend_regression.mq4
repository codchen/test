//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double beta_threshold = 1e-5;
input double error_threshold = 1e-6;
input int max_regression_lookback = 150;
input double custom_error_decadence = -2;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

double beta, alpha, custom_error;

int MAGICNUM = 42;

// file repo: C:\Users\codch\AppData\Roaming\MetaQuotes\Terminal\3212703ED955F10C7534BE8497B221F4\tester\files

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   last_bar = 0;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  if (Bars < 10 + max_regression_lookback || Bars == last_bar) return;
  
  CustomRegression();

  // Plotting
  if (MathAbs(beta) > beta_threshold && custom_error < error_threshold) {
    string object_name = "Trend " + Bars;
    ObjectCreate(object_name, OBJ_TREND, 0, iTime(NULL, tf, 10), variable(1) + 9 * beta, iTime(NULL, tf, 1), variable(1));
    ObjectSetInteger(0, object_name, OBJPROP_RAY, 0);
  }

  last_bar = Bars;
}
//+------------------------------------------------------------------+

// comp_1: y mean
// comp_2: sum of 1/i
// comp_3: sum of yi / i
void CustomRegression() {
  double comp_1 = 0;
  double comp_2 = 0;
  double comp_3 = 0;
  double comp_4 = 0;
  double comp_5 = 0;
  double tmp_0, tmp_1, tmp_2;
  for (int i = 1; i <= max_regression_lookback; i++) {
    tmp_0 = MathPow(i, custom_error_decadence);
    tmp_1 = MathPow(i, custom_error_decadence + 1);
    tmp_2 = MathPow(i, custom_error_decadence + 2);
    comp_1 += tmp_0 * variable(i);
    comp_2 += tmp_1;
    comp_3 += tmp_0;
    comp_4 += tmp_1 * variable(i);
    comp_5 += tmp_2;
  }

  beta = (comp_1 * comp_2 - comp_3 * comp_4) / (comp_2 * comp_2 - comp_3 * comp_5);
  alpha = (comp_4 - beta * comp_5) / comp_2;

  double current_residual;
  custom_error = 0;
  for (int i = 1; i <= max_regression_lookback; i++) {
    current_residual = variable(i) - alpha - beta * i;
    custom_error += current_residual * current_residual * MathPow(i, custom_error_decadence);
  }
}


double variable(int shift) {
  return (High[shift] + Low[shift]) / 2;
}