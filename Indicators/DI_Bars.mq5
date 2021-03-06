//+------------------------------------------------------------------+
//|                                                      DI_Bars.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  LimeGreen,DodgerBlue,Red
int CalcBars=10;

#define DIR_UP 1.0
#define DIR_DOWN 2.0
#define DIR_NONE 0.0
#property indicator_width1 3

double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double DirBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=CalcBars+2;
//--- indicator buffers mapping
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,DirBuffer,INDICATOR_COLOR_INDEX);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
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

   first=2;

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
      SetDirection(open,high,low,close,i);
      double dir=DirBuffer[i];
      //---
      OpenBuffer[i]=open[i];
      HighBuffer[i]=high[i];
      LowBuffer[i]=low[i];
      CloseBuffer[i]=close[i];

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetDirection(const double  &open[],const double  &high[],const double  &low[],const double  &close[],const int i)
  {
//--- get some data
   double Hi    =high[i];
   double prevHi=high[i-1];
   double Lo    =low[i];
   double prevLo=low[i-1];
   double prevCl=close[i-1];
//--- fill main positive and main negative buffers
   double dTmpP=Hi-prevHi;
   double dTmpN=prevLo-Lo;
   if(dTmpP<0.0)   dTmpP=0.0;
   if(dTmpN<0.0)   dTmpN=0.0;
   if(dTmpP>dTmpN) dTmpN=0.0;
   else
     {
      if(dTmpP<dTmpN) dTmpP=0.0;
      else
        {
         dTmpP=0.0;
         dTmpN=0.0;
        }
     }

   if(dTmpP==0.0 && dTmpN==0.0)
      DirBuffer[i]=DIR_NONE;
   else if(dTmpP>dTmpN)
      DirBuffer[i]=DIR_UP;
   else if(dTmpP<dTmpN)
      DirBuffer[i]=DIR_DOWN;

  }      
//+------------------------------------------------------------------+
