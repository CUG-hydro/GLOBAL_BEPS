/*************************************************************************
  Program:     zcomp.c
  --------
 	 Description:
	 ------------ 
	 Calculate z variables.
	 
	 Details:
	 -------

	Z 	Description
	-------------------------------------------------------------

    2	day of year  
   	3	precipitation 				(m)  
	4 	max. Air temperature 		(deg c) 	
 	5  	min. Air temperature 		(deg c)    
   	6  	relative humidity			(%)  
   	7  	soil temperature, ave 24 hr temp   	(deg c)  
   	8  	daily total incoming solar radiation  (kj/m2/d)
   	9  	average incoming solar radiation	(W/m2)		
	10	LAI

    14 	daylight average air temperature 	(deg c)  
    15 	average night min. temperature  	(deg c)  
    16 	vapor pressure deficit        		(mb)  
    17 	absolute humidity deficit   		(mic. gm/m3)  
   	18 	running periods (daylength for daily model)  (sec)  
   	19 	daily total absorbed radiation    	(kj/m2/d)
	20	daily averaged absorbed radiation  	(W/m2)
       		
	22	available water capacity 	 	(m)
	23	land cover type

	26	leaf nitrogen concentration  fraction	

	30	Cos(Theta_noon)
	31	Cos(Theta_mean)
	32	sunlit LAI 
	33	shaded LAI
	34	daily mean radiation over sunlit leaves (W/m2)
	35	daily mean radiation over shaded leaves (W/m2)
	36	radiation over sunlit leaves at noon (W/m2)
	37	radiation over shaded leaves at noon (W/m2)
	38	net radiation for sunlit leaves (W/m2)
	39	net radiation for shaded leaves (W/m2)
	40	net radiation for understory (W/m2)
	41	net radiation for ground (W/m2)
	42  understory LAI

***************************************************************************
  CCRS (EMS/Applications Division)
  Written by:   J. Liu      
  Modified by: X.F. Feng
  Last update:  July 2003
*****************************************************************************/


//#include"beps.h"

