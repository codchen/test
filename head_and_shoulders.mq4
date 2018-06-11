#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input int max_lookback = 100;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar;
int max_coverage_1, max_coverage_2;
int shoulder_1, shoulder_2;
int window_end;
int head;
int neck_1, neck_2;

int MAGICNUM = 42;

int OnInit() {
	last_bar = 0;
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
  if (Bars == last_bar) return;

  WindowEndInInterest();
  GetHead();
  GetFirstShoulder();
  GetSecondShoulder();
  GetFirstNeck();
  GetSecondNeck();

  if (HasPattern()) {
  	string name = "pattern_" + Bars;
  	ObjectCreate(name, OBJ_VLINE, 0, iTime(NULL, tf, 0), 0);

  	string name_1 = "shoulder_to_neck_" + Bars;
  	ObjectCreate(name_1, OBJ_TREND, 0, iTime(NULL, tf, shoulder_1), Close[shoulder_1], iTime(NULL, tf, neck_1), Close[neck_1]);
  	ObjectSetInteger(0, name_1, OBJPROP_RAY, 0);

  	string name_2 = "neck_to_head_" + Bars;
  	ObjectCreate(name_2, OBJ_TREND, 0, iTime(NULL, tf, neck_1), Close[neck_1], iTime(NULL, tf, head), Close[head]);
  	ObjectSetInteger(0, name_2, OBJPROP_RAY, 0);

  	string name_3 = "head_to_neck_" + Bars;
  	ObjectCreate(name_3, OBJ_TREND, 0, iTime(NULL, tf, head), Close[head], iTime(NULL, tf, neck_2), Close[neck_2]);
  	ObjectSetInteger(0, name_3, OBJPROP_RAY, 0);

  	string name_4 = "neck_to_shoulder" + Bars;
  	ObjectCreate(name_4, OBJ_TREND, 0, iTime(NULL, tf, neck_2), Close[neck_2], iTime(NULL, tf, shoulder_2), Close[shoulder_2]);
  	ObjectSetInteger(0, name_4, OBJPROP_RAY, 0);

  	string name_5 = "end_to_shoulder_" + Bars;
  	ObjectCreate(name_5, OBJ_TREND, 0, iTime(NULL, tf, window_end), Close[window_end], iTime(NULL, tf, shoulder_1), Close[shoulder_1]);
  	ObjectSetInteger(0, name_5, OBJPROP_RAY, 0);

  	string name_6 = "shoulder_to_start_" + Bars;
  	ObjectCreate(name_6, OBJ_TREND, 0, iTime(NULL, tf, shoulder_2), Close[shoulder_2], iTime(NULL, tf, 1), Close[1]);
  	ObjectSetInteger(0, name_6, OBJPROP_RAY, 0);

  	Print("Detected at ", TimeCurrent(), "; ", max_coverage_1, ", ", max_coverage_2, ", ", shoulder_1, ", ", shoulder_2);

  	// if (OrdersTotal() == 0) {
  	// 	OrderSend(Symbol(), OP_SELL, 0.1, Bid, 5, High[head], Bid - (High[head] - Low[neck_2]), "", MAGICNUM, 0, Blue);
  	// }
  }

  last_bar = Bars;
}

void WindowEndInInterest() {
	double last_close = Close[1];
	for (int i = 2; i < MathMin(Bars, max_lookback); i++) {
		if (Low[i] <= last_close) {
			window_end = i;
			return;
		}
	}
	window_end = MathMin(Bars, max_lookback);
}

void GetHead() {
	head = 1;
	for (int i = 1; i < window_end; i++) {
		if (Close[i] > Close[head]) head = i;
	}
}

void GetFirstShoulder() {
	max_coverage_1 = 0;
	shoulder_1 = window_end;
	for (int i = window_end; i > head; i--) {
		for (int j = 1; j <= MathMin(window_end - i, i - head); j++) {
			if (!(Close[i] > Close[i - j] && Close[i] > Close[i + j])) {
				if (j - 1 >= max_coverage_1) {
					max_coverage_1 = j - 1;
					shoulder_1 = i;
				}
				break;
			}
		}
	}
}

void GetSecondShoulder() {
	max_coverage_2 = 0;
	shoulder_2 = 1;
	for (int i = 1; i < head; i++) {
		for (int j = 1; j <= MathMin(i - 1, head - i); j++) {
			if (!(Close[i] > Close[i - j] && Close[i] > Close[i + j])) {
				if (j - 1 >= max_coverage_2) {
					max_coverage_2 = j - 1;
					shoulder_2 = i;
				}
				break;
			}
		}
	}
}

void GetFirstNeck() {
	neck_1 = shoulder_1;
	for (int i = shoulder_1; i > head; i--) {
		if (Close[i] < Close[neck_1]) neck_1 = i;
	}
}

void GetSecondNeck() {
	neck_2 = shoulder_2;
	for (int i = shoulder_2; i < head; i++) {
		if (Close[i] < Close[neck_2]) neck_2 = i;
	}
}

bool HasPattern() {
	// if (window_end < 50) return false;
	if (window_end - shoulder_1 < 5 || shoulder_1 - neck_1 < 3 || neck_1 - head < 5 ||
		head - neck_2 < 3 || neck_2 - shoulder_2 < 5 || shoulder_2 < 3) return false;

	if (head < window_end / 3 || head > window_end * 2 / 3) return false;

	// if (max_coverage_1 < 8 || max_coverage_2 < 8) return false;

	// if (MathAbs(High[shoulder_1] - High[shoulder_2]) > 0.001) return false;

	// if (MathAbs(Low[neck_1] - Low[neck_2]) > 0.001) return false;

	// if (MathMin(Low[neck_1], Low[neck_2]) - Close[1] > 0.001) return false;

	if (shoulder_1 == window_end || shoulder_2 == 1 ||
		(Close[shoulder_1] - Close[window_end]) / (window_end - shoulder_1) < 0.0001 ||
		(Close[shoulder_2] - Close[1]) / (shoulder_2 - 1) < 0.0001) return false;

	if (shoulder_1 == neck_1 || shoulder_2 == neck_2 ||
		(Close[shoulder_1] - Close[neck_1]) / (shoulder_1 - neck_1) < 0.0001 ||
		(Close[shoulder_2] - Close[neck_2]) / (neck_2 - shoulder_2) < 0.0001) return false;

	if (neck_1 == head || neck_2 == head ||
		(Close[head] - Close[neck_1]) / (neck_1 - head) < 0.0001 ||
		(Close[head] - Close[neck_2]) / (head - neck_2) < 0.0001) return false;

	for (int i = 1; i <= 100; i++) {
		if (High[window_end + i] > Close[shoulder_1]) return false;
	}

	return true;
}