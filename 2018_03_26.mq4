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
input int TakeProfit = 100;
input int StopLoss = 300;

input int MAPeriod = 14;
input int HorizontalSRPeriod = 200;
input double SRDistanceThreshold = 0.1;

input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
int rsi_signal, ac_signal, total;
double enter_signal, exit_signal, order_size, stop_loss, take_profit;
int MAGICNUM = 42;

int ma_above_minus_below; // in the past MAPeriod days, the number of close above MA - the number of close below MA
double resistance, support, sr_distance;
double resistance_distance, support_distance;
int price_action; // 1: pin bar, 2: same length, 3: star; negative for bearish counterpart
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
    
    SetPriceAction();
    SetMAAboveMinusBelow();
    SetSupportAndResistance();
    SetDistances();
//---
    total = OrdersTotal();
    if (total == 0) {
      SetEnterSignal();
      SetOrderSize();

      if (enter_signal > 0) {
        ticket = OrderSend(Symbol(), OP_BUY, order_size, Ask, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", stop_loss, " TP: ", take_profit, " Size: ", order_size);
          } else {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError(), " with size ", order_size);
          Print("Market stop level: ",  MarketInfo("EURUSD", MODE_STOPLEVEL), " but S/L is set as ", StopLoss*Point);
        }
      } else if (enter_signal < 0) {
        ticket = OrderSend(Symbol(), OP_SELL, order_size, Bid, 5, stop_loss, take_profit, "", MAGICNUM, 0, Blue);
        if (ticket > 0) {
          if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", stop_loss, " TP: ", take_profit, " Size: ", order_size);
          } else {
            Print("Error selecting opened order: ", ticket, " with ", GetLastError());
          }
        } else {
          Print("Cannot open ticket: ", GetLastError(), " with size ", order_size);
          Print("Market stop level: ",  MarketInfo("EURUSD", MODE_STOPLEVEL), " but S/L is set as ", StopLoss*Point);
        }
      }
    } else {
      if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
        SetExitSignal();
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
void SetPriceAction()
   {
     if (Bars < HorizontalSRPeriod + 5 || High[2] == Low[2] || High[1] == Low[1]) {
       price_action = 0;
     }
     else if ((High[2] - MathMax(Close[2], Open[2])) / (High[2] - Low[2]) > 0.75 &&
         Open[1] > Close[1] && Close[1] < Low[2]) {
       price_action = -1;
     } else if (Close[2] > Open[2] && (Close[2] - Open[2]) / (High[2] - Low[2]) > 0.75 &&
         Open[1] > Close[1] && (Open[1] - Close[1]) / (High[1] - Low[1]) > 0.75 &&
         MathAbs(Close[1] - Open[2]) < 20 * Point && MathAbs(Open[1] - Close[2]) > 20 * Point) {
       price_action = -2;
     } else if (Close[3] > Open[3] && MathMin(Open[2], Close[2]) > MathMax(Close[3], Open[1]) && Open[1] > Close[1] &&
         MathAbs(Close[2] - Open[2]) / (High[2] - Low[2]) < 0.1) {
       price_action = -3;    
     } else if ((MathMin(Close[2], Open[2]) - Low[2]) / (High[2] - Low[2]) > 0.75 &&
         Open[1] < Close[1] && Close[1] > High[2]) {
       price_action = 1;    
     } else if (Close[2] < Open[2] && (Open[2] - Close[2]) / (High[2] - Low[2]) > 0.75 &&
         Open[1] < Close[1] && (Close[1] - Open[1]) / (High[1] - Low[1]) > 0.75 &&
         MathAbs(Close[1] - Open[2]) < 20 * Point && MathAbs(Open[1] - Close[2]) > 20 * Point) {
       price_action = 2;    
     } else if (Close[3] < Open[3] && MathMax(Open[2], Close[2]) < MathMin(Close[3], Open[1]) && Open[1] < Close[1] &&
         MathAbs(Close[2] - Open[2]) / (High[2] - Low[2]) < 0.1) {
       price_action = 3;    
     } else {
       price_action = 0;
     }
   }

void SetMAAboveMinusBelow()
   {
     double ma_value;
     ma_above_minus_below = 0;
     for (int i = 0; i < MAPeriod; i++) {
       ma_value = iMA(NULL, tf, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, i + 1);
       if (ma_value < Close[i + 1]) ma_above_minus_below++;
       else ma_above_minus_below--;
     }
   }
   
void SetSupportAndResistance()
   {
     int r_idx, s_idx;
     r_idx = iHighest(NULL, tf, MODE_HIGH, HorizontalSRPeriod, 1);
     s_idx = iLowest(NULL, tf, MODE_LOW, HorizontalSRPeriod, 1);
     if (r_idx != -1) resistance = High[r_idx];
     if (s_idx != -1) support = Low[s_idx];
     sr_distance = resistance - support;
     if (Bars % 1000 == 0) Print(resistance, support);
   }
   
void SetDistances()
   {
     resistance_distance = resistance - Bid;
     support_distance = Ask - support;
   }
  
void SetEnterSignal()
   {
     double last_ma = iMA(NULL, tf, MAPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
     if (Close[1] > last_ma &&
         ma_above_minus_below < -MAPeriod / 2 &&
         MathAbs(support_distance) < SRDistanceThreshold * sr_distance &&
         price_action > 0) {
       enter_signal = 0.1;
       stop_loss = support - StopLoss * Point;
       take_profit = resistance - TakeProfit * Point;
     } else if (Close[1] < last_ma &&
                ma_above_minus_below > MAPeriod / 2 &&
                MathAbs(resistance_distance) < SRDistanceThreshold * sr_distance &&
                price_action < 0) {
       enter_signal = -0.1;
       stop_loss = resistance + StopLoss * Point;
       take_profit = support + TakeProfit * Point;
     } else {
       enter_signal = 0.0;
       stop_loss = 0.0;
       take_profit = 0.0;
     }
   }
   
void SetOrderSize()
   {
     order_size = MathAbs(enter_signal);
   }
   
void SetExitSignal()
   {
     if (MathAbs(support_distance) < SRDistanceThreshold * sr_distance) {
       exit_signal = -1;
     } else if (MathAbs(resistance_distance) < SRDistanceThreshold * sr_distance) {
       exit_signal = 1;
     } else {
       exit_signal = 0;
     }
   } 