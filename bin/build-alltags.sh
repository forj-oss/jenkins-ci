#!/bin/bash
#
# This script is used to build officially all released docker images (tagged) or latest releases
# It requires a tag parameter if a tag build is made. Otherwise, a latest is simply built.
#
# Release workflow is:
#
# - Someone fork and create a new release file under release-notes then submit a PR.
# - Jenkins is started to validate the code as usual and test the release note file (version string must be valid)
# - The repo maintainer at some time will accept the new release proposal and merge it to master.
# - A new job started on Jenkins will tag the code with the version defined in the release note and publish that tag to docker hub (with publish-alltags.sh). github release is created on that tag with all information defined in the release note.

# Latest workflow is:
# - when a new commit is pushed to master, latest is updated.
# - Every tuesday, when a new jenkins version is made available, latest is updated.

source bin/build-fcts.sh

case "$1" in
  release-it )
    export VERSION=$(cat VERSION)
    if [ "$(git tag -l $VERSION)" = "" ]
    then
       echo "Unable to publish a release version. git tag missing"
       exit 1
    fi
    COMMIT="$(git log -1 --oneline| cut -d ' ' -f 1)"
    if [ "$(git tag -l --points-at $COMMIT | grep $VERSION)" = "" ]
    then
       echo "'$COMMIT' is not tagged with '$VERSION'. Only commit tagged can publish officially this tag as docker image."
       exit 1
    fi
    export VERSION_TAG=${VERSION}_
    ;;
  latest )
    export VERSION=latest
    export VERSION_TAG=latest_
    ;;
  *)
    echo "Script used to publish release and latest code ONLY. If you want to test a fork, use build. It will create a local docker image jenkins:test"
    exit 1
esac

getReleaseTags | while read LINE
do
   if [ "$DRY_RUN"  = "--dry-run" ]
   then
       bin/do_build-tag.sh $DRY_RUN "$LINE"
   else
       APP_VERSION=$(echo "$LINE" | awk -F'|' '{ print $1 }')
       LOG=logs/$VERSION_TAG$APP_VERSION.log
       echo "LOG: $LOG"
       mkdir -p logs
       touch logs/$VERSION_TAG$APP_VERSION.run
       nohup bin/do_build-tag.sh $DRY_RUN "$LINE" > $LOG 2>&1 &
       sleep 2
   fi
done

if [ "$DRY_RUN"  = "--dry-run" ]
then
   exit
fi

RUN=$(ls -l logs/*.run | wc -l)
RUN_OLD=0

while [ ${RUN} -ne 0 ]
do
    if [[ ${RUN_OLD} -ne ${RUN} ]]
    then
       runnings="$(ls logs/*.run 2>/dev/null | sed 's|logs/\(.*\)\.run|\1|g'| tr '\n' ' ')"
       printf "%s publish running ($runnings)\n" ${RUN}
       RUN_OLD=${RUN}
    fi
    sleep 2
    RUN=$(ls -l logs/*.run 2>/dev/null| wc -l)
done
echo "DONE"
