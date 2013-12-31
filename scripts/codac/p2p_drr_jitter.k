/*written by Sujan */
/*Modified on feb22 08 by Sujan */


main(string ifile, string ofile)
{

	waveform pad,padn,in,inn,diff_in,diff_pad;
	waveform diff_in1,diff_pad1;
	waveform vdd,vdds,vss;
	waveform ivdd,ivdds,ivss;
	
	int ntran_in,ntran_out;
	int i;
	int rise_no = 0 ;
	int no = 0 ;
	int fall_no = 0;
	int wave_start=1;
	
	file fp;
	
	float rise_delay;
	float min_rise_delay=1e34;
	float max_rise_delay=-1e34;
	
	float fall_delay;
	float delay_ddr;
	float min_fall_delay=1e34;
	float max_fall_delay=-1e34;
	float min_delay=1e34;
	float max_delay=-1e34;
	float prev_delay=0;
	float prev_delay_rise=0;
	float prev_delay_fall=0;
	float max_p2p_jitter_rise = -1e34;
	float peak_to_peak_jitter_rise = 0;
	float max_p2p_jitter_fall = -1e34;
	float max_p2p_jitter_ddr = -1e34;
	float peak_to_peak_jitter_fall = 0;
	float peak_to_peak_jitter_ddr = 0;
	float ddr_peak_to_peak_jitter = 0;
	float ivdd_avg,ivdds_avg,ivss_avg;
	
	
	readspicepunch(ifile);
	in=readwave(ifile,"vilvds_sg_padp");
	inn=readwave(ifile,"vilvds_sg_padn");
	pad=readwave(ifile,"volvds_cro_padp");
	padn=readwave(ifile,"volvds_cro_padn");
	vdd = readwave(ifile,"vvdd");
	vss = readwave(ifile,"vvss");
	vdds= readwave(ifile,"vvdds");
	ivdd = readwave(ifile,"ivddext");
	ivdds= readwave(ifile,"ivddsext");
	ivss= readwave(ifile,"ivss");
	diff_in1=in-inn;
	diff_pad1=pad-padn;
	diff_in=range(diff_in1,450e-9);
	diff_pad=range(diff_pad1,450e-9);
	
	setsighigh(0.1,diff_in);
	setsigcent(0,diff_in);
	setsiglow(-0.1,diff_in);
	
	setsighigh(0.05,diff_pad);
	setsigcent(0,diff_pad);
	setsiglow(-0.05,diff_pad);
	
	ntran_out=gettransitions(diff_pad);
	ntran_in=gettransitions(diff_in);

/*	printf("pad=%d ",ntran_out);
	printf("y= %d",ntran_in);
*/
	for(i=wave_start;i<=ntran_out;i++)
	{
		if(i%2==0)
		{
			fall_delay=delay(diff_pad,i,diff_in,i);
/*			printf("\nFall delay %e @ %d:" , fall_delay,i);
*/			if(fall_delay>max_fall_delay)
			{
				max_fall_delay=fall_delay;
			}
			if(fall_delay<min_fall_delay)
			{
				min_fall_delay=fall_delay;
			}
			if(i==wave_start+1)
			{
				prev_delay_fall = fall_delay;
				peak_to_peak_jitter_fall = 0;
			}
		        if(i!=wave_start+1)
			{
			 	peak_to_peak_jitter_fall = fabs (max_fall_delay - min_fall_delay);
				prev_delay_fall = fall_delay;
			}
	                if(peak_to_peak_jitter_fall > max_p2p_jitter_fall)
			{
				
				max_p2p_jitter_fall = peak_to_peak_jitter_fall;
			fall_no = (i+1)/2 ;
			}
		}
		if(i%2==1)
		{
			rise_delay=delay(diff_pad,i,diff_in,i);
/*			printf("\nRise delay %e @ %d:" , rise_delay,i); 
*/			if(rise_delay>max_rise_delay)
			{
				max_rise_delay=rise_delay;
			}
			if(rise_delay<min_rise_delay)
			{
					min_rise_delay=rise_delay;
			}
        	        if(i==wave_start)
			{
				prev_delay_rise = rise_delay;
				peak_to_peak_jitter_rise = 0;
			}
		        if(i!=wave_start)
			{
	 			peak_to_peak_jitter_rise = fabs (max_rise_delay - min_rise_delay);
				prev_delay_rise = rise_delay;
			}	
	                if(peak_to_peak_jitter_rise > max_p2p_jitter_rise)
			{	
				max_p2p_jitter_rise = peak_to_peak_jitter_rise;
				rise_no = (i)/2;
			}
		}
		delay_ddr=delay(diff_pad,i,diff_in,i);
/*		printf("\nDelay %e @ %d:" , delay_ddr,i);
*/		if(delay_ddr>max_delay)
		{
			max_delay=delay_ddr;
		}
		if(delay_ddr<min_delay)
		{
			min_delay=delay_ddr;
		}
		if(i==wave_start+1)
		{
			prev_delay = delay_ddr;
			peak_to_peak_jitter_ddr = 0;
		}
		if(i!=wave_start+1)
		{
		 	peak_to_peak_jitter_ddr = fabs (max_delay - min_delay);
			prev_delay = delay_ddr;
		}
	        if(peak_to_peak_jitter_ddr > max_p2p_jitter_ddr)
		{
			max_p2p_jitter_ddr = peak_to_peak_jitter_ddr;
		no = i;
		}
	}
	ddr_peak_to_peak_jitter = peak_to_peak_jitter_ddr;
/*
	if(ofile=="/dev/null")
	{
*/		printf("\n\n");
		printf("Punchfile           : %s\n",ifile);
		printf("Min Rise Delay      : %e\n",min_rise_delay);
		printf("Max Rise_Delay      : %e\n",max_rise_delay);
		printf("Rise Jitter         : %e\n",(max_rise_delay-min_rise_delay));
		printf("Min_Fall_Delay      : %e\n",min_fall_delay);
		printf("Max_Fall_Delay      : %e\n",max_fall_delay);
		printf("Fall Jitter         : %e\n",(max_fall_delay-min_fall_delay));
		printf("Max P2P Rise Jitter : %e\n",max_p2p_jitter_rise);
		printf("Max P2P Fall Jitter : %e\n",max_p2p_jitter_fall);
		printf("Max Data Jitter     : %e\n",ddr_peak_to_peak_jitter);
/*	}
*/
	ivss_avg=average(ivss);
	ivdd_avg=average(ivdd);
	ivdds_avg=average(ivdds);

	printf("\n");
	fp=fopen(ofile,"w");
	fprintf(fp,"\nRise Transistion : Min Delay = %e   Max Delay = %e   Jitter = %e",min_rise_delay,max_rise_delay,(max_rise_delay-min_rise_delay));
	fprintf(fp,"\nFall Transistion : Min Delay = %e   Max Delay = %e   Jitter = %e",min_fall_delay,max_fall_delay,(max_fall_delay-min_fall_delay));
	fprintf(fp,"\nMax P2P Rise Jitter : %e",max_p2p_jitter_rise);
	fprintf(fp,"\nMax P2P Fall Jitter : %e",max_p2p_jitter_fall);
	fprintf(fp,"\nMax Data Jitter     : %e\n",ddr_peak_to_peak_jitter);
	fprintf(fp,"\nAverage VDD Current : %e",ivdd_avg);
	fprintf(fp,"\nAverage VDDS Current: %e",ivdds_avg);
	fprintf(fp,"\nAverage VSS Current : %e\n",ivss_avg);
	fclose(fp);
}
