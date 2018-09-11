# Jenkins

This repository contains automation scripts to build jenkins from scratch with plugins and pre-initialized configuration data.
It has been strongly inspired by the [public Docker image](https://hub.docker.com/r/library/jenkins/) (but not used as reference) and enhanced.

Why?

We introduced several new features, like:
- [jenkins features](https://github.com/forj-oss/jenkins-install-inits) to help building easily a new jenkins image, by selecting some wanted features (Combination of plugins/config/scripts)
- startup scripts capability
- Support for Docker out of Docker

## To run it

Usually, you won't do that, because you want to build your own jenkins with the list of features you need. But if you want to see a basic version of jenkins, you can do the following:

```bash
docker run -it --rm -p 8080:8080 forjdevops/jenkins:latest_1.658
```

### Jenkins version and docker tags

A docker image is versionned through his tag version and then pushed. Then on your Dockerfile, you refer to one version.

Ex:

```Dockerfile
FROM forjdevops/jenkins:latest_1.6
```

We deliver several different jenkins version and maintain some of them.
For docker image tagging, we follow those rules:
- Some version of jenkins (3 versions) gets a tag prefixed by
  the project release ie `<ReleaseVersion>_<JenkinsVersion>`.

  Ex: `0.2_1.658`, `0.2_1.642`, `0.2_2.50`

- A branch of version. We maintain 3 different branches: 1.6x-latest, 1.6x-stable and 2.x.
  Latest version of a branch gets named as `<ReleaseVersion>_<BranchVersion>-latest`.

  Ex: `0.2_2.x-latest`

- `<ReleaseVersion>_latest` will refer to the latest version for a dedicated version of this project.

  Ex: `0.2_latest`

- `latest_<jenkins_version|latest>` will refer to the HEAD of the `jenkins-ci` repository. It will be updated any time a PR on jenkins-ci is merged.

- latest is the default tag for docker. We use it to refer to the latest version of jenkins, as found in http://pkg.jenkins.io/redhat/

  Ex: `latest` refer to the latest version of jenkins and version of this project ie is identical to `latest_latest`


To get a list of published and available versions, connect to [Docker Registry](https://hub.dockercom/forjdevops/jenkins/tags)

This project maintains a collection of tags, ie a limited collection of version of jenkins. To get the list of maintained version, read [releases.lst](releases.lst)

## To build your own Jenkins image

This is the most common use case.

Create a Dockerfile:

    FROM forjdevops/jenkins:0.5_1.642.4

    # To install plugins/features
    COPY jplugins.lst /tmp/
    RUN /usr/local/bin/jplugin install /tmp/jplugins.lst
    # For possible Jenkins features, see https://github.com/forj-oss/jenkins-install-inits

## Jenkins version

The project manages and publish multiples jenkins version to docker hub. The publication to docker hub is controlled by `releases.lst` and executed by `bin/publish-alltags.sh`

You can build a single version, locally.

By default, the Dockerfile currently install version Jenkins 1.642.4 LTS from RedHat jenkins Repository.
But you can specify any version as soon as those vrrsion are available in Jenkins ([Stable](https://pkg.jenkins.io/redhat-stable/) or [latest](https://pkg.jenkins.io/redhat/))

`Latest` example: It will create a jenkins:test image
```bash
JENKINS_VERSION=2.141 bin/build.sh
```

`stable` example: It will create a jenkins:test image
```bash
JENKINS_VERSION=2.121.3 bin/build.sh '' redhat-stable
```

with a different tag: It will create a blabla:latest image
```bash
JENKINS_VERSION=2.121.3 bin/build.sh blabla redhat-stable
```

## Using Docker Out of Docker for your Jenkins master

If you are new to Docker or ask yourself about what is Docker Out of Docker (DooD), read this:

- [DinD vs DooD](http://blog.teracy.com/2017/09/11/how-to-use-docker-in-docker-dind-and-docker-outside-of-docker-dood-for-local-ci-testing/])
- Interesting article from Jérôme Petazzoni - [Do not use DinD for CI](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/)

To enable it, do the following:

- at docker build:
    1. Start your Jenkins image as `root` instead of `jenkins`

- At docker run:
    1. Provide DOCKER_DOOD_GROUP, as the group ID of docker on the docker host

        ex: docker run -it --rm **-e DOCKER_DOOD_GROUP=991** [...]

    2. Provide the DooD mount

        ex: docker run -it --rm **-v /var/run/docker.sock:/var/run/docker.sock** [...]

    3. Optionnaly, mount a static docker client. Check https://download.docker.com/linux/static/stable/x86_64/
    
        ex: docker run -it --rm **-v /home/centos/docker/docker:/bin/docker** [...]

## for more details about jenkins
 See [public Docker image](https://hub.docker.com/r/library/jenkins/)

FORJ Team

