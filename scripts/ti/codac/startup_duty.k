/*
	Codac Script to calculate start-up of OSC

	Written by Kartik Shenoy (a0393831)

	SYNTAX : codac <scriptname> <punchfile>
	
	Inputs required : Name of Y signal to be specified in this file
	The OSC is said to have started-up when the duty cycle crosses 45-55%
*/
int DEBUG=1;


/* Function to convert a float to string and append the units
   Eg. 0.000120        ==> 120.000u
       0.0000000000153 ==>  15.300p
*/
string unitify(float inum){
	string ostr;
	if(inum >= 1){
		ostr=str(inum);
	}else if(inum >= 1e-3){
		sprintf(ostr,"%.3fm",inum*1e3);
	}else if(inum >= 1e-6){
		sprintf(ostr,"%.3fu",inum*1e6);
	}else if(inum >= 1e-9){
		sprintf(ostr,"%.3fn",inum*1e9);
	}else if(inum >= 1e-12){
		sprintf(ostr,"%.3fp",inum*1e12);
	}else{
		sprintf(ostr,"%.3ff",inum*1e15);
	}
	return(ostr);
}


main(string punchfile){

/* Inputs required */
	string name_sig="VY";

	
/* Variable declaration */	
	waveform sig,vin;
	int tran,tran_startup,tran_total;
	float duty;
	float time_startup;
	string time_startup_str;
	

/* Variable Initialisation */
	tran=1;
	tran_startup=0;
	time_startup=0;
	duty=0;
	

/* Reading waveforms and verifying if specified signals are present */
/* Else prints all the signals present in the punchfile and exits */
	readspicepunch(punchfile);
	sig = readwave(punchfile,name_sig);
	if(!sig){
		printf("\n   Cannot find the signal %s in the specifed punchfile\n",name_sig);
		printf("   Following is the list of signals present; please select from it");
		while(nextsignal(vin)){
			printf("     %s\n",getsigname(vin));
		}
		printf("\n");
		exit(1);
	}else if(DEBUG)	printf("Signal found in Input file...\n\n");


/* Set high, mid and low values of the signal. Required to identify transitions */
	setsiglow(0.25,sig);
	setsigcent(0.5,sig);
	setsighigh(0.75,sig);


/* Identifying 1st rising edge of Y and starting calculation */
	if(isfall(sig,tran)){
		tran++;
		printf("Identified 1st transition as a fall. Incrementing to start computation from a rising transition\n");
	}


	tran_total=gettransitions(sig);
	if(DEBUG) printf("Total no. of transitions in %s = %d\n",name_sig,tran_total);
	
	while(tran<tran_total){
		duty = dutycycle(sig,tran);

		if(DEBUG) printf("Tran : %4d   Duty Cycle : %f\n",tran,duty);

		if((duty > 0.45)&&(duty < 0.55)){
			tran_startup = tran;
			time_startup = gettransitiontime(sig,tran);
			break;
		}else{
			tran+=2;
		}		
	}
	
	if(tran_startup==0){
		printf("\nThe Simulation has not started up yet. Please run it for a longer duration\n\n");
		exit(2);
	}else{
		time_startup_str = unitify(time_startup);
		printf("\nStartup occured at time = %s at transition %d\n\n",time_startup_str,tran_startup);
	}
}
