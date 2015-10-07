#!/tool/pandora64/bin/bash

# SYNTAX:

# Functions ======================================================================================================  {{{1
print_help() {
  echo "Usage:"
  echo "  `basename $0` [OPTIONS]"
  echo
  echo "Options:"
  echo "  -h    Print this help"
  echo "  -s    Summarize"
}


# Option handling ================================================================================================  {{{1
summarize=0
args=('.')

while getopts ":sh" opt; do
  case $opt in
    s)
      # Summarize
      summarize="1"
      ;;

    h)
      print_help
      exit 0
      ;;

    :)
      echo "ERROR: Option -${OPTARG} requires an argument" >&2; echo
      print_help
      exit 1
      ;;

    \?)
      echo "ERROR: Invalid option: -${OPTARG}" >&2; echo
      print_help
      exit 1
      ;;
  esac
  shift $((OPTIND-1))
done

(( $# > 0 )) && args="$@"


# Main ===========================================================================================================  {{{1
for dir in ${args[@]}; do
  for subdir in $(command find $dir -name gather.xml | sed -e 's,/comms/gather.xml$,,'); do
    #echo "Processing ${dir}, ${subdir}"
    if [[ -f "${subdir}/summary.ljd" ]]; then
      total=$(command grep -Po "(?<=Total Number of Jobs : )\d+" "${subdir}/summary.ljd")
      passed=$(command grep -Po "(?<=Number of Passing Jobs : )\d+" "${subdir}/summary.ljd")
      failed=$((total - passed))
      completed=$total
      running=0
    else
      total=$(command grep -c '/exec_dir' ${subdir}/comms/gather.xml)
      passed=$(command find ${subdir} -name PASSED | wc -l)
      failed=$(command find ${subdir} -name FAILED | wc -l)
      completed=$(( passed + failed ))
      running=$(( total - completed ))
    fi

    pass_rate=0
    if (( $completed > 0 )); then
      pass_rate=$(echo "scale=1; $passed*100/($completed)" | command bc)
    fi

    unset sig_dir; declare -A sig_dir
    unset sig_count; declare -A sig_count
    for fail_dir in $(command find -name FAILED); do
      fail_dir=$(dirname $fail_dir)
      sig=$(grep -Poi '(?<=Signature: ).*' $fail_dir/summary.rj)
      cycle=$(grep -Poi '(?<=Cycles:: )\d+' $fail_dir/sim.out)
      printf -v sig_dir["$sig"] '%s<;%d>;%s\n' "${sig_dir[$sig]}" "$cycle" "${fail_dir/#\./$PWD}"
      sig_count["$sig"]=$((${sig_count[$sig]}+1))
    done

    echo
    echo "************************************************************************************************************************"
    echo "* Directory: ${subdir/#'.'/$PWD}"
    echo "* Total=${total}, Pass=${passed}, Fail=${failed}, Running=${running}", Buckets=${#sig_count[@]}
    for sig in "${!sig_count[@]}"; do
      printf "* (%4d) %s\n" ${sig_count["$sig"]} "$sig"
    done
    echo "************************************************************************************************************************"
    echo

    if [[ "$summarize" == "0" ]]; then
      for sig in "${!sig_dir[@]}"; do
        echo "------------------------------------------------------------------------------------------------------------------------"
        echo "* $sig"
        echo "------------------------------------------------------------------------------------------------------------------------"
        echo -e ${sig_dir["$sig"]} | /usr/bin/column -t -s ';'
        echo
      done
    else
      echo
    fi
  done
done
