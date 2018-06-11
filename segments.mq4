#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input double max_error = 0.05;
input int lookback = 200;
input ENUM_TIMEFRAMES tf = PERIOD_CURRENT;

int last_bar;
int segments[];
int segment_num;

int OnInit() {
	last_bar = 0;
	segment_num = 0;
	ArrayResize(segments, lookback);
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
  if (Bars == last_bar || Bars < lookback + 50) return;

  ObjectsDeleteAll(0, OBJ_TREND);

  ResetSegments();

  ComputeSegments();

  PlotSegments();

  last_bar = Bars;
}

void PlotSegments() {
	int last_endpoint = 0;
	for (int i = 0; i < segment_num; i++) {
		string object_name = "segment_" + Bars + "_" + i;
		ObjectCreate(object_name, OBJ_TREND, 0, iTime(NULL, tf, segments[i]), Close[segments[i]], iTime(NULL, tf, last_endpoint), Close[last_endpoint]);
		ObjectSetInteger(0, object_name, OBJPROP_RAY, 0);
		last_endpoint = segments[i];
	}
}

void ResetSegments() {
	for (int i = 0; i < segment_num; i++) segments[i] = 0;
	segment_num = 0;
}

void ComputeSegments() {
	int last_endpoint = 0;

	for (int i = 1; i <= lookback; i++) {
		if (ErrorTooLarge(last_endpoint, i)) {
			segments[segment_num] = i - 1;
			segment_num++;
			last_endpoint = i - 1;
		}
	}
}

bool ErrorTooLarge(int start, int end) {
	double slope = (Close[end] - Close[start]) / (end - start);
	for (int i = start + 1; i < end; i++) {
		if (MathAbs(Close[start] + slope * (i - start) - Close[i]) > max_error) return true;
	}
	return false;
}

double Slope(int start, int end) {
	return (Close[end] - Close[start]) / (end - start);
}