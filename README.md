# Jenkins CI/CD Lab

A hands-on DevOps project demonstrating a complete CI/CD pipeline using GitHub, Jenkins, Docker, and AWS EC2.

The pipeline automatically checks out the application source code, runs automated tests, builds a Docker image, connects to an AWS EC2 deployment server over SSH, transfers the Docker image, and deploys the application container.

---

## 🎯 Project Objective

The objective of this project is to build and understand a practical Jenkins-based CI/CD pipeline rather than only configuring Jenkins in isolation.

The final pipeline demonstrates:

- Git-based source control
- Jenkins Controller and Agent architecture
- Pipeline as Code using a `Jenkinsfile`
- Automated application testing
- Docker image building
- Jenkins credential management
- SSH-based deployment
- AWS EC2 deployment
- Docker image transfer between environments
- Automated container replacement

---

## 🏗️ Architecture

```text
                    GitHub
                      │
                      │ Source Code
                      ▼
              Jenkins Controller
                      │
                      │ Pipeline
                      ▼
               Jenkins Agent
                      │
          ┌───────────┼───────────┐
          │           │           │
       Checkout      Test     Docker Build
                                  │
                                  │
                                  ▼
                         Docker Image
                                  │
                                  │ SSH
                                  ▼
                           AWS EC2 Server
                                  │
                                  │ docker load
                                  ▼
                         Docker Container
                                  │
                                  │
                                  ▼
                         Application :5000
                                  │
                         EC2 Port 80
                                  │
                                  ▼
                              Browser
```

🔄 CI/CD Pipeline

The Jenkins pipeline contains the following stages:
```text
           docker save
                ↓
               gzip
                ↓
               SSH
                ↓
              gunzip
                ↓
          docker load
```

1. Checkout
Jenkins checks out the application source code from the GitHub repository.
2. EC2 SSH Test
Jenkins retrieves the stored SSH credential and verifies that the Jenkins Agent can connect to the AWS EC2 deployment server.
The test verifies:
- Remote user
- EC2 hostname
- Docker installation
3. Test
A dedicated Docker test image is built from Dockerfile.test.
The application tests are then executed inside the test container.
The current test suite verifies:
- /
- /health
4. Docker Build
Jenkins builds the application image:
jenkins-cicd-lab:<BUILD_NUMBER>
The Jenkins build number is used as the image tag so individual builds can be identified.
5. Deploy to EC2
The Docker image is transferred from the Jenkins Agent to AWS EC2.

The process is:
```text
             docker save
                  ↓
                 gzip
                  ↓
                 SSH
                  ↓
                gunzip
                  ↓
             docker load
```

After loading the image, Jenkins remotely:
1. Stops the previous application container if it exists.
2. Removes the previous container.
3. Starts the new container.
4. Maps EC2 port 80 to container port 5000.


🐳 Docker
The application container uses:

  Python 3.14
  Flask

The application exposes:
   Container: 5000

The EC2 deployment exposes:
   EC2: 80 → Container: 5000

🤖 Jenkins Architecture
This project uses separate Jenkins Controller and Agent components.

Jenkins Controller
   The Controller coordinates the pipeline and manages Jenkins configuration.

Jenkins Agent
    The Agent executes the actual pipeline workload.

The custom Jenkins Agent image contains:
- Java/Jenkins inbound agent
- Python
- pip
- Git
- Docker CLI
- OpenSSH client

The Agent also has access to the Docker socket in this local lab environment so that it can build Docker images.

🔐 Jenkins Credentials
  The EC2 deployment uses a Jenkins-managed SSH credential.

Credential ID:
   aws-ec2-deploy

The private key is stored inside Jenkins credentials rather than inside the repository.

The Jenkinsfile retrieves the credential using:

    withCredentials([
         sshUserPrivateKey(...)
    ])

Private keys and secrets are not stored in Git.

☁️ AWS EC2
The deployment target is an Amazon EC2 instance running:
- Amazon Linux 2023
- Docker
- Git

The application is deployed as a Docker container.

The EC2 security group allows:
- SSH on port 22 from the configured source IP
- HTTP on port 80

📁 Repository Structure

03-jenkins-cicd-lab/
│
├── app/
│   └── app.py
│
├── tests/
│   └── test_app.py
│
├── Dockerfile
├── Dockerfile.test
├── Jenkinsfile
├── jenkins-agent.Dockerfile
├── requirements.txt
└── .gitignore

