#!/apps/ame/bin/codac
/*	
	Codac Script to calculate Jitter and C2C Jitter
	Written by Kartik Shenoy (a0393831)

	SYNTAX : codac c2cJitter.k <punchfile>

	Calculates both Max and C2C Jitter

	Normalisation:-
	  Supports signal normalisation prior to jitter computation.
	  Normalisation can be selected (or not) by setting the variable 'norm_type'
	  Normalisation modes supported are "Static", "Dynamic" and "None"
	  To perform static normalisation, the DC values of the supplies are required
	  To perform dynamic normalisation, the supplies themselves should be punched and the variables 'power_*' and 'gnd_*' should be set appropriately
	  To disable normalisation, set 'norm_type="None"'.

	Trigger:-
	  Jitter calculation can be performed by selecting an ideal trigger or with respect to a reference signal.
	  This can be done by setting the variable 'trigger' to "Ideal" or "Reference" respectively.
	  When ideal trigger is selected, the frequency of the clock pulse should be specified in 'freq_ref'
	  When trigger=Reference, the name of the reference signal should be set in 'ref_prenorm'
*/

string unitify(float);

main(string ifile){

//==================================================================================================
// Variable declaration
//======================

	waveform sig,sig_prenorm,sign_prenorm;
	waveform power_sig,gnd_sig;
	waveform ref,ref_prenorm,refn_prenorm;
	waveform power_ref,gnd_ref;

	int tran,tran_start,tran_stop;
	int tran_total_sig,tran_total_ref;
	int num_odd,num_even;

	float freq_ref;
	float power_sig_dc,power_ref_dc;
	float time,delta,c2c_jitter;
	float prev_delta_odd,prev_delta_even;
	float p2p_jitter_odd,p2p_jitter_even,p2p_jitter_period;

	string ofile;
	string trigger,norm_type;
	
	string str_min_delta_odd,str_max_delta_odd;
	string str_min_delta_even,str_max_delta_even;
	string str_max_c2c_jitter_odd,str_max_c2c_jitter_even;
	string str_p2p_jitter_odd,str_p2p_jitter_even,str_p2p_jitter_period;
	
	file fp;


// Initialisation values. Don't change unless required
	float min_delta_odd       =  1e34;
	float max_delta_odd       = -1e34;
	float min_delta_even      =  1e34;
	float max_delta_even      = -1e34;
	float min_delta_period    =  1e34;
	float max_delta_period    = -1e34;
	float max_c2c_jitter_odd  = -1e34;
	float max_c2c_jitter_even = -1e34;

    ofile=ifile+".txt";



//==================================================================================================
// Required Inputs
//=================

// Reading input waveforms
	readspicepunch(ifile);
	sig_prenorm = readwave(ifile,"vpadp");
	sign_prenorm = readwave(ifile,"vpadn");
	//sign_prenorm = 0;
	if(trigger=="Reference"){       // Reference waveforms if trigger is given as "Reference"
		ref_prenorm = readwave(ifile,"");
		refn_prenorm = readwave(ifile,"");
	}


// Supplies for signals required for normalisation. Ignore if norm_type="None"
	if(norm_type=="Dynamic"){       // Supply waveforms required for dynamic normalisation of input
		power_sig = readwave(ifile,"vvdd");
		gnd_sig   = 0;
		if(trigger=="Reference"){   // Supply waveforms for Reference required for dynamic normalisation
			power_ref = readwave(ifile,"");
			gnd_ref   = 0;
		}
	}else if(norm_type=="Static"){  // DC value of input supply for Static normalisation
		power_sig_dc = 1.1;		
		if(trigger=="Reference"){   // DC value of reference supply for Static normalisation
			power_ref_dc = 1.98;
		}		
	}


// Transition from which calculations should start
    tran_start = 10;


// Choose Trigger Type : Ideal/Reference
// Ideal     : Jitter calculations will be done wrt. an ideal clock of the specified frequency (freq_ref)
// Reference : Jitter calculations will be done wrt. the specified reference signal
	trigger="Ideal";
	freq_ref = 800e6;


// Normalisation Type : Dynamic/Static/None
// In case of Static normalisation, enter the DC values of the voltage sources, for input and sigput signals, below
// In case of Dynamic normalisation, ensure that the waveforms of the voltage sources, for input and sigput signals, are punched sig
	norm_type="None";



//==================================================================================================
// Signal manipulation
//=====================

// Converting differential single to single-ended (P-N) 
	sig_prenorm -= sign_prenorm;
	if(trigger=="Reference"){
		ref_prenorm -= refn_prenorm;
	}
	

// Normalising the signals here 
// Note that in the absence of ground noise, this reduces to (sig=sig_prenorm/power_sig) viz an accurate representation 
// However, in the presence of ground noise, the below formula is only an approximation 
	if(norm_type=="Dynamic"){
		printf("\nApplying Dynamic normalisation");
		sig = (sig_prenorm-gnd_sig)/(power_sig-gnd_sig);
		if(trigger=="Reference"){
			ref = (ref_prenorm-gnd_ref)/(power_ref-gnd_ref);
		}
	}else if(norm_type=="Static"){
		printf("\nApplying Static normalisation");
		sig = (sig_prenorm)/(power_sig_dc);
		if(trigger=="Reference"){
			ref = (ref_prenorm)/(power_ref_dc);
		}		
	}else if(norm_type=="None"){
		printf("\nNormalisation not done");
		sig = sig_prenorm;
		if(trigger=="Reference"){
			ref = ref_prenorm;
		}
	}else{
		printf("\nPlease enter proper normalisation type");
		exit(1);
	}


	setsighigh(0.2,sig);
	setsigcent(0,sig);
	setsiglow(-0.2,sig);
	
	if(trigger=="Reference"){
		setsighigh(0.2,ref);
		setsigcent(0,ref);
		setsiglow(-0.2,ref);
	}
	
	
	if(trigger=="Reference"){
		tran_total_ref = gettransitions(ref);
		tran_total_sig = gettransitions(sig);	
		if(tran_total_ref != tran_total_sig){  
			printf("\n\nWARNING : The number of transitions in the input and output signals dont match"); 
			printf("\n  Transitions in Signal      : %d",tran_total_sig);
			printf("\n  Transitions in Ref. Signal : %d",tran_total_ref);
			if(tran_total_ref < tran_total_sig){
				tran_stop = tran_total_ref;
			}else{
				tran_stop = tran_total_sig;
			}
			printf("\n  Computing till transition number %d",tran_stop);
		}else{
			tran_stop = tran_total_ref;
		}
	}else{
		tran_stop = gettransitions(sig);
	}	


	for(tran=tran_start;tran<=tran_stop;tran++){ 

		time=gettransitiontime(sig,tran);
//		printf("\n\n  %3d    : Time  = %e",tran,time);

		if(trigger=="Reference"){
			delta = delay(sig,tran,ref,tran);
		}else{
			delta = time - (tran)*0.5/freq_ref;
		}
		  
		if((tran-tran_start)%2==1){
			
			if(delta > max_delta_odd){
				max_delta_odd = delta;
			}
			if(delta < min_delta_odd){
				min_delta_odd = delta;
			}
			
	        if(tran==tran_start+1){
				prev_delta_odd = delta;
				c2c_jitter = 0;
			}else{
		 		c2c_jitter = fabs(delta - prev_delta_odd);
				prev_delta_odd = delta;
			}
			
	        if(c2c_jitter > max_c2c_jitter_odd){
				max_c2c_jitter_odd = c2c_jitter;
				num_odd = (tran)/2;
			}
//			printf("\n    Odd  : Delta = %e : Max = %e : Min = %e",delta,max_delta_odd,min_delta_odd);
  	    }

		if((tran-tran_start)%2==0){
			
			if(delta > max_delta_even){
				max_delta_even = delta;
			}
			if(delta < min_delta_even){
				min_delta_even = delta;
			}
			
			if(tran==tran_start){
				prev_delta_even = delta;
				c2c_jitter = 0;
			}else{
		 		c2c_jitter = fabs (delta - prev_delta_even);
				prev_delta_even = delta;
			}	

			if(c2c_jitter > max_c2c_jitter_even){
				max_c2c_jitter_even = c2c_jitter;
				num_even = (tran+1)/2;				
			}
//			printf("\n    Even : Delta = %e : Max = %e : Min = %e",delta,max_delta_even,min_delta_even);
  	    }

		if(delta > max_delta_period){
			max_delta_period = delta;
		}
		if(delta < min_delta_period){
			min_delta_period = delta;
		}
//		printf("\n    Data : Delta = %e : Max = %e : Min = %e : Diff = %e",delta,max_delta_period,min_delta_period,max_delta_period-min_delta_period);

	}
	
	
	p2p_jitter_odd    = max_delta_odd    - min_delta_odd;
	p2p_jitter_even   = max_delta_even   - min_delta_even;
	p2p_jitter_period = max_delta_period - min_delta_period;
	
	str_max_delta_odd       = unitify(max_delta_odd);
	str_max_delta_even      = unitify(max_delta_even);
	str_p2p_jitter_odd      = unitify(p2p_jitter_odd);
	str_min_delta_odd       = unitify(min_delta_odd);
	str_min_delta_even      = unitify(min_delta_even);
	str_p2p_jitter_even     = unitify(p2p_jitter_even);
	str_max_c2c_jitter_odd  = unitify(max_c2c_jitter_odd);
	str_max_c2c_jitter_even = unitify(max_c2c_jitter_even);
	str_p2p_jitter_period   = unitify(p2p_jitter_period);

	printf("\n");

    printf("Punch file      : %s\n",ifile);
	printf("\n");
	printf("Period jitter   = %s",str_p2p_jitter_period);
    printf("\n");
	if(isfall(sig,tran_start)){
		printf("P2P rise jitter = %s\n",str_p2p_jitter_odd);
		printf("C2C rise jitter = %s in transition no. %d\n",str_max_c2c_jitter_odd,num_odd);
		printf("Rise min delta  = %s ; max delta = %s\n",str_min_delta_odd,str_max_delta_odd);
		printf("\n");
		printf("P2P fall jitter = %s\n",str_p2p_jitter_even);
		printf("C2C fall jitter = %s in transition no. %d\n",str_max_c2c_jitter_even,num_even);
		printf("Fall min delta  = %s ; max delta = %s\n",str_min_delta_even,str_max_delta_even);
	}else{
		printf("P2P rise jitter = %s\n",str_p2p_jitter_even);
		printf("C2C rise jitter = %s in transition no. %d\n",str_max_c2c_jitter_even,num_even);
		printf("Rise min delta  = %s ; max delta = %s\n",str_min_delta_even,str_max_delta_even);
		printf("\n");
		printf("P2P fall jitter = %s\n",str_p2p_jitter_odd);
		printf("C2C fall jitter = %s in transition no. %d\n",str_max_c2c_jitter_odd,num_odd);
		printf("Fall min delta  = %s ; max delta = %s\n",str_min_delta_odd,str_max_delta_odd);
	}
	printf("\n\n");

	fp=fopen(ofile,"w");
    fprintf(fp,"Punch file      : %s\n",ifile);
	fprintf(fp,"\n");
	fprintf(fp,"Period jitter   = %e\n",p2p_jitter_period);
	fprintf(fp,"\n");
	if(isfall(sig,tran_start)){
		fprintf(fp,"P2P rise jitter = %e\n",p2p_jitter_odd);
		fprintf(fp,"C2C rise jitter = %e in transition no. %d\n",max_c2c_jitter_odd,num_odd);
		fprintf(fp,"Rise min delta  = %e ; max delta = %e\n",min_delta_odd,max_delta_odd);
		fprintf(fp,"\n");
		fprintf(fp,"P2P fall jitter = %e\n",p2p_jitter_even);
		fprintf(fp,"C2C fall jitter = %e in transition no. %d\n",max_c2c_jitter_even,num_even);
		fprintf(fp,"Fall min delta  = %e ; max delta = %e\n",min_delta_even,max_delta_even);
	}else{
		fprintf(fp,"P2P rise jitter = %e\n",p2p_jitter_even);
		fprintf(fp,"C2C rise jitter = %e in transition no. %d\n",max_c2c_jitter_even,num_even);
		fprintf(fp,"Rise min delta  = %e ; max delta = %e\n",min_delta_even,max_delta_even);
		fprintf(fp,"\n");
		fprintf(fp,"P2P fall jitter = %e\n",p2p_jitter_odd);
		fprintf(fp,"C2C fall jitter = %e in transition no. %d\n",max_c2c_jitter_odd,num_odd);
		fprintf(fp,"Fall min delta  = %e ; max delta = %e\n",min_delta_odd,max_delta_odd);
	}
	fclose(fp);
    freespicepunchfile(ifile);

    return 0;
}



//==================================================================================================
// Function Definition
//=====================

string unitify(float inum){
    string ostr;
    float num=abs(inum);

    if(num >= 1){
        ostr=str(num);
    }else if(num >= 1e-3){
        sprintf(ostr,"%.3fm",num*1e3);
    }else if(num >= 1e-6){
        sprintf(ostr,"%.3fu",num*1e6);
    }else if(num >= 1e-9){
        sprintf(ostr,"%.3fn",num*1e9);
    }else if(num >= 1e-12){
        sprintf(ostr,"%.3fp",num*1e12);
    }else{
        sprintf(ostr,"%.3ff",num*1e15);
    }

    if(inum < 0){
        sprintf(ostr,"-%s",ostr);
    }
	return(ostr);
}
