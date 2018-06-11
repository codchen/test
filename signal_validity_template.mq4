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
input string Filename = "test";
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
      trade_price = Close[TradeWindow];
      would_be_profit = (high_in_window - trade_price) / Point;
      would_be_loss = (trade_price - low_in_window) / Point;
      FileWrite(TimeGMT(), fd, signal, description, would_be_profit, would_be_loss);
    }
  }
  
void SetSignalInPast()
  {
    int shift = TradeWindow;
    
    if (Bars % 10000 == 0) {
      signal = 1;
      description = "test";
    } else {
      signal = 0;
    }
  }
  
void SetExtremesInWindow()
  {
    high_in_window = iHigh(NULL, tf, iHighest(NULL, tf, MODE_HIGH, TradeWindow, 0));
    low_in_window = iLow(NULL, tf, iLowest(NULL, tf, MODE_LOW, TradeWindow, 0));
  }