🧪 Application Tests
The application currently contains two basic tests:
    test_home
    test_health

Tests are executed automatically by Jenkins before the Docker deployment stage.

If the tests fail, the pipeline stops before deployment.

This ensures that a failed build is not automatically deployed.

🛠️ Custom Jenkins Agent
The custom agent is defined in:

    jenkins-agent.Dockerfile

The image extends:

    jenkins/inbound-agent:jdk21

and installs the tools required by the pipeline.

This demonstrates how Jenkins agents can be customized according to build requirements.

🧠 Troubleshooting Lessons:

    This project involved several real-world Jenkins troubleshooting scenarios.

Jenkins Agent Connection-
    The inbound Jenkins Agent initially failed to connect because the Jenkins secret was configured incorrectly.

    The issue was resolved by using the correct agent secret and WebSocket connection.

Agent Tooling-
    The default inbound agent image did not contain the Python and Docker CLI tools required by the pipeline.

    A custom Jenkins Agent image was created to provide the required tooling.

Docker Socket Access-
    The Jenkins Agent required access to the Docker daemon for Docker builds.

    In this local Docker Desktop lab, the Docker socket was mounted into the agent and the required group access was configured.

    This is a powerful capability and should be hardened appropriately in production environments.

Jenkinsfile UTF-8 BOM-
    The Jenkinsfile initially contained a UTF-8 BOM.

    This caused Jenkins to interpret the beginning of the file incorrectly and report that the pipeline DSL was unavailable.

    The BOM was removed and the pipeline then loaded correctly.

Declarative Pipeline Structure-
    The deployment stage was initially placed outside the stages block.

    Jenkins reported:

        No such DSL method 'steps'

    The stage structure was corrected so that all stages are contained within:

        stages {
             ...
        }

Remote Environment Variables-
    The initial deployment attempted to use:

         ${BUILD_NUMBER}

    inside the remote EC2 shell.

    BUILD_NUMBER is a Jenkins environment variable and is not automatically available on the EC2 server.

    The pipeline was corrected by creating the image tag on the Jenkins Agent first and then sending the resolved tag to EC2.

🔒 Security Considerations-
    This project is a learning lab and contains several deliberate simplifications.

SSH Host Verification-
    The deployment currently uses:

    StrictHostKeyChecking=no

and:
    UserKnownHostsFile=/dev/null

This avoids interactive host verification during the lab.

A production deployment should verify and manage the EC2 host key properly.

Docker Socket-
    The Jenkins Agent has access to the Docker socket so that it can build Docker images.

    Access to the Docker socket provides significant control over the Docker host and should be carefully secured in production.

SSH Credentials-
    Private SSH keys should remain inside Jenkins Credentials and must never be committed to Git.

AWS Cost-
    The EC2 instance is a paid AWS resource even though the lab uses cost-control measures.

    The instance should be stopped when it is not needed.

📊 Successful Deployment-
The completed pipeline successfully demonstrated:

GitHub
   ↓
Jenkins Controller
   ↓
Jenkins Agent
   ↓
Automated Tests
   ↓
Docker Build
   ↓
SSH to AWS EC2
   ↓
Docker Image Transfer
   ↓
Docker Load
   ↓
Container Replacement
   ↓
Application Running on EC2

The successful deployment was verified through a web browser against the EC2 public IP.

🚀 Future Improvements
Possible future improvements include:
- Docker BuildKit / buildx
- Amazon ECR for image storage
- HTTPS/TLS
- Proper SSH host-key verification
- Terraform for AWS infrastructure
- Ansible for configuration management
- Kubernetes deployment
- Amazon EKS
- Monitoring and logging
- Deployment rollback strategy
- Blue/green or rolling deployments
- Automated GitHub webhook triggering
These improvements are intentionally outside the current project's core scope.

📚 Technologies Used
- Git
- GitHub
- Jenkins
- Jenkins Pipeline
- Jenkins Agents
- Groovy
- Python
- Flask
- Docker
- SSH
- AWS EC2
- Amazon Linux 2023
- PowerShell

✅ Project Status
Project 3 — Jenkins CI/CD Lab: Completed

GitHub → Jenkins Controller → Jenkins Agent → Test → Docker Build → SSH → EC2 → Docker → Running application
