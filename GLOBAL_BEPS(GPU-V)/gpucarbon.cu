/*************************************************************************
  Program:     carbon.c
  --------
  Description:
  ----------- 
	Estimate photosythesis and plant respiration.
  Details:
  -------	
 	Use Farquhar's model for photosynthesis calculation
	Input:
	b[25]: Q10 for leaf
	b[28]: Q10 for stem	
	b[29]: Q10 for root	

	b[19]: leaf maintenance res. coe 
	b[20]: stem maintenance res. coe  	
	b[21]: coarse root maintenance res. coe
	b[24]: fine root maintenance res. coe 
	x[8]: leafC
	x[9]: stemC
	x[10]: rootC
	z[4]:Tmax
	z[5]:Tmin
	z[10]: LAI	
	z[14]: daylight average temperature
	z[18]: daylength
	Output
	g[25]: leaf Rm(forest) or total Rm (other land cover) in kg C/m2/day
	g[30]stem Rm     //zfm
***************************************************************************
  CCRS (EMS/Applications Division)
  Wrintten by: 	J. Liu
  Modified by:  X.F. Feng
  Last update:  July 2003
*****************************************************************************/
#ifndef   MY_H_FILE      
#define   MY_H_FILE       
#include "gpubeps.cuh"
#endif 

//#include "beps.h" 

