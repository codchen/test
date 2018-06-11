//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double beta_threshold = 0.0001;
input int window_threshold = 5;
input int max_regression_lookback = 250;
input double mse_pow = -0.05;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

int trend_start;

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
  
  IncrementalRegression(max_regression_lookback);

  // Plotting
  if (trend_start >= 0) {
    string object_name = "Trend " + Bars;
    ObjectCreate(object_name, OBJ_TREND, 0, iTime(NULL, tf, trend_start), variable(trend_start), iTime(NULL, tf, 1), variable(1));
    ObjectSetInteger(0, object_name, OBJPROP_RAY, 0);
  }

  last_bar = Bars;
}
//+------------------------------------------------------------------+

void IncrementalRegression(int max_window) {
  // Starting with two data points (minimum for a regression estimation)
  double y_mean = 0.5 * (variable(1) + variable(2));
  double x_mean = 1.5;
  double nominator = 0.5 * (variable(2) - variable(1));
  double denominator = 0.5;
  double beta = variable(2) - variable(1);
  double alpha = variable(1) + variable(1) - variable(2);

  bool last_trendy = false;
  bool current_trendy = false;
  int next_idx = 0;

  double min_validity = 1000000;
  double beta_of_min_validity = 0;
  int i_of_min_validity = -1;
  // incrementally calculate
  for (int i = window_threshold; i <= max_window; i++) {
    double new_nominator = IncrementalBetaNominator(i - 1, nominator, y_mean);
    double new_denominator = IncrementalBetaDenominator(i - 1, denominator);
    double new_beta = new_nominator / new_denominator;
    double new_y_mean = IncrementalYMean(i - 1, y_mean);
    double new_x_mean = 0.5 * i * (i + 1);
    double new_alpha = new_y_mean - new_beta * new_x_mean;
    double new_mean_squared_error = GetMSE(i, new_alpha, new_beta);

    /***
     * LOGIC
     ***/
    double validity = new_mean_squared_error * MathPow(i, mse_pow);
    if (validity < min_validity) {
      min_validity = validity;
      beta_of_min_validity = new_beta;
      i_of_min_validity = i;
    }
    /***/
    y_mean = new_y_mean;
    x_mean = new_x_mean;
    nominator = new_nominator;
    denominator = new_denominator;
    beta = new_beta;
    alpha = new_alpha;
  }

  Print(i_of_min_validity, " of ", iTime(NULL, tf, 0), " with beta ", beta_of_min_validity);

  if (MathAbs(beta_of_min_validity) >= beta_threshold) {
    trend_start = i_of_min_validity;
  } else {
    trend_start = -1;
  }
}

double IncrementalBetaNominator(int old_window, double old_nominator, double old_y_mean) {
  return old_nominator + (variable(old_window + 1) - old_y_mean) * old_window * 0.5;
}

double IncrementalBetaDenominator(int old_window, double old_denominator) {
  return old_denominator + 0.25 * old_window * (old_window + 1);
}

double IncrementalYMean(int old_window, double old_y_mean) {
  return old_y_mean + (variable(old_window + 1) - old_y_mean) / (old_window + 1);
}

double GetMSE(int window, int alpha, int beta) {
  double mean_squared_error = 0.0;
  double current_residual;
  for (int i = 1; i <= window; i++) {
    current_residual = variable(i) - alpha - beta * i;
    mean_squared_error += current_residual * current_residual;
  }
  return mean_squared_error / window;
}

double variable(int shift) {
  return (High[shift] + Low[shift]) / 2;
}