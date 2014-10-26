#!/bin/sh
if [ -z $REPO_PATH ]; then
  echo "REPO_PATH is unset!"
  exit 1
fi

# directories to search
TAG_DIRS=($REPO_PATH/libs/verif $REPO_PATH/ch)
export TAGS_DB=$REPO_PATH/.tags
export CSCOPE_DB=$REPO_PATH/.cscope.out

# Clean up temp files
rm -f $TAGS_DB
rm -f $CSCOPE_DB

# Find files
find ${TAG_DIRS[@]} -type f \( -iname "*.h" -or -iname "*.cc" \) >| $REPO_PATH/tags.filelist
# Follow symlinks for generates files
find ${TAG_DIRS[@]} -type l \( -iname "*.h" -or -iname "*.cc" \) -exec readlink '{}' \; >> $REPO_PATH/tags.filelist

/tool/pandora64/latest/bin/ctags --languages=c++ --c++-kinds=+p --fields=+Sail --extra=+q -L $REPO_PATH/tags.filelist -f $TAGS_DB 2> /dev/null &
cscope -bqk -i $REPO_PATH/tags.filelist -f $CSCOPE_DB 2> /dev/null &

wait
rm -f $REPO_PATH/tags.filelist