/*float max(float a,float b)
{
	if (a>b)
		return a;
	return b;
}*/
__device__ void gpucarbon(float CNl,long index,float b[],float g[],float x[],float z[],float co,float TI)
{
  float exponent,exponent_n,ratio_d;    //ratio_d_n; ���쳤�ȱ�����
//  float sapw_max=0.1;	
  float rf25, pr;		              /* for Rm with Bonan (1995) */
  int short lc_p;
//  float ratio_froot=1;
 
  float tb=15;                       //��������Ĳο��¶� 
//  float a=0.0;
  float a1,a2;
   float Gsunlit_o, Gshaded_o, Gsunlit_n, Gshaded_n, slope, D0;
int jj;

float cs1,cs2,cbl,cc;

  //JUW  2017-10-15  ��  
//b[25]=b[25];
//b[28]=b[28];
//b[29]=b[29];
a2=z[45];
if(a2<0) a2=0;
/*
 b[25]=2.62-0.023*a2;
 b[28]=2.52-0.046*a2;
 b[29]=2.52-0.046*a2;
*/
/*
b[25]=2.42-0.03*a2;

if(b[25]<1.9) b[25] =1.9;



b[28]=2.32-0.03*a2;
if(b[28]<1.8)b[28]=1.8;

b[29]=2.32-0.03*a2;

if(b[29]<1.8) b[29]=1.8;
*/

 
b[25]=2.42-0.02*a2;

if(b[25]<1.9) b[25] =1.9;


b[28]=2.32-0.02*a2;
if(b[28]<1.80)b[28]=1.80;

b[29]=2.32-0.02*a2;

if(b[29]<1.80) b[29]=1.80;
 

if (index==1) {
 
// RESPIRATION	����

	//===========================================================����һ���ƽ���������=======================================================

	if(z[23]==13) slope=8; 
	else          slope=10; 
    D0=0.005;


/*
slope=12.7-0.207*z[14];
if(slope>10) slope=10;
if(slope<6.9) slope=6.9;
 

slope=10;

D0=(142.4-4.8*z[14]);
if(D0>80) D0=80;
if(D0<8)  D0=8;
*/

    for(jj=1;jj<=5;jj++){
	gpufarq_psn(CNl,b,z,g,co);    

  //���׵���:umol/ m2/s  //mol m2/s
	//Gsunlit_o=slope*g[28]*g[80]/co/(1.0+z[16]/D0)+0.001; //z[16]:VPD(0.1kPa"     
   // Gshaded_o=slope*g[29]*g[80]/co/(1.0+z[16]/D0)+0.001; //z[16]:VPD(0.1kPa"



	Gsunlit_o=slope*g[28]*g[80]*z[46]/co+D0; //z[16]:VPD(0.1kPa"     
	Gshaded_o=slope*g[29]*g[80]*z[46]/co+D0; //z[16]:VPD(0.1kPa"



 //���׵���:m/s
	cs1=Gsunlit_o*8.314*(z[14]+273.14)/101350;   
			
	cs2=Gshaded_o*8.314*(z[14]+273.14)/101350;
	

	cbl=0.08;
	// leaf cuticular conductance 
	cc=0.00005;

	g[20] =cbl*(cc+cs1)/(cbl+cc+cs1);   //��Ҷ                   //2013��9��11�ոģ� ԭ������ѹ�Ͳ���

	g[21] =cbl*(cc+cs2)/(cbl+cc+cs2);   //��Ҷ     //�øù�ʽ�� �� 

}

 


    //һ���GPP  //convert umol C/m2/s --> kg C/m2/period ��λת����
    //z[32]: Sunlit LAI; z[33]: Shaded LAI, z[18]: һ����ճ���
	
    g[24] = (g[28]*z[32]+g[29]*z[33])*z[18]*12.0/1000000000.0;
   //========================================================================================================================================

	//leaf day time maintenance respiration //a equation below can overwrite this one  
	x[8]= z[10]/b[1];
	
	
	exponent=(z[14]-tb)/10.0;         //z[14] �����¶�
    exponent_n=(z[15]-tb)/10.0;       //z[15] ҹ���¶�   
    ratio_d=z[18]/86400;              //�����ճ���ռһ��ı���


	//g[23] =x[8]*b[19]*pow(b[25],exponent);//*z[18]/86400;   //Ҷ����ά���Ժ���

//g[23] =x[8]/1000.0*b[19]*pow(b[25],exponent);//*z[18]/86400;   //Ҷ����ά���Ժ���

g[23]=0.0;

	if(g[23]<0.0)  g[23]=0.0;
//Rm calculation, Bonan (1995), z[10]: LAI; z[4]: Tmax; z[5]:Tmin 

	lc_p=( int short)z[23];    //�ر�������
	switch(lc_p)
	{
	case 4: case 10://Evergreen needle forest, ������Ҷ��
	{
		//x[8]= z[10]/b[1];      //����LAI��SLA�õ��ڲ�������     //2013-08-13
		
	     //leaf night time maintenance respiration, ����ҶƬ��ά���Ժ���
	 
		//b[19],�ο��������ʣ���Readb();b[25]: Q10: ��read_init�и���
		
		g[25] =0.45*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));  //2018-04-25: 0.4 to 0.45
		
      //  g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);
       if(g[25]<0.0) g[25]=0.0; 

		//stem maintenance respiration�����ɺ���
    
		//x[9],�߲�ľ����������model(); b[20]���ο���������,��readb()��b[28],Q10,��read_init();
		//exponent=(z[15]-tb)/10.0;
	 	//g[30] = x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���
		
		g[30] =0.45*x[42]/1000.0/(0.4+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d)); //2018-04-25: 0.4 to 0.45
		
	//	g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
			
        // g[30]=__max(g[30],0.0);
        if(g[30]<0.0) g[30]=0.0;

		// root maintenance respiration  
		//exponent=(z[15]-tb)/10.0;
		
		//ratio_froot=exp(1.007)*pow(x[10],(float)-(0.841));
		//ratio_froot=__min(0.9, ratio_froot);
				
			 
	  //g[31]=0.05*x[10]*(1-ratio_froot)*b[21]*pow(b[29],exponent);		//coarse root  
      // g[31]=x[10]*(1-ratio_froot)*b[21]*pow(b[29],exponent);		//coarse root  
	
		g[31]=0.04*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		// //2018-04-25: 0.04 to 0.045
       g[31]=g[31] +0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	       //  //2018-04-25: 0.04 to 0.045
	 
	   //g[31]=g[31]+x[10]*ratio_froot*b[24]*pow(b[29],exponent);	// coarse + fine root */
       	  
	//����Ҷ������������ϸ����������b[24], �ο��������ʣ�b[29]: Q10	
	  //  g[31]=x[8]*0.8*b[24]*pow(b[29],exponent);//fine root respiration, ϸ���������� //2011��8��30�ս�����1.3 ��Ϊ1.1, ԭ����������̫��
	
		//g[31] = __max  (g[31], 0.0);  
		if(g[31]<0.0)  g[31]=0.0;
	}
	break;

	case 1:case 7: case 8: //Evergreen broadleaved forest, ������Ҷ��
	{
	//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;   //2014-09-12 0.6 to 0.8
		//  g[25] = 0.5*x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		
		//g[25] = __max( g[25], 0.0);
           if(g[25]<0.0) g[25]=0.0;

		/* stem maintenance respiration */

    	//exponent=(z[15]-tb)/10.0;
	
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2
		
	   	g[30] =0.4*x[42]/1000.0/(0.4+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�    //2014-09-12 0.75 to 0.9
		
      //  g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
        if(g[30]<0.0) g[30]=0.0;

        /* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		/*g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root 
		g[31] = __max  (g[31], 0.0); 
          */
 
      g[31]= 0.1*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13                                              //2014-09-12 0.05 to 0.1                              
   	  g[31]=g[31] +0.1*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));// coarse + fine root  ///2013-08-13
      if(g[31]<0.0)  g[31]=0.0;

	}
	break;

	case 5: //Deciduous needleleaved forest,   
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		//g[25] = __max( g[25], 0.0);
      if(g[25]<0.0) g[25]=0.0;

		/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent); //test2
		
		g[30] =0.5*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
	//	g[30] = __max( g[30], 0.0);

