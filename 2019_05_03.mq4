#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Custom/TradeStrategy.mqh>
#include <Custom/EntryStrategy.mqh>
#include <Custom/ExitStrategy.mqh>
#include <Custom/TrailingStopStrategy.mqh>

int last_bar = 0;

// TODO: get percentage of 'correct' prediction
int OnInit() {
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
	AdjustStopLossAndTakeProfit();

	if (Bars == last_bar) return;

	entry_info entry = GetEntrySignal();

	Trade(entry.signal, entry.stop_loss, entry.take_profit);

	CloseTradesIfNeeded();

	RealizedR();

	if (Bars % 100 == 0) {
		Print("realized r: " + realized_r[0] + ", " + realized_r[1] + ", " + realized_r[2] + ", " + realized_r[3] + ", " + realized_r[4] + ", " + realized_r[5] + ", ");
	}

	last_bar = Bars;
}