#ifndef   MY_H_FILE      
#define   MY_H_FILE       
#include "gpubeps.cuh"
#endif 


   __device__ void gpuzcomp(
    long jday,
    int long pix,
    float lat_p,
    short int  lc_p,float CI,float TI,
    float awc_p,
    float lai_p,
    float b[],float   x[],float z[],
    short climatedata[],float *tmean)
    { 
    float   xtmax, xtmin, xrad, xppt, tave,  h;
	float   etemp1, etemp2, esd, es, ampl, day, xd; 

    float gfn;			       /* gap function at noon */
    float omega;		       /* clumping index */
    float theta_m;		       /* solar zenith angle at noon */
    float alfa;
    float ssun;		       /* radiation for sunlit leaves */
    float sshade;		       /* radiation for shaded leaves */  
    
	// for shortwave radiation
	float lai_u;			   // understory lai
	float n_ssun;			   // net shortwave radiation for sun lit leaves
	float n_sshade;		   // net shortwave radiation for sun lit leaves
	float n_sunder;	       // net shortwave radiation for understory
	float n_sground;		   // net shortwave radiation for gound

	// for longwave radiation
	float m_lnet_o;		   // mean longwave radiation for overstory
	float m_lnet_u;		   // mean longwave radiation for understory
	float lnet_g;			   // net longwave radiation for ground
    int long pixx;
    
    int count;



    count=pix/4950;
    pixx=pix+4950*count*4;

    xtmax =climatedata[3*4950+pixx]*0.1-273.15;   ///CRU ���ϵ��¶ȵ�λ��K, �������   
	xtmin =climatedata[4*4950+pixx]*0.1-273.15;   ///CRU ���ϵ��¶ȵ�λ��K���������   
	h	  =climatedata[2*4950+pixx]*0.1;            //  relative humidity(%)
	xrad  =climatedata[pixx];//*0.1// MJ/d
	xppt  =climatedata[4950+pixx]*0.1;           // the unit of the original input data is 0.1 mm.

     z[45]=TI;      //ÿ��pixel �Ķ���ƽ���¶ȣ�



   if(h<15)  h=15;
   if(h>100) h=100;

   if(xtmax<-50)  xtmax=-50;
   if(xtmax>45)   xtmax=45;

   if(xtmin<-50)  xtmin=-50;
   if(xtmin>45)   xtmin=45;

   if(xppt<0) xppt=0;
   if(xppt>1500) xppt=1500;

   if(xrad<0.5) xrad=0.5;
   if(xrad>600) xrad=600;



	z[2] = jday;
     
/* convert ppt. 0.1mm to meters */       
    if ( xppt < 0 )       z[3] = 0;
	else                  z[3] = xppt / 1000.0 ;   ///zfm preci unit is mm , convert to m
   
	z[4] = xtmax;     
    z[5] = xtmin;    


   *tmean=(xtmax+xtmin)/2.0;

    tave = (z[4]+z[5])/2.0; 
 	
    if (jday <= 1) 
	z[1] = b[22];

    //z[1] = __max((z[1]+tave), b[22]);
   if((z[1]+tave)>b[22]) z[1]=z[1]+tave;
   else                  z[1]=b[22];    

/* average temperatures, soil, air */ 
    
    z[7]  = tave;

/* if snowpack exists, soil temp defined as 0 deg */ 

    if (x[1] > 0.0) 	
	z[7] = 0.0;

//================================================================================LAI 
  
	omega=CI/100.0; 
	if(omega<0.4) omega=0.4;

	z[10]  =lai_p;

/* daylight mean temp. z[14], nighttime mean temp. z[15] */
    z[14]  =  0.212 * (z[4] - tave) + tave;   //�����¶�
   //  z[15]  = (z[14]+2*z[5])/3.0;   //ҹ��ƽ������     2017-11-29ǰ�� ҹ������ƫ��
 
z[15]  = (z[14]+z[5])/2.0;
	
	//etemp1 = 16.78*tave-116.9;
	//etemp2 = tave + 237.3; 

	//2017-11-23���������ں͹����Ҫ�ڰ�����У������ð����¶ȼ���VPD
	etemp1 = 16.78*z[14]-116.9;
	//etemp2 = tave + 237.3; 

etemp2 = z[14]+ 237.3; 


	esd = exp (etemp1/etemp2);
    es = esd * h *0.01 ;


//	z[16]= (100-h)*0.01*esd;                 // in kpa
//   z[16]= (100-h)*0.1*esd;                  // in mbar


z[16] =(esd - es)*10.0;// __max(((esd - es) * 10),0.0) ;                 // in mbar
 if(z[16]<0) z[16]=0;
      
z[46]=h*0.01;



/* compute daylength in seconds */ 
      if(lat_p<0)  xd  =  (float) jday +105;
else               xd  =  (float) jday -79.0;
   //2017-11-23��ǰ��ȫ��  xd  =  (float) jday -79.0;   �÷��̽������ñ�����

if (xd < 0.0)  	xd = 286.0 + (float) jday;

    ampl = exp(7.42+0.045* abs(lat_p))/3600.0; 
  
	day  = ampl * (sin(xd*0.01721)) + 12.0; 
    z[18]  =  day * 3600.0;// * 0.95;     //running period   ??????????????????????????????????//20171128:0.95

/* total incoming solar radiation in kj/m2/s */ 
  // z[8]  = xrad *24.0*3600*0.85/1000;        ///zfm ע�ⵥλ�� ����������̫������    NCAR ������һ��24Сʱ��ֵ��0.85��ϵ�������ݷ�ȷ���������վ�����ϱȣ� NCAR ���������һ��ϵ�� 
      
	
	z[8]  = xrad*100000;
/* average incoming solar radiation in watt/m2 */ 

    z[9] = z[8]/z[18];  ///zfm ע�ⵥλ   // ??????????????????????????????????
  // z[9] = z[8];    ///zfm rad unit is w/m2


/* FPAR */ 
   theta_m=fabs((lat_p-23.5*sin((jday-81)*2*PI/365.0))*PI/180.0);    //����̫���춥��   //2017-10-26��ȡ����ֵ����
   
   if (fabs(PI/2-theta_m)<0.01)	alfa=0.05;
 
	else alfa=(cos(theta_m)-(PI/2-theta_m)*sin(theta_m))/((PI/2-theta_m)*(1-sin(theta_m)));
 

	/*
	switch(lc_p)
    {

	case 6 : case 9://mixe =0.6, for MODIS 
		omega=0.65;           //0.6   //2013-0828��0.7��Ϊ0.65 
		break;

	case 1: case 2: case 3:case 7: case 8:    //broadleaf forest =0.7, for MODIS 
		omega=0.75;      //0.7       //2013-0828��0.8��Ϊ0.75    
		break;

	case 4: case 5: case 10: //coni=0.5, for MODIS 
		omega=0.55;   //0.55  7-21         //2013-0828��0.6��Ϊ0.55  
		break;

    case 11:  case 12: case 14:     //shrub=0.5, for MODIS, shrub same as conif, closed shrub and woody savanna
		omega=0.5;
		break;

	case 13: case 16: case 17: case 18: 	// grass=0.9, for MODIS, opened shrub & savanna & grassland
		omega=0.9;
		break;
	
	default:
		omega=0.8;


    }

*/


	if (fabs(PI/2-theta_m)<0.01)	gfn=0.1;
	else
	   gfn = exp(-0.4*omega*z[10]/cos(theta_m));    //gap function at noon

	z[19]=(0.95-0.94*alfa*gfn);         //__max(0.0,(0.95-0.94*alfa*gfn));   
	if(z[19]<0) z[19]=0;
	
	
	z[19]=z[8]*z[19];           //ÿ��overstorey������̫������
    

/*  daily averaged absorbed radiation in W/m2 */
    z[20]=z[19]/z[18];      //��λs����̫�����伴w/m2/s
	//z[20]=z[19];//6.10

/* leaf nitrogen */ 
    z[21] = b[26];        //Ҷ��

/* awc */
    z[22]=awc_p;              //awc
	
	//z[22]=__max(0.1,z[22]);     z[22]=__min(0.6,z[22]);
if(z[22]<0.1) z[22]=0.1;
if(z[22]>0.6) z[22]=0.6;


/* land cover */
    z[23]=(float)lc_p;            // land cover

/* cos(Thita_m)  */

  /* cos(Thita_m)  */
    z[30]=cos(theta_m);
    if(z[30]<0.01) z[30]=0.01;
/* cos(Thita_avg) */
    z[31]=cos(PI/8+3*theta_m/4);    ////??????????
   if(z[30]<0.01) z[30]=0.01;

/* average sunlit leaves */
	if (z[31]<0.01)
		z[32]=0;
	else
		z[32]=2*z[31]*(1-exp(-0.5*omega*lai_p/z[31]));   //��Ҷlai  z[31]: ƽ��̫���춨������

/* average shaded leaves */
    z[33]=lai_p-z[32];                    //��Ҷlai

/* daily averaged radiation for sunlit and shaded leaves */
    gpurad_ssl(z[9],z[31],z[10],lc_p,omega,&ssun,&sshade);     //z[10]:��LAI ��Z[31]��ƽ��̫���춨������
	z[34]=ssun;      //�վ���Ҷ̫������
    z[35]=sshade;    //�վ���Ҷ̫������

// printf ("z[9]=%f z[31]=%f z[10]=%f omega=%f &ssun=%f &sshade=%f\n", z[9], z[31], z[10], omega, &ssun, &sshade);

/*  radiation for sunlit and shaded leaves at noon*/
    gpurad_ssl(z[9]*PI/2,z[30],z[10],lc_p,omega,&ssun,&sshade); 
	z[36]=ssun;            //������Ҷ��̫������
    z[37]=sshade;          //������Ҷ��̫������  ??????????????����Ҷ�����䣨���棩�к�����
	

// understory lai
	switch(lc_p)
	{

/************** for LCTM, July*   //���²�lai**********/
	case 1:  case 3:            // conifer  //for umd ,zhoulei 4.1
		lai_u=1.175*exp(-0.991*z[10]);            //���²�lai
       	break;	

	case 2:  case 4:         //broad leaf forest  //EBF & DBF ;zhoulei 4.1
		lai_u=1.5;
       	break;

	case 5:                             // mixed between conifer and broadleaf //mixed forest;zhoulei 4.1
		lai_u=0.5*(1.5+1.175*exp(-0.991*z[10]));
		break;	

	default:
		lai_u=0.0;

  	}
lai_u=0.05;

	// net shortwave radiation calculation
	gpunet_shortwave(z[9],z[31],z[10],lc_p,omega,&ssun,&sshade,lai_u,&n_ssun,&n_sshade,&n_sunder,&n_sground);

	// net longwave radiation calculation

	// z[14]: daytime average temperature
	gpunet_longwave(lai_p,lai_u,omega,es,(z[14]+275.0),&m_lnet_o,&m_lnet_u,&lnet_g);
	z[38]=n_ssun+m_lnet_o;           //��Ҷ̫��������
	//net shortwave radiation for sun lit leaves + mean longwave radiation for overstory 
	z[39]=n_sshade+m_lnet_o;         //��Ҷ������
	//net shortwave radiation for shaded lit leaves + mean longwave radiation for overstory 
	z[40]=n_sunder + m_lnet_u;        //���²�ľ�����
	//net shortwave radiation for understory +  mean longwave radiation for understory
	z[41]=n_sground + lnet_g;           //����ľ�����
	//net shortwave radiation for gound + net longwave radiation for ground
	z[42]=lai_u;                     //���²�Ҷ���ָ��
	

    return;
}

__device__ int gpurad_ssl(float sg, float cos_theta,  float lai_p, int short lc_p,float omega,float *ssun,float *sshade)
{		   
    float theta_avg; 	 	 // Mean cos(thita) 
    float s0;			     // solar constant (=1367 W m-2)
    float rr;			     // ratio of sdif_over to sg
    float sdir;		         // direct radiation W m-2 */
    float sdif_over;		 // diffusive radiation over plant canopy 
    float sdif_under;		 // diffusive radiation under plant canopy
    float c;			     // radiation from multiple scattering

/************* calcuate sdir and sdif_over ********************/

    s0=1367;

    if (cos_theta<0.01)
	{
		sdif_over=0;
		sdir=0;
	}
	else
	{
		rr=sg/(s0*cos_theta);                 // �ж�ָ��
		
                                                   //ֱ��
/*
		if(lc_p==1 || lc_p==7 || lc_p==8){
     	sdif_over=sg*(0.7327+3.8453*rr-16.31*pow(rr,2)+18.96*pow(rr,3)-7.0802*pow(rr,4)); 	//ɢ��	
        if(sdif_over>sg) sdif_over=sg;	
		sdir=sg-sdif_over;                                                     //ֱ��
		}

		else{
		if (rr>0.8) sdif_over=0.13*sg;
		else
			sdif_over=sg*(0.943+0.732*rr-4.9*pow(rr,2)+1.796*pow(rr,3)+2.058*pow(rr,4)); 	//ɢ��	
		sdir=sg-sdif_over;  

		}
		*/
		if (rr>0.75) sdif_over=0.15*sg;      //2018-01-26�ģ�if (rr>0.8) sdif_over=0.13*sg;  
		else
			sdif_over=sg*(0.943+0.732*rr-4.9*pow(rr,2)+1.796*pow(rr,3)+2.058*pow(rr,4)); 	//ɢ��	
		sdir=sg-sdif_over;  


		//sdif_over=sg*1.0/(1+exp(-3.98+8.05*rr)); 	//ɢ��	
		//if(sdif_over>sg) sdif_over=sg;	
		//sdir=sg-sdif_over;                                                     //ֱ��

	}
		
/************* calculate ssun and sshade ***********************/

/* radiation from multiple scattering */
	//c=0.07*omega*sdir*(1.1-0.1*lai_p)*exp(-cos_theta);     //���ɢ��    //2013-08-27��  
	c=0.07*omega*sdir*(1.1-0.1*lai_p)*exp(-cos_theta);     //���ɢ��    //2013-08-27��  

	
	
	
	/* sdif_under */
    theta_avg=0.537+0.025*lai_p;
    sdif_under=sdif_over*exp(-0.5*omega*lai_p/theta_avg);    //���²�ɢ��
	
/* radiation for shaded leaves, X.F., Sep 2003 */
   // if ((lai_p<0.01) && (sdif_over-sdif_under)<0)
    if ((lai_p<0.01) && (sdif_over-sdif_under)<=0)      //lai_p��Ҷ���
		*sshade=0;
	else	
		*sshade=(sdif_over-sdif_under)/lai_p+c;

/* radiation for sunlit leaves */
    if (cos_theta <0.01)
		*ssun=0;
	else
		*ssun=0.5*sdir/cos_theta +*sshade;         //��1999����



    return 1;             //???????????????????????????????????
}

__device__ int gpunet_shortwave(float sg,float cos_theta,float lai_p, int short lc_p,
								float omega,float *ssun,float *sshade,float lai_u, float *n_ssun,float *n_sshade,float *n_sunder,float *n_sground)		 

{		   
    float theta_avg; 		 // Mean cos(theta) 
    float s0;			     // solar constant (=1367 W m-2)
    float rr;			     //ratio of sdif_over to sg 
    float sdir;		         // direct radiation W m-2
    float sdif_over;		 // diffusive radiation over plant canopy
    float sdif_under;		 // diffusive radiation under plant canopy
    float c;			     // radiation from multiple scattering
	float c_for_net;
	float alpha_l=0.25;
	float alpha_g=0.2;
	float theta_avg_under;  // Mean cos(theta) for understory  

//************* calcuate sdir and sdif_over ********************

    s0=1367;

    if (cos_theta<0.01)
	{
		sdif_over=0;
		sdir=0;
	}
	else
	{
		rr=sg/(s0*cos_theta);
/*
		if(lc_p==1 || lc_p==7 || lc_p==8){
			sdif_over=sg*(0.7327+3.8453*rr-16.31*pow(rr,2)+18.96*pow(rr,3)-7.0802*pow(rr,4)); 	//ɢ��	
			if(sdif_over>sg) sdif_over=sg;	
			sdir=sg-sdif_over;                                                     //ֱ��
		}

		else{
			if (rr>0.8) sdif_over=0.13*sg;
			else
				sdif_over=sg*(0.943+0.732*rr-4.9*pow(rr,2)+1.796*pow(rr,3)+2.058*pow(rr,4)); 	//ɢ��	
			sdir=sg-sdif_over;  
		}
		*/

		if (rr>0.75) sdif_over=0.15*sg;     //2018-01-26�ģ�if (rr>0.8) sdif_over=0.13*sg; 
		else
			sdif_over=sg*(0.943+0.732*rr-4.9*pow(rr,2)+1.796*pow(rr,3)+2.058*pow(rr,4)); 	//ɢ��	
		sdir=sg-sdif_over;  

		
		
		
		
		/*
		sdif_over=sg*1.0/(1+exp(-3.98+8.05*rr)); 	//ɢ��	
		if(sdif_over>sg) sdif_over=sg;	
		sdir=sg-sdif_over;                                                     //ֱ��
  */ 
	}
		
/************* calculate ssun and sshade ***********************/

/* radiation from multiple scattering */
	c=0.07*omega*sdir*(1.1-0.1*lai_p)*exp(-cos_theta);
	
/* sdif_under */
    theta_avg=0.537+0.025*lai_p;
    sdif_under=sdif_over*exp(-0.5*omega*lai_p/theta_avg);
	
 
/* radiation for shaded leaves  X.F. Sep 2003*/
    // if ((lai_p<0.01 ) && (sdif_over-sdif_under)<0)
	if ((lai_p<0.01 ) && (sdif_over-sdif_under)<=0)
        
		*sshade=0.0;
	else	
		*sshade=(sdif_over-sdif_under)/lai_p+c;

 

/* radiation for sunlit leaves */
    if (cos_theta <0.01)
		*ssun=0.0;
	else
		*ssun=0.5*sdir/cos_theta +*sshade;
 
	
/* net short radiation for shaded leaves, X.F., Sep 2003 */
	c_for_net=alpha_l*omega*sdir*(1.1-0.1*lai_p)*exp(-cos_theta);;      //??????????????????????????????
     //if ((lai_p<0.01) && (sdif_over-sdif_under)<0.0)
      if ((lai_p<0.01) && (sdif_over-sdif_under)<=0.0)   //X.F. Sep 2003
		*n_sshade=0;
	else	
		*n_sshade=(sdif_over-sdif_under)/lai_p+c_for_net;       //????????????????????????��sshade/?????????????

/* net short radiation for sun lit leaves */
	*n_ssun=(1-alpha_l)**ssun + *n_sshade;
  
/* net short radiation for understory */

    if(cos_theta<0.05) cos_theta=0.05;   //==========================================================JUW 2013_06_16===================================================

	*n_sunder=(1-alpha_l)*(sdir*exp(-0.5*omega*lai_p/cos_theta)+sdif_under);
   
	
	if(*n_sunder<0)*n_sunder=0;



/* net short radiation for ground */
	theta_avg_under=theta_avg=0.537+0.025*lai_u;
	*n_sground=(1-alpha_g)*(sdir*exp(-0.5*omega*(lai_p+lai_u)/cos_theta)+sdif_under*exp(-0.5*omega*lai_u/theta_avg_under));
    if(*n_sground<0) *n_sground=0;
	
	// printf("*n_sground=%f \n", *n_sground);
    return 1;
}

