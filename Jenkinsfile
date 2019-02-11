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
// https://pkg.jenkins.io/redhat-stable/
    stages {
        stage('Get latest weekly version'){
            steps{
                script {
                    env.JENKINS_VERSION = sh(
                        script: 'curl http://mirrors.jenkins.io/war/ | grep -oE ">[0-9]+\\.+[0-9]+\\.?[0-9]*" | tail -1 | cut -c 2-',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage ('Set environments'){
            steps{
                script {
                    env.TAG_NAME = "docker.dxc.com:8085/devops-jenkins-base:${JENKINS_VERSION}-${BUILD_NUMBER}"
                }
            }
        }
        
        stage('Build Image') {
            environment{
               // REDHAT_REPO="redhat-stable" //Use this variable to use only stable versions otherwise use blank string
                REDHAT_REPO="redhat" //Use weekly version
            }
            steps {
                sh 'bash ./bin/build.sh $TAG_NAME $REDHAT_REPO' 
            }
        }

        stage ('Push container to artifactory'){
            steps {
                withCredentials([usernamePassword(credentialsId:'pdxc-jenkins',usernameVariable: 'ARTIFACTORY_USER', passwordVariable:'ARTIFACTORY_PASSWORD')]){                 
                    sh '''
                        docker login docker.dxc.com:8085 --username $ARTIFACTORY_USER --password $ARTIFACTORY_PASSWORD
                        docker push $TAG_NAME
                    '''
                }
            }
        }
    }
}