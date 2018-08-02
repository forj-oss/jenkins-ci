#!/usr/bin/env bash

if [  "$1" = "--dry-run" ]
then
    export DOCKER_CMD="echo docker"
    echo "Dry run"
    shift
else
    export DOCKER_CMD="sudo docker"
fi

export JENKINS_VERSION="$(echo "$1" | awk -F'|' '{ print $1 }')"
TAGS="$(echo "$1" | awk -F'|' '{ print $2 }' | sed 's/,/ /g')"
STABLE="$(echo "$1" | awk -F'|' '{ print $3 }' | sed 's/,/ /g')"
echo "=============== Building jenkins flavor Jenkins $JENKINS_VERSION"
$(dirname $0)/build.sh $TAG_BASE:${VERSION}_$JENKINS_VERSION $STABLE
echo "=============== Publishing flavored tags: $TAGS"
for TAG in $TAGS
do
  echo "=> $TAG_BASE:${VERSION}_$TAG"
  $DOCKER_CMD tag $TAG_BASE:${VERSION}_$JENKINS_VERSION $TAG_BASE:${VERSION}_$TAG
  $DOCKER_CMD push $TAG_BASE:${VERSION}_$TAG
done
echo "=============== DONE - Flavor Jenkins $JENKINS_VERSION"
if [ "$JENKINS_VERSION" = "$(cat releases.lst | tail -n 1 | awk -F'|' '{ print $1 }')" ]
then
   echo "=============== Publishing latest tags with Default Flavor $JENKINS_VERSION embedded."
   if [ $VERSION != latest ]
   then
        echo "=> $TAG_BASE:$VERSION"
        set -x
        $DOCKER_CMD push $TAG_BASE:$VERSION
        set +x
   fi
   echo "=> $TAG_BASE:latest ($TAG_BASE:${VERSION}_$JENKINS_VERSION)"
   set -x
   $DOCKER_CMD tag $TAG_BASE:${VERSION}_$JENKINS_VERSION $TAG_BASE:latest
   $DOCKER_CMD push $TAG_BASE:latest
   set +x
   echo "=============== DONE"
fi
rm -f logs/$VERSION_TAG$JENKINS_VERSION.run
