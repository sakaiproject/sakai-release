#!/bin/bash
#
#

function log () {
    if [[ $_VERBOSE -eq 1 ]]; then
        echo "$@"
    fi
}
if [ "$1" == "-v" ]
then
 git cherry 11.x master -v --abbrev=10 | grep '^+' | grep --invert-match -E 'SAK-|KNL-|SAM-|LSNBLDR-|LNSBLDR-|LSNBDLR-|DASH-|RSF-|Sak-' | grep -E '(\#|\s)[0-9]{4}(\:|\s|$)*'
else
 if [ "$1" == "-a" ]
 then
   git cherry 11.x master -v --abbrev=10 | grep '^+' | grep --invert-match -E 'SAK-|KNL-|SAM-|LSNBLDR-|LNSBLDR-|LSNBDLR-|DASH-|RSF-|Sak-|(\#|\s)[0-9]{4}(\:|\s|$)*'
 else
   for f in $(git cherry 11.x master -v --abbrev=10 | grep '^+' | grep --invert-match -E 'SAK-|KNL-|SAM-|LSNBLDR-|LNSBLDR-|LSNBDLR-|DASH-|RSF-|Sak-' | grep -E '(\#|\s)[0-9]{4}(\:|\s|$)*' | awk '{print $2;}'); do      
     echo "git cherry-pick $f"
   done
 fi
fi