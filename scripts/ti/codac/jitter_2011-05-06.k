#!/apps/ame/bin/codac
/*

    Codac Script to calculate P2P, C2C and Source-synchronous Jitter
    Written by Kartik Shenoy (a0393831)

    SYNTAX: codac <jitter> <punchfile>

    DESCRIPTION:
      The name of the signal should be specified in "sig_prenorm","sign_prenorm"

      Setup:-
        Setup should be specified by setting the variable "setup" to "Normal" or "SrcSyn"
        Normal mode is to measure jitter of one/same signal at different points in the circuit
          eg. To measure jitter at pad/y etc for LVCMOS Tx/Rx

      Trigger:-
        Jitter calculation can be performed with respect to an ideal trigger or a reference signal
          by setting the variable "trigger" to "Ideal" or "Reference" respectively
        When ideal trigger is selected, the frequency should be specified in "ref_freq"
        When trigger=Reference, the name of the reference signal should be set in "ref_prenorm","refn_prenorm"

      Normalisation:-
        Supports normalisation of signal (and independently of the reference if selected) prior to jitter computation.
        Normalisation can be selected by setting the variables "norm_type_sig" and "norm_type_ref"
        Normalisation modes supported are "Static", "Dynamic" and "None"
        To disable normalisation, set variables "norm_type_*" to "None"
        To perform static normalisation, the DC values of the supplies (and ground)
          should be set using the variables "*_pwr_dc" and "*_gnd_dc"
        To perform dynamic normalisation, the supplies themselves should be punched and
          the variables "*_pwr" and "*_gnd" should be set appropriately

    CHANGELOG:
      2011-05-05: Added support for source-synchronous jitter measurements

*/


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


