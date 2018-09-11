#! /bin/bash -e
#

if [[ "id -un" = "root" ]]
then
    if [[ "$DOCKER_DOOD_GROUP" != "" ]]
    then
        /usr/local/bin/install_dood.sh $DOCKER_DOOD_GROUP
    fi

    exec su - jenkins /usr/local/bin/jenkins.sh "$@"
    # End
fi

if [[ "$DOCKER_DOOD_GROUP" != "" ]]
then
    echo "DOOD cannot be configured from a non privilege account. Requires to be root. Update your image to run the container as root."
    exit 1
fi
exec /usr/local/bin/jenkins.sh "$@"
