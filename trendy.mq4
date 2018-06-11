#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar, last_signal;
int last_signals[5];
int signal;

int OnInit() {
	ArrayInitialize(last_signals, -1);
	Print(MarketInfo(NULL, MODE_LOTSIZE));
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
  if (Bars == last_bar) return;

  int spread = (int)MarketInfo("EURUSD",MODE_SPREAD);

  if (BullishTrend()) signal = 2;
  else if (BearishTrend()) signal = 0;
  else signal = 1;

  if (signal != last_signal) {
  	string name = "signal_" + Bars;
  	ObjectCreate(name, OBJ_VLINE, 0, iTime(NULL, tf, 1), 1);
  	switch (signal) {
  		case 0: {
  			ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);

  			if (OrdersTotal() == 0) {
  				OrderSend(NULL, OP_SELL, 0.1, Bid, 5, Bid + 0.03, Bid - 0.1, "", 0, 0, clrBlue);
  			}
  			break;
  		}
  		case 1: {
  			ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlue);

  			if (OrdersTotal() != 0) {
  				OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
  				if (OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
      			else if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet);
  			}
  			break;
  		}
  		case 2: {
  			ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);

  			if (OrdersTotal() == 0) {
  				OrderSend(NULL, OP_BUY, 0.1, Ask, 5, Ask - 0.03, Ask + 0.1, "", 0, 0, clrBlue);
  			}
  			break;
  		}
  	}
  }


  last_bar = Bars;
  last_signal = signal;
}

// base line: 150 SSMA

// breakout: price cross over/under base line, then pulls away; after ranging

// trend: gap of X pips between price and base line

// ranging: multiple crosses between price and base line within period Y

bool BullishTrend() {
	return Close[1] - Baseline(1) > iATR(NULL, tf, 14, 1);
}

bool BearishTrend() {
	return Baseline(1) - Close[1] > iATR(NULL, tf, 14, 1);
}

double Baseline(int shift) {
	return iMA(NULL, tf, 150, 0, MODE_SMMA, PRICE_CLOSE, shift);
}

void UpdateLastSignals() {
	for (int i = 4; i > 0; i--) {
		last_signals[i] = last_signals[i - 1];
	}
	last_signals[0] = signal;
}