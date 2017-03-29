#!/bin/bash
#
# This script is used to publish officially all released docker images (tagged)
#
# Release workflow is:
#
# - Someone fork and create a tag release then submit a PR.
# - GitHub jenkins can be started to start an 'ITG' image validation
# - The repo maintainer at some time will accept the new release.
# - Github should send a jenkins job to build officially this new release
#   I expect to get this info in $1 (Release number)

# Then this job should implement the following code in jenkins
# And jenkins-ci images for each flavors will be officially pushed to the internal registry.

export TAG_BASE="forjdevops/jenkins-dood"

if [ ! -f VERSION ] || [ ! -f releases.lst ]
then
   echo "VERSION or releases.lst files not found. Please move to the repo root dir and call back this script."
   exit 1
fi

if [ "$1" = "--dry-run" ]
then
    DRY_RUN="--dry-run"
    shift
else
    DRY_RUN=""
fi

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
    echo "Script used to publish release and latest code ONLY. If you want to test a fork, use build. It will create a local docker image jenkins-dood:test"
    exit 1
esac

cat releases.lst | while read LINE
do
   [[ "$LINE" =~ ^# ]] && continue

   if [ "$DRY_RUN"  = "--dry-run" ]
   then
       bin/do_build-tag.sh $DRY_RUN "$LINE"
   else
       APP_VERSION=$(echo "$LINE" | awk -F'|' '{ print $1 }')
       LOG=logs/$APP_VERSION.log
       echo "LOG: $LOG"
       mkdir -p logs
       touch logs/$APP_VERSION.run
       nohup bin/do_build-tag.sh $DRY_RUN "$LINE" > $LOG 2>&1 &
       sleep 2
   fi
done

if [ "$DRY_RUN"  = "--dry-run" ]
then
   exit
fi

RUN=$(ls -l logs/*.run | wc -l)

while [ $RUN -ne 0 ]
do
    printf "%s publish running\e[J\r" $RUN
    sleep 2
    RUN=$(ls -l logs/*.run | wc -l)
done
echo "DONE"
