#!/bin/bash -e
#
#

BASE_TAG="jenkins"

JENKINS_FEATURES_REPO=https://github.com/forj-oss/jenkins-install-inits

if [ "$http_proxy" != "" ]
then
   PROXY=" --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy --build-arg no_proxy=$no_proxy"
   echo "Using your local proxy setting : $http_proxy"
   if [ "$no_proxy" != "" ]
   then
      PROXY="$PROXY --build-arg no_proxy=$no_proxy"
      echo "no_proxy : $http_proxy"
   fi
fi

if [ "$DOCKER_VERSION" != "" ]
then
   DOCKER_VERSION_ARG="--build-arg DOCKER_VERSION=$DOCKER_VERSION"
fi

LATEST_JENKINS_VERSION="$(awk -F"|" '$2 ~ /^latest/ || $2 ~ /,latest/ { printf "%s\n",$1 }' releases.lst)"

if [ "$JENKINS_VERSION" = "" ]
then
   JENKINS_VERSION=$LATEST_JENKINS_VERSION
   echo "Using Jenkins version '$JENKINS_VERSION'."
fi
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
   DOCKER_CMD="sudo docker"
fi

echo "-------------------------"
set -x
[ $PUSH = true ] && $DOCKER_CMD pull $TAG_NAME || echo "Building it from scratch"
$DOCKER_CMD build $PROXY $TAG_ARG $OS $JENKINS_VERSION_ARG $DOCKER_VERSION_ARG $JENKINS_INSTALL_URL_FLAG .