main(string ifile){

/* Variable declaration */
    waveform sig,sig_prenorm,sign_prenorm;
    waveform sig_pwr,sig_gnd;
    waveform ref,ref_prenorm,refn_prenorm;
    waveform ref_pwr,ref_gnd;

    int tran,tran_start,tran_stop,tran_total_sig,tran_total_ref,tran_sig,tran_sig_next;
    int num_odd,num_even;

    float ref_freq,ui;
    float sig_pwr_dc,ref_pwr_dc;
    float time,time_stop;
    float delta,delta_odd_prev,delta_even_prev,delta_setup,delta_hold;
    float jitter_p2p_odd,jitter_p2p_even,jitter_p2p_period,jitter_c2c,jitter_srcsyn;

    string ofile;
    string trigger,norm_type_sig,norm_type_ref,setup;

    string str_delta_odd_min,str_delta_odd_max;
    string str_delta_even_min,str_delta_even_max;
    string str_jitter_c2c_odd_max,str_jitter_c2c_even_max;
    string str_jitter_p2p_odd,str_jitter_p2p_even,str_jitter_p2p_period;
    string str_jitter_srcsyn;
    string str_setup_max,str_setup_min,str_hold_max,str_hold_min;

    file fp;


/* Initialisation values. Don't change unless required */
    float delta_odd_min=1e34;
    float delta_odd_max=-1e34;
    float delta_even_min=1e34;
    float delta_even_max=-1e34;
    float delta_period_min=1e34;
    float delta_period_max=-1e34;
    float jitter_c2c_odd_max=-1e34;
    float jitter_c2c_even_max=-1e34;
    float setup_min=1e34;
    float setup_max=-1e34;
    float hold_min=1e34;
    float hold_max=-1e34;


    sprintf(ofile,"%s.txt",ifile);


/* The transition from  which computation must start */
    tran_start = 1;


/* Jitter setup to be used : Normal/SrcSyn */
/* Normal : Normal jitter setup, input and output are the same signal at different points in the circuit */
/* SrcSyn : Source-synchronous jitter setup */
    setup = "Normal";


/* Choose Trigger Type : Ideal/Reference */
/* Ideal     : Jitter calculations will be done wrt. an ideal clock of the specified frequency (ref_freq) */
/* Reference : Jitter calculations will be done wrt. the specified reference signal */
    trigger  = "Ideal";
    ref_freq = 1;


/* Normalisation Type : Dynamic/Static/None */
/* In case of Static normalisation, enter the DC values of the voltage sources, for input and sigput signals, below */
/* In case of Dynamic normalisation, ensure that the waveforms of the voltage sources, for input and sigput signals, are punched sig */
    norm_type_sig = "None";
    norm_type_ref = "None";


/* Reading waveforms */
    readspicepunch(ifile);
    sig_prenorm = readwave(ifile,"");
    sign_prenorm = 0;

    if(trigger=="Reference"){
        ref_prenorm = readwave(ifile,"");
        refn_prenorm = 0;
    }


/* Supplies for signals */
    if(norm_type_sig=="Dynamic"){
        sig_pwr = readwave(ifile,"");
        sig_gnd = 0;
    }else if(norm_type=="Static"){
        sig_pwr_dc = 0;
        sig_gnd_dc = 0;
    }
    if(trigger=="Reference" && norm_type_ref=="Dynamic"){
        ref_pwr = readwave(ifile,"");
        ref_gnd = 0;
    }else if(trigger=="Reference" && norm_type_ref=="Static"){
        ref_pwr_dc = 0;
        ref_gnd_dc = 0;
    }


/* Converting differential single to single-ended (P-N) */
    sig_prenorm -= sign_prenorm;
    if(trigger=="Reference"){
        ref_prenorm -= refn_prenorm;
    }


/* Normalising the signals here */
/* Note that in the absence of ground noise, this reduces to (sig=sig_prenorm/sig_pwr) viz an accurate representation */
/* However, in the presence of ground noise, the below formula is only an approximation */
    if(norm_type_sig=="Dynamic"){
        printf("\nApplying Dynamic normalisation to the signal");
        sig = (sig_prenorm-sig_gnd)/(sig_pwr-sig_gnd);
    }else if(norm_type_sig=="Static"){
        printf("\nApplying Static normalisation to the signal");
        sig = (sig_prenorm-sig_gnd_dc)/(sig_pwr_dc-sig_gnd_dc);
    }else if(norm_type_sig=="None"){
        printf("\nNormalisation not done for the signal");
        sig = sig_prenorm;
    }else{
        printf("\nPlease enter proper normalisation type");
        exit(1);
    }
    if(trigger == "Reference"){
        if(norm_type_ref=="Dynamic"){
            printf("\nApplying Dynamic normalisation to the reference");
            ref = (ref_prenorm-ref_gnd)/(ref_pwr-ref_gnd);
        }else if(norm_type_ref=="Static"){
            printf("\nApplying Static normalisation to the reference");
            ref = (ref_prenorm-ref_gnd_dc)/(ref_pwr_dc-ref_gnd_dc);
        }else if(norm_type_ref=="None"){
            printf("\nNormalisation not done for the reference");
            ref = ref_prenorm;
        }else{
            printf("\nPlease enter proper normalisation type");
            exit(1);
        }
    }


    setsighigh(0.2,sig);
    setsigcent(0,sig);
    setsiglow(-0.2,sig);

    if(trigger=="Reference"){
        setsighigh(0.2,ref);
        setsigcent(0,ref);
        setsiglow(-0.2,ref);
    }


    if(setup=="SrcSyn"){

        if(trigger=="Reference"){
            tran_stop = gettransitions(ref);
        }else{
            tran_total_sig = gettransitions(sig);
            time_stop = gettransitiontime(sig,tran_total_sig);
            tran_stop = time_stop/(0.5/ref_freq) + 1;
        }

        for(tran=tran_start,tran_sig=tran_start;tran<=tran_stop;tran++){

            tran_sig_next=tran_sig+1;
            if(trigger=="Reference"){
                delta_setup = delay(ref,tran,sig,tran_sig);
                delta_hold  = delay(sig,tran_sig_next,ref,tran);
            }else{
/*                time=gettransitiontime(sig,tran);
                delta = time-(tran)*(0.5/ref_freq);
              printf("\n\n  %3d    : Time  = %e",tran,time);
*/          }

            if(delta_setup < ui){
                setup_min = min(setup_min,delta_setup);
                setup_max = max(setup_max,delta_setup);
/*              printf("\n    Setup : Delta = %e : Max = %e : Min = %e",delta_setup,delta_setup_max,delta_setup_min);*/
            }

            if(delta_hold < ui){
                hold_min = min(hold_min,delta_hold);
                hold_max = max(hold_max,delta_hold);
/*              printf("\n    Hold  : Delta = %e : Max = %e : Min = %e",delta_hold,delta_hold_max,delta_hold_min);*/

                tran_sig++;
            }

        }

        jitter_srcsyn = setup_max-setup_min;

        str_jitter_srcsyn = unitify(jitter_srcsyn);
        str_setup_max     = unitify(setup_max);
        str_setup_min     = unitify(setup_min);
        str_hold_max      = unitify(hold_max);
        str_hold_min      = unitify(hold_min);

        printf("\n");

        printf("Punch file      : %s\n",ifile);
        printf("\n");
        printf("Source-sync jitter = %s",str_jitter_srcsyn);
        printf("  Max Setup Time   = %s",str_setup_max);
        printf("  Min Setup Time   = %s",str_setup_min);
        printf("  Max Hold Time    = %s",str_hold_max);
        printf("  Min Hold Time    = %s",str_hold_min);

        printf("\n\n");

        fp=fopen(ofile,"w");
        fprintf(fp,"Punch file      : %s\n",ifile);
        fprintf(fp,"\n");
        fprintf(fp,"Source-sync jitter = %e",jitter_srcsyn);
        fprintf(fp,"  Max Setup Time   = %e",setup_max);
        fprintf(fp,"  Min Setup Time   = %e",setup_min);
        fprintf(fp,"  Max Hold Time    = %e",hold_max);
        fprintf(fp,"  Min Hold Time    = %e",hold_min);

        fclose(fp);

    }else{

        tran_total_sig = gettransitions(sig);
        if(trigger=="Reference"){
            tran_total_ref = gettransitions(ref);
            if(tran_total_ref != tran_total_sig){
                printf("\n\nWARNING : The number of transitions in the input and output signals do not match");
                printf("\n  Transitions in Signal    : %d",tran_total_sig);
                printf("\n  Transitions in Reference : %d",tran_total_ref);

                tran_stop = min(tran_total_ref,tran_total_sig);
                printf("\n  Computing till transition number %d",tran_stop);
            }else{
                tran_stop = tran_total_ref;
            }

        }else{
            tran_stop = tran_total_sig;
        }

        for(tran=tran_start;tran<=tran_stop;tran++){

            if(trigger=="Reference"){
                delta = delay(sig,tran,ref,tran);
            }else{
                time=gettransitiontime(sig,tran);
                delta = time-(tran)*(0.5/ref_freq);
/*              printf("\n\n  %3d    : Time  = %e",tran,time);*/
            }

            if((tran-tran_start)%2==1){

                delta_odd_max = max(delta_odd_max,delta);
                delta_odd_min = min(delta_odd_min,delta);

                if(tran==tran_start+1){
                    delta_odd_prev = delta;
                    jitter_c2c = 0;
                }else{
                    jitter_c2c = fabs(delta-delta_odd_prev);
                    delta_odd_prev = delta;
                }

                if(jitter_c2c > jitter_c2c_odd_max){
                    jitter_c2c_odd_max = jitter_c2c;
                    num_odd = (tran)/2;
                }
/*              printf("\n    Odd  : Delta = %e : Max = %e : Min = %e",delta,delta_odd_max,delta_odd_min);*/
            }

            if((tran-tran_start)%2==0){

                delta_even_max = max(delta_even_max,delta);
                delta_even_min = min(delta_even_min,delta);

                if(tran==tran_start){
                    delta_even_prev = delta;
                    jitter_c2c = 0;
                }else{
                    jitter_c2c = fabs(delta-delta_even_prev);
                    delta_even_prev = delta;
                }

                if(jitter_c2c > jitter_c2c_even_max){
                    jitter_c2c_even_max = jitter_c2c;
                    num_even = (tran+1)/2;
                }
/*              printf("\n    Even : Delta = %e : Max = %e : Min = %e",delta,delta_even_max,delta_even_min);*/
            }

            delta_period_max = max(delta_period_max,delta);
            delta_period_min = min(delta_period_min,delta);
/*          printf("\n    Data : Delta = %e : Max = %e : Min = %e : Diff = %e",delta,delta_period_max,delta_period_min,delta_period_max-delta_period_min);*/

        } /* End of setup!="SrcSyn" -> for loop */


        jitter_p2p_odd    = delta_odd_max    - delta_odd_min;
        jitter_p2p_even   = delta_even_max   - delta_even_min;
        jitter_p2p_period = delta_period_max - delta_period_min;

        str_delta_odd_max       = unitify(delta_odd_max);
        str_delta_even_max      = unitify(delta_even_max);
        str_delta_odd_min       = unitify(delta_odd_min);
        str_delta_even_min      = unitify(delta_even_min);
        str_jitter_p2p_odd      = unitify(jitter_p2p_odd);
        str_jitter_p2p_even     = unitify(jitter_p2p_even);
        str_jitter_c2c_odd_max  = unitify(jitter_c2c_odd_max);
        str_jitter_c2c_even_max = unitify(jitter_c2c_even_max);
        str_jitter_p2p_period   = unitify(jitter_p2p_period);

        printf("\n");

        printf("Punch file      : %s\n",ifile);
        printf("\n");
        printf("Period jitter   = %s",str_jitter_p2p_period);
        printf("\n");
        if(isfall(sig,tran_start)){
            printf("P2P rise jitter = %s\n",str_jitter_p2p_odd);
            printf("C2C rise jitter = %s in transition no. %d\n",str_jitter_c2c_odd_max,num_odd);
            printf("Rise min delta  = %s ; max delta = %s\n",str_delta_odd_min,str_delta_odd_max);
            printf("\n");
            printf("P2P fall jitter = %s\n",str_jitter_p2p_even);
            printf("C2C fall jitter = %s in transition no. %d\n",str_jitter_c2c_even_max,num_even);
            printf("Fall min delta  = %s ; max delta = %s\n",str_delta_even_min,str_delta_even_max);
        }else{
            printf("P2P rise jitter = %s\n",str_jitter_p2p_even);
            printf("C2C rise jitter = %s in transition no. %d\n",str_jitter_c2c_even_max,num_even);
            printf("Rise min delta  = %s ; max delta = %s\n",str_delta_even_min,str_delta_even_max);
            printf("\n");
            printf("P2P fall jitter = %s\n",str_jitter_p2p_odd);
            printf("C2C fall jitter = %s in transition no. %d\n",str_jitter_c2c_odd_max,num_odd);
            printf("Fall min delta  = %s ; max delta = %s\n",str_delta_odd_min,str_delta_odd_max);
        }
        printf("\n\n");

        fp=fopen(ofile,"w");
        fprintf(fp,"Punch file      : %s\n",ifile);
        fprintf(fp,"\n");
        fprintf(fp,"Period jitter   = %e\n",jitter_p2p_period);
        fprintf(fp,"\n");
        if(isfall(sig,tran_start)){
            fprintf(fp,"P2P rise jitter = %e\n",jitter_p2p_odd);
            fprintf(fp,"C2C rise jitter = %e in transition no. %d\n",jitter_c2c_odd_max,num_odd);
            fprintf(fp,"Rise min delta  = %e ; max delta = %e\n",delta_odd_min,delta_odd_max);
            fprintf(fp,"\n");
            fprintf(fp,"P2P fall jitter = %e\n",jitter_p2p_even);
            fprintf(fp,"C2C fall jitter = %e in transition no. %d\n",jitter_c2c_even_max,num_even);
            fprintf(fp,"Fall min delta  = %e ; max delta = %e\n",delta_even_min,delta_even_max);
        }else{
            fprintf(fp,"P2P rise jitter = %e\n",jitter_p2p_even);
            fprintf(fp,"C2C rise jitter = %e in transition no. %d\n",jitter_c2c_even_max,num_even);
            fprintf(fp,"Rise min delta  = %e ; max delta = %e\n",delta_even_min,delta_even_max);
            fprintf(fp,"\n");
            fprintf(fp,"P2P fall jitter = %e\n",jitter_p2p_odd);
            fprintf(fp,"C2C fall jitter = %e in transition no. %d\n",jitter_c2c_odd_max,num_odd);
            fprintf(fp,"Fall min delta  = %e ; max delta = %e\n",delta_odd_min,delta_odd_max);
        }
        fclose(fp);

    } /* End of setup!="SrcSyn" */

}
