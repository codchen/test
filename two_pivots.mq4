#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar = 0;
int last_tentative_high = -1;
int last_tentative_low = -1;
int current_tentative_high = -1;
int current_tentative_low = -1;
string last_high_name, last_low_name;

int last_ten_highs[10];
int last_ten_lows[10];

int OnInit() {
	ArrayInitialize(last_ten_highs, 0);
	ArrayInitialize(last_ten_lows, 0);
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
  if (Bars == last_bar) return;

  if (last_tentative_high != -1) last_tentative_high += 1;
  if (last_tentative_low != -1) last_tentative_low += 1;

  UpdatePivots();

  if (last_tentative_high != -1 && current_tentative_high != -1) {
  	if (!ValidateTentativeHigh(last_tentative_high)) {
  		ObjectDelete(0, last_high_name);
  		UpdateLastTenHighs(-1);
  	} else {
  		UpdateLastTenHighs(last_tentative_high);
  	}
  } else {
  	UpdateLastTenHighs(-1);
  }
  if (last_tentative_low != -1 && current_tentative_low != -1) {
  	if (!ValidateTentativeLow(last_tentative_low)) {
  		ObjectDelete(0, last_low_name);
  		UpdateLastTenLows(-1);
  	} else {
  		UpdateLastTenLows(last_tentative_low);
  	}
  } else {
  	UpdateLastTenLows(-1);
  }

  if (current_tentative_high != -1) {
  	last_high_name = "High_" + Bars;
  	ObjectCreate(last_high_name, OBJ_TEXT, 0, Time[1], High[1]);
  	ObjectSetText(last_high_name, CharToStr(159), 14, "Wingdings", Blue);
  }
  if (current_tentative_low != -1) {
  	last_low_name = "Low_" + Bars;
  	ObjectCreate(last_low_name, OBJ_TEXT, 0, Time[1], Low[1]);
  	ObjectSetText(last_low_name, CharToStr(159), 14, "Wingdings", Red);
  }

  if (PenetratedLastTwoHighs()) {
  	string name = "Penetrate_high_" + Bars;
  	ObjectCreate(name, OBJ_TEXT, 0, Time[1], Close[1]);
  	ObjectSetText(name, CharToStr(159), 14, "Wingdings", Purple);
  }
  if (PenetratedLastTwoLows()) {
  	string name = "Penetrate_low_" + Bars;
  	ObjectCreate(name, OBJ_TEXT, 0, Time[1], Close[1]);
  	ObjectSetText(name, CharToStr(159), 14, "Wingdings", Pink);
  }

  last_bar = Bars;
  if (current_tentative_high != -1) last_tentative_high = current_tentative_high;
  if (current_tentative_low != -1) last_tentative_low = current_tentative_low;
}

void UpdatePivots() {
	current_tentative_high = -1;
	current_tentative_low = -1;

	double pivot_threshold = iATR(NULL, tf, 14, 1);
	int high_counter = 2;
	double high_delta = 0;
	while (high_counter < Bars && High[high_counter] <= High[1]) {
		high_delta = MathMax(high_delta, High[1] - High[high_counter]);
		if (high_delta > pivot_threshold) {
			current_tentative_high = 1;
			break;
		}
		high_counter++;
	}

	int low_counter = 2;
	double low_delta = 0;
	while (low_counter < Bars && Low[low_counter] >= Low[1]) {
		low_delta = MathMax(low_delta, Low[low_counter] - Low[1]);
		if (low_delta > pivot_threshold) {
			current_tentative_low = 1;
			break;
		}
		low_counter++;
	}
}

bool ValidateTentativeHigh(int idx) {
	double lowest = High[idx];
	for (int i = 2; i < idx; i++) {
		lowest = MathMin(lowest, High[i]);
	}
	return High[idx] - lowest > iATR(NULL, tf, 14, idx);
}

bool ValidateTentativeLow(int idx) {
	double highest = Low[idx];
	for (int i = 2; i < idx; i++) {
		highest = MathMax(highest, Low[i]);
	}
	return highest - Low[idx] > iATR(NULL, tf, 14, idx);
}

void UpdateLastTenHighs(int last_high) {
	if (last_high != -1) {
		for (int i = 9; i > 0; i--) {
			if (last_ten_highs[i - 1] != 0) last_ten_highs[i] = last_ten_highs[i - 1] + 1;
		}
		last_ten_highs[0] = last_high;
	} else {
		for (int i = 0; i < 10; i++) {
			if (last_ten_highs[i] != 0) last_ten_highs[i]++;
		}
	}
}

void UpdateLastTenLows(int last_low) {
	if (last_low != -1) {
		for (int i = 9; i > 0; i--) {
			if (last_ten_lows[i - 1] != 0) last_ten_lows[i] = last_ten_lows[i - 1] + 1;
		}
		last_ten_lows[0] = last_low;
	} else {
		for (int i = 0; i < 10; i++) {
			if (last_ten_lows[i] != 0) last_ten_lows[i]++;
		}
	}
}

bool PenetratedLastTwoHighs() {
	if (last_ten_highs[0] == 0 || last_ten_highs[1] == 0) return false;
	double last_high = High[last_ten_highs[0]];
	double last_last_high = High[last_ten_highs[1]];
	double target = last_high + (last_high - last_last_high) / (last_ten_highs[1] - last_ten_highs[0]) * (last_ten_highs[0] - 1);
	return Close[1] > target;
}

bool PenetratedLastTwoLows() {
	if (last_ten_lows[0] == 0 || last_ten_lows[1] == 0) return false;
	double last_low = Low[last_ten_lows[0]];
	double last_last_low =  Low[last_ten_lows[1]];
	double target = last_low + (last_low - last_last_low) / (last_ten_lows[1] - last_ten_lows[0]) * (last_ten_lows[0] - 1);
	return Close[1] < target;
}
