#!/bin/bash
#
# You must run this in the Sakai working directory in master branch
# chcherrypick.sh -u (to update your repo)
# chcherrypick.sh -f jiracode (to find a jira in 11.x branch)
# chcherrypick.sh -m (to check the list of pending cherry picks even they are not Verified in jira)
# chcherrypick.sh -v (to check the list of pending cherry picks verbose mode)
# chcherrypick.sh (to check the list of pending cherry picks)
#

SEPARATOR=$'\n'"###"
SEPARATOREND="###"
CNT=1
LASTISSUE=""
MERGE=""
CHECKST="Merge.*Verified"
_VERBOSE=0
VER=11

function log () {
    if [[ $_VERBOSE -eq 1 ]]; then
        echo "$@"
    fi
}

if [ "$1" == "-u" -o "$1" == "-f" ]
then
   if [ "$1" == "-u" ]
   then
     echo "Updating git repo..."
     git checkout master
     git pull upstream master
     git checkout 11.x
     git pull upstream 11.x
   fi
   if [ "$2" != "" ]
   then
     echo "Finding jira in 11.x branch..."
     git checkout 11.x > /dev/null 2>&1
     git log --pretty=oneline --abbrev-commit --since="2016-02-17" | grep $2
   fi
else
 if [ "$1" == "-m" ]
 then
   CHECKST="Merge"
 fi
 if [ "$1" == "-i" ]
 then
   CHECKST="\"customfield_11676\":null"
   VER=12
 fi
 if [ "$1" == "-v" ]
 then
   _VERBOSE="1"
 fi
 TOTAL=`git cherry 11.x master -v | grep -e ^\+.*$ | wc -l`
 echo "Analyzing $TOTAL missing commits from master..."
 for f in $(git cherry 11.x master -v | awk '{if ( $1=="+" ) print $3 " "NR" " substr($2,0,7);}' | sort -k1 | cut -d " " -f 1,3); do
  if [ $((CNT%2)) -eq 0 ]
  then
    if [ "$MERGE" == "11" ]
    then
      echo "git cherry-pick $f"
    fi
    if [[ "$MERGE" == "UNKNOWN" ]] && [[ "$_VERBOSE" == "1" ]];
    then
      git cherry 11.x master -v | grep $f
    fi
    if [[ "$MERGE" == "12" ]];
    then
      echo "https://jira.sakaiproject.org/browse/$ISSUE"
    fi
  else
    ISSUE=`echo $f | sed 's/\,$//g' | sed 's/\:$//g' | sed 's/\;$//g' | sed 's/Batch/SAK\-30521/g' | sed 's/resource\-responsive/SAK\-30564/g' | sed 's/Samigo/DASH\-356/g' | sed 's/LNSBLDR/LSNBLDR/g'`
    if [ "$LASTISSUE" != "$ISSUE" ]
    then
      LASTISSUE=$ISSUE
      if [[ $ISSUE == SAK-* ]] || [[ $ISSUE == SAM-* ]] || [[ $ISSUE == KNL-* ]] || [[ $ISSUE == DASH-* ]] || [[ $ISSUE == RSF-* ]] || [[ $ISSUE == LSNBLDR-* ]];
      then
	 if $(curl -v --silent https://jira.sakaiproject.org/rest/api/2/issue/$ISSUE?fields=status\&fields=customfield_11676 2>&1 | grep -qE $CHECKST)
   then
            echo "$SEPARATOR $ISSUE: $VER.x $SEPARATOREND"
	          MERGE="$VER"
	 else
            log "$SEPARATOR $ISSUE: Not ready for $VER.x $SEPARATOREND"
            MERGE=N
	 fi
	 log "https://jira.sakaiproject.org/browse/$ISSUE"
      else
         if [[ $ISSUE =~ \#?[0-9]{4} ]];
         then
           log "$SEPARATOR GBNG: $ISSUE $SEPARATOREND"
           MERGE=N
         else
           log "$SEPARATOR NONJIRA: $ISSUE $SEPARATOREND"
           MERGE=UNKNOWN
         fi
      fi
    fi
  fi
  CNT=$[CNT + 1]
 done
fi