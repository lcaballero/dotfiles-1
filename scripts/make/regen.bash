#!/bin/bash
# Usage: regen.bash simid

. /proj/verif_release_ro/cbwa_initscript/current/cbwa_init.bash

echo "Creating ${1}..."
mkdir $1 && cd $1
pushd `/proj/sr_rtl_svdc/sra/rel/bdcore/latest/tools/verif/latest_bdcore_regr_build`

# stupid source command started being passed the $argv so I'm clearing it out here
origArgOne=($1)
origArgs=($argv)
argv=""
. $verif_release/cbwa_bootcore/$bootcore_ver/bin/_loadenv.bash

loadenv
popd
echo "Regenerating $origArgOne ..."
. $REPO_PATH/tools/verif/regenerate_fail.bash -s $origArgs
cd wa*/$origArgOne/regenerate/
