//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double mse_tolerance_intercept = 1e-7;
input double mse_tolerance_coef = 1e-8;
input double mse_tolerance_power = 2; 
input double beta_threshold = 0.0001;
input int window_threshold = 4;
input int max_trend_num = 7;
input int max_regression_lookback = 250;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

int trend_starts[];

int MAGICNUM = 42;

// file repo: C:\Users\codch\AppData\Roaming\MetaQuotes\Terminal\3212703ED955F10C7534BE8497B221F4\tester\files

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   last_bar = 0;
   ArrayResize(trend_starts, max_trend_num);
   ArrayInitialize(trend_starts, 0);
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
  
  ClearTrendArray();
  IncrementalRegression(max_regression_lookback);

  // Plotting
  datetime last_x = iTime(NULL, tf, 1);
  double last_y = variable(1);
  datetime new_x;
  double new_y;
  for (int i = 0; i < max_trend_num; i++) {
    if (trend_starts[i] == 0) break;
    string object_name = "" + Bars + ", " + trend_starts[i];
    new_x = iTime(NULL, tf, trend_starts[i]);
    new_y = variable(trend_starts[i]);
    if (!ObjectCreate(object_name, OBJ_TREND, 0, new_x, new_y, last_x, last_y)) {
      Print("error plotting");
    } else {
      ObjectSetInteger(0, object_name, OBJPROP_RAY, 0);
      last_x = new_x;
      last_y = new_y;
    }
  }

  last_bar = Bars;
}
//+------------------------------------------------------------------+
void ClearTrendArray() {
  ArrayInitialize(trend_starts, 0);
}

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
  // incrementally calculate
  for (int i = 3; i <= max_window; i++) {
    double new_nominator = IncrementalBetaNominator(i - 1, nominator, y_mean);
    double new_denominator = IncrementalBetaDenominator(i - 1, denominator);
    double new_beta = new_nominator / new_denominator;
    double new_y_mean = IncrementalYMean(i - 1, y_mean);
    double new_x_mean = 0.5 * i * (i + 1);
    double new_alpha = new_y_mean - new_beta * new_x_mean;

    /***
     * LOGIC
     ***/
    if (MathAbs(new_beta) >= beta_threshold && i >= window_threshold) {
      double new_mean_squared_error = GetMSE(i, new_alpha, new_beta);
      if (new_mean_squared_error <= mse_tolerance_intercept + mse_tolerance_coef * MathPow(i, mse_tolerance_power)) {
        last_trendy = true;
        current_trendy = true;
      }
    }

    if (last_trendy && !current_trendy) {
      trend_starts[next_idx] = i - 1;
      next_idx += 1;
      if (next_idx == max_trend_num) return;
      last_trendy = false;
    }

    current_trendy = false;
    /***/
    y_mean = new_y_mean;
    x_mean = new_x_mean;
    nominator = new_nominator;
    denominator = new_denominator;
    beta = new_beta;
    alpha = new_alpha;
  }

  if (last_trendy) trend_starts[next_idx] = max_window;
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