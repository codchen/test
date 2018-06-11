#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Custom/EntryScore.mqh>

input int seed = 17;

int count = 0;
double total = 0;

int signal;
double s_l;
double entry;
int last_bar = 0;

int OnInit()
  {
  	Print(MarketInfo(NULL, MODE_MINLOT));
  	Print(MarketInfo(NULL, MODE_LOTSTEP));
  	MathSrand(seed);
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

	SetSignalTenDaysAgo();

	if (signal != 0) {
		count++;
		double score = EntryScore_TenDays(entry, s_l, signal > 0);
		total += score;
	}

	if (Bars % 100 == 0 && count > 0) {
		double avg = total / count;
		Print("Average score so far is: " + avg);
	}
	last_bar = Bars;
}

// void SetSignalTenDaysAgo() {
// 	if (Close[12] < iMA(NULL, PERIOD_D1, 150, 0, MODE_SMMA, PRICE_CLOSE, 12) &&
// 		Close[11] > iMA(NULL, PERIOD_D1, 150, 0, MODE_SMMA, PRICE_CLOSE, 11)) {
// 	    entry = Open[10];
// 	    s_l = entry - 0.01;
// 	    signal = 1;
// 	} else if (Close[12] > iMA(NULL, PERIOD_D1, 150, 0, MODE_SMMA, PRICE_CLOSE, 12) &&
// 		Close[11] < iMA(NULL, PERIOD_D1, 150, 0, MODE_SMMA, PRICE_CLOSE, 11)) {
// 	    entry = Open[10];
// 	    s_l = entry + 0.01;
// 	    signal = -1;
// 	} else {
// 		signal = 0;
// 	}
// }

void SetSignalTenDaysAgo() {
	// if both MA crossover and ADX crossover
	if (Close[11] > iMA(NULL, PERIOD_D1, 9, 0, MODE_SMA, PRICE_CLOSE, 11) &&
		iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_PLUSDI, 11) > iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_MINUSDI, 11) &&
		!(Close[12] > iMA(NULL, PERIOD_D1, 9, 0, MODE_SMA, PRICE_CLOSE, 12) &&
			iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_PLUSDI, 12) > iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_MINUSDI, 12))) {
		entry = Open[10];
	    s_l = entry - 0.01;
	    signal = 1;
	} else if (Close[11] < iMA(NULL, PERIOD_D1, 9, 0, MODE_SMA, PRICE_CLOSE, 11) &&
		iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_PLUSDI, 11) < iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_MINUSDI, 11) &&
		!(Close[12] < iMA(NULL, PERIOD_D1, 9, 0, MODE_SMA, PRICE_CLOSE, 12) &&
			iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_PLUSDI, 12) < iADX(NULL, PERIOD_D1, 14, PRICE_CLOSE, MODE_MINUSDI, 12))) {
		entry = Open[10];
	    s_l = entry + 0.01;
	    signal = -1;
	} else {
		signal = 0;
	}
}