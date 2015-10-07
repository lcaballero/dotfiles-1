#!/apps/ame/bin/codac
/*
	Codac script to calculate average VDDS power
*/

main(string ifile){
	
	waveform ivdds;
	waveform vdds;
	float ivdds_avg,vvdds_avg,pvdds_avg;
	
	readspicepunch(ifile);
	ivdds=readwave(ifile,"ivddsext");
	vdds=readwave(ifile,"vvddsext");

	ivdds_avg=average(ivdds,1e-6,1.3e-6);
	vvdds_avg=average(vdds,1e-6,1.3e-6);
	pvdds_avg=(-ivdds_avg-45e-3)*vvdds_avg;

	printf("  Average VDDS Current = %f\n",ivdds_avg);
	printf("  Average VDDS Value   = %f\n",vvdds_avg);
	printf("  Average VDDS Power   = %f\n",pvdds_avg);
}
