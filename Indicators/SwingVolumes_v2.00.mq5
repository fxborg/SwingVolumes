//+------------------------------------------------------------------+
//|                                           SwingVolumes v2.00.mq5 |
//| SwingVolumes v2.00                        Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "2.00"
#property indicator_separate_window
#property indicator_buffers 11
#property indicator_plots   6

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_color1  DodgerBlue
#property indicator_color2  LimeGreen
#property indicator_color3  Gold
#property indicator_color4  DodgerBlue
#property indicator_color5  LimeGreen
#property indicator_color6  Gold


#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1

#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 2

#property indicator_style1 STYLE_DOT
#property indicator_style2 STYLE_DOT
#property indicator_style3 STYLE_DOT
//---
input ENUM_TIMEFRAMES CalcTF=PERIOD_M10; // Calclation TimeFrame
input int FastPeriod=4;
input int MainPeriod=20;
input int SlowPeriod=60;
input int Smooth_for_Fast=2;
input int Smooth_for_Main=4;
input int Smooth_for_Slow=8;

//---

//---
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);
//---

//---
#define DIR_UP 1.0
#define DIR_DOWN 2.0
#define DIR_NONE 0.0
//---

//---
double UpVolBuffer[];
double DnVolBuffer[];
double FastBuffer[];
double FastMaBuffer[];
double MainBuffer[];
double MainMaBuffer[];
double SlowBuffer[];
double SlowMaBuffer[];
double SlowHistBuffer[];
double MainHistBuffer[];
double FastHistBuffer[];
//---

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(PeriodSeconds(PERIOD_CURRENT)<=PeriodSeconds(CalcTF))
     {
      Alert("Calclation Time Frame is too Large");
      return(INIT_FAILED);
     }

//---- Initialization of variables of data calculation starting point
   min_rates_total=20;
//--- indicator buffers mapping
   SetIndexBuffer(0,SlowHistBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MainHistBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,FastHistBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,SlowMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,MainMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,FastMaBuffer,INDICATOR_DATA);   
   SetIndexBuffer(6,UpVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,DnVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,FastBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,MainBuffer,INDICATOR_DATA);
   SetIndexBuffer(10,SlowBuffer,INDICATOR_DATA);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="Swing Volumes v2.00";
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
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

   if(first+1<prev_calculated && UpVolBuffer[prev_calculated-3]>0)
      first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {

      //---
      bool isNewBar=(i==rates_total-1);
      //---
      double up_vol=0;
      double dn_vol=0;
      //---
      MqlRates tf_rates[];
      //---
      datetime from=(datetime)(time[i]-10);
      datetime to=(isNewBar)?TimeCurrent()+10:(datetime)(time[i+1]-10);
      int tf_rates_total=CopyRates(Symbol(),CalcTF,from,to,tf_rates);
      if(tf_rates_total<1) continue;
      //---
      for(int pos=0;pos<tf_rates_total;pos++)
        {
         double dir=CalcUpDn(tf_rates,pos);
         //---
         if(tf_rates[pos].time>(time[i]-10))
           {
            //---
            up_vol+= ((double)tf_rates[pos].tick_volume) * dir;
            dn_vol+= ((double)tf_rates[pos].tick_volume) * (1.0-dir);
           }
         //---
        }
      //---
      UpVolBuffer[i]=(double)up_vol;
      DnVolBuffer[i]=(double)dn_vol*-1;
      //---
      double calc_period=MathMax(MathMax((FastPeriod+Smooth_for_Fast),
                                 (MainPeriod+Smooth_for_Main)),
                                 (SlowPeriod+Smooth_for_Slow));
      if(i<=min_rates_total+2+calc_period) continue;
      //--
      double op=0.0;
      double ma=0.0;
      //---  
      for(int j=FastPeriod-1;j>0;j--) op+=(UpVolBuffer[i-j]+DnVolBuffer[i-j]);
      FastBuffer[i]=op+(UpVolBuffer[i]+DnVolBuffer[i]);
      //---
      for(int j=0;j<Smooth_for_Fast;j++) ma+=FastBuffer[i-j];
      FastMaBuffer[i]=ma/Smooth_for_Fast;      
      FastHistBuffer[i]=FastMaBuffer[i];
      //---
      op=0.0;
      ma=0.0;
      //---
      for(int j=MainPeriod-1;j>0;j--) op+=(UpVolBuffer[i-j]+DnVolBuffer[i-j]);
      MainBuffer[i]=op+(UpVolBuffer[i]+DnVolBuffer[i]);
      //---
      for(int j=0;j<Smooth_for_Main;j++) ma+=MainBuffer[i-j];
      MainMaBuffer[i]=ma/Smooth_for_Main;
      MainHistBuffer[i]=MainMaBuffer[i];
      //---

      //---
      op=0.0;
      ma=0.0;
      //---
      for(int j=SlowPeriod-1;j>0;j--) op+=(UpVolBuffer[i-j]+DnVolBuffer[i-j]);
      SlowBuffer[i]=op+(UpVolBuffer[i]+DnVolBuffer[i]);
      //---
      for(int j=0;j<Smooth_for_Slow;j++) ma+=SlowBuffer[i-j];
      SlowMaBuffer[i]=ma/Smooth_for_Slow;
      SlowHistBuffer[i]=SlowMaBuffer[i];
      //---

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcUpDn(MqlRates  &rates[],const int i)
  {

   double up= (rates[i].close-rates[i].open) + (rates[i].close-rates[i].low);
   double dn= (rates[i].open-rates[i].close) + (rates[i].high-rates[i].close);

   if(dn==0 && up>0) return 1.0;
   if(dn>0 && up==0) return 0.0;
   if(dn==0 && up==0) return 0.5;
   double dir=(up/(up+dn));

   return dir;

  }
