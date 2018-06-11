//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int TakeProfit = 100;
input int StopLoss = 2000;
input double beta_threshold = 1e-5;
input double error_threshold = 1e-6;
input int max_regression_lookback = 150;
input double custom_error_decadence = -2;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

double beta, alpha, custom_error;
double last_beta = 1000000000;
double last_custom_error, last_alpha;

bool seek_cover_loss = false;

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

  if (OrdersTotal() == 0) {
    if (ShouldEnter()) {
      string object_name = "Trend " + Bars;
      ObjectCreate(object_name, OBJ_TREND, 0, iTime(NULL, tf, 10), variable(1) + 9 * beta, iTime(NULL, tf, 1), variable(1));
      ObjectSetInteger(0, object_name, OBJPROP_RAY, 0);
      if (beta < 0) {
        SetStopLossTakeProfit(true);
        OrderSend(Symbol(), OP_BUY, 0.1, Ask, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
        seek_cover_loss = false;
      } else {
        SetStopLossTakeProfit(false);
        OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
        seek_cover_loss = false;
      }
    }
  } else {
    if (ShouldExit()) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
      else if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet);
    }
  }

  last_bar = Bars;
  last_beta = beta;
  last_alpha = alpha;
  last_custom_error = custom_error;
}
//+------------------------------------------------------------------+

bool ShouldEnter() {
  return MathAbs(last_beta) < MathAbs(beta) && MathAbs(beta) > beta_threshold;
}

bool ShouldExit() {
  OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
  if (OrderType() == OP_BUY) {
    if (seek_cover_loss) {
      return Bid >= OrderOpenPrice();
    } else if (beta > 0) {
      seek_cover_loss = true;
    }
  } else if (OrderType() == OP_SELL) {
    if (seek_cover_loss) {
      return Ask <= OrderOpenPrice();
    } else if (beta < 0) {
      seek_cover_loss = true;
    }
  }
  return false;
}

void SetStopLossTakeProfit(bool buy) {
  if (buy) {
    stop_loss = Ask - StopLoss * Point;
    take_profit = Ask + TakeProfit * Point;
  } else {
    stop_loss = Bid + StopLoss * Point;
    take_profit = Bid -  TakeProfit * Point;
  }
}

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