/*************************************************************************
  Program:     	readawc.c 
  -------
  Description:
  -----------
 	 Read AWC data in binary file (format:32f, this code is for awc_chn.001).
***************************************************************************4
  CCRS (EMS/Applications Division)
  Written by:   J. Liu
  Modified by: X.F. Feng
  Last updatd:  Oct. 2003
*****************************************************************************/
#include"beps.h"
#include"malloc.h"
void readsoildata(long line,struct hy_c1 HY1[],struct hy_c2 HY2[],struct hy_c3 HY3[],int short *rcode)
  {
  FILE  *f1;	
		
  long int ptr;
  long int size, nitems; /// long int
  unsigned char *clay,*silt,*sand;  ///��unsigned char
  long  j; 
  float aa1,aa2;
  
  
  clay=(unsigned char*)malloc(npixels*sizeof(unsigned char));
  sand=(unsigned char*)malloc(npixels*sizeof(unsigned char));
  silt=(unsigned char*)malloc(npixels*sizeof(unsigned char));
  
  

 
  //��һ���ˮ�Ĳ�������-----------------------------------------------------------
   
  f1=fopen("\\Global_Input\\Global_soil\\Global_clay1_0727.dat","rb");
  //Calculate starting point of data 
	ptr=(line*npixels+ pix_offset)*sizeof(unsigned char) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data  
  	fread(&clay[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

  f1=fopen("\\Global_Input\\Global_soil\\Global_silt1_0727.dat","rb");
    //ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data  
  	fread(&silt[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);
  
  f1=fopen("\\Global_Input\\Global_soil\\Global_sand1_0727.dat","rb");
   // ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data 
  	fread(&sand[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

   
  for(j=0;j<npixels;j++){
	 // printf("j=%d",j);
if(clay[j]==205) clay[j]=30;
if(silt[j]==205) silt[j]=30;
if(sand[j]==205) sand[j]=40;
//clay[j]=__max(2,clay[j]); clay[j]=__min(90,clay[j]);
//silt[j]=__max(2,silt[j]); silt[j]=__min(90,silt[j]);
//sand[j]=__max(2,sand[j]); sand[j]=__min(90,sand[j]);

if(clay[j]<2) clay[j]=2;  if(clay[j]>90) clay[j]=90; 
if(silt[j]<2) silt[j]=2;  if(silt[j]>90) silt[j]=90; 
if(sand[j]<2) sand[j]=2;  if(sand[j]>90) sand[j]=90; 

sand[j]=100.0-clay[j]-silt[j];
   
  HY1[j].silt=(float)(silt[j]/100.0);    HY1[j].clay=(float)(clay[j]/100.0);  


      //HY1[j].PR=(float)(((50.5-0.142*sand1[j]-0.037*clay1[j]))/100.0)*1.25;
        HY1[j].PR=(float)(((50.5-0.142*sand[j]+0.037*clay[j]))/100.0)*1.05;	  //���㱥�ͺ�ˮ������	//2012-10-14��Clayǰϵ������		
       
		
		aa1=-5.99+0.0544*sand[j]+0.0451*silt[j];
		aa2=11.43-0.1034*sand[j]-0.0687*silt[j];
        HY1[j].FC=(float)(HY1[j].PR*pow(aa1/(-15.0),1.0/aa2));                //����ˮ��
        HY1[j].WP=(float)(HY1[j].PR*pow(aa1/(-1500.0),1.0/aa2));              //����ϵ��

        HY1[j].SP=(float) (exp((1.54-0.0095*sand[j]+0.0063*silt[j])*3.0)*9.8/10000.0); // ����ˮ�� 2012-10-14��0.5
        
		HY1[j].B=(3.10+0.157*clay[j]-0.003*sand[j]); //ԭ��Ϊ0.7�� 2012-10-14��Ϊ0.3       //����b             
	    
		if(clay[j]>5)  HY1[j].K=0.0051*pow(clay[j]/100.0,-2.03)*10;  //���ʹ����� m/day, Cambell and Norman
	   else             HY1[j].K=0.0051*pow(0.05,-2.03)*20;
	 


  }


//�ڶ���  ˮ�Ĳ�������-----------------------------------------------------------
       
  f1=fopen("\\Global_Input\\Global_soil\\Global_clay2_0727.dat","rb");
  //Calculate starting point of data  
	//ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data /
  	fread(&clay[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

  f1=fopen("\\Global_Input\\Global_soil\\Global_silt2_0727.dat","rb");
  //  ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	///	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data  
  	fread(&silt[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

  f1=fopen("\\Global_Input\\Global_soil\\Global_sand2_0727.dat","rb");
   // ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data/
	fseek(f1,ptr,SEEK_SET);    
	//	Read data /
  	fread(&sand[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1); 
       
for(j=0;j<npixels;j++){

if(clay[j]==205) clay[j]=30;
if(silt[j]==205) silt[j]=30;
if(sand[j]==205) sand[j]=40;


//clay[j]=__max(2,clay[j]); clay[j]=__min(90,clay[j]);
//silt[j]=__max(2,silt[j]); silt[j]=__min(90,silt[j]);
//sand[j]=__max(2,sand[j]); sand[j]=__min(90,sand[j]);


if(clay[j]<2) clay[j]=2;  if(clay[j]>90) clay[j]=90; 
if(silt[j]<2) silt[j]=2;  if(silt[j]>90) silt[j]=90; 
if(sand[j]<2) sand[j]=2;  if(sand[j]>90) sand[j]=90; 



sand[j]=100.0-clay[j]-silt[j];
    

  HY2[j].silt=(float)(silt[j]/100.0);      HY2[j].clay=(float)(clay[j]/100.0);  

        HY2[j].PR=(float)(((50.5-0.142*sand[j]+0.037*clay[j]))/100.0)*1.05;	  //���㱥�ͺ�ˮ������	//2012-10-14��Clayǰϵ������


        aa1=-5.99+0.0544*sand[j]+0.0451*silt[j];
		aa2=11.43-0.1034*sand[j]-0.0687*silt[j];
        HY2[j].FC=(float) (HY2[j].PR*pow(aa1/(-15.0),1.0/aa2));                //����ˮ��
        HY2[j].WP=(float) (HY2[j].PR*pow(aa1/(-1500.0),1.0/aa2));              //����ϵ��


        HY2[j].SP=(float)(exp((1.54-0.0095*sand[j]+0.0063*silt[j])*3.0)*9.8/10000.0); // ����ˮ��
        
		HY2[j].B=(3.10+0.157*clay[j]-0.003*sand[j]);     //ԭ��Ϊ0.7�� 2012-10-14��Ϊ0.5         //����b
	    if(clay[j]>5)    HY2[j].K=0.0051*pow(clay[j]/100.0,-2.03)*10;  //���ʹ����� m/day, Cambell and Norman
	   else              HY2[j].K=0.0051*pow(0.05,-2.03)*20;
	   } 



 


//������  ˮ�Ĳ�������-----------------------------------------------------------


   f1=fopen("\\Global_Input\\Global_soil\\Global_clay2_0727.dat","rb");
  //Calculate starting point of data  
	//ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data 
	fseek(f1,ptr,SEEK_SET);    
	///	Read data  
  	fread(&clay[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

    f1=fopen("\\Global_Input\\Global_soil\\Global_silt2_0727.dat","rb");
    //ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data  
  	fread(&silt[0],size=1,nitems=npixels,f1);   ///��
    fclose(f1);

 f1=fopen("\\Global_Input\\Global_soil\\Global_sand2_0727.dat","rb");
  //  ptr=(line*npixels+ pix_offset)*sizeof(float) ;   ///��
	//	Seek to start of data  
	fseek(f1,ptr,SEEK_SET);    
	//	Read data /
  	fread(&sand[0],size=1,nitems=npixels,f1);   //+/��
    fclose(f1); 
       
 
for(j=0;j<npixels;j++){
if(clay[j]==205) clay[j]=30;
if(silt[j]==205) silt[j]=30;
if(sand[j]==205) sand[j]=40;



//clay[j]=__max(2,clay[j]); clay[j]=__min(90,clay[j]);
//silt[j]=__max(2,silt[j]); silt[j]=__min(90,silt[j]);
//sand[j]=__max(2,sand[j]); sand[j]=__min(90,sand[j]);

if(clay[j]<2) clay[j]=2;  if(clay[j]>90) clay[j]=90; 
if(silt[j]<2) silt[j]=2;  if(silt[j]>90) silt[j]=90; 
if(sand[j]<2) sand[j]=2;  if(sand[j]>90) sand[j]=90; 

sand[j]=100.0-clay[j]-silt[j];
  HY3[j].silt=(float)(silt[j]/100.0);     HY3[j].clay=(float)(clay[j]/100.0);  

     
 HY3[j].PR=(float)(((50.5-0.142*sand[j]+0.037*clay[j]))/100.0)*1.05;	  //���㱥�ͺ�ˮ������//2012-10-14��Clayǰϵ������
        aa1=-5.99+0.0544*sand[j]+0.0451*silt[j];
		aa2=11.43-0.1034*sand[j]-0.0687*silt[j];
        
		
		HY3[j].FC=(float) (HY3[j].PR*pow(aa1/(-15.0),1.0/aa2));                //����ˮ��
        HY3[j].WP=(float) (HY3[j].PR*pow(aa1/(-1500.0),1.0/aa2));              //����ϵ��

        HY3[j].SP=(float) (exp((1.54-0.0095*sand[j]+0.0063*silt[j])*3.0)*9.8/10000.0); // ����ˮ��   //2012-10-14����1.5��
     
		HY3[j].B=(3.10+0.157*clay[j]-0.003*sand[j]);   //ԭ��Ϊ0.7�� 2012-10-14��Ϊ0.4        //����b
	    if(clay[j]>5)    HY3[j].K=0.0051*pow(clay[j]/100.0,-2.03)*10;  //���ʹ����� m/day, Cambell and Norman
	   else              HY3[j].K=0.0051*pow(0.05,-2.03)*20;

	   if(HY1[j].B<2.5) HY1[j].B=2.5;
      if(HY2[j].B<2.5) HY2[j].B=2.5;
      if(HY3[j].B<2.5) HY3[j].B=2.5;

      if(HY1[j].K>4.0) HY1[j].K=4.0;
      if(HY2[j].K>4.0) HY2[j].K=4.0;
      if(HY3[j].K>4.0) HY3[j].K=4.0;

	  if(HY1[j].K<0.1) HY1[j].K=0.1;
	  if(HY2[j].K<0.1) HY2[j].K=0.1;
	  if(HY3[j].K<0.1) HY3[j].K=0.1;

	    if(HY1[j].WP<0.06) HY1[j].WP=0.06;
        if(HY2[j].WP<0.06) HY2[j].WP=0.06;
        if(HY3[j].WP<0.06) HY3[j].WP=0.06;


		if(HY1[j].FC<0.12) HY1[j].FC=0.12;
	    if(HY2[j].FC<0.12) HY2[j].FC=0.12;	
        if(HY3[j].FC<0.12) HY3[j].FC=0.12;

     	if(HY1[j].PR<0.30) HY1[j].PR=0.30;
		if(HY2[j].PR<0.30) HY2[j].PR=0.30;	
		if(HY3[j].PR<0.30) HY3[j].PR=0.30;
	  
		if(HY1[j].SP<0.025) HY1[j].SP=0.025;
		if(HY2[j].SP<0.025) HY2[j].SP=0.025;	
		if(HY3[j].SP<0.025) HY3[j].SP=0.025;
	   
	   
		if(j==4101){

printf("WP=%f  FC=%f  PR=%f   B=%f, K=%f  SP=%f\n ",HY1[j].WP,HY1[j].FC,HY1[j].PR,HY1[j].B,HY1[j].K,HY1[j].SP);

printf("WP=%f  FC=%f  PR=%f   B=%f, K=%f  SP=%f\n ",HY2[j].WP,HY2[j].FC,HY2[j].PR,HY2[j].B,HY2[j].K,HY2[j].SP);


		}





		if(j==3782){

			printf("WP=%f  FC=%f  PR=%f   B=%f, K=%f  SP=%f\n ",HY1[j].WP,HY1[j].FC,HY1[j].PR,HY1[j].B,HY1[j].K,HY1[j].SP);

			printf("WP=%f  FC=%f  PR=%f   B=%f, K=%f  SP=%f\n ",HY2[j].WP,HY2[j].FC,HY2[j].PR,HY2[j].B,HY2[j].K,HY2[j].SP);


		}




	   /*
	   HY1[j].PR=HY1[j].PR; 
HY2[j].PR=HY2[j].PR;
HY3[j].PR=HY3[j].PR;
*/
//printf("B=%f %f %f \n",


} 

free(sand);
free(clay);
free(silt);


  }






