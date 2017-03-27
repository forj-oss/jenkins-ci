#!/bin/bash
# Script to create the application master jenkins on mesos/marathon.

if [ "$1" = "" ]
then
   echo "Usage is $0 <MasterServer>"
   exit 1
fi

MARATHON_API="http://$1:8080"
MESOS_VERSION=0.24.1
JENKINS_MESOS_DOOD_URL="clarsonneur/jenkins-mesos-dood"

APP_NAME=jenkins-master

# We set jenkins memory container to 1GB, while jenkins through java is configured with heap size max to 256M.
# When we check the docker stats, it shows jenkins to be using 550M... So, the 1GB limits should be ok.

GLUSTER=false
JENKINS_HOME_ENABLED=false

if [ -f ~/.marathon_jenkins ]
then
   echo "~/.marathon_jenkins loaded."
   source ~/.marathon_jenkins
fi

if [ "$GLUSTER" = true ]
then
   echo "Using Glusterfs volume driver"
   STORAGE=',
       { "key" : "env", "value" : "COPY_REFERENCE_FILE_LOG=/data/jenkins/container.log" },
       { "key" : "env", "value" : "JENKINS_HOME=/data/jenkins" },
       { "key": "volume-driver", "value": "glusterfs" },
       { "key": "volume", "value": "gv0:/data" }'
else
   echo "Disabling usage of Glusterfs volume driver"
fi

if [ "$JENKINS_HOME_ENABLED" = true ]
then
   echo "Using Jenkins volume local mount"
   JENKINS_HOME=',
      { "containerPath": "/var/jenkins_home", "hostPath": "/var/jenkins_home", "mode": "RW" }'
else
   echo "Disabling usage of jenkins volume mount"
fi

if [ "$CREDS_ENABLE" = true ]
then
   URIS='
 "uris": [
   "file:///etc/docker_creds.tar.gz"
 ],'
   echo "Usage of local /etc/docker_creds.tar.gz"
else
   echo "No credential declared."
fi


DOCK='{
 "id": "'$APP_NAME'",
 "cpus": 1,
 "mem": 1024,
 "instances": 1, '"$URIS"'
 "args": [ "--handlerCountMax=100", "--handlerCountMaxIdle=20" ],
 "container": {
   "type": "DOCKER",
   "docker": {
     "image": "'"$JENKINS_MESOS_DOOD_URL"':'"$MESOS_VERSION"'",
     "network": "HOST",
     "parameters" : [
       { "key" : "env", "value" : "JAVA_OPTS=-Xmx256m" }'"$STORAGE"'
     ]
   },
   "volumes": [
      { "containerPath": "/var/run/docker.sock", "hostPath": "/var/run/docker.sock", "mode": "RW" }'"$JENKINS_HOME"'
   ]
 }
}'

#   ],
#   "portMappings": [
#    {"containerPort":8080, "hostPort":0,"servicePort":10000,"protocol":"tcp"},
#    {"containerPort":50000,"hostPort":0,"servicePort":10001,"protocol":"tcp"}

RESULT="$(curl -s -X GET $MARATHON_API/v2/apps/jenkins_master_docker)"

if [ "$(echo $RESULT | grep "App '$APP_NAME' does not exist")" != "" ]
then
  curl -s -X POST $MARATHON_API/v2/apps -d "$DOCK" -H "Content-type: application/json"
else
  curl -s -X PUT $MARATHON_API/v2/apps/$APP_NAME -d "$DOCK" -H "Content-type: application/json"
fi
echo
