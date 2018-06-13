#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int last_bar = 0;
int last_initiated_bar = 0;
double sl = 0;
double tp = 0;
double stop_and_reverse_sl = 0;
double stop_and_reverse_tp = 0;

int status = 0;
int last_occurrence = 0;

int OnInit() {
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
	if (OrdersTotal() == 0 && low_volatility() && last_bar != last_initiated_bar) {
		int condition = meet_condition();
		if (condition != -1) {
			if (Ask >= High[2 + condition] + delta() * Point) {
				sl = Low[2 + condition] - delta() * Point;
				stop_and_reverse_sl = High[2 + condition] + delta() * Point;
				double risk = Ask - sl;

				if (risk <= 1500 * Point) {
					tp = Ask + 2 * risk;
					OrderSend(NULL, OP_BUY, 0.0015 / risk, Ask, 5, 0.0001, 10, "Long 1", 0, 0, Purple);
					last_initiated_bar = last_bar;
				}
			}

			if (Bid <= Low[2 + condition] - delta() * Point) {
				sl = High[2 + condition] + delta() * Point;
				stop_and_reverse_sl = Low[2 + condition] - delta() * Point;
				double risk = sl - Bid;

				if (risk <= 1500 * Point) {
					tp = Bid - 2 * risk;
					OrderSend(NULL, OP_SELL, 0.0015 / risk, Bid, 5, 10, 0.0001, "Short 1", 0, 0, Purple);
					last_initiated_bar = last_bar;
				}
			}
		}
	} else {
		OrderSelect(0, SELECT_BY_POS);

		if (OrderLots() >= 0.1) {
			if (OrderMagicNumber() == 0) {
				if (OrderType() == OP_BUY) {
					if (Bid <= sl) {
						stop_and_reverse_tp = Bid - (OrderOpenPrice() - Bid) * 2;
						double old_lots = OrderLots();
						OrderClose(OrderTicket(), old_lots, Bid, 5, Green);
						OrderSend(NULL, OP_SELL, old_lots, Bid, 5, stop_and_reverse_sl, 0.0001, "Short 2", 1, 0, Red);
					} else if (Bid >= tp) {
						OrderClose(OrderTicket(), OrderLots() / 2, Bid, 5, Yellow);
						OrderSelect(0, SELECT_BY_POS);
						OrderModify(OrderTicket(), OrderOpenPrice(), MathMax(OrderOpenPrice(), MathMin(Low[1], Low[2])), 10, 0, Orange);
					}
				} else {
					if (Ask >= sl) {
						stop_and_reverse_tp = Ask + (Ask - OrderOpenPrice()) * 2;
						double old_lots = OrderLots();
						OrderClose(OrderTicket(), old_lots, Ask, 5, Green);
						OrderSend(NULL, OP_BUY, old_lots, Ask, 5, stop_and_reverse_sl, 10, "Long 2", 1, 0, Red);
					} else if (Ask <= tp) {
						OrderClose(OrderTicket(), OrderLots() / 2, Ask, 5, Yellow);
						OrderSelect(0, SELECT_BY_POS);
						OrderModify(OrderTicket(), OrderOpenPrice(), MathMin(OrderOpenPrice(), MathMax(High[1], High[2])), 0.0001, 0, Orange);
					}
				}
			} else {
				if (OrderType() == OP_BUY) {
					if (Bid >= stop_and_reverse_tp) {
						OrderClose(OrderTicket(), OrderLots() / 2, Bid, 5, Yellow);
						OrderSelect(0, SELECT_BY_POS);
						OrderModify(OrderTicket(), OrderOpenPrice(), MathMax(OrderOpenPrice(), MathMin(Low[1], Low[2])), 10, 0, Orange);
					}
				} else {
					if (Ask <= stop_and_reverse_tp) {
						OrderClose(OrderTicket(), OrderLots() / 2, Ask, 5, Yellow);
						OrderSelect(0, SELECT_BY_POS);
						OrderModify(OrderTicket(), OrderOpenPrice(), MathMin(OrderOpenPrice(), MathMax(High[1], High[2])), 0.0001, 0, Orange);
					}
				}
			}
		} else {
			if (OrderType() == OP_BUY) {
				OrderModify(OrderTicket(), OrderOpenPrice(), MathMax(OrderStopLoss(), MathMin(Low[1], Low[2])), 10, 0, Orange);
			} else {
				OrderModify(OrderTicket(), OrderOpenPrice(), MathMin(OrderStopLoss(), MathMax(High[1], High[2])), 0.0001, 0, Orange);
			}
		}
	}

	last_bar = Bars;
}

double delta() {
	return 100;
	// return iATR(NULL, PERIOD_D1, 14, 1) / Point;
}

bool low_volatility() {
	return iATR(NULL, PERIOD_D1, 14, 1) < 0.01 / current_mid_price();
}

int meet_condition() {
	for (int i = 0; i < 2; i++) {
		bool has_inside_bar_sequence = High[1 + i] - Low[i + 1] < 0.05 &&
			High[2 + i] > High[1 + i] && High[3 + i] > High[2 + i] &&
			Low[2 + i] < Low[1 + i] && Low[3 + i] < Low[2 + i];
		if (has_inside_bar_sequence) return i;
	}

	return -1;
}

double sma200() {
	return iMA(NULL, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 1);
}

double current_mid_price() {
	return (Ask + Bid) / 2;
}
