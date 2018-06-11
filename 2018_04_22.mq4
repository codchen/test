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

int last_tentative_high = -1;
int last_tentative_low = -1;
int current_tentative_high = -1;
int current_tentative_low = -1;

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
	int smallest_idx = 1;
	for (int i = 1; i < 100; i++) {
		if (Low[i] < Low[smallest_idx]) smallest_idx = i;
	}
	if (Low[smallest_idx] >= Ask) return -1;
	else return Low[smallest_idx];
}

// TODO
double Resistance() {
	int largest_idx = 1;
	for (int i = 1; i < 100; i++) {
		if (High[i] < High[largest_idx]) largest_idx = i;
	}
	if (High[largest_idx] <= Bid) return -1;
	else return High[largest_idx];
}

// TODO
bool ShouldEnterLong() {
	return Close[1] - Baseline(1) > Threshold();
}

// TODO
bool ShouldEnterShort() {
	return Baseline(1) - Close[1] > Threshold();
}

double Baseline(int shift) {
	return iMA(NULL, tf, 150, 0, MODE_SMMA, PRICE_CLOSE, shift);
}

double Threshold() {
	return iATR(NULL, tf, 14, 1);
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
	if (ticket_num > 5) ticket_num = 2;
	ArrayResize(tickets, ticket_num);
	for (int i = 0; i < ticket_num; i++) {
		tickets[i] = OrderSend(Symbol(), OP_BUY, trade_size / ticket_num, Ask, 5, s_l, t_f, "", 0, 0, Blue);
	}
}

void EnterShort() {
	double resistance = Resistance();
	if (resistance < 0) return;
	double support = Support();
	r = resistance - Bid;
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
	if (ticket_num > 5) ticket_num = 2;
	ArrayResize(tickets, ticket_num);
	for (int i = 0; i < ticket_num; i++) {
		tickets[i] = OrderSend(Symbol(), OP_SELL, trade_size / ticket_num, Bid, 5, s_l, t_f, "", 0, 0, Blue);
	}
}

void AdjusLongPositionIfNecessary() {
	for (int i = 0; i < ticket_num - 1; i++) {
		OrderSelect(tickets[i], SELECT_BY_TICKET, MODE_TRADES);
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

void AdjustShortPositionIfNecessary() {
	for (int i = 0; i < ticket_num - 1; i++) {
		OrderSelect(tickets[i], SELECT_BY_TICKET, MODE_TRADES);
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