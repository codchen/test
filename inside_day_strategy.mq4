#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int last_bar = 0;
int last_initiated_bar = 0;
double sl = 0;
double stop_and_reverse_sl = 0;

int OnInit() {
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
	if (OrdersTotal() == 0 && low_volatility()) {
		int condition = meet_condition();
		if (condition != -1 && last_initiated_bar != last_bar - conditon) {
			if (Ask >= High[1 + condition] + delta() * Point) {
				sl = Low[1 + condition] - delta() * Point;
				stop_and_reverse_sl = High[1 + condition] + delta() * Point;
				double risk = Ask + delta() * Point - Low[1 + condition];

				if (risk <= 1000 * Point) {
					double tp = Ask + 2 * risk;
					OrderSend(NULL, OP_BUY, 0.1, Ask, 5, 0.0001, tp, "Long 1", 0, 0, Purple);

					last_initiated_bar = last_bar;
				}
			}

			if (Bid <= Low[1 + condition] - delta() * Point) {
				sl = High[1 + condition] + delta() * Point;
				stop_and_reverse_sl = Low[1 + condition] - delta() * Point;
				double risk = High[1 + condition] + delta() * Point - Bid;

				if (risk <= 1000 * Point) {
					double tp = Bid - 2 * risk;
					OrderSend(NULL, OP_SELL, 0.1, Bid, 5, 10, tp, "Short 1", 0, 0, Purple);

					last_initiated_bar = last_bar;
				}
			}
		}
	} else {
		OrderSelect(0, SELECT_BY_POS);

		if (OrderMagicNumber() == 0) {
			if (OrderType() == OP_BUY) {
				if (Bid <= sl) {
					double tp = Bid - (OrderOpenPrice() - Bid) * 2; 
					OrderClose(OrderTicket(), OrderLots(), Bid, 5, Green);
					OrderSend(NULL, OP_SELL, 0.1, Bid, 5, stop_and_reverse_sl, tp, "Short 2", 1, 0, Red);
				}
			} else {
				if (Ask >= sl) {
					double tp = Ask + (Ask - OrderOpenPrice()) * 2; 
					OrderClose(OrderTicket(), OrderLots(), Ask, 5, Green);
					OrderSend(NULL, OP_BUY, 0.1, Ask, 5, stop_and_reverse_sl, tp, "Long 2", 1, 0, Red);
				}
			}
		}
	}

	last_bar = Bars;
}

double delta() {
	return 100;
}

bool low_volatility() {
	return iATR(NULL, PERIOD_D1, 14, 1) < 0.02 / (Ask + Bid);
}

int meet_condition() {
	for (int i = 0; i < 5; i++) {
		bool has_inside_bar_sequence = High[1 + i] - Low[i + 1] < 0.05 &&
			High[2 + i] > High[1 + i] && High[3 + i] > High[2 + i] &&
			Low[2 + i] < Low[1 + i] && Low[3 + i] < Low[2 + i];
		if (has_inside_bar_sequence) return i;
	}

	return -1;
}
