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

int OnInit() {
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
  	}
  }
  if (last_tentative_low != -1 && current_tentative_low != -1) {
  	if (!ValidateTentativeLow(last_tentative_low)) {
  		ObjectDelete(0, last_low_name);
  	}
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
