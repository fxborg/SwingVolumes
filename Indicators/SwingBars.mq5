//+------------------------------------------------------------------+
//|                                                     SwingVol.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_BARS
#property indicator_color1  Gray,DodgerBlue,Red
int CalcBars=10;

#define DIR_UP 1.0
#define DIR_DOWN 2.0
#define DIR_NONE 0.0
#property indicator_width1 2

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
   int i,j,first;
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
      if(i<=2+CalcBars)continue;
      double atr=0.0;
      for(j=0; j < CalcBars;j++)   atr += high[i-j]-low[i-j];
      atr /= CalcBars;
      SetZigZag(open,high,low,close,i,atr);
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
void SetZigZag(const double  &open[],const double  &high[],const double  &low[],const double  &close[],const int i,const double atr)
  {
   double up2= (high[i-2]-open[i-2])+(close[i-2]-low[i-2]);
   double dn2= (open[i-2]-low[i-2])+(high[i-2]-close[i-2]);
   double up1= (high[i-1]-open[i-1])+(close[i-1]-low[i-1]);
   double dn1= (open[i-1]-low[i-1])+(high[i-1]-close[i-1]);
   double up0= (high[i]-open[i])+(close[i]-low[i]);
   double dn0= (open[i]-low[i])+(high[i]-close[i]);

   if(atr*0.5>(high[i]-low[i]))
     {
      DirBuffer[i]=DirBuffer[i-1];
      return;
     }
   if(atr*1.2<MathAbs(close[i]-open[i]))
     {
      if(close[i]<open[i])
         DirBuffer[i]=DIR_DOWN;
      else
         DirBuffer[i]=DIR_UP;
      return;
     }

   if(up1+up0>dn1+dn0)
     {
      if(DirBuffer[i-1]==DIR_UP && up1>dn1 && up0<dn0 && up1<dn0)
         DirBuffer[i]=DIR_DOWN;
      else
         DirBuffer[i]=DIR_UP;

     }
   else
     {
      if(DirBuffer[i-1]==DIR_DOWN && dn1>up1 && dn0<up0 && dn1<up0)
         DirBuffer[i]=DIR_UP;
      else
         DirBuffer[i]=DIR_DOWN;
     }
  }
//+------------------------------------------------------------------+