if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
	 	/*g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root 
		g[31] = __max  (g[31], 0.0); 
          */

      g[31]=  0.05*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.05*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
       if(g[31]<0.0)  g[31]=0.0;
	
	}
   	break;

	case 2: case 3://DBF����Ҷ��Ҷ��
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);

if(g[25]<0.0) g[25]=0.0;

	/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent); //test2
		
		g[30] =0.45*x[42]/1000.0/(0.45+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
	
        //g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		//g[30] = __max( g[30], 0.0);

if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */

		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	//1 fine root  
		g[31] = __max  (g[31], 0.0); 
         */
     
	  g[31]=  0.05*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.05*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
	}
	break;

	case 6: case 9: //MF mixed forest���콻��
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);
if(g[25]<0.0) g[25]=0.0;
		/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent);
		
		
	    g[30] =0.70*x[42]/1000.0/(0.70+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
			
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
	//	g[30] = __max( g[30], 0.0);
       if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */

		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root  
		g[31] = __max  (g[31], 0.0); 
           */
      g[31]=  0.04*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
	}
	break;
 
case 11:case 12:case 14: //  shrubland�� ��ľ
	{
		/* leaf carbon = LAI/SLA */ 

		//x[8]= z[10]/b[1];

		/* leaf night time maintenance respiration */
		
		g[25] =2.0*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		//g[25] = __max( g[25], 0.0);

    if(g[25]<0.0) g[25]=0.0;

/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
	   // g[30] = x[9]*b[20]*pow(b[28],exponent);
		
		 g[30] =2.0*0.5*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		
	     //g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
		//g[30] = __max( g[30], 0.0);
       if(g[30]<0.0) g[30]=0.0;
		/* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	//fine root  
		g[31] = __max  (g[31], 0.0);  
            */

      g[31]=2.0*  0.04*x[44] /1000.0*b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	        //*coarse root   //2013-08-13
      g[31]=g[31] +2.0*0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
    	}
	break;

case 13 ://grassland�� �ݵ�
	{
      		
		g[25] =1.6*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

        g[30] =1.6*x[44]/1000.0*b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;



	}
	break;

case 16: case 17: case 18: //Zfm3.25 12,14://cropland
	{

		g[25] =2.0*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;   //Leaf 

        g[30] =2.0*x[42]/1000.0*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;   //steam
	
		g[31] =2.0*x[44]/1000.0*b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;


		//g[30] =1.4*0.35*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		//if(g[30]<0.0) g[30]=0.0;


	}
    break;

	default:                              	/* other land cover types */
	{
	

         exponent=(z[15]-tb)/10.0;
		g[25] =0.45*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

		g[30] =0.35*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		if(g[30]<0.0) g[30]=0.0;

	}

	}
	
  //a1 =g[24]*0.75-1.0*(g[25]*0.85+g[30] +g[31] );  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������    //2018-05-17

 
   a1 =g[24]*0.75-1.0*(g[25]+g[30] +g[31] );  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������    //201308011



  a2= a1/g[24];

  if(a2<0.35)      a2=0.35;
  else if(a2>0.65) a2=0.65;


  g[26]=g[24]*a2;
	
 
}  //==========================================================================the end of index==1===========================================

