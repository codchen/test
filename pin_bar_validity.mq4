//+------------------------------------------------------------------+
//|                                     signal_validity_template.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
input int TradeWindow = 400;
input int SignalPrecedingWindow = 200;
input string Filename = "pin_bar";
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int signal;
string description;
int fd;
double trade_price, high_in_window, low_in_window, would_be_profit, would_be_loss;
int last_bar;

// file repo: C:\Users\codch\AppData\Roaming\MetaQuotes\Terminal\3212703ED955F10C7534BE8497B221F4\tester\files

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ResetLastError();
   fd = FileOpen(Filename + ".csv", FILE_WRITE|FILE_CSV);
   if (fd == INVALID_HANDLE) {
     Print("File opening failed");
   }

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
   FileClose(fd);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if (Bars == last_bar) return;
    
    WriteToFile();
    
    last_bar = Bars;
  }
//+------------------------------------------------------------------+
void WriteToFile()
  {
    if (Bars < TradeWindow + SignalPrecedingWindow) return;
    
    SetSignalInPast();
    
    if (signal != 0) {
      SetExtremesInWindow();
      trade_price = iClose(NULL, tf, TradeWindow);
      if (signal > 0) {
        would_be_profit = (high_in_window - trade_price) / Point;
        would_be_loss = (trade_price - low_in_window) / Point;
      } else {
        would_be_profit = (trade_price - low_in_window) / Point;
        would_be_loss = (high_in_window - trade_price) / Point;
      }
      string time = "" + TimeLocal();
      FileWrite(fd, signal, time, would_be_profit, would_be_loss);
    }
  }
  
void SetSignalInPast()
  {
    int shift = TradeWindow;
    double dayOneHigh = iHigh(NULL, tf, 2 + TradeWindow);
    double dayOneLow = iLow(NULL, tf, 2 + TradeWindow);
    double dayOneOpen = iOpen(NULL, tf, 2 + TradeWindow);
    double dayOneClose = iClose(NULL, tf, 2 + TradeWindow);
    double dayTwoOpen = iOpen(NULL, tf, 1 + TradeWindow);
    double dayTwoClose = iClose(NULL, tf, 1 + TradeWindow);
    
    if (dayOneHigh - dayOneLow == 0) {
      signal = 0;
    } else if ((dayOneHigh - MathMax(dayOneClose, dayOneOpen)) / (dayOneHigh - dayOneLow) > 0.75 &&
        dayTwoOpen > dayTwoClose && dayTwoClose < dayOneLow) {
      signal = -1;
      description = "Bearish Pin Bar";
    } else if ((MathMin(dayOneClose, dayOneOpen) - dayOneLow) / (dayOneHigh - dayOneLow) > 0.75 &&
        dayTwoOpen < dayTwoClose && dayTwoClose > dayOneHigh) {
      signal = 1;
      description = "Bullish Pin Bar";
    } else {
      signal = 0;
    }
  }
  
void SetExtremesInWindow()
  {
    high_in_window = iHigh(NULL, tf, iHighest(NULL, tf, MODE_HIGH, TradeWindow, 0));
    low_in_window = iLow(NULL, tf, iLowest(NULL, tf, MODE_LOW, TradeWindow, 0));
  }