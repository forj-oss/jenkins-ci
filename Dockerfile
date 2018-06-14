FROM centos:7

LABEL maintainer="clarsonneur@gmail.com"

ENV JENKINS_HOME=/var/jenkins_home \
    JENKINS_UC=https://updates.jenkins-ci.org \
    JENKINS_DATA_REF=/usr/share/jenkins/ref
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

COPY ref/plugins/README.md $JENKINS_DATA_REF/plugins/
COPY ref/init.groovy.d/README.md $JENKINS_DATA_REF/init.groovy.d/
COPY ref/jenkins.start.d/README.md $JENKINS_DATA_REF/jenkins.start.d/

ENV TINI_SHA 066ad710107dc7ee05d3aa6e4974f01dc98f3888
ADD https://github.com/krallin/tini/releases/download/v0.5.0/tini-static /bin/tini
RUN chmod +x /bin/tini && \
    echo "$TINI_SHA /bin/tini" | sha1sum -c -

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/volume from a data container,
# ensure you use same uid

# Retrieve list of embedded plugins in jenkins war file
# NOTE: for Jenkins 2.0 or latest, remove the embedded plugins before the feature.lst execution, to avoid plugin duplicates

ARG JENKINS_VERSION=1.642
ADD http://pkg.jenkins-ci.org/redhat/jenkins.repo /etc/yum.repos.d/jenkins.repo
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins && \
    rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key && \
    yum -y install java jenkins-$JENKINS_VERSION unzip git && \
    yum clean all

COPY jenkins.sh /usr/local/bin/
ARG JPLUGINS_VERSION=0.0.6
ARG JPLUGINS_URL=https://github.com/forj-oss/jplugins/releases/download/${JPLUGINS_VERSION}/jplugins
ADD $JPLUGINS_URL /usr/local/bin/jplugins
RUN chmod +rx /usr/local/bin/jplugins && \
    unzip -jd $JENKINS_DATA_REF/plugins /usr/lib/jenkins/jenkins.war WEB-INF/*plugins/*.hpi && \
    /usr/local/bin/jplugins list-installed --jenkins-home=$JENKINS_DATA_REF --save-pre-installed && \
    rm -f $JENKINS_DATA_REF/plugins/*.hpi && \
    printf "$JENKINS_VERSION" > $JENKINS_DATA_REF/jenkins.install.UpgradeWizard.state && \
    printf "$JENKINS_VERSION" > $JENKINS_DATA_REF/jenkins.install.InstallUtil.lastExecVersion && \
    chown -R jenkins $JENKINS_HOME $JENKINS_DATA_REF

VOLUME /var/jenkins_home

EXPOSE 8080 8443 50000

USER jenkins

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh" ]
