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

int pivots[10];
int pivot_num = 0;
int pivot_num_when_buy;
int pivots_when_buy[10];

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

  SetPivots();

  if (OrdersTotal() == 0) {
    if (ShouldEnterSell()) {
      OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
    }
  } else {
    UpdatePivotsWhenBuy();
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
  if (pivot_num != 3) return false; // no setup
  if (Close[pivots[0]] <= iMA(NULL, tf, 50, 0, MODE_SMMA, PRICE_CLOSE, pivots[0])) return false; // no prior trend
  if (Close[pivots[0]] - Close[pivots[1]] < 1000 * Point) return false; // current trend too weak
  if ((Close[pivots[2]] - Close[pivots[1]]) / (Close[pivots[0]] - Close[pivots[1]]) < 0.3) return false; // retrace too weak
  if ((Close[pivots[2]] - Close[pivots[1]]) / (Close[pivots[0]] - Close[pivots[1]]) > 0.7) return false; // retrace too strong
  if (1.0 * (pivots[1] - pivots[2]) / (pivots[0] - pivots[2]) < 0.4) return false; // retrace too steep
  if (1.0 * (pivots[1] - pivots[2]) / (pivots[0] - pivots[2]) > 0.6) return false; // retrace too flat

  stop_loss = Close[pivots[0]];
  take_profit = Close[pivots[1]];
  pivot_num_when_buy = pivot_num;
  for (int i = 0; i < pivot_num; i++) pivots_when_buy[i] = pivots[i];
  return true;
}

bool ShouldExit() {
  OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

  if (pivot_num == 0) return true;
  if (pivot_num == 1) return false;

  if (pivot_num % 2 == 0 && Ask > Close[pivots_when_buy[2]]) return true;
  if (pivot_num % 2 == 1 && Close[pivots[pivot_num - 2]] > Close[pivots_when_buy[1]]) return true;

  return false;
}

void UpdatePivotsWhenBuy() {
  for (int i = 0; i < pivot_num; i++) pivots_when_buy[i]++;
}

void SetPivots() {
  pivot_num = 0;
  for (int i = 0; i < 10; i++) pivots[i] = 0;

  int pivot;
  int left_bound = 150;

  for (int iter = 0; iter < 10; iter++) {
    pivot = 0;
    for (int i = 0; i < left_bound; i++) {
      if (pivot_num % 2 == 0 && Close[i] > Close[pivot]) pivot = i;
      if (pivot_num % 2 == 1 && Close[i] < Close[pivot]) pivot = i;
    }
    if (pivot < 10) return;
    pivots[pivot_num] = pivot;
    pivot_num++;
    left_bound = pivot;
  }
}
