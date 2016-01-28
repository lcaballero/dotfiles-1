/* Written by Kartik Shenoy */

main(string ifile){

/*************/
/* Variables */
/*************/

	int start_tran=25;
	
/* Normalisation Type : AC/DC */
/* In case of AC normalisation, ensure that the waveforms of the voltage sources, for input and output signals, are punched out */
/* In case of DC normalisation, enter the DC values of the voltage sources, for input and output signals, below */
	string norm_type="DC";
	
/* Voltage Sources for Input and Output signals for DC normalistion */
	float power_in_dc  = 1.98;
	float power_out_dc = 1.1;
	
/*	file fp;
	int precision=2;
*/
	
	waveform out,out_prenorm;
	waveform in,in_prenorm;
	waveform power_in,power_out;
	waveform gnd_in,gnd_out;
	int tran,ntran_in,ntran_out,stop_tran;
	float odd_delay,even_delay;
	
/* Default parameter values. Don't change unless required */	
	int odd_no=0;
	int even_no=0;
	float min_odd_delay=1e34;
	float max_odd_delay=-1e34;
	float min_even_delay=1e34;
	float max_even_delay=-1e34;
	float prev_delay_odd=0;
	float prev_delay_even=0;
	float max_c2c_jitter_odd = -1e34;
	float cycle_to_cycle_jitter_odd = 0;
	float max_c2c_jitter_even = -1e34;
	float cycle_to_cycle_jitter_even = 0;
	
	
	readspicepunch(ifile);
	out_prenorm = readwave(ifile,"vy");
	in_prenorm  = readwave(ifile,"vpadxi");
	if(norm_type=="AC"){
		power_in  = readwave(ifile,"Vvdds_pkg");
		power_out = readwave(ifile,"Vvdd_pkg");
		gnd_in    = readwave(ifile,"Vvss");
		gnd_out   = readwave(ifile,"Vvss");
	}
	
	
/* Normalising the Input and Output here */
/* Note that in the absence of ground noise, this reduces to (in=in_prenorm/power_in) viz an accurate representation */
/* However, in the presence of ground noise, the below formula is only a crude approximation */

	if(norm_type=="AC"){
		printf("\nApplying AC normalisation");
		in  = (in_prenorm-gnd_in)/(power_in-gnd_in);
		out = (out_prenorm-gnd_out)/(power_out-gnd_out);
	}else if(norm_type=="DC"){
		printf("\nApplying DC normalisation");
		in  = (in_prenorm)/(power_in_dc);
		out = (out_prenorm)/(power_out_dc);
	}else{
		printf("\nPlease enter proper normalisation type");
		exit(1);
	}
	
	setsiglow(0.25,in);
	setsigcent(0.5,in);
	setsighigh(0.75,in);
	
	setsiglow(0.25,out);
	setsigcent(0.5,out);
	setsighigh(0.75,out);
	
	ntran_in  = gettransitions(in);
	ntran_out = gettransitions(out);
	if(ntran_in != ntran_out){  
		printf("\n\nThe number of transitions in the Input and Output signals dont match"); 
		printf("\n  Number of transitions in Output Signal : %d",ntran_out);
		printf("\n  Number of transitions in Input Signal  : %d",ntran_in);
		if(ntran_in < ntran_out){
			stop_tran = ntran_in;
		}else{
			stop_tran = ntran_out;
		}
		printf("\nComputing till transition number %d",stop_tran);
	}else{
		stop_tran = ntran_in;
	}
	

	for(tran=start_tran;tran<=stop_tran;tran++){ 
		if((tran-start_tran)%2==1){
			odd_delay=delay(out,tran,in,tran);
/*			printf("\n Odd delay %6.14f :" , odd_delay);
*/			
			if(odd_delay>max_odd_delay){
				max_odd_delay=odd_delay;
			}
			
			if(odd_delay<min_odd_delay){
				min_odd_delay=odd_delay;
			}
			
	        if(tran==start_tran+1){
			prev_delay_odd = odd_delay;
			cycle_to_cycle_jitter_odd = 0;
			}
			
		    if(tran!=start_tran+1){
		 	cycle_to_cycle_jitter_odd = fabs (odd_delay - prev_delay_odd);
			prev_delay_odd = odd_delay;
			}
				
	        if(cycle_to_cycle_jitter_odd > max_c2c_jitter_odd){
			max_c2c_jitter_odd = cycle_to_cycle_jitter_odd;
			odd_no = (tran)/2;
			}
		}

		if((tran-start_tran)%2==0){
			even_delay=delay(out,tran,in,tran);
/*			printf(" Even Delay %6.12f:" , even_delay);
*/			
			if(even_delay>max_even_delay){
				max_even_delay=even_delay;
			}
	
			if(even_delay<min_even_delay){
				min_even_delay=even_delay;
			}
			
			if(tran==start_tran){
			prev_delay_even = even_delay;
			cycle_to_cycle_jitter_even = 0;
			}
		    
			if(tran!=start_tran){
		 	cycle_to_cycle_jitter_even = fabs (even_delay - prev_delay_even);
			prev_delay_even = even_delay;
			}	
	        
			if(cycle_to_cycle_jitter_even > max_c2c_jitter_even){
			max_c2c_jitter_even = cycle_to_cycle_jitter_even;
			even_no = (tran+1)/2 ;
			}
		}
	}
	
	max_odd_delay*=1e12;
	max_even_delay*=1e12;
	min_odd_delay*=1e12;
	min_even_delay*=1e12;
	max_c2c_jitter_odd*=1e12;
	max_c2c_jitter_even*=1e12;
	
	printf("\n");
	
	if(isrise(in,start_tran)){
		printf("\n  Rise Transition : Jitter = %6.4fp ; Min delay = %6.4fp ; Max delay = %6.4fp",(max_odd_delay-min_odd_delay),min_odd_delay,max_odd_delay);
		printf("\n  Fall Transition : Jitter = %6.4fp ; Min delay = %6.4fp ; Max delay = %6.4fp",(max_even_delay-min_even_delay),min_even_delay,max_even_delay);
	}else{
		printf("\n  Rise Transition : Jitter = %6.4fp ; Min delay = %6.4fp ; Max delay = %6.4fp",(max_even_delay-min_even_delay),min_even_delay,max_even_delay);
		printf("\n  Fall Transition : Jitter = %6.4fp ; Min delay = %6.4fp ; Max delay = %6.4fp",(max_odd_delay-min_odd_delay),min_odd_delay,max_odd_delay);
	}
	printf("\n");
	if(isrise(in,start_tran)){
		printf("\n  Max Rise c2c jitter of %6.4fp in rise transition no. %d",max_c2c_jitter_odd,odd_no);
		printf("\n  Max Fall c2c jitter of %6.4fp in fall transition no. %d",max_c2c_jitter_even,even_no);
	}else{
		printf("\n  Max Rise c2c jitter of %6.4fp in rise transition no. %d",max_c2c_jitter_even,even_no);
		printf("\n  Max Fall c2c jitter of %6.4fp in fall transition no. %d",max_c2c_jitter_odd,odd_no);
	}
	printf("\n\n");
	
/*	
	if(ofile!=""){
		fp=fopen(ofile,"w");
		fclose(fp);
	}
*/
}
