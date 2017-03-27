#!/bin/bash
#
# This script is basically used to start a jenkins through docker.
# If you want to start it from mesos/marathon, use:
# create_mesos_jenkins_master_as_docker.sh

if [ -r jenkins_credentials.sh ]
then
   CREDENTIALS="-v $PWD/jenkins_credentials.sh:/tmp/jenkins_credentials.sh"
fi

if [ "$http_proxy" != "" ]
then
   PROXY="-e http_proxy=$http_proxy -e https_proxy=$http_proxy -e no_proxy=$no_proxy"
fi

# Check if the label file exist, then load it in $TAG_NAME
if [ -f .git-label ]
then
   TAG_NAME="$(cat .git-label)"
else
   TAG_NAME="jenkins-mesos-dood:0.24.1"
fi

# TODO: Add jenkins port support for marathon.
set -x
docker run --name jmdood -it --rm $CREDENTIALS $PROXY --net=host $TAG_NAME
