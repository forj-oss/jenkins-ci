#! /bin/bash -e
#

if [[ "$(id -un)" = "root" ]]
then
    if [[ "$UID" != "" ]] && [[ "$GID" != "" ]]
    then
        docker-lu jenkins $UID jenkins $GID
    fi

    if [[ "$DOCKER_DOOD_GROUP" != "" ]]
    then
        /usr/local/bin/install_dood.sh $DOCKER_DOOD_GROUP
    fi

    if [[ "$(stat -c "%U" $JENKINS_HOME)" = "root" ]]
    then
        echo "Changing directory $JENKINS_HOME ownership to jenkins"
        chown jenkins:jenkins $JENKINS_HOME
    fi

    echo "Forcing Jenkins user."
    exec su jenkins /usr/local/bin/jenkins.sh "$@"
    # End
fi

if [[ "$DOCKER_DOOD_GROUP" != "" ]]
then
    echo "DOOD cannot be configured from a non privilege account. Requires to be root. Update your image to run the container as root."
    exit 1
fi
echo "Using Jenkins user '$(id -un)'."
exec /usr/local/bin/jenkins.sh "$@"
