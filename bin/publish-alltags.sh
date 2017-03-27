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

TAG_BASE="forjdevops/jenkins-dood"

if [ ! -f VERSION ] || [ ! -f releases.lst ]
then
   echo "VERSION or releases.lst files not found. Please move to the repo root dir and call back this script."
   exit 1
fi

case "$1" in
  release-it )
    VERSION=$(cat VERSION)
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
    VERSION_TAG=${VERSION}_
    ;;
  latest )
    VERSION=latest
    VERSION_TAG=latest_
    ;;
  *)
    echo "Script used to publish release and latest code ONLY. If you want to test a fork, use build. It will create a local docker image jenkins-dood:test"
    exit 1
esac

cat releases.lst | while read LINE
do
   [[ "$LINE" =~ ^# ]] && continue
   export JENKINS_VERSION="$(echo "$LINE" | awk -F'|' '{ print $1 }')"
   TAGS="$(echo "$LINE" | awk -F'|' '{ print $2 }' | sed 's/,/ /g')"
   echo "=============== Building jenkins-dood flavor Jenkins $JENKINS_VERSION"
   $(dirname $0)/build.sh $TAG_BASE:${VERSION}_$JENKINS_VERSION
   echo "=============== Publishing flavored tags"
   for TAG in $TAGS
   do
      echo "=> $TAG_BASE:${VERSION}_$TAG"
      sudo docker tag $TAG_BASE:${VERSION}_$JENKINS_VERSION $TAG_BASE:${VERSION}_$TAG
      sudo docker push $TAG_BASE:${VERSION}_$TAG
   done
   echo "=============== DONE - Flavor Jenkins $JENKINS_VERSION"
done
export JENKINS_VERSION="$(cat releases.lst | tail -n 1 | awk -F'|' '{ print $1 }')"
echo "=============== Publishing latest tags with Default Flavor $JENKINS_VERSION embedded.
=> $TAG_BASE:$VERSION"
sudo docker push $TAG_BASE:$VERSION
echo "=> $TAG_BASE:latest ($TAG_BASE:${VERSION}_$JENKINS_VERSION)"
sudo docker tag $TAG_BASE:${VERSION}_$JENKINS_VERSION $TAG_BASE
sudo docker push $TAG_BASE
echo "=============== DONE"
