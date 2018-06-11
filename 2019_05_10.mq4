#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Custom/TradeStrategy_v2.mqh>
#include <Custom/EntryStrategy_v2.mqh>
#include <Custom/ExitStrategy_v2.mqh>
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

	last_bar = Bars;
}
