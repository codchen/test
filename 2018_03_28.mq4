//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int ma_period = 14;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
int last_bar;
double stop_loss, take_profit;

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
void OnTick()
  {
    int ticket;
//---
    if (Bars < 10 || Bars == last_bar) return;
    
    SetSignal();

    int total = OrdersTotal();

    if (total == 0) {
      if (signal > 0) {
        ticket = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 5, Ask - 500 * Point, Ask + 500 * Point, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError());
        }
      } else if (signal < 0) {
        ticket = OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, Bid + 500 * Point, Bid - 500 * Point, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError());
        }
      }
    } else {
      if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
        if (OrderType() == OP_BUY && signal < 0) {
          if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet)) {
            Print("Error closing ticket ", OrderTicket(), " with ", GetLastError());
          }
        } else if (OrderType() == OP_SELL && signal > 0) {
          if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet)) {
            Print("Error closing ticket ", OrderTicket(), " with ", GetLastError());
          }
        }
      } else {
        Print("Error seleting order to be exited: ", GetLastError());
      }
    }
    
    last_bar = Bars;
  }
//+------------------------------------------------------------------+
  
void SetSignal()
  {
    double one_before = iMA(NULL, tf, ma_period, 0, MODE_SMMA, PRICE_CLOSE, 1);
    double two_before = iMA(NULL, tf, ma_period, 0, MODE_SMMA, PRICE_CLOSE, 2);
    double three_before = iMA(NULL, tf, ma_period, 0, MODE_SMMA, PRICE_CLOSE, 3);
    if (one_before > two_before && two_before < three_before) {
      signal = 1;
    } else if (one_before < two_before && two_before > three_before) {
      signal = -1;
    } else {
      signal = 0;
    }
  }
