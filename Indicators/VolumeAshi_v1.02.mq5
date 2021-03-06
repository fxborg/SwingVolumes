//+------------------------------------------------------------------+
//|                                              VolumeAshiv1.02.mq5 |
//| VolumeAshi v1.02                          Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   1


#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  Gray,DodgerBlue,Red


#property indicator_width1 1
//---
input ENUM_TIMEFRAMES CalcTF=PERIOD_M10; // Calclation TimeFrame
input int SummaryBars=4;
//---

//---
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);
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
double UpVolBuffer[];
double DnVolBuffer[];
double TimeBuffer[];

//---

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(PeriodSeconds(PERIOD_CURRENT)<PeriodSeconds(CalcTF))
     {
      Alert("Calclation Time Frame is too Large");
      return(INIT_FAILED);
     }

//---- Initialization of variables of data calculation starting point
   min_rates_total=20;
//--- indicator buffers mapping

   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,DirBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,UpVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,DnVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,TimeBuffer,INDICATOR_CALCULATIONS);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);

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

   if(first+1<prev_calculated && UpVolBuffer[prev_calculated-3]>0)
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
      bool isNewBar=(i==rates_total-1);
      //---

      //---
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
      double op=0.0;
      if(i<=SummaryBars+min_rates_total+2)continue;
      for(int j=SummaryBars-1;j>0;j--)
        {
          op += (UpVolBuffer[i-j]+DnVolBuffer[i-j]);
        }
      
      OpenBuffer[i]  = op;
      HighBuffer[i]  = OpenBuffer[i] + UpVolBuffer[i];
      LowBuffer[i]   = OpenBuffer[i] + DnVolBuffer[i];
      CloseBuffer[i] = OpenBuffer[i] + (UpVolBuffer[i]+DnVolBuffer[i]);
      DirBuffer[i]   =(OpenBuffer[i]<CloseBuffer[i]) ? DIR_UP : DIR_DOWN;


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

//   double up= (rates[i].high-rates[i].open) + (rates[i].close-rates[i].low)*2;
//   double dn= (rates[i].open-rates[i].low) + (rates[i].high-rates[i].close)*2;
//   double total =(rates[i].high-rates[i].low) + (rates[i].high-rates[i].low)*2;

   if(dn==0 && up>0) return 1.0;
   if(dn>0 && up==0) return 0.0;
   if(dn==0 && up==0) return 0.5;
   //double dir=(up/total);
   double dir=(up/(up+dn));

   return dir;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getWeekNumber(const int day_of_year,const int day_of_week)
  {
   int iDay=(day_of_week)%7+1;                    // convert day to standard index (1=Mon,...,7=Sun)          
   return(int)MathFloor(((day_of_year-iDay)+10)/7);                // calculate standard week number
  }
//+------------------------------------------------------------------+
