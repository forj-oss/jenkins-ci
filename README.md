# Jenkins

This repository contains automation scripts to build jenkins from scratch with plugins and pre-initialized configuration data.
It has been strongly inspired by the [public Docker image](https://hub.docker.com/r/library/jenkins/) (but not used as reference) and enhanced.

Why?

We introduced several new features, like:
- [jenkins features](https://github.com/forj-oss/jenkins-install-inits) to help building easily a new jenkins image, by selecting some wanted features (Combination of plugins/config/scripts)
- a docker static binary cli to help doing Docker Out Of Docker.
- startup scripts capability

# To run it

Usually, you won't do that, because you want to build your own jenkins with the list of features you need. But if you want to see a basic version of jenkins, you can do the following:

```bash
docker run -it --rm -p 8080:8080 forjdevops/jenkins-dood:latest_1.658
```

## Jenkins version and docker tags

A docker image is versionned through his tag version and then pushed. Then on your Dockerfile, you refer to one version.

Ex:

```Dockerfile
FROM forjdevops/jenkins-dood:latest_1.642
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


To get a list of published and available versions, connect to [Docker Registry](https://hub.dockercom/forjdevops/jenkins-dood/tags)

This project maintains a collection of tags, ie a limited collection of version of jenkins. To get the list of maintained version, read [releases.lst](releases.lst)

# To build your own Jenkins image

This is the most common use case.

Create a Dockerfile:

    FROM forjdevops/jenkins-dood:1.642

    # To install plugins/features
    COPY features.lst /tmp/
    RUN /usr/local/bin/jenkins.sh /tmp/features.lst
    # For possible features init files, see https://github.com/forj-oss/jenkins-install-inits

# Jenkins version

The Dockerfile currently install version Jenkins 1.642 LTS from RedHat jenkins Repository

# for more details about jenkins
 See [public Docker image](https://hub.docker.com/r/library/jenkins/)

FORJ Team

