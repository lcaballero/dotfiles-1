#!/bin/sh
if [ -z $REPO_PATH ]; then
  echo "REPO_PATH is unset!"
  exit 1
fi

# directories to search
TAG_DIRS=($REPO_PATH/libs/verif $REPO_PATH/ch $REPO_PATH/import/avf)
# clean up temp files
rm -f $REPO_PATH/tags.filelist
rm -f $REPO_PATH/tags
rm -f $REPO_PATH/cscope.out
# find files
find ${TAG_DIRS[@]} -type f \( -iname "*.h" -or -iname "*.cc" \) > $REPO_PATH/tags.filelist
# follow symlinks for generates files
find ${TAG_DIRS[@]} -type l \( -iname "*.h" -or -iname "*.cc" \) -exec readlink '{}' \; >> $REPO_PATH/tags.filelist
/tool/pandora64/latest/bin/ctags --languages=c++ --c++-kinds=+p --fields=+Sail --extra=+q -L $REPO_PATH/tags.filelist -f $REPO_PATH/tags &
cscope -b -i $REPO_PATH/tags.filelist -f $REPO_PATH/cscope.out &
wait
