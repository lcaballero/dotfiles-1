#!/apps/ame/bin/codac
/*
	Codac Script to calculate start-up of OSC
	Written by Kartik Shenoy (a0393831)

	SYNTAX : codac <scriptname> <punchfile>
	
	When duty cycle of Y signal crosses 45%-55%, it is said to have started-up
	 
	Inputs required
	 - Name of Y signal to be specified in the file.

*/
int DEBUG=0;


/* Function to convert a float to string and append the units
	Eg. 0.000120        ==> 120.000e-06
		0.0000000000153 ==>  15.300e-15
*/
string unitify(float inum){
	string ostr;
	if(inum >= 1){
		ostr=str(inum);
	}else if(inum >= 1e-3){
		sprintf(ostr,"%.1fe-03",inum*1e3);
	}else if(inum >= 1e-6){
		sprintf(ostr,"%.1fe-06",inum*1e6);
	}else if(inum >= 1e-9){
		sprintf(ostr,"%.1fe-09",inum*1e9);
	}else if(inum >= 1e-12){
		sprintf(ostr,"%.1fe-12",inum*1e12);
	}else{
		sprintf(ostr,"%.1fe-15",inum*1e15);
	}
	return(ostr);
}


main(string punchfile){

/* Inputs required */
	string name_sig="vy";
	

/* Variable declaration */	
	waveform sig;
	int tran,tran_startup,tran_total;
	float duty,time_startup_duty;
	string time_startup_duty_str;
	int flag=0;
	string ofile;
	file fp;
	

/* Variable Initialisation */
	tran=1;
	tran_startup=1;
	sprintf(ofile,"%s.txt",punchfile);
	fp=fopen(ofile,"w");
	

/* Reading waveforms and verifying if specified signals are present */
/* Else prints all the signals present in the punchfile and exits */
	readspicepunch(punchfile);
	
	sig = readwave(punchfile,name_sig);

	if(!sig){
		printf("\n   Cannot find the signal %s in the specifed punchfile\n",name_sig);
		flag=1;
	}
	
	if(flag){
		print("   Following is the list of signals present; please select from it");
		while(nextsignal(sig)){
			printf("     %s\n",getsigname(sig));
		}
		printf("\n");
		exit(1);
	}else if(DEBUG) printf("Signals found in Input file...\n\n");


/* Set high, mid and low values of the signal. Required to identify transitions */
	setsighigh(0.6,sig);
	setsigcent(0.4,sig);
	setsiglow(0.2,sig);
	

/* Identifying 1st rising edge of Y and starting calculation */
	if(isfall(sig,tran)){
		tran++;
		printf("Identified 1st transition as a fall. Incrementing to start computation from a rising transition\n");
	}


/* Identifying no. of transitions to limit loop runs */
    tran_total=gettransitions(sig);
    printf("Total no. of transitions in specified signal = %d",tran_total);


	while(!((duty > 0.45)&&(duty < 0.55)) && tran<tran_total){
        if(isrise(sig,tran)){
            duty = dutycycle(sig,tran);

            if(DEBUG) printf("Tran : %4d   Duty Cycle : %f\n",tran,duty);

            if((duty > 0.45)&&(duty < 0.55)){
                tran_startup = tran;
                time_startup_duty = gettransitiontime(sig,tran);
            }else{
                tran+=2;
            }		
        }else{
            tran++;
        }
	}
	
	if(tran>tran_total){
		printf("\nThe Simulation has not started up yet. Please run it for a longer duration\n\n");
		exit(2);
	}else{
        time_startup_duty_str = unitify(time_startup_duty);
        printf("\nStartup occured at time = %s at transition %d\n\n",time_startup_duty_str,tran_startup);
        fprintf(fp,"Startup time = %e\n",time_startup_duty);
    }
}
