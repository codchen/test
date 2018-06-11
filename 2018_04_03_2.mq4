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
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

int bar_when_sold;
double recent_high;

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
  if (Bars == last_bar) return;

  if (OrdersTotal() == 0) {
    if (ShouldEnterSell()) {
      OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
      bar_when_sold = Bars;
    }
  } else {
    if (ShouldExit()) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
      else if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet);
    }
  }

  last_bar = Bars;
}
//+------------------------------------------------------------------+

bool ShouldEnterSell() {
  int highest_idx = 0;
  for (int i = 1; i < 100; i++) {
    if (Close[highest_idx] < Close[i]) {
      highest_idx = i;
    }
  }
  if (highest_idx < 30) return false;

  for (int i = 1; i < 100; i++) {
    if (Close[highest_idx + i] >= Close[highest_idx]) return false;
  }

  int lowest_idx = 0;
  for (int i = 1; i < highest_idx; i++) {
    if (Close[i] < Close[lowest_idx]) lowest_idx = i;
  }
  if (lowest_idx < highest_idx / 3 || lowest_idx > 2 * highest_idx / 3) return false;

  int recent_high_idx = 0;
  for (int i = 1; i < lowest_idx; i++) {
    if (Close[i] > Close[recent_high_idx]) recent_high_idx = i;
  }
  if (recent_high_idx < 3) return false;

  double gap = Close[highest_idx] - Close[lowest_idx];
  double small_gap = Close[recent_high_idx] - Close[lowest_idx];
  if (gap > 1000 * Point &&
      Close[recent_high_idx] - Close[lowest_idx] > gap / 3 &&
      Close[recent_high_idx] - Close[lowest_idx] < 2 * gap / 3 &&
      Close[0] - Close[lowest_idx] < 2 * small_gap / 3) {
    stop_loss = Close[recent_high_idx] + small_gap / 2;
    take_profit = Close[lowest_idx];
    return true;
  }
  return false;
}

bool ShouldExit() {
  OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
  return false;
}
