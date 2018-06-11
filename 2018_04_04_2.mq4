//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int TakeProfit = 1000;
input int StopLoss = 200;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;
double last_ssma_5 = 0;
double last_ssma_150 = 0;
double current_ssma_5, current_ssma_150;

int cnt = 0;

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
  if (Bars == last_bar || Bars < 200) return;

  SetMAs();

  if (OrdersTotal() == 0) {
    int enter_signal = ShouldEnter();
    if (enter_signal > 0) {
      OrderSend(Symbol(), OP_BUY, 0.1, Ask, 5, Ask - StopLoss * Point, Ask + TakeProfit * Point, "", MAGICNUM, 0, Blue);
    } else if (enter_signal < 0) {
      OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, Bid + StopLoss * Point, Bid - TakeProfit * Point, "", MAGICNUM, 0, Blue);
    }
  } else {
    if (ShouldExit()) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
      else if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet);
    }
  }

  SetCnt();

  last_ssma_5 = current_ssma_5;
  last_ssma_150 = current_ssma_150;

  last_bar = Bars;
}
//+------------------------------------------------------------------+
void SetMAs() {
  current_ssma_5 = iMA(NULL, tf, 10, 0, MODE_SMMA, PRICE_CLOSE, 0);
  current_ssma_150 = iMA(NULL, tf, 150, 0, MODE_SMMA, PRICE_CLOSE, 0);
}

void SetCnt() {
  if (current_ssma_150 < current_ssma_5) {
    if (cnt < 0) cnt = 1;
    else cnt++;
  }
  if (current_ssma_150 > current_ssma_5) {
    if (cnt > 0) cnt = -1;
    else cnt--;
  }
}

int ShouldEnter() {
  if (last_ssma_150 > last_ssma_5 && current_ssma_150 < current_ssma_5) return 1;
  if (last_ssma_150 < last_ssma_5 && current_ssma_150 > current_ssma_5) return -1;
  return 0;
}

bool ShouldExit() {
  OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

  return false;
}
