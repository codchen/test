//+------------------------------------------------------------------+
//|                                                   2018_03_25.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input int TakeProfit = 500;
input int StopLoss = 300;
input double Lots = 0.1;
input int RSIPeriod = 14;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
int rsi_signal, ac_signal, total;
double enter_signal, exit_signal, order_size;
int MAGICNUM = 42;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
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
    int ticket = 0;
    
    SetRSISignal();
    SetACSignal();
//---
    total = OrdersTotal();
    if (total == 0) {
      SetEnterSignal();
      SetOrderSize();

      if (enter_signal > 0) {
        ticket = OrderSend(Symbol(), OP_BUY, order_size, Ask, 5, Ask - StopLoss*Point, Ask + TakeProfit*Point, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", Ask - StopLoss*Point, " TP: ", Ask + TakeProfit*Point, " Size: ", order_size);
          } else {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError(), " with size ", order_size);
          Print("Market stop level: ",  MarketInfo("EURUSD", MODE_STOPLEVEL), " but S/L is set as ", StopLoss*Point);
        }
      } else if (enter_signal < 0) {
        ticket = OrderSend(Symbol(), OP_SELL, order_size, Bid, 5, Bid + StopLoss*Point, Bid - TakeProfit*Point, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", Bid + StopLoss*Point, " TP: ", Bid - TakeProfit*Point, " Size: ", order_size);
          } else {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError(), " with size ", order_size);
          Print("Market stop level: ",  MarketInfo("EURUSD", MODE_STOPLEVEL), " but S/L is set as ", StopLoss*Point);
        }
      }
    } else {
      SetExitSignal();
      
      if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
        if (OrderType() == OP_BUY && exit_signal > 0) {
          if (OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet)) {
            Print("Successfully closed opened ticket: ", OrderTicket());
          } else {
            Print("Error closing ticket ", OrderTicket(), " with ", GetLastError());
          }
        } else if (OrderType() == OP_SELL && exit_signal < 0) {
          if (OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet)) {
            Print("Successfully closed opened ticket: ", OrderTicket());
          } else {
            Print("Error closing ticket ", OrderTicket(), " with ", GetLastError());
          }
        }
      } else {
        Print("Error seleting order to be exited: ", GetLastError());
      }
    }
  }
//+------------------------------------------------------------------+
void SetRSISignal()
   {
      double rsi = iRSI(Symbol(),tf,RSIPeriod,PRICE_CLOSE,0);
      double prev_rsi = iRSI(Symbol(),tf,RSIPeriod,PRICE_CLOSE,1);
      if (prev_rsi < rsi) {
        if (rsi > 90.0) rsi_signal = 4;
        else if (rsi > 80.0) rsi_signal = 3;
        else if (rsi > 70.0) rsi_signal = 2;
        else if (rsi > 60.0) rsi_signal = 1;
        else rsi_signal = 0;
      } else {
        if (rsi < 40.0) rsi_signal = -1;
        else if (rsi < 30.0) rsi_signal = -2;
        else if (rsi < 20.0) rsi_signal = -3;
        else if (rsi < 10.0) rsi_signal = -4;
        else rsi_signal = 0;
      }
   }
   
void SetACSignal()
   {
      double acs[5];
      for (int i = 0; i < 5; i++) acs[i] = iAC(Symbol(),tf,i);
      if (acs[0] < 0 && acs[0] > acs[1] && acs[1] > acs[2] && acs[2] < acs[3] && acs[3] < acs[4]) {
        ac_signal = 1;
      } else if (acs[0] > 0 && acs[0] < acs[1] && acs[1] < acs[2] && acs[2] > acs[3] && acs[3] > acs[4]) {
        ac_signal = -1;
      } else {
        ac_signal = 0;
      }
   }
  
void SetEnterSignal()
   {
     if (ac_signal == 1 && rsi_signal >= 2) {
       enter_signal = 0.1;
     } else if (ac_signal == -1 && rsi_signal <= -2) {
       enter_signal = -0.1;
     } else {
       enter_signal = 0.0;
     }
   }
   
void SetOrderSize()
   {
     order_size = MathAbs(enter_signal);
   }
   
void SetExitSignal()
   {
     exit_signal = 0;
   } 