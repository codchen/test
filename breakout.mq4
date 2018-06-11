#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar;
int pivots[20];
datetime last_time = D'1970.03.05 15:46:58';
double pivot_threshold;

int OnInit() {
	ArrayInitialize(pivots, 0);
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {}

void OnTick() {
  if (Bars == last_bar) return;

  // ObjectsDeleteAll(0, OBJ_TEXT);

  UpdatePivots();

  for (int i = 0; i < 20; i++) {
  	if (Time[MathAbs(pivots[i])] == last_time) {
  		break;
  	}
  	string objName = "Bullseye_" + Bars + "_" + i;
 	if (pivots[i] > 0) {
 		ObjectCreate(objName, OBJ_TEXT, 0, Time[pivots[i]], High[pivots[i]]); 
    	ObjectSetText(objName, CharToStr(159), 14, "Wingdings", Blue); 
 	} else {
 		ObjectCreate(objName, OBJ_TEXT, 0, Time[-pivots[i]], Low[-pivots[i]]); 
    	ObjectSetText(objName, CharToStr(159), 14, "Wingdings", Red); 
 	}
  }
  last_time = Time[MathAbs(pivots[0])];

  // if (IsRanging()) {
  // 	string objName = "VL_" + Bars;
  // 	ObjectCreate(objName, OBJ_VLINE, 0, Time[1], Close[1]);
  // 	ObjectSetInteger(0, objName, OBJPROP_COLOR, Green);
  // }

  // if (IsBullishTrend()) {
  // 	string objName = "Bullish_trend_" + Bars;
  // 	ObjectCreate(objName, OBJ_TREND, 0, Time[0], Close[0], Time[0], Close[0] + 0.1); 
  //   ObjectSetInteger(0, objName, OBJPROP_COLOR, Yellow);
  // }

  // if (IsBearishTrend()) {
  // 	string objName = "Bearish_trend_" + Bars;
  // 	ObjectCreate(objName, OBJ_TREND, 0, Time[0], Close[0], Time[0], Close[0] - 0.1); 
  //   ObjectSetInteger(0, objName, OBJPROP_COLOR, Purple);
  // }

  last_bar = Bars;
}

void UpdatePivots() {
	int pivot_num = 0;
	int current_idx = 2;
	while (pivot_num < 20 && current_idx < Bars) {
		pivot_threshold = iATR(NULL, tf, 14, current_idx);

		int current_left_high = current_idx + 1;
		double delta_left_high = 0;
		bool left_surpass_high = false;
		while (High[current_left_high] <= High[current_idx] && current_left_high < Bars) {
			delta_left_high = MathMax(delta_left_high, High[current_idx] - High[current_left_high]);
			if (delta_left_high > pivot_threshold) {
				left_surpass_high = true;
				break;
			}
			current_left_high++;
		}
		int current_right_high = current_idx - 1;
		double delta_right_high = 0;
		bool right_surpass_high = false;
		while (High[current_right_high] <= High[current_idx] && current_right_high > 0) {
			delta_right_high = MathMax(delta_right_high, High[current_idx] - High[current_right_high]);
			if (delta_right_high > pivot_threshold) {
				right_surpass_high = true;
				break;
			}
			current_right_high--;
		}
		if (left_surpass_high && right_surpass_high) {
			pivots[pivot_num] = current_idx;
			pivot_num++; 
		}

		if (pivot_num == 20) break;

		int current_left_low = current_idx + 1;
		double delta_left_low = 0;
		bool left_surpass_low = false;
		while (Low[current_left_low] >= Low[current_idx] && current_left_low < Bars) {
			delta_left_low = MathMax(delta_left_low, Low[current_left_low] - Low[current_idx]);
			if (delta_left_low > pivot_threshold) {
				left_surpass_low = true;
				break;
			}
			current_left_low++;
		}
		int current_right_low = current_idx - 1;
		double delta_right_low = 0;
		bool right_surpass_low = false;
		while (Low[current_right_low] >= Low[current_idx] && current_right_low > 0) {
			delta_right_low = MathMax(delta_right_low, Low[current_right_low] - Low[current_idx]);
			if (delta_right_low > pivot_threshold) {
				right_surpass_low = true;
				break;
			}
			current_right_low--;
		}
		if (left_surpass_low && right_surpass_low) {
			pivots[pivot_num] = -current_idx;
			pivot_num++; 
		}

		current_idx++;
	}
}

// bool IsBullishTrend() {
// 	int last_top = 0;
// 	for (int i = 0; i < 20; i++) {
// 		if (last_top == 0 && pivots[i] > 0) {
// 			last_top = pivots[i];
// 			break;
// 		}
// 	}
// 	return High[1] - pivot_threshold > High[last_top];
// }

// bool IsBearishTrend() {
// 	int last_bottom = 0;
// 	for (int i = 0; i < 20; i++) {
// 		if (last_bottom == 0 && pivots[i] < 0) {
// 			last_bottom = -pivots[i];
// 			break;
// 		}
// 	}
// 	return Low[1] + pivot_threshold < Low[last_bottom];
// }

// bool IsBullishTrend() {
// 	return pivots[0] < 0 && pivots[1] > 0 && pivots[2] < 0 &&
// 	    Low[-pivots[0]] - pivot_threshold > Low[-pivots[2]] &&
// 		High[1] - pivot_threshold > High[pivots[1]];
// }

// bool IsBearishTrend() {
// 	return pivots[0] > 0 && pivots[1] < 0 && pivots[2] > 0 &&
// 		High[pivots[0]] + pivot_threshold < High[pivots[2]] &&
// 		Low[1] + pivot_threshold < Low[-pivots[1]];
// }

// get max number of most recent highs/lows where Max(highs) - Min(highs) < threshold

// If no new tentative high/low on the current bar, consider it to be ranging market
// bool IsRanging() {
// 	int top_idx = -1; 
// 	int bottom_idx = -1;
// 	for (int i = 0; i < 20; i++) {
// 		if (pivots[i] > 0) top_idx = pivots[i];
// 		else bottom_idx = -pivots[i];
// 		if (top_idx != -1 && bottom_idx != -1) break;
// 	}
// 	return High[top_idx] - Low[bottom_idx] < pivot_threshold * 2 && Close[1] < High[top_idx] && Close[1] > Low[bottom_idx];
// }

// trendy if last 3 highs AND 3 lows are incremental (decremental)

