#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar = 0;
double r;
double exit_rate;
int tickets[];
int ticket_num;

int OnInit() {
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
  if (Bars == last_bar) return;

  Trade();

  last_bar = Bars;
}

// TODO
double Support() {
	return 100.0;
}

// TODO
double Resistance() {
	return 100.0;
}


// TODO
bool ShouldEnterLong() {
	return true;
}

// TODO
bool ShouldEnterShort() {
	return true;
}

double TradeSize() {
	return 0.1;
}

void EnterLong() {
	double support = Support();
	if (support < 0) return;
	double resistance = Resistance();
	r = Ask - support;
	double s_l = support;
	double t_f;
	double trade_size = TradeSize();
	if (resistance < 0) {
		t_f = Ask + 10000 * Point;
		ticket_num = 2;
	} else {
		t_f = resistance;
		ticket_num = MathCeil((t_f - Ask) / r);
	}
	if (ticket_num < 2) return;
	ArrayResize(tickets, ticket_num);
	for (int i = 0; i < ticket_num; i++) {
		tickets[i] = OrderSend(Symbol(), OP_BUY, trade_size / ticket_num, Ask, 5, s_l, t_f, "", MAGICNUM, 0, Blue);
	}
}

void EnterShort() {
	double resistance = Resistance();
	if (resistance < 0) return;
	double support = Support();
	r = Resistance - Bid;
	double s_l = resistance;
	double t_f;
	double trade_size = TradeSize();
	if (support < 0) {
		t_f = Bid - 10000 * Point;
		ticket_num = 2;
	} else {
		t_f = support;
		ticket_num = MathCeil((Bid - t_f) / r);
	}
	if (ticket_num < 2) return;
	ArrayResize(tickets, ticket_num);
	for (int i = 0; i < ticket_num; i++) {
		tickets[i] = OrderSend(Symbol(), OP_SELL, trade_size / ticket_num, Bid, 5, s_l, t_f, "", MAGICNUM, 0, Blue);
	}
}

void AdjusLongPositionIfNecessary() {
	for (int i = 0; i < ticket_num - 1; i++) {
		OrderSelect(tickets[i], SELECT_BY_POS, MODE_TRADES);
		if (OrderCloseTime() == 0) {
			if (Bid > 2 * r + OrderStopLoss()) {
				OrderClose(tickets[i], OrderLots(), Bid, 5, Purple);
			}
			break;
		}
	}

	if (Bid > 2.5 * r + OrderStopLoss()) {
		for (int i = 0; i < ticket_num; i++) {
			if (OrderCloseTime() == 0) {
				OrderModify(tickets[i], OrderOpenPrice(), OrderStopLoss() + r, OrderTakeProfit(), OrderExpiration(), Red);
			}
		}
	}
}

void AdjusShortPositionIfNecessary() {
	for (int i = 0; i < ticket_num - 1; i++) {
		OrderSelect(tickets[i], SELECT_BY_POS, MODE_TRADES);
		if (OrderCloseTime() == 0) {
			if (Ask < OrderStopLoss() - 2 * r) {
				OrderClose(tickets[i], OrderLots(), Ask, 5, Purple);
			}
			break;
		}
	}

	if (Ask < OrderStopLoss() - 2.5 * r) {
		for (int i = 0; i < ticket_num; i++) {
			if (OrderCloseTime() == 0) {
				OrderModify(tickets[i], OrderOpenPrice(), OrderStopLoss() - r, OrderTakeProfit(), OrderExpiration(), Red);
			}
		}
	}
}

void Trade() {
	if (OrdersTotal() == 0) {
		if (ShouldEnterLong()) EnterLong();
		else if (ShouldEnterShort()) EnterShort();
	} else {
		OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
		if (OrderType() == OP_BUY) AdjusLongPositionIfNecessary();
		else if (OrderType() == OP_SELL) AdjustShortPositionIfNecessary();
	}
}