/*************************************************************************
  Program:     doflux.c
  --------
  Description:
  ----------- 
	Calculate and update the fluxes in carbon and water cycles.
***************************************************************************
  CCRS (EMS/Applications Division)
  Written by:   J. Liu      
  Last update:	December 2000
*****************************************************************************/
	 
#ifndef   MY_H_FILE      
#define   MY_H_FILE       
#include "gpubeps.cuh"
#endif 


   __device__ void gpudoflux(float CNl,int long pix,long index,float b[],float g[],float x[],float z[],
                              float co, float TI,float soilw1,float soilw2,float soilw3, struct hy_c1 HY1[],struct hy_c2 HY2[], struct hy_c3 HY3[],
                               float *soilwn1,float*soilwn2,float*soilwn3)
    {          
   float aa,bb,B[5],K[5],Psi[5],depth[5],kk[5];
   float soilw_in=0, theta_o[5],theta_n1,theta_n2,theta_n3,ET=0;
   float rr[4],rrr[4],x22_old,x21_old;
    float rrr1,rrr2,rrr3;
    float baita; //��ϵ�ڲ�ͬ������ı仯�ٶ�   // 2013-7-20��Ϊ0.96  // 2013-9-17��Ϊ0.95
    float depth3;
    float AT,ratio; 

	if (z[23]==13 || z[23]==16 || z[23]==17 || z[23]==18 ) {  //13 �ݵأ� 16��17��18Ϊũ��
     baita=0.93; depth3=0.6;
	 } 
	else if (z[23]==1 || z[23]==7 || z[23]==8  ) {  //������Ҷ��
    baita=0.965;
	depth3=4.0;                                                            //2018-3-1: 5.0 ��Ϊ3.0
	 

	
	} 
    else if (z[23]==2 || z[23]==3   ) {  //��Ҷ��Ҷ��
     baita=0.96; depth3=1.5;   //2014-08-19 ��2.0 ��Ϊ1��0 
	 } 

    else if (z[23]==5   ) {  //��Ҷ��Ҷ��
     baita=0.96; depth3=1.0;
	 } 
     else if (z[23]==6 || z[23]==9 ) {  //�콻��
     baita=0.96; depth3=1.0;
	 } 

     else if (z[23]==10 ) {  //������Ҷ��
     baita=0.965; depth3=1.5;   //2014-08-19 ��2.0 ��Ϊ1��0 
	 } 
 
	 else if (z[23]==4 ) {  //������Ҷ��
		 baita=0.96; depth3=1.0;   //2014-08-19 ��2.0 ��Ϊ1��0 
	 } 



     else if (z[23]==11 || z[23]==12 || z[23]==14) {  //��ľ
     baita=0.955; depth3=1.5;  //2014-08-19 ��2.0 ��Ϊ1��0 
	 } 
    else {
    baita=0.955; depth3=1.5;  //2014-08-19 ��2.0 ��Ϊ1��0 
    }


depth[0]=depth1+depth2+depth3;       
depth[1]=depth1;  depth[2]=depth2;   depth[3]=depth3;  //�����������

//��ϵ�ķֲ�����, baita ȡСֵ����ϵ�ֲ�����ȼ�С��

rr[1]=1-pow(baita, depth[1]*100);
rr[2]=pow(baita, depth[1]*100)-pow(baita, (depth[1]+depth[2])*100);
rr[3]=1.0-rr[1]-rr[2];

//����B 
Psi[1]=HY1[pix].SP;  Psi[2]=HY2[pix].SP; Psi[3]=HY3[pix].SP;

B[1]  =HY1[pix].B;     B[2]=HY2[pix].B;    B[3]=HY3[pix].B;

K[1]  =HY1[pix].K;     K[2]=HY2[pix].K;    K[3]=HY3[pix].K;

if(z[4]<-2.0) {   //JUW20180125
kk[1]=K[1] *0.5; 
kk[2]=K[2] *0.5;
kk[3]=K[3] *0.5;
}
else{
	kk[1]=K[1]; 
	kk[2]=K[2];
	kk[3]=K[3];
}



   x[21]=soilw1;
   x[22]=soilw2;
   x[23]=soilw3;
   b[34]=HY1[pix].WP;//0.12; ��ήϵ��	        
   b[35]=HY1[pix].FC;//0.35; ����ˮ��	 
   b[36]=HY1[pix].PR;//0.52;    


//  resistance 
//	ra(b, g, x, z); 
	if( z[23]==16 && z[23]==17  && z[23]==18 || z[23]==13) g[40]=1.0/30.0;   //�����߽���迹ȡ����
	else	g[40]=1.0/5.0; 





//  canopy interception  
    gpuinter(b, g, x, z);    

//  snowmelt routine  
     gpumelt (b, g, x, z);

	 gpurs(pix,b, g, x, z,rr,&rrr1,&rrr2,&rrr3,TI,HY1,HY2,HY3);  //���������迹

	 //rsoil(b, g, x, z); 
                                                
	 gpucarbon(CNl,index,b, g, x, z,co,TI); //����GPP��NPP
   
// Penman - Monteith estimate of transpiration, overstory  
	g[16]=		gpupenmon(z[14],z[16],z[38],g[40],g[20])*z[32]; //��Ҷ��������
	g[16]=g[16]+gpupenmon(z[14],z[16],z[39],g[40],g[21])*z[33]; //��Ҷ��������
  
// �ڲ���������canopy transpiration  
	 g[17] = g[16]* z[18];

     //g[17]=__max(0,g[17]);  g[17]=__min(100,g[17]);
 if(g[17]<0.0 )   g[17]=0.0;
  if(g[17]>100.0)   g[17]=100.0;



// Penman - Monteith estimate of evaporation from soil  
	// if snowpack>0 or snow/ice area  evp_soil=0  
	if((z[14]<0) || (z[23]==31)) g[12]=0.0;
	else g[12]= z[18]*gpupenmon(z[14],z[16],z[41],0.5*g[40],g[41]);        //2012-10-15��Ϊ0.5*g[40];  
  
// Urban area 
	if (z[23]==13) g[12]=0.8*g[12];
	 // g[12]=__max(0,g[12]);
    if(g[12]<0.0)  g[12]=0.0;

	
// Penman - Monteith estimate of evaporation from understory  
// if LAI_u z[42]=0, temperature z[14]<0 or  ice z[23]=31, trans_under=0  
	if( ((z[14]<0) || (z[23]==31)) || z[42]==0) g[19]=0.0;
	else g[19]=z[18]*gpupenmon(z[14],z[16],z[40],g[40],g[19]);
	 
	
	//g[19]=__max(0,g[19]);   g[19]= __min(10,g[19]);
	
if(g[19]<0.0001) g[19]=0.0001;  
if(g[19]>100.0)  g[19]=100.0;

	//g[19]=0;// z[18]*penmon(z[14],z[16],z[40],g[40],g[19]); 
  
// ********** Water update ***************** 

//  snow = snow + ground snow + snow from canopy - melt - sublimation  
    x[1] = x[1] + g[2]+ g[7] - g[3]- g[13]; 
 
// swc[i]=swc[i-1] + ground rain + snowmelt + rain from tree - evap from soil-trans 

//==       ----------------------------------------------------------------------------------------------------------------------------��������������������²�������ˮ��
/*
if(TI>0)ratio=0.5;
else {
//ratio=0.5+0.0*TI;
//if(ratio<0.25) ratio=0.25;
ratio=0.5;
}
*/

ratio=0.5+0.2*z[45];

if(ratio<0.01) ratio=0.01;
if(ratio>=0.5)  ratio=0.5;


	if(soilw3>HY3[pix].FC ) {
       aa=ratio*kk[3]*pow((float)(soilw3/HY3[pix].PR),float(2.0*B[3]*1.2+3));
     	if(aa>(soilw3-HY3[pix].FC)*depth[3])  aa=(soilw3-HY3[pix].FC)*depth[3];
         }
	else aa=0;

//aa=0;

        //������澶������   
        /*
		if(soilw1<b[35] ) bb=0;  
		else{
		bb=pow(soilw1/b[36],3.0);
	    x[1]=x[1];
		}*/
        //������澶������   

       if((g[1]+ g[3] + g[6])<0.005) bb=0;
	   else{
        if(soilw1>(b[35]*0.75)) bb=pow(soilw1/b[36],(float)3.0);
		else  bb=0;
	   }
	
		
		//���� ����ս�ˮ��С��5mm, û�е��澶��

//=====================================================================================================================================================================
	
	soilw_in = (g[1]+ g[3] + g[6])*(1.0-bb);         //g[1]Ϊ��Ч��ˮ����g[3]Ϊ��ѩ���룬g[6]Ϊ�ڲ�����������Ľ�ˮ  
	
	ET = g[12]+g[17]+g[19];
	

	//���ں���������

	x[21] = soilw1+(soilw_in - (g[17]*rrr1+g[12]))/depth[1];
    
	x[22] = soilw2 - (g[17]*rrr2)/depth[2];
    
	x[23] = soilw3 - (g[17]*rrr3+aa)/depth[3];
	
	if(x[21]>HY1[pix].PR){ //���������,�����ˮ�ֵ��ڶ���
	x21_old= x[21];
	x[22]  = x[22]+ (x[21]-HY1[pix].PR)*depth[1]/depth[2];
    x[21]=HY1[pix].PR;
      
	
	if(x[22]>HY2[pix].PR){//���һ�͵ڶ��������,�����ˮ���γɵر���
     x22_old= x[22];
	// x[22]=__min(x[22],b[36]);

 x[22]=HY2[pix].PR;

	 g[33]=(x22_old-HY2[pix].PR)*depth[2];
	  }
	}
   /* if soil water goes negative set, b[34]: wilting point   */ 
   
   /*
   b[34]=HY1[pix].WP;//0.12; ��ήϵ��	        
   b[35]=HY1[pix].FC;//0.35; ����ˮ��	 
   b[36]=HY1[pix].PR;//0.52;    
   */

 //if(x[21]<HY1[pix].WP*0.5) x[21]=HY1[pix].WP*0.5;      //ϵ��0.5 ��2012-10-15��

 theta_o[1]=x[21]/HY1[pix].PR; 
 theta_o[2]=x[22]/HY2[pix].PR;
 theta_o[3]=x[23]/HY3[pix].PR;

gpuv_moisture(pix,depth3, B,kk, Psi,HY1,HY2,HY3, theta_o, &theta_n1,&theta_n2,&theta_n3);  //��������ˮ�ֵĴ�ֱ������

x[21]=theta_n1*HY1[pix].PR; 
x[22]=theta_n2*HY2[pix].PR;
x[23]=theta_n3*HY3[pix].PR;
 
/*

x[21]=__min(HY1[pix].PR,x[21]); 
x[22]=__min(HY2[pix].PR,x[22]);
x[23]=__min(HY3[pix].PR,x[23]);


 
x[21]=__max(0.5*HY1[pix].WP,x[21]); 
x[22]=__max(0.5*HY2[pix].WP,x[22]);
x[23]=__max(0.5*HY3[pix].WP,x[23]);
 */



if(x[21]>HY1[pix].PR) x[21]=HY1[pix].PR; 
if(x[22]>HY2[pix].PR) x[22]=HY2[pix].PR; 
if(x[23]>HY3[pix].PR) x[23]=HY3[pix].PR; 

 if( x[21]<0.5*HY1[pix].WP) x[21]=0.5*HY1[pix].WP; 
 if( x[22]<0.5*HY2[pix].WP) x[22]=0.5*HY2[pix].WP; 
 if( x[23]<0.5*HY3[pix].WP) x[23]=0.5*HY3[pix].WP; 


*soilwn1=x[21];
*soilwn2=x[22];
*soilwn3=x[23];


/*  outflow = outflow + new outflow  */

   // x[3] = x[3] + g[33]+aa+bb;          //�ܵľ����� ��Ҫ�Դ˱������л������õ�������ܾ���

	x[31]=x[31]+aa;                       //���¾���

	x[32]=x[32]+(g[1]+ g[3] + g[6])*bb+g[33];            //�ر���

    x[3] = x[3] + x[31]+x[32];//g[33]+aa+bb;     //�ܵľ����� ��Ҫ�Դ˱������л������õ�������ܾ���
	
	
	/*	trans = trans + new trans */

    x[4]=  x[4]+g[17]  +g[19];   // �ܵ�����
 
/*  evapo = evapo + evap_canopy + sublimatio_canopy + evap_soil + sublimation_snow */

   x[5] =x[5] + g[4]+g[5]+g[12] +g[13];    //������

/*  understory = trans_under + new trans_under */
    x[18] = x[18] + g[19];   

/********* carbon update **********/ 

    x[6] = x[6] + g[26]; 				/* acumulated NPP */
    x[24]= g[26]*1000.0;
//   x[7] = x[7] + (g[25]+g[30]+g[31]); 	/* acumulated total Rm */
//	x[14] = x[14] + g[25]; 				/* acumulated leaf Rm */
//	x[15] = x[15] + g[30]; 				/* acumulated stem Rm */
//	x[16] = x[16] + g[31]; 				/* acumulated root Rm */

   x[11]= x[11]+ g[24];				/* acumulated gpp */

/********* For this run only, uptake E **********/ 

	x[7] = x[7] +g[4]; 					/* E_can */
	x[14] = x[14] + g[5]; 				/* S_can */
	x[15] = x[15] + g[12]; 				/* E_soil */
	x[16] = x[16] + g[13]; 				/* S_soil */

    return;
}





