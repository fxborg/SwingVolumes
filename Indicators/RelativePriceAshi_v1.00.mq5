//+------------------------------------------------------------------+
//|                                      RelativePriceAshi_v1.00.mq5 |
//| RelativePriceAshi v1.00                   Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1


#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  Gray,DodgerBlue,Red


#property indicator_width1 1
//---
input int SummaryBars=4;
//---

//---

//---
#define DIR_UP 1.0
#define DIR_DOWN 2.0
#define DIR_NONE 0.0
//---

double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double DirBuffer[];
//---
//---

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- Initialization of variables of data calculation starting point
   min_rates_total=SummaryBars+2;
//--- indicator buffers mapping

   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,DirBuffer,INDICATOR_COLOR_INDEX);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);
//---

   first=min_rates_total;

   if(first+1<prev_calculated && DirBuffer[prev_calculated-3]>0)
      first=prev_calculated-2;
   else
     {
      for(i=0; i<first; i++)
        {
         DirBuffer[i]=0;  // Gray 
        }
     }

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {

      //---
      double op,cl=0.0;
      for(int j=SummaryBars-1;j>0;j--)cl+=(close[i-j]-close[(i-j)-1]);

      op=cl;
      OpenBuffer[i]  = op;
      HighBuffer[i]  = op+(high[i]-open[i]);
      LowBuffer[i]   = op-(open[i]-low[i]);
      CloseBuffer[i] = op+(close[i]-open[i]);
      DirBuffer[i]   =(OpenBuffer[i]<CloseBuffer[i]) ? DIR_UP : DIR_DOWN;


     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
