#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int last_bar = 0;
int pending_status = 0;

int OnInit() {
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
	if (last_bar != Bars) {
		pending_status = 0;
	}

	if (OrdersTotal() == 0) {
		if (pending_status != 0) {
			if (Ask >= High[1] + 150 * Point && pending_status == 1) {
				OrderSend(NULL, OP_BUY, 0.1, Ask, 5, Ask - 300 * Point, Ask + 600 * Point, "", 0, 0, Red);
			} else if (Bid <= Low[1] - 150 * Point && pending_status == -1) {
				OrderSend(NULL, OP_SELL, 0.1, Bid, 5, Bid + 300 * Point, Bid - 600 * Point, "", 0, 0, Red);
			}
		} else if (adx(3) < 35 && adx(2) < adx(3) && adx(1) < adx(2)) {
			if (Ask <= Low[1] - 150 * Point) {
				pending_status = 1;
			} else if (Bid >= High[1] + 150 * Point) {
				pending_status = -1;
			}
		}
	}

	last_bar = Bars;
}

double adx(int shift) {
	return iADX(NULL, PERIOD_H1, 14, PRICE_CLOSE, MODE_MAIN, shift);
}
