#!/bin/bash
#
#

function log () {
    if [[ $_VERBOSE -eq 1 ]]; then
        echo "$@"
    fi
}
git cherry 11.x master -v --abbrev=10 | grep '^+' | grep --invert-match -E 'SAK-|KNL-|SAM-|LSNBLDR-|LNSBLDR-|LSNBDLR-|DASH-|RSF-|Sak-|(\#|\s)[0-9]{4}(\:|\s|$)*'
