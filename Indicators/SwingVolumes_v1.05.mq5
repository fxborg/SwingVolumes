//+------------------------------------------------------------------+
//|                                            SwingVolumes_1.05.mq5 |
//| Swing Volumes v1.05                       Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.05"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE

#property indicator_color1  DodgerBlue
#property indicator_color2  Red
#property indicator_color3  Lime
#property indicator_color4  Orange

#property indicator_width1 4
#property indicator_width2 4
#property indicator_width3 2
//---
input int TotalPeriod=4; // Total Period
input int MaPeriod=3; // Ma Period
input ENUM_TIMEFRAMES CalcTF=PERIOD_M5; // Calclation TimeFrame
//---

int RangePeriod=10;

//---
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);
//---

//---
#define DIR_UP 1.0
#define DIR_DOWN -1.0
#define DIR_NONE 0.0
//---

//---
double UpVolBuffer[];
double DnVolBuffer[];
double SwingUpVolBuffer[];
double SwingDnVolBuffer[];
double SwingMaBuffer[];
double DirBuffer[];
double LastDir1Buffer[];
double LastTimeBuffer[];
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
   min_rates_total=RangePeriod+2;
//--- indicator buffers mapping

   SetIndexBuffer(0,SwingUpVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SwingDnVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SwingMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,UpVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,DnVolBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,DirBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LastDir1Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LastTimeBuffer,INDICATOR_CALCULATIONS);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);

//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
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
   int i,j,first;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);
//---

   first=5+RangePeriod+TotalPeriod;

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
      bool isNewBar=(i==rates_total-1);
      //---
      int backs=2;
      int calc_seconds=RangePeriod*PeriodSeconds(CalcTF);
      //---
      if(LastDir1Buffer[i-1]==0 && LastTimeBuffer[i-1]!=(double)time[i-1]) backs=3;
      //---
      long up_vol=0;
      long dn_vol=0;
      double tf_dir[];
      //---
      MqlRates tf_rates[];

      //---
      datetime from=(datetime)(time[i+1-backs]-calc_seconds);
      datetime to=(isNewBar)?TimeCurrent()+10:(datetime)(time[i+1]-10);
      int tf_rates_total=CopyRates(Symbol(),CalcTF,from,to,tf_rates);
      //---
      if(!isNewBar && tf_rates_total<Scale*backs-3) continue;
      if(!isNewBar && tf_rates_total<RangePeriod+1) continue;
      //---
      ArrayResize(tf_dir,tf_rates_total);
      ArrayInitialize(tf_dir,0.0);
      //---

      //---
      double ar=0.0;
      int pos=0;
      for(pos=RangePeriod;pos<tf_rates_total;pos++)
        {
         if(LastDir1Buffer[i-1]!=0 && tf_rates[pos].time<time[i]-10)
            tf_dir[pos]=LastDir1Buffer[i-1];
         else
           {
            //---
            for(j=0;j<=RangePeriod;j++) ar+=tf_rates[pos-j].high-tf_rates[pos-j].low;
            ar/=RangePeriod;
            //---

            tf_dir[pos]=CalcUpDn(tf_rates,tf_dir,pos,ar,tf_dir[pos-1]);
           }
         //---
         if(tf_rates[pos].time>time[i]-10)
           {
            //---
            if(tf_dir[pos]==DIR_DOWN)dn_vol+=tf_rates[pos].tick_volume;
            if(tf_dir[pos]==DIR_UP)  up_vol+=tf_rates[pos].tick_volume;
            if(tf_dir[pos]==DIR_NONE)
              {
               dn_vol=0;
               up_vol=0;
               break;
              }
            //---
           }
         //---
         if(pos==tf_rates_total-1)
           {
            LastTimeBuffer[i]=(double)time[i];
            LastDir1Buffer[i]=tf_dir[pos];
           }
         //---
        }
      if(dn_vol==0 && up_vol==0)
        {
         SwingUpVolBuffer[i]= SwingUpVolBuffer[i-1];
         SwingDnVolBuffer[i]= SwingDnVolBuffer[i-1];
         continue;
        }

      //---
      UpVolBuffer[i]=(double)up_vol;
      DnVolBuffer[i]=(double)dn_vol*-1;

      double main_ar=0.0;
      for(j=0; j<RangePeriod;j++) main_ar+=high[i-j]-low[i-j];
      main_ar/=RangePeriod;

      SetDirection(open,high,low,close,i,main_ar);
      double dir=DirBuffer[i];
      //---
      //  bug fix
      SwingUpVolBuffer[i]=0;
      SwingDnVolBuffer[i]=0;
      //----
      if(DirBuffer[i-1]==dir)
        {
         //---
         for(j=0;j<TotalPeriod;j++)
           {
            if(dir!=DirBuffer[i-j])break;
            SwingUpVolBuffer[i]+= UpVolBuffer[i-j];
            SwingDnVolBuffer[i]+= DnVolBuffer[i-j];
           }
         //---
        }
      else
        {
         SwingUpVolBuffer[i]= UpVolBuffer[i];
         SwingDnVolBuffer[i]= DnVolBuffer[i];
        }
      //---
      int ma_first=5+RangePeriod+TotalPeriod+MaPeriod;
      //---
      if(i<=MaPeriod)continue;
      //---
      double upsum=0.0;
      double dnsum=0.0;

      //---
      for(j=0;j<MaPeriod;j++)
        {
         upsum+=SwingUpVolBuffer[i-j];
         dnsum+=SwingDnVolBuffer[i-j];
        }
      //---
      SwingMaBuffer[i]=upsum/MaPeriod+dnsum/MaPeriod;
      //---
     }


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcUpDn(MqlRates  &rates[],double  &dir_buf[],const int i,const double ar,const double dir1)
  {
   double up2= (rates[i-2].high-rates[i-2].open)+(rates[i-2].close-rates[i-2].low);
   double dn2= (rates[i-2].open-rates[i-2].low)+(rates[i-2].high-rates[i-2].close);
   double up1= (rates[i-1].high-rates[i-1].open)+(rates[i-1].close-rates[i-1].low);
   double dn1= (rates[i-1].open-rates[i-1].low)+(rates[i-1].high-rates[i-1].close);
   double up0= (rates[i].high-rates[i].open)+(rates[i].close-rates[i].low);
   double dn0= (rates[i].open-rates[i].low)+(rates[i].high-rates[i].close);

   if(dir_buf[i-1]!=0 && ar*0.5>(rates[i].high-rates[i].low))
     {
      return dir1;
     }
   if(ar*1.2<MathAbs(rates[i].close-rates[i].open))
     {
      if(rates[i].close<rates[i].open)
         return DIR_DOWN;
      else
         return DIR_UP;
     }

   if(up1+up0>dn1+dn0)
     {
      if(dir1==DIR_UP && up1>dn1 && up0<dn0 && up1<dn0)
         return DIR_DOWN;
      else
         return DIR_UP;

     }
   else
     {
      if(dir1==DIR_DOWN && dn1>up1 && dn0<up0 && dn1<up0)
         return DIR_UP;
      else
         return DIR_DOWN;
     }
   return DIR_NONE;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetDirection(const double  &open[],const double  &high[],const double  &low[],const double  &close[],const int i,const double atr)
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
