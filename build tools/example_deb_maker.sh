#!/bin/bash
# @date:            11apr15
# @name:            example_deb_mkr
# @author:          Austin Matthews
# @description:     create example .deb with version headers
# @notes:           git_branches - list of branch names in git '$branch'
#                   release_name - list of release names '$sVer'
#                   start_date   - list of release start dates
# @debug:           enable DEBUG mode with 'set -x -v'
#set -x -v

# @functions:
sLib="/root/bin/deb_functions.sh"
if [ -f ${sLib} ]; then
  . ${sLib}; logTee "[pre-flight] sourced function library -- ${sLib} "
else
  echo "[FATAL] failed to import function library -- check ${sLib} "; exit 2
fi

# @variables:
git_branches=( "beta"        "development"   "production" )
release_name=( "1.0.2"       "2.1.3"         "3.0.3"      )
start_date=(   "11/1/2014"   "11/1/2014"     "11/1/2014"  )

# @pre-flight:
checkRoot
checkLock
# verify branch_count equals release_count
branches_count=${#git_branches[@]}
releases_count=${#release_name[@]}
st_dates_count=${#start_date[@]}
if [ $branches_count -ne $releases_count ] || [ $branches_count -ne $st_dates_count ]; then
  error "Brances / Releases / Start Date missmatch -- exiting"
fi
logsOn
cd /opt
index=0
while [ "$index" -lt "$branches_count" ]; do
# @stage_one: check github for any updates or exit
  logTee " ${git_branches[$index]} git pull stage begin"
  branch=${git_branches[$index]}
  sVer=${release_name[$index]}
  pushd $branch
  gitStage
  if [ $? -eq 1 ]; then
    logTee "  zero changes since last build "
    let index=$index+1
    popd
    continue
  fi
# @stage_two: write header to all python files and rm all .pyc files
  debStage2
  find -name "*.py" -exec sed -i "1i #!\/usr\/bin\/env python   \n# Example, Inc.     $branch \n# Copyright 2015\n " {} \; && find -name "*.py" -exec sed -i '/^\#!\/usr\/bin\/env python$/d' {} \;
  find /opt/example -name "*.pyc" -exec rm -f {} \;
  debStage2Post
# @stage_three: bundle as a debian package
  stage3
  let index=$index+1
done
scanDpkg /opt/packages/
logsOff
