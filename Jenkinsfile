pipeline {
    agent {
        label "jenkins-agent-2"
    }

    options {
        skipDefaultCheckout(true)
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("EC2 SSH Test") {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: "aws-ec2-deploy",
                        keyFileVariable: "SSH_KEY",
                        usernameVariable: "SSH_USER"
                    )
                ]) {
                    sh '''
                        ssh \
                            -i "$SSH_KEY" \
                            -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            "$SSH_USER@ec2-3-110-48-174.ap-south-1.compute.amazonaws.com" \
                            'whoami && hostname && docker --version'
                    '''
                }
            }
        }

        stage("Test") {
            steps {
                sh '''
                    docker build \
                        -f Dockerfile.test \
                        -t jenkins-cicd-lab:test-${BUILD_NUMBER} .

                    docker run --rm \
                        jenkins-cicd-lab:test-${BUILD_NUMBER}
                '''
            }
        }

        stage("Docker Build") {
            steps {
                sh '''
                    docker build \
                        -t jenkins-cicd-lab:${BUILD_NUMBER} .
                '''
            }
        }

        stage("Deploy to EC2") {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: "aws-ec2-deploy",
                        keyFileVariable: "SSH_KEY",
                        usernameVariable: "SSH_USER"
                    )
                ]) {
                    sh '''
                        IMAGE_TAG="jenkins-cicd-lab:${BUILD_NUMBER}"

                        echo "Deploying ${IMAGE_TAG} to EC2..."

                        docker save "$IMAGE_TAG" | gzip | \
                        ssh \
                            -i "$SSH_KEY" \
                            -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            "$SSH_USER@ec2-3-110-48-174.ap-south-1.compute.amazonaws.com" \
                            'gunzip | docker load'

                        ssh \
                            -i "$SSH_KEY" \
                            -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            "$SSH_USER@ec2-3-110-48-174.ap-south-1.compute.amazonaws.com" \
                            "
                                docker stop jenkins-cicd-lab || true
                                docker rm jenkins-cicd-lab || true

                                docker run -d \
                                    --name jenkins-cicd-lab \
                                    -p 80:5000 \
                                    $IMAGE_TAG

                                docker ps
                            "

                        echo "Deployment completed successfully."
                    '''
                }
            }
        }
    }
}
