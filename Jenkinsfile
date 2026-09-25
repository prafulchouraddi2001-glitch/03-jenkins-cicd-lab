pipeline {
    agent {
        label "jenkins-agent-2"
    }

    stages {
        stage("Checkout") {
            steps {
                checkout scm
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
    }
}