else { //----------------------------------------------------------------------------index=0;

/*
gpufarq_psn(CNl,b,z,g,co);    

g[24] = (g[28]*z[32]+g[29]*z[33])*z[18]*12.0/1000000000.0;

a2=0.5;
  g[26]=g[24]*a2;

*/



// RESPIRATION	����

	//===========================================================����һ���ƽ���������=======================================================
/*
	if(z[23]==13) slope=6; 
	else          slope=8; 


	 D0=1.35+z[45]*0.007;                                  // D0=1.25+z[45]*0.025;
	if(D0<1.35) D0=1.35; 
     D0=D0*10.0;


	slope=12.7-0.207*z[14];
	if(slope>10) slope=10;
	if(slope<6.9) slope=6.9;

slope=10;

	D0=(142.4-4.8*z[14]);
	if(D0>80) D0=80;
	if(D0<8)  D0=8;
*/

	if(z[23]==13) slope=8; 
	else          slope=10; 
	D0=0.005;



	 for(jj=1;jj<=5;jj++){

	gpufarq_psn(CNl,b,z,g,co);    

  //���׵���:mol/ m2/s
	//Gsunlit_o=slope*g[28]*g[80]/co/(1.0+z[16]/D0)+0.001; //z[16]:VPD(0.1kPa"     
   // Gshaded_o=slope*g[29]*g[80]/co/(1.0+z[16]/D0)+0.001; //z[16]:VPD(0.1kPa"



	Gsunlit_o=slope*g[28]*g[80]*z[46]/co+D0; //z[16]:VPD(0.1kPa"     
	Gshaded_o=slope*g[29]*g[80]*z[46]/co+D0; //z[16]:VPD(0.1kPa"


	//Rg=8.314 UNIT: m3 Pa/mol/k.

 //���׵���:m/s/PA
	cs1=Gsunlit_o*8.314*(z[14]+273.14)/101350;   
			
	cs2=Gshaded_o*8.314*(z[14]+273.14)/101350;
	

	cbl=0.08;
	// leaf cuticular conductance 
	cc=0.00005;

	g[20] =cbl*(cc+cs1)/(cbl+cc+cs1);   //��Ҷ                   //2013��9��11�ոģ� ԭ������ѹ�Ͳ���

	g[21] =cbl*(cc+cs2)/(cbl+cc+cs2);   //��Ҷ     //�øù�ʽ�� �� 

}

 


    //һ���GPP  //convert umol C/m2/s --> kg C/m2/period ��λת����
    //z[32]: Sunlit LAI; z[33]: Shaded LAI, z[18]: һ����ճ���
	
    g[24] = (g[28]*z[32]+g[29]*z[33])*z[18]*12.0/1000000000.0;
   //========================================================================================================================================

	//leaf day time maintenance respiration //a equation below can overwrite this one  
	x[8]= z[10]/b[1];
	
	
	exponent=(z[14]-tb)/10.0;         //z[14] �����¶�
    exponent_n=(z[15]-tb)/10.0;       //z[15] ҹ���¶�   
    ratio_d=z[18]/86400;              //�����ճ���ռһ��ı���


	//g[23] =x[8]*b[19]*pow(b[25],exponent);//*z[18]/86400;   //Ҷ����ά���Ժ���

//g[23] =x[8]/1000.0*b[19]*pow(b[25],exponent);//*z[18]/86400;   //Ҷ����ά���Ժ���

g[23]=0.0;

	if(g[23]<0.0)  g[23]=0.0;
//Rm calculation, Bonan (1995), z[10]: LAI; z[4]: Tmax; z[5]:Tmin 

	lc_p=(int short )z[23];    //�ر�������
	switch(lc_p)
	{
	case 4: case 10://Evergreen needle forest, ������Ҷ��
	{
		//x[8]= z[10]/b[1];      //����LAI��SLA�õ��ڲ�������     //2013-08-13
		
	     //leaf night time maintenance respiration, ����ҶƬ��ά���Ժ���
	 
		//b[19],�ο��������ʣ���Readb();b[25]: Q10: ��read_init�и���
		
		g[25] =0.45*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));  //2018-04-25: 0.4 to 0.45
		
      //  g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);
       if(g[25]<0.0) g[25]=0.0; 

		//stem maintenance respiration�����ɺ���
    
		//x[9],�߲�ľ����������model(); b[20]���ο���������,��readb()��b[28],Q10,��read_init();
		//exponent=(z[15]-tb)/10.0;
	 	//g[30] = x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���
		
		g[30] =0.45*x[42]/1000.0/(0.4+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d)); //2018-04-25: 0.4 to 0.45
		
	//	g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
			
        // g[30]=__max(g[30],0.0);
        if(g[30]<0.0) g[30]=0.0;

		// root maintenance respiration  
		//exponent=(z[15]-tb)/10.0;
		
		//ratio_froot=exp(1.007)*pow(x[10],(float)-(0.841));
		//ratio_froot=__min(0.9, ratio_froot);
				
			 
	  //g[31]=0.05*x[10]*(1-ratio_froot)*b[21]*pow(b[29],exponent);		//coarse root  
      // g[31]=x[10]*(1-ratio_froot)*b[21]*pow(b[29],exponent);		//coarse root  
	   g[31]=  0.04*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		// //2018-04-25: 0.04 to 0.045
       g[31]=g[31] +0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	       //  //2018-04-25: 0.04 to 0.045
	 
	   //g[31]=g[31]+x[10]*ratio_froot*b[24]*pow(b[29],exponent);	// coarse + fine root */
       	  
	//����Ҷ������������ϸ����������b[24], �ο��������ʣ�b[29]: Q10	
	  //  g[31]=x[8]*0.8*b[24]*pow(b[29],exponent);//fine root respiration, ϸ���������� //2011��8��30�ս�����1.3 ��Ϊ1.1, ԭ����������̫��
	
		//g[31] = __max  (g[31], 0.0);  
		if(g[31]<0.0)  g[31]=0.0;
	}
	break;

	case 1:case 7: case 8: //Evergreen broadleaved forest, ������Ҷ��
	{
	//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		exponent=(z[15]-tb)/10.0;
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;   //2014-09-12 0.6 to 0.8
		//  g[25] = 0.5*x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		
		//g[25] = __max( g[25], 0.0);
           if(g[25]<0.0) g[25]=0.0;

		/* stem maintenance respiration */

    	//exponent=(z[15]-tb)/10.0;
	
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2
		
	   	g[30] =0.4*x[42]/1000.0/(0.4+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�    //2014-09-12 0.75 to 0.9
		
      //  g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
        if(g[30]<0.0) g[30]=0.0;

        /* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		/*g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root 
		g[31] = __max  (g[31], 0.0); 
          */
 
      g[31]= 0.1*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13                                              //2014-09-12 0.05 to 0.1                              
   	  g[31]=g[31] +0.1*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	       // coarse + fine root  ///2013-08-13
      if(g[31]<0.0)  g[31]=0.0;

	}
	break;

	case 5: //Deciduous needleleaved forest,   
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		exponent=(z[15]-tb)/10.0;
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		//g[25] = __max( g[25], 0.0);
      if(g[25]<0.0) g[25]=0.0;

		/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent); //test2
		
		g[30] =0.75*x[42]/1000.0/(0.75+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
	//	g[30] = __max( g[30], 0.0);

if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
	 	/*g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root 
		g[31] = __max  (g[31], 0.0); 
          */

      g[31]=  0.05*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.05*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
       if(g[31]<0.0)  g[31]=0.0;
	
	}
   	break;

	case 2: case 3://DBF����Ҷ��Ҷ��
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		exponent=(z[15]-tb)/10.0;
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);

