pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerLogin')
        SNYK_CREDENTIALS = credentials('SnykToken')
    }
    stages {
        stage('Secret scanning using trufflehog') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '--entrypoint='
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'trufflehog filesystem . --exclude-paths trufflehog-excluded-paths.txt --fail --json --no-update > trufflehog-scan-result.json'
                }
                sh 'cat trufflehog-scan-result.json'
                archiveArtifacts artifacts: 'trufflehog-scan-result.json'
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'node:lts-buster-slim'
                }
            }
            steps {
                sh 'npm install'
            }
        }
        stage('SCA Snyk Test') {
            agent {
                docker {
                    image 'snyk/snyk:node'
                    args '-u root --network host --env SNYK_TOKEN=$SNYK_CREDENIALS_PSW --entrypoint='
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'snyk test --json > snyk-scan-report.json'
                }
                sh 'cat snyk-scan-report.json'
                archiveArtifacts artifacts: 'snyk-scan-report.json'
            }
        }
        stage('SCA Retire Js') {
            agent {
                docker {
                    image 'node:lts-buster-slim'
                }
            }
            steps {
                sh 'npm install retire'
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh './node_modules/retire/lib/cli.js --outputformat json --outputpath retire-scan-report.json'
                }
                sh 'cat retire-scan-report.json'
                archiveArtifacts artifacts: 'retire-scan-report.json'
            }
        }
        stage('Build Docker Image and Push to Docker Registry') {
            agent {
                docker {
                    image 'docker:dind'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t sc4redy/nodejsgoof:01 .'
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push sc4redy/nodejsgoof:01'
            }
        }
        stage('Deploy Docker Image') {
            agent {
                docker {
                    image 'kroniak/ssh-client'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'DeploymentSSHKey', keyFileVariable: 'keyfile')]) {
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 docker pull sc4redy/nodejsgoof:01'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 docker rm --force mongodb'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 docker run --detach --name mongodb -p 27017:27017 mongo:3'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 docker rm --force nodejsgoof'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128 docker run -it --detach --name nodejsgoof --network host sc4redy/nodejsgoof:01'
                }
            }
        }
    }
}
