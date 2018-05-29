FROM centos:7

MAINTAINER clarsonneur@gmail.com

ENV JENKINS_HOME=/var/jenkins_home \
    JENKINS_UC=https://updates.jenkins-ci.org \
    JENKINS_DATA_REF=/usr/share/jenkins/ref
ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

ARG DOCKER_VERSION=1.10.3

ARG JENKINS_VERSION=1.642

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/volume from a data container,
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

RUN curl -so /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo && \
    rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key && \
    yum -y install java jenkins-$JENKINS_VERSION unzip git && \
    yum clean all

ENV TINI_SHA 066ad710107dc7ee05d3aa6e4974f01dc98f3888
RUN curl -fL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA /bin/tini" | sha1sum -c -

# Retrieve list of embedded plugins in jenkins war file
# NOTE: for Jenkins 2.0 or latest, remove the embedded plugins before the feature.lst execution, to avoid plugin duplicates
RUN mkdir -p $JENKINS_DATA_REF && unzip -jd $JENKINS_DATA_REF/plugins /usr/lib/jenkins/jenkins.war WEB-INF/*plugins/*.hpi
COPY ref/plugins/README.md $JENKINS_DATA_REF/plugins
COPY ref/init.groovy.d/README.md $JENKINS_DATA_REF/init.groovy.d/
COPY ref/jenkins.start.d/README.md $JENKINS_DATA_REF/jenkins.start.d/

RUN printf "$JENKINS_VERSION" > $JENKINS_DATA_REF/jenkins.install.UpgradeWizard.state && \
    printf "$JENKINS_VERSION" > $JENKINS_DATA_REF/jenkins.install.InstallUtil.lastExecVersion && \
    chown -R jenkins $JENKINS_HOME $JENKINS_DATA_REF

COPY jenkins.sh /usr/local/bin/
ARG JENKINS_INSTALL_INITS_URL=https://github.com/forj-oss/jenkins-install-inits/raw/master
ADD $JENKINS_INSTALL_INITS_URL/jenkins-install.sh /usr/local/bin/
RUN chmod +rx /usr/local/bin/jenkins-install.sh

VOLUME /var/jenkins_home

EXPOSE 8080 50000

USER jenkins

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh" ]
