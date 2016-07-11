#!/bin/bash
#The provided list is pulled out of the pom.xml from the release with xmlstarlet
#xmlstarlet sel -N x="http://maven.apacherg/POM/4.0.0" -t -v "//x:profile/x:modules[../x:id/text() = 'sakai-provided']" pom.xml | sed '/^$/d' | sed -e 's/\s*\(\S*\)/"\1"/' | tr "\n" " "
#Search is based on http://unix.stackexchange.com/questions/6463/find-searching-in-parent-directories-instead-of-subdirectories

#Put this in the top level of your tagged directory (like 10.2) and change theses descriptions.

#You need to create a staging repo first. This might change again in 10.3

stagingrepo="orgsakaiproject-1032"
description="Sakai 10.2 release"

#Don't include master in this yet
provided=( "jsf" "velocity" "reset-pass/account-validator-api" "announcement/announcement-api/api" "assignment/assignment-api/api" "basiclti/basiclti-api" "external-calendaring-service/api" "calendar/calendar-api/api" "calendar/calendar-hbm" "common/archive-api" "common/impl" "common/import-impl" "common/edu-person-api" "common/manager-api" "common/type-api" "common/privacy-api" "common/privacy-hbm" "content/content-copyright/api" "content-review/content-review-api/model" "content-review/content-review-api/public" "courier/courier-api/api" "delegatedaccess/api" "edu-services/cm-service/cm-api/api" "edu-services/gradebook-service/api" "edu-services/gradebook-service/hibernate" "edu-services/scoring-service/api" "edu-services/sections-service/sections-api" "edu-services/sections-service/sections-impl/sakai/impl" "edu-services/sections-service/sections-impl/standalone" "edu-services/sections-service/sections-impl/integration-support" "edu-services/sections-service/sections-impl/sakai/model" "emailtemplateservice/api" "entitybroker/api" "entitybroker/utils" "hierarchy/api" "kernel/component-manager" "kernel/api" "kernel/kernel-util" "kernel/test-harness" "lessonbuilder/api" "lessonbuilder/hbm" "login/login-api/api" "mailarchive/mailarchive-api/api" "mailsender/api" "message/message-api/api" "metaobj/metaobj-api/api" "msgcntr/messageforums-api" "msgcntr/messageforums-hbm" "" "polls/api" "portal/portal-api/api" "portal/portal-render-api/api" "" "portal/portal-util/util" "presence/presence-api/api" "profile2/api" "chat/chat-api/api" "citations/citations-api/api" "help/help-component-shared" "dav/dav-common" "help/help-api" "web/news-api/api" "podcasts/podcasts-api" "postem/postem-api" "rights/rights-api/api" "rwiki/rwiki-api/api" "syllabus/syllabus-api" "usermembership/api" "web/web-api/api" "samigo/samigo-api" "samigo/samigo-hibernate" "samigo/samigo-services" "samigo/samigo-qti" "jobscheduler/scheduler-api" "jobscheduler/scheduler-component-shared" "jobscheduler/scheduler-events-model" "search/search-api/api" "search/search-util" "shortenedurl/api" "signup/api" "site-manage/site-association-api/api" "site-manage/site-association-hbm/hbm" "site-manage/site-manage-api/api" "site-manage/site-manage-hbm" "sitestats/sitestats-api" "sitestats/sitestats-impl-hib" "taggable/taggable-api/api" "taggable/taggable-hbm/hbm" "userauditservice/api" "warehouse/warehouse-api/api" )
set -e

curpwd=`pwd`
for path in "${provided[@]}"; do
  path="$curpwd/$path"
  pushd .
  while [[ "`readlink -f $path`" != "${curpwd}" ]]; do
     echo "find \"$path\"  -maxdepth 1 -mindepth 1 -name \"pom.xml\" -printf \"%h\""
     match=`find "$path"  -maxdepth 1 -mindepth 1 -name "pom.xml" -printf "%h"`
     if [ -n "${match}" ]; then
      cd $match
      mvn deploy -N -Psakai-release -Dmaven.test.skip=true -Ddescription="$description" -DstagingRepositoryId=$stagingrepo
     fi
     #Move back one
     path=${path}/..
  done
  popd
done 
