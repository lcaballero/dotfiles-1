#!/apps/ame/bin/codac
/*
	Script to print the names of all the signals in the punchfile
	Written by Kartik Shenoy
*/

main(string punchfile) {

	waveform vin;
	readspicepunch(punchfile);

	print("Signals present in the waveform are :-");
	while(nextsignal(vin)){
		printf("  %s\n",getsigname(vin));
	}
	print("\n");
}
