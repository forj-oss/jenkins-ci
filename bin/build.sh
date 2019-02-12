#!/bin/bash -e
#
#

BASE_TAG="jenkins"

JENKINS_FEATURES_REPO=https://github.com/forj-oss/jenkins-install-inits

source $(dirname $0)/build-fcts.sh

if [ "$http_proxy" != "" ]
then
   PROXY=" --build-arg http_proxy --build-arg https_proxy"
   echo "Using your local proxy setting : $http_proxy"
   if [ "$no_proxy" != "" ]
   then
      PROXY="$PROXY --build-arg no_proxy"
      echo "no_proxy : $no_proxy"
   fi
fi

if [ "$DOCKER_VERSION" != "" ]
then
   DOCKER_VERSION_ARG="--build-arg DOCKER_VERSION=$DOCKER_VERSION"
fi

SOURCE="$2"
if [[ "$SOURCE" = "" ]]
then
   SOURCE=redhat
fi

if [[ "$JENKINS_VERSION" = "" ]]
then
   jenkinsVersion "regexp:.*" $2
fi
echo "Using jenkins version $JENKINS_VERSION in branch $2."

JENKINS_VERSION_ARG="--build-arg JENKINS_VERSION=$JENKINS_VERSION"

if [ "$1" != "" ]
then
   TAG_NAME="$1"
else
   TAG_NAME="$BASE_TAG:test"
fi
TAG_ARG="-t $TAG_NAME"

if [[ "$2" != "redhat-stable" ]]
then
    OS="--build-arg OS=redhat"
fi

[[ ! -z $JENKINS_INSTALL_INITS_URL ]] && JENKINS_INSTALL_URL_FLAG="--build-arg JENKINS_INSTALL_INITS_URL=$JENKINS_INSTALL_INITS_URL"

if [ "$(echo "$TAG_NAME" | awk ' $1 ~ /\//')" = "" ]
then
   echo "Simply tagging to '$TAG_NAME'"
   PUSH=false
else
   echo "tagging to '$TAG_NAME'."
   PUSH=true
fi

if [ "$DOCKER_CMD" = "" ]
then
   DOCKER_CMD="docker"
fi

echo "-------------------------"
set -x
$DOCKER_CMD pull $TAG_NAME
$DOCKER_CMD build $PROXY $TAG_ARG $OS $JENKINS_VERSION_ARG $DOCKER_VERSION_ARG $JENKINS_INSTALL_URL_FLAG .
