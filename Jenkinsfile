pipeline {
    agent any
     options{
        buildDiscarder(logRotator (
                numToKeepStr: '2',
                daysToKeepStr: '-1',
                artifactDaysToKeepStr: '-1',
                artifactNumToKeepStr: '-1'
            )
        )
    }

    triggers {
        cron('0 0 * * 2') //At 00:00 on Tuesday
    }
    stages {
        stage('Build Jenkins images') {
            steps {
                script {
                    def builds = [:]
                    lines = sh(script:'''#!/bin/bash 
                                     source bin/build-fcts.sh 
                                     getReleaseTags
                                     ''', returnStdout:true).trim().split('\n')
                    lines.each { String f ->
                        def (version, tags, source)=f.tokenize("|")
                        builds["${version}"] = {
                            node {
                                checkout scm

                                stage("version ${version}") {
                                    script {
                                        env.JENKINS_VERSION = "${version}"
                                        def JenkinsSource = "${source}"
                                        if (JenkinsSource == "null") {
                                            JenkinsSource="redhat"
                                        }
                                        env.JENKINS_REPO_SOURCE = "${JenkinsSource}"
                                    }
                                    sh '''#!/bin/bash -e

                                    source bin/build-fcts.sh
                                    set -x
                                    bin/build.sh $TAG_BASE:$(getLastVersion)_$JENKINS_VERSION $JENKINS_REPO_SOURCE
                                    '''
                                }
                            }
                        }
                    }
                parallel builds
                }
            }
        }


        stage ('Push images to dockerhub'){
            environment{
                GITHUB_REPO="jenkins-ci"
                GITHUB_USER="forj-oss"
            }
            when { branch 'master' }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD'),
                    usernamePassword(credentialsId: 'github-jenkins-cred', passwordVariable: 'GITHUB_TOKEN')
                    ]) {
                    sh '''
                        docker login --username $DOCKERHUB_USERNAME --password $DOCKERHUB_PASSWORD
                        bin/publish_alltags.sh
                    '''
                }
            }
        }
    }
}