__device__ int gpunet_longwave(
	float lai_o,
	float lai_u,
	float omega,
	float es,
	float ta,
	float *m_lnet_o,
	float *m_lnet_u,		             
	float *lnet_g)			             
{
	float sigma;			             //Stefan-Boltzmann constant =5.67*10^(-8) W m^-2 K^-4
	float epsilon_a, epsilon_o,epsilon_u,epsilon_g;
	float to,tu,tg;		             //temperature, in K
	float l_a,l_o,l_u,l_g;				 // longwave radiation
	float r_ctheta_o, r_ctheta_u;       //representive zenith angle
	float exponent_o, exponent_u;
	float lnet_o, lnet_u;

	sigma=5.67/100000000;

	epsilon_o=0.98;
	epsilon_u=0.98;
	epsilon_g=0.95;
//	epsilon_a=1.24*pow(((es)/ta), (1.0/7.0));  // es in mbar, ta in K
epsilon_a=1.72*pow(float((es)/ta), float(1.0/7.0));  // es in kpa, ta in K

	to=ta;	                              // in K
	tu=ta;
	tg=ta;

	// longwave radiation
	l_a=epsilon_a*sigma*pow(ta,(float)4.0);   //air
	l_o=epsilon_o*sigma*pow(to,(float)4.0);    //overstorey
	l_u=epsilon_u*sigma*pow(tu,(float)4.0);    //understorey
	l_g=epsilon_o*sigma*pow(tg,(float)4.0);     //ground
	
	// represntive angle
	r_ctheta_o=0.573+0.025*lai_o;
	r_ctheta_u=0.573+0.025*lai_u;

	exponent_o=exp(-0.5*lai_o*omega/r_ctheta_o);
	exponent_u=exp(-0.5*lai_u*omega/r_ctheta_u);

	//net longwave radiation
	lnet_o=(l_a + l_u* (1-exponent_u) + l_g* exponent_u - 2*l_o)*(1-exponent_o);
	lnet_u=(l_a*exponent_o + l_o* (1-exponent_o) + l_g - 2*l_u)*(1-exponent_u);
	*lnet_g=(l_a*exponent_o + l_o* (1-exponent_o))*exponent_u + l_u*(1-exponent_u) - l_g ;

	if (lai_o>0.01) *m_lnet_o =lnet_o/lai_o;
		else *m_lnet_o=0.0;
	if (lai_u !=0) *m_lnet_u = lnet_u/lai_u;
		else *m_lnet_u=0.0;


	return 1;
}