if(g[25]<0.0) g[25]=0.0;

	/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent); //test2
		
		g[30] =0.75*x[42]/1000.0/(0.75+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
	
        //g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		//g[30] = __max( g[30], 0.0);

if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */

		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	//1 fine root  
		g[31] = __max  (g[31], 0.0); 
         */
     
	  g[31]=  0.05*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.05*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
	}
	break;

	case 6: case 9: //MF mixed forest���콻��
	{
		//x[8]= z[10]/b[1];
		/* leaf night time maintenance respiration */
		
		exponent=(z[15]-tb)/10.0;
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 

		//g[25] = __max( g[25], 0.0);
if(g[25]<0.0) g[25]=0.0;
		/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		//g[30] = x[9]*b[20]*pow(b[28],exponent);
		
		
	    g[30] =0.70*x[42]/1000.0/(0.70+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
			
		//g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
	//	g[30] = __max( g[30], 0.0);
       if(g[30]<0.0) g[30]=0.0;

		/* root maintenance respiration */

		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	// fine root  
		g[31] = __max  (g[31], 0.0); 
           */
      g[31]=  0.04*x[44]/1000.0 *b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));		//*coarse root   //2013-08-13
      g[31]=g[31] +0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
	}
	break;
 
case 11:case 12:case 14: //  shrubland�� ��ľ
	{
		/* leaf carbon = LAI/SLA */ 

		//x[8]= z[10]/b[1];

		/* leaf night time maintenance respiration */
		
		exponent=(z[15]-tb)/10.0;
		g[25] =x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

  //g[25] = x[8]*b[19]*pow(b[25],exponent)*(86400.0-z[18])/86400; 
		//g[25] = __max( g[25], 0.0);

    if(g[25]<0.0) g[25]=0.0;

/* stem maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
	   // g[30] = x[9]*b[20]*pow(b[28],exponent);
		
		 g[30] =0.5*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		
	     //g[30] =x[9]*b[20]*pow(b[28],exponent);//test2    //��ά���Ժ���  //2011��7��25�ո�     //20130623��
		
		//g[30] = __max( g[30], 0.0);
       if(g[30]<0.0) g[30]=0.0;
		/* root maintenance respiration */
		//exponent=(z[15]-tb)/10.0;
		/*
		g[31]=x[8]*1.0*b[24]*pow(b[29],exponent);	//fine root  
		g[31] = __max  (g[31], 0.0);  
            */

      g[31]=  0.04*x[44] /1000.0*b[21]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	        //*coarse root   //2013-08-13
      g[31]=g[31] +0.04*x[43]/1000.0 *b[24]*(pow(b[29],exponent)*ratio_d+pow(b[29],exponent_n)*(1-ratio_d));	    // coarse + fine root  ///2013-08-13
     if(g[31]<0.0)  g[31]=0.0;
    	}
	break;

