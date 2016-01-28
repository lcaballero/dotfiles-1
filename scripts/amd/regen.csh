#! /bin/csh

# usage : source regen.csh simid

source /proj/verif_release_ro/cbwa_initscript/current/cbwa_init.csh

mkdir $1
echo "creating $1"
cd $1 
pushd `/proj/sr_rtl_svdc/sra/rel/bdcore/latest/tools/verif/latest_bdcore_regr_build`

# stupid source command started being passed the $argv so I'm clearing it out here
set origArgOne = ($1)
set origArgs = ($argv)
set argv = ""
source $verif_release/cbwa_bootcore/$bootcore_ver/bin/_loadenv.csh

loadenv
popd
echo "regenerating $origArgOne"
source $REPO_PATH/tools/verif/regenerate_fail.csh -s $origArgs
cd wa*/$origArgOne/regenerate/
