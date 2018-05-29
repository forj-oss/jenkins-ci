#! /bin/bash -e

# Copy files from /usr/share/jenkins/ref into /var/jenkins_home
# So the initial JENKINS-HOME is set with expected content. 
# Don't override, as this is just a reference setup, and use from UI 
# can then change this, upgrade plugins, etc.
copy_reference_file() {
	f=${1%/} 
    rel=${f:23}
    dir=$(dirname ${f})
	if [[ ! -e /var/jenkins_home/${rel} ]]
	then
		echo "copy $rel to JENKINS_HOME" >> $COPY_REFERENCE_FILE_LOG
		mkdir -p /var/jenkins_home/${dir:23}
		cp -r /usr/share/jenkins/ref/${rel} /var/jenkins_home/${rel};
		# pin plugins on initial copy
		[[ ${rel} == plugins/*.jpi ]] && touch /var/jenkins_home/${rel}.pinned
    else
        if [[ ${rel} = jenkins.install.UpgradeWizard.state ]] || [[ ${rel} = jenkins.install.InstallUtil.lastExecVersion ]] || [[ ${rel} ~= ^plugins/.*\.hpi$ ]]
        then
            echo "refresh $rel to JENKINS_HOME" >> $COPY_REFERENCE_FILE_LOG
    		mkdir -p /var/jenkins_home/${dir:23}
	    	cp -r /usr/share/jenkins/ref/${rel} /var/jenkins_home/${rel};
        fi
	fi; 
}

# Remove jenkins wizard at startup time.


# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
   export -f copy_reference_file
   echo "--- Copying files at $(date)" >> $COPY_REFERENCE_FILE_LOG
   find /usr/share/jenkins/ref/ -type f -exec bash -c "copy_reference_file '{}'" \;

   for FILE in /var/jenkins_home/jenkins.start.d/*
   do
      [[ "$FILE" =~ \.sh$ ]] || continue
      if [[ "$FILE" =~ source\.sh$ ]]
      then
         echo "Sourcing '$FILE'"
         source "$FILE"
      else
         echo "Executing '$FILE'..."
         bash $FILE
      fi
   done

   if [ "$JENKINS_CREDENTIALS" = "" ]
   then
      JENKINS_CREDENTIALS="/tmp/jenkins_credentials.sh"
   fi

   if [ -e "$JENKINS_CREDENTIALS" ]
   then
      echo "Loading $JENKINS_CREDENTIALS..."
      source "$JENKINS_CREDENTIALS"
   else
      echo "$JENKINS_CREDENTIALS NOT FOUND. No credentials loaded."
   fi

   if [ "$GIT_EMAIL" = "" ] || [ "$GIT_USERNAME" = "" ]
   then
      echo "Warning! No GIT_EMAIL or GIT_USERNAME properly configured (missing in /tmp/jenkins_credentials.sh?)"
   fi
   echo "
Values set are:
SEED_JOBS_REPO : '$SEED_JOBS_REPO'
GIT_USER       : '$GIT_USER'
GIT_PASSWORD   : '${GIT_PASSWORD:+'***'}'
GIT_EMAIL      : '${GIT_EMAIL:='jenkins@demo.net'}'
GIT_USERNAME   : '${GIT_USERNAME:='Jenkins builder'}'"

   git config --global user.email "$GIT_EMAIL" &&   git config --global user.name "$GIT_USERNAME"

   exec java $JAVA_OPTS -jar /usr/*/jenkins/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
