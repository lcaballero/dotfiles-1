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
    string name_padxi="vpadxi";
	

/* Variable declaration */	
	waveform sig,padxi;
	int tran_sig,tran_total_sig,tran_startup_duty;
    int tran_padxi,tran_total_padxi,tran_startup_vpp;
	float duty,time_startup_duty;
    float vpp,time_prev,time_curr,time_startup_vpp,vbias;
	string time_startup_duty_str,time_startup_vpp_str,vpp_targ_str;
	int flag=0;
	string ofile;
	file fp;

    int meas_startup_duty = 1;
    int meas_startup_vpp  = 1;
    float vpp_targ = 0.1;
	

/*  Opening file and reading waveforms */
	sprintf(ofile,"%s.txt",punchfile);
	fp=fopen(ofile,"w");
	readspicepunch(punchfile);

    if(meas_startup_duty == 1){

/*      Variable Initialisation */
        tran_sig = 1;
        tran_startup_duty = 1;

        sig = readwave(punchfile,name_sig);

/*      Else prints all the signals present in the punchfile and exits */
        if(!sig){
            printf("\n   Cannot find the signal %s in the specifed punchfile\n",name_sig);

            print("   Following is the list of signals present; please select from it");
            while(nextsignal(sig)){
                printf("     %s\n",getsigname(sig));
            }

            printf("\n");
            exit(1);
        }


/*      Set high, mid and low values of the signal. Required to identify transitions */
        setsighigh(0.6,sig);
        setsigcent(0.4,sig);
        setsiglow(0.2,sig);


/*      Identifying 1st rising edge and starting calculation */
        if(isfall(sig,tran_sig)){
            tran_sig++;
            printf("Identified 1st transition as a fall. Incrementing to start computation from a rising transition\n");
        }


/*      Identifying no. of transitions to limit loop runs */
        tran_total_sig=gettransitions(sig);
        printf("Total no. of transitions in specified signal = %d\n",tran_total_sig);


        while(!((duty > 0.45)&&(duty < 0.55)) && tran_sig<tran_total_sig){
            if(isrise(sig,tran_sig)){
                duty = dutycycle(sig,tran_sig);

                if(DEBUG) printf("Tran : %4d   Duty Cycle : %f\n",tran_sig,duty);

                if((duty > 0.45)&&(duty < 0.55)){
                    tran_startup_duty = tran_sig;
                    time_startup_duty = gettransitiontime(sig,tran_sig);
                }else{
                    tran_sig+=2;
                }		
            }else{
                tran_sig++;
            }
        }
    }

    if(meas_startup_vpp == 1){

        padxi = readwave(punchfile,name_padxi);

/*      Else prints all the signals present in the punchfile and exits */
        if(!padxi){
            printf("\n   Cannot find the signal %s in the specifed punchfile\n",name_padxi);

            print("   Following is the list of signals present; please select from it");
            while(nextsignal(padxi)){
                printf("     %s\n",getsigname(padxi));
            }

            printf("\n");
            exit(1);
        }


/*      Variable Initialisation */
        tran_padxi = 1;
        tran_startup_vpp = 1;
        time_prev = 0;


        vbias = gety(padxi,100e-6);
/*      Set high, mid and low values of the signal. Required to identify transitions */
        setsighigh(vbias+vpp_targ/4,padxi);
        setsigcent(vbias,padxi);
        setsiglow(vbias-vpp_targ/4,padxi);


/*      Identifying no. of transitions to limit loop runs */
        tran_total_padxi=gettransitions(padxi);
        printf("Total no. of transitions in padxi = %d\n\n",tran_total_padxi);


        time_curr = gettransitiontime(padxi,tran_padxi);
        vpp = peak2peak(padxi,time_prev,time_curr);

        while(vpp < vpp_targ && tran_padxi < tran_total_padxi){
            time_prev = time_curr;
            tran_padxi+=2;
            time_curr = gettransitiontime(sig,tran_padxi);
            vpp = peak2peak(padxi,time_prev,time_curr);
        }
        time_startup_vpp = time_curr;
    }


    if(meas_startup_duty == 1){
        if(tran_sig > tran_total_sig){
            printf("\nThe Simulation has not started up yet. Please run it for a longer duration\n\n");
            exit(2);
        }else{
            time_startup_duty_str = unitify(time_startup_duty);
            printf("Startup occured at time = %s at transition %d\n\n",time_startup_duty_str,tran_startup_duty);
            fprintf(fp,"Startup time = %e\n",time_startup_duty);
        }
    }

    if(meas_startup_vpp == 1){
        if(DEBUG) printf("Padxi High = %f\n",vbias+vpp_targ/4);
        if(DEBUG) printf("Padxi Cent = %f\n",vbias);
        if(DEBUG) printf("Padxi Low  = %f\n",vbias-vpp_targ/4);

        if(tran_padxi > tran_total_padxi){
            printf("Padxi signal hasn't reached the required pk-pk value. Run it for a longer duration\n\n");
            exit(2);
        }else{
            vpp_targ_str = unitify(vpp_targ);
            time_startup_vpp_str = unitify(time_startup_vpp);
            printf("Padxi reached Pk-Pk value of %s at time = %s\n\n",vpp_targ_str,time_startup_vpp_str);
            fprintf(fp,"\nPadxi reached Pk-Pk value of %f at time = %e\n",vpp_targ,time_startup_vpp);
        }
    }
}