case 13 ://grassland�� �ݵ�
	{
    	
		/*
		rf25=0.4;      //0.5, 0.35 //5.18
		pr=0;      //  0.0   zfm5.14

		/// g[25] is total rm in kg C/m2/day
		//g[25] = 1.0368*(2*z[10])*rf25*(1+pr)*pow(2, 0.1*(0.5*(z[4]+z[5])-25.0))/1000;
	    // g[25] =0.30* 1.0368*(4*z[10])*rf25*(1+pr)*pow(b[28],exponent)/1000;  //2012-10-14��,����0.25    //20130803,ϵ����0.2��Ϊ0.3
		 g[25] =0.25* 1.0368*(4*z[10])*rf25*(1+pr)*pow(b[28],exponent)/1000;  
		g[30]=0.0;
		g[31]=0.0;
    */


		exponent=(z[15]-tb)/10.0;
		g[25] =0.45*x[41]/1000.0*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

		g[30] =0.35*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		if(g[30]<0.0) g[30]=0.0;



	}
	break;

case 16: case 17: case 18: //Zfm3.25 12,14://cropland
	{
       exponent=(z[15]-tb)/10.0;
		g[25] =0.5*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

		g[30] =0.4*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		if(g[30]<0.0) g[30]=0.0;


	}
    break;

	default:                              	/* other land cover types */
	{
	

         exponent=(z[15]-tb)/10.0;
		g[25] =0.45*x[41]/1000.0*b[19]*(pow(b[25],exponent)*ratio_d+pow(b[25],exponent_n)*(1-ratio_d));//*(86400.0-z[18])/86400;

		g[30] =0.35*x[42]/1000.0/(0.5+x[42]/1000.0)*b[20]*(pow(b[28],exponent)*ratio_d+pow(b[28],exponent_n)*(1-ratio_d));//test2    //��ά���Ժ���  //2011��7��25�ո�
		if(g[30]<0.0) g[30]=0.0;

	}

	}
	
  a1 =g[24]*0.75-1.0*(g[25]*0.75+g[30] +g[31] );  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������    //201308011

 
  a2= 0.5;

  g[26]=g[24]*a2;


}
	
