/* Written by Kartik Shenoy */

main(string ifile){

/*************/
/* Variables */
/*************/

	int start_tran=11;
	float freq=12e6;
	
/* Normalisation Type : AC/DC/None */
/* In case of AC normalisation, ensure that the waveforms of the voltage sources, for input and sigput signals, are punched sig */
/* In case of DC normalisation, enter the DC values of the voltage sources, for input and sigput signals, below */
/* In case of No normalisation, enter the low, mid and high values for the signal */
	string norm_type="DC";
	float norm_low=0.25;
	float norm_cent=0.5;
	float norm_high=0.75;
	
/* Supply values for signals for DC normalistion */
	float power_sig_dc = 1.1;
	
	waveform sig,sig_prenorm;
	waveform power_sig,gnd_sig;
	int tran,stop_tran;
	
	float odd_delta,even_delta;
	float odd_time,even_time;

	float val;
	float mult;
	string unit;

/* Initialisation values. Don't change unless required */	
	int odd_no=0;
	int even_no=0;
	float min_odd_delta=1e34;
	float max_odd_delta=-1e34;
	float min_even_delta=1e34;
	float max_even_delta=-1e34;
	float max_c2c_jitter_odd = -1e34;
	float max_c2c_jitter_even = -1e34;
	float prev_delta_odd=0;
	float prev_delta_even=0;
	float c2c_jitter_odd = 0;
	float c2c_jitter_even = 0;
	
	
/* Reading waveforms */
	readspicepunch(ifile);
	sig_prenorm = readwave(ifile,"vy");
	if(norm_type=="AC"){
		power_sig = readwave(ifile,"Vvdd_pkg");
		gnd_sig   = readwave(ifile,"Vvss");
	}
	
/* Normalising the signals here */
/* Note that in the absence of ground noise, this reduces to (sig=sig_prenorm/power_sig) viz an accurate representation */
/* However, in the presence of ground noise, the below formula is only an approximation */
	if(norm_type=="AC"){
		printf("\nApplying AC normalisation");
		sig = (sig_prenorm-gnd_sig)/(power_sig-gnd_sig);
	}else if(norm_type=="DC"){
		printf("\nApplying DC normalisation");
		sig = (sig_prenorm)/(power_sig_dc);
	}else if(norm_type=="None"){
		printf("\nNormalisation not done");
	}else{
		printf("\nPlease enter proper normalisation type");
		exit(1);
	}
	
	if(norm_type=="None"){
		setsiglow(norm_low,sig);
		setsigcent(norm_cent,sig);
		setsighigh(norm_high,sig);
	}else{
		setsiglow(0.25,sig);
		setsigcent(0.5,sig);
		setsighigh(0.75,sig);
	}
	
	stop_tran = gettransitions(sig);
	for(tran=start_tran;tran<=stop_tran;tran++){ 
		if((tran-start_tran)%2==1){
			odd_time=gettransitiontime(sig,tran);
			odd_delta=odd_time-(tran-1)*0.5/freq;
		  
			if(odd_delta>max_odd_delta){
				max_odd_delta=odd_delta;
			}else if(odd_delta<min_odd_delta){
				min_odd_delta=odd_delta;
			}
	        if(tran==start_tran+1){
				prev_delta_odd = odd_delta;
				c2c_jitter_odd = 0;
			}else{
		 		c2c_jitter_odd = fabs(odd_delta - prev_delta_odd);
				prev_delta_odd = odd_delta;
			}
	        if(c2c_jitter_odd > max_c2c_jitter_odd){
				max_c2c_jitter_odd = c2c_jitter_odd;
				odd_no = (tran)/2;
			}
/*			printf("\n  %3d : Odd  Time = %.18f : Delta = %.18f : Max = %.18f : Min = %.18f",tran,odd_time,odd_delta,max_odd_delta,min_odd_delta);
*/		}

		if((tran-start_tran)%2==0){
			even_time=gettransitiontime(sig,tran);
			even_delta=even_time-(tran-1)*0.5/freq;			
			
			if(even_delta>max_even_delta){
				max_even_delta=even_delta;
			}else if(even_delta<min_even_delta){
				min_even_delta=even_delta;
			}
			if(tran==start_tran){
				prev_delta_even = even_delta;
				c2c_jitter_even = 0;
			}else{
		 		c2c_jitter_even = fabs (even_delta - prev_delta_even);
				prev_delta_even = even_delta;
			}	
			if(c2c_jitter_even > max_c2c_jitter_even){
				max_c2c_jitter_even = c2c_jitter_even;
				even_no = (tran+1)/2;				
			}
/*			printf("\n  %3d : Even Time = %.18f : Delta = %.18f : Max = %.18f : Min = %.18f",tran,even_time,even_delta,max_even_delta,min_even_delta);
*/		}
	}
	
	val=(max_odd_delta - min_odd_delta + max_even_delta - min_even_delta)/2;
	if(val>1){
		mult=1;
		unit="";
	}else if(val>1e-3){
		mult=1e3;
		unit="m";
	}else if(val>1e-6){
		mult=1e6;
		unit="u";
	}else if(val>1e-9){
		mult=1e9;
		unit="n";
	}else if(val>1e-12){
		mult=1e12;
		unit="p";
	}else{
		mult=1e15;
		unit="f";
	}

	max_odd_delta*=mult;
	max_even_delta*=mult;
	min_odd_delta*=mult;
	min_even_delta*=mult;
	max_c2c_jitter_odd*=mult;
	max_c2c_jitter_even*=mult;
	
	printf("\n");
	if(isrise(sig,start_tran)){
		printf("\n  Rise Transition : Jitter = %3.3f%s ; Min delta = %.3f%s ; Max delta = %.3f%s",(max_odd_delta-min_odd_delta),unit,min_odd_delta,unit,max_odd_delta,unit);
		printf("\n  Fall Transition : Jitter = %3.3f%s ; Min delta = %.3f%s ; Max delta = %.3f%s",(max_even_delta-min_even_delta),unit,min_even_delta,unit,max_even_delta,unit);
	}else{
		printf("\n  Rise Transition : Jitter = %3.3f%s ; Min delta = %.3f%s ; Max delta = %.3f%s",(max_even_delta-min_even_delta),unit,min_even_delta,unit,max_even_delta,unit);
		printf("\n  Fall Transition : Jitter = %3.3f%s ; Min delta = %.3f%s ; Max delta = %.3f%s",(max_odd_delta-min_odd_delta),unit,min_odd_delta,unit,max_odd_delta,unit);
	}

	printf("\n");
	if(isrise(sig,start_tran)){
		printf("\n  Max Rise c2c jitter of %3.3f%s in rise transition no. %d",max_c2c_jitter_odd,unit,odd_no);
		printf("\n  Max Fall c2c jitter of %3.3f%s in fall transition no. %d",max_c2c_jitter_even,unit,even_no);
	}else{
		printf("\n  Max Rise c2c jitter of %3.3f%s in rise transition no. %d",max_c2c_jitter_even,unit,even_no);
		printf("\n  Max Fall c2c jitter of %3.3f%s in fall transition no. %d",max_c2c_jitter_odd,unit,odd_no);
	}

	printf("\n\n");
	
/*	
	if(ofile!=""){
		fp=fopen(ofile,"w");
		fclose(fp);
	}
*/
}
