//+------------------------------------------------------------------+
//|                                                SwingVol_1.04.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.04"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   4

#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color3  Green
#property indicator_color4  Orange
#property indicator_color1  DodgerBlue
#property indicator_color2  Red
int RangePeriod=10;
ENUM_TIMEFRAMES CalcTF=PERIOD_M5;     // Histgram Time Frame
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);

#define DIR_UP 1.0
#define DIR_DOWN -1.0
#define DIR_NONE 0.0
#property indicator_width1 4
#property indicator_width2 4
#property indicator_width3 2
#property indicator_width4 2
double UpVolBuffer[];
double DnVolBuffer[];
double SwingUpVolBuffer[];
double SwingDnVolBuffer[];
double DirBuffer[];
double LastDir1Buffer[];
double LastTimeBuffer[];

//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=RangePeriod+2;
//--- indicator buffers mapping

   SetIndexBuffer(0,SwingUpVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SwingDnVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,UpVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DnVolBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,DirBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,LastDir1Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LastTimeBuffer,INDICATOR_CALCULATIONS);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);

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

   first=RangePeriod*2;

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


      bool isNewBar=(i==rates_total-1);
      //---
      int backs=2;
      int calc_seconds=RangePeriod*PeriodSeconds(CalcTF);
      if(LastDir1Buffer[i-1]==0 && LastTimeBuffer[i-1]!=(double)time[i-1]) backs=3;
      long up_vol=0;
      long dn_vol=0;
      double tf_dir[];
      //---
      MqlRates tf_rates[];

      datetime from=(datetime)(time[i+1-backs]-calc_seconds);
      datetime to=(isNewBar)?TimeCurrent()+10:(datetime)(time[i+1]-10);
      int tf_rates_total=CopyRates(Symbol(),CalcTF,from,to,tf_rates);
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
      //---
      SetDirection(open,high,low,close,i);
      double dir=DirBuffer[i];
      //---
      //---
      
      if( DirBuffer[i-1]==dir)
        {
         SwingUpVolBuffer[i]=SwingUpVolBuffer[i-1]+ UpVolBuffer[i];
         SwingDnVolBuffer[i]=SwingDnVolBuffer[i-1]+ DnVolBuffer[i];
        } 
      else
        { 
         SwingUpVolBuffer[i]= UpVolBuffer[i];
         SwingDnVolBuffer[i]= DnVolBuffer[i];
        }

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