/* 24HR. NET C/m2  */
   //	g[26] = 0.75*g[24]-g[25]-g[30]-g[31];  //g[26] �� NPP          //2012-10-14�Ļ�
	
	// g[26] = 0.7*g[24]-(g[25]*1.5+g[30]*4.0+g[31]*1.0)*1.0;  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������ 

  //g[26] = 0.7*(g[24]-(g[25]+g[30]+g[31])*0.8);  //g[26] �� NPP ԭ����

    //g[26] = 0.46*g[24];
	
	
	//g[26] = 0.7*g[24]-(g[25]*1.5+g[30]*4.0+g[31]*1.0)*1.0;  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������ 
	
	//g[26] = 0.75*g[24]-(g[25]*1.8+g[30]*15.0+g[31]*1.0);  //g[26] �� NPP ԭ����   //g[25] Ҷ������ g[30] �� ����   //g[31]������    //20130803
	
	
    return;

   }

__device__ int gpufarq_psn(float CNl, float b[],float z[],float g[],float co)
{
	float pa; 		/* (Pa) atmospheric pressure */
//	float co2;		/* (ppm) atmospheric [CO2] */
	float t,tt;		/* (deg C) air temperature */
	float irad;	/* (umol/m2/s) PAR photon flux density */
	float gg;      /* (m/s) conductance to CO2 */
	float Rd;		/* (umol/m2/s) dark respiration rate  */
//	float lnc;		/* (kg Nleaf/m2) leaf N concentration, area units */
//	float flnr;	/* (kg NRub/kg Nleaf) fraction of leaf N in Rubisco */
	
	float tk;     /* (K) absolute temperature */
	float O2;     /* (Pa) atmospheric partial pressure O2 */ 
	float Ca;     /* (Pa) atmospheric partial pressure CO2 */
	float gamma;  /* (Pa) co2 compensation point, no dark respiration */
	float Kc;     /* (Pa) MM constant for carboxylase reaction */
	float Ko;     /* (Pa) MM constant for oxygenase reaction */
	float act;    /* (umol/kgRubisco/s) Rubisco activity */
	float Vmax;   /* (umol/m2/s) maximum carboxylation velocity */
	float Jmax;   /* (umol/m2/s) maximum rate of electron transport */
	float J;      /* (umol/m2/s) maximum rate of Rubisco regeneration */
	float Av;     /* (umol/m2/s) Rubisco limited assimilation rate */
	float Aj;     /* (umol/m2/s) RuBP regeneration limited assim rate */
	float A;      /* (umol/m2/s) net assimilation rate */
//    float Vmax25;  /* block it, just because the code is change. X.F. July */
    float Nratio;  /* block it, just because the code is change. X.F. July */
     int  short lc_p; /* block it, just because the code is change. X.F. July */
	float kk,aa,bb,cc,dd,ee, term1,term2,term3;  
//lixuansong:ȥ����static
	 float fnr = 7.16;   	/* kg Rub/kg NRub */
	 float Kc25 = 30.0; 		/* (Pa) MM const carboxylase, 25 deg C */ 
	 float q10Kc = 2.1;    	/* (DIM) Q_10 for kc */
	 float Ko25 = 30000.0;   /* (Pa) MM const oxygenase, 25 deg C */
	 float q10Ko = 1.2;   	/* (DIM) Q_10 for ko */
	 float act25 = 3.6;    	/* (umol/mgRubisco/min) Rubisco activity */
	 float q10act = 2.4;  	/* (DIM) Q_10 for Rubisco activity */			
      float ft;
	

	int i;	                    	/* index for sunlit/shaded leaves, 0: sun, 1 shade */			
  	for (i=0;i<=1;i++)
        {

	/* convert w/m2 to umol/m2/s */
	
/*	if (i==0) irad=2.04*z[34]*;
	else 
          irad=2.04*z[35]; 
*/

	if (i==0) irad=4.55*z[34]*0.5;
	else 
          irad=4.55*z[35]*0.5; 


	t = z[14];                                 //Average temperature during day time
	tk = t + 273.15;
	
	if (i==0) gg=g[20];
  	else
	  gg=g[21];

	/* convert conductance from m/s --> umol/m2/s/Pa ����Ҫ��*/ 
	
	gg =gg/1.6 * 1000000 / (8.3143 * tk); 
	
	/* calculate the atomsheric pressure */
	
	pa=100000;

	/* convert atmospheric CO2 from ppm --> Pa */
	
	Ca =co * pa / 1e6;  // zfm4.22  ԭco=360
  	
	/* calculate atmospheric O2 in Pa, assumes 21% O2 by volume */
	
	O2 = 0.21 * pa;

	/* correct kinetic constants for temperature, and do unit conversions */

	Ko = Ko25 * pow(q10Ko, float((t-25.0)/10.0));
	Kc = Kc25 * pow(q10Kc, (float)((t-25.0)/10.0));
	act = pow(q10act, (float)((t-25.0)/10.0));


ft=1.0/(1+exp((-220000+712.0*(t+273.15))/(8.32*(t+273.15)))); 

//2018-06-11: 710 Change to 712   Decrease earlier at high temperatures

//ft=1.0/(1+exp((-215600+700*(t+273.15))/(8.32*(t+273.15)))); 

	/* calculate gamma (Pa), assumes Vomax/Vcmax = 0.21 */

	gamma = 4.02*pow((float)1.75, (float)(t-25)/10);    //compensation point
	 

/**************** Modification according to Bonan ************* */
/********************Modified by X.F. Aug************************/
	lc_p=( int short)z[23];
   
	//Vmax25=b[49];
	//Nratio=b[50];
    
	 Nratio= b[50]/CNl;

     if(Nratio>1.0) Nratio=1.0;
     if(Nratio<0.45) Nratio=0.45;
  


	 Vmax=b[49]*Nratio*act*ft;                                                           //juw

	/**************** End of the modification ********************/

	/* calculate Jmax = f(Vmax) */

	Jmax = 29.1 + 1.64*Vmax;
	
	/* calculate J = f(Jmax, I) */

 //  J = Jmax * irad / (irad + 2.1*Jmax);
	J=0.24*irad/sqrt(1+0.24*0.24*irad*irad/Jmax/Jmax);   //F.Ian Woodward   Global Biogeochemical Cycles, 1995,9(4):471-490,����11
	/* Rd */

  	Rd=0.015*Vmax;
	g[23]=Rd*z[18]*12.01;

/***************** With daily integration *****************************/ 
	kk=Kc*(1+O2/Ko);
  
/* Av */   
	Av=0;

    	aa = (kk+Ca)*(kk+Ca);
    	bb = 2*(2*gamma+kk-Ca)*Vmax+2*(Ca+kk)*Rd;
    	cc = (Vmax-Rd)*(Vmax-Rd);

     	if (aa>0 && cc>0)
        {
	dd = sqrt(aa*gg*gg+bb*gg+cc);
	ee = (bb*bb-4*aa*cc)/(8*aa*sqrt(aa));

	term1=sqrt(aa)*gg*gg/2+sqrt(cc)*gg;
	term2=((2*aa*gg+bb)*dd-bb*sqrt(cc))/(4*aa);
	term3=ee*(log(2*aa*gg+bb+2*sqrt(aa)*dd)-log(bb+2*sqrt(aa)*sqrt(cc)));

	if (gg!=0) Av=0.5*1.27*(term1-term2+term3)/gg;

	}

/* Aj */
 	Aj=0;
    
    	aa = (2.33*gamma+Ca)*(2.33*gamma+Ca);
    	bb = 0.4*(4.3*gamma-Ca)*J+2*(Ca+2.33*gamma)*Rd;
    	cc = (0.22*J-Rd)*(0.22*J-Rd);

      	if (aa>0 && cc>0)
        {
	dd = sqrt(aa*gg*gg+bb*gg+cc);
	ee = (bb*bb-4*aa*cc)/(8*aa*sqrt(aa));

	term1=sqrt(aa)*gg*gg/2+sqrt(cc)*gg;
	term2=((2*aa*gg+bb)*dd-bb*sqrt(cc))/(4*aa);
	term3=ee*(log(2*aa*gg+bb+2*sqrt(aa)*dd)-log(bb+2*sqrt(aa)*sqrt(cc)));

	if (gg!=0) Aj=0.5*1.27*(term1-term2+term3)/gg;

	}

	/* calculate A as the minimum of (Av,Aj) */
	if (Av < Aj) A = Av; 
	else         A = Aj;

	/* primary output */
	 
if(A<0) A=0;                            //JUW-2013-10-31 Very important

	if (i==0) g[28]=A;
	else g[29]=A;
   
		
   }
   return 1;
 }	

