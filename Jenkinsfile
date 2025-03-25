pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerLogin')
    }
    stages {
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
        stage('Build Docker Image and Push to Docker Registry') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'DockerLogin', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'docker build -t sc4redy/nodejsgoof:01 .'
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker push sc4redy/nodejsgoof:01'
                }
            }
        }
        stage('Deploy Docker Image') {
            agent {
                docker {
                    image 'kroniak/ssh-client'
                }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'DeploymentSSHKey', keyFileVariable: 'keyfile'),
                                 usernamePassword(credentialsId: 'DockerLogin', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    def sshCmd = "ssh -i ${keyfile} -o StrictHostKeyChecking=no ubuntu@192.168.36.128"
                    sh "${sshCmd} 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'"
                    sh "${sshCmd} 'docker pull sc4redy/nodejsgoof:01'"
                    sh "${sshCmd} 'docker rm --force mongodb || true'"
                    sh "${sshCmd} 'docker run --detach --name mongodb -p 27017:27017 mongo:3'"
                    sh "${sshCmd} 'docker rm --force nodejsgoof || true'"
                    sh "${sshCmd} 'docker run --detach --name nodejsgoof --network host sc4redy/nodejsgoof:01'"
                }
            }
        }
    }
}

