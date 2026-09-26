# Jenkins CI/CD Lab

A hands-on DevOps project that builds, tests, containerizes, and deploys a Flask application to **AWS EC2 using Jenkins CI/CD**.

The pipeline connects **GitHub → Jenkins Controller → Jenkins Agent → Docker → AWS EC2**, with automated testing and SSH-based deployment.

---

## 🚀 What This Project Demonstrates

- Jenkins Controller and Agent architecture
- Pipeline as Code with `Jenkinsfile`
- GitHub source control
- Automated application testing
- Docker image building
- Jenkins-managed SSH credentials
- SSH-based deployment to AWS EC2
- Docker image transfer between environments
- Automated container replacement
- Build-number-based Docker image tagging

---

## 🏗️ Architecture

```text
                         GitHub
                            │
                            │ git checkout
                            ▼
                   Jenkins Controller
                            │
                            │ Pipeline
                            ▼
                     Jenkins Agent
                            │
              ┌─────────────┼─────────────┐
              │             │             │
           Checkout        Test      Docker Build
                                           │
                                           ▼
                                  Docker Image
                                           │
                                           │ SSH
                                           ▼
                                     AWS EC2
                                           │
                                    docker load
                                           │
                                           ▼
                                  Docker Container
                                           │
                                    Port 5000
                                           │
                                    EC2 Port 80
                                           │
                                           ▼
                                        Browser
```

---

## 🔄 CI/CD Pipeline

The Jenkins pipeline executes these stages:

```text
Checkout
   ↓
EC2 SSH Test
   ↓
Test
   ↓
Docker Build
   ↓
Deploy to EC2
```

### 1. Checkout

Jenkins checks out the application source code from GitHub.

### 2. EC2 SSH Test

Jenkins retrieves the EC2 SSH credential from Jenkins Credentials and verifies connectivity to the deployment server.

The stage verifies:

- Remote user
- EC2 hostname
- Docker installation

### 3. Test

A dedicated Docker image is built using `Dockerfile.test`.

The application test suite runs inside the test container.

Current tests:

- `test_home`
- `test_health`

If the tests fail, the pipeline stops before deployment.

### 4. Docker Build

Jenkins builds the application image using the current Jenkins build number:

```text
jenkins-cicd-lab:<BUILD_NUMBER>
```

For example:

```text
jenkins-cicd-lab:13
```

This makes individual deployment builds identifiable.

### 5. Deploy to EC2

The Docker image is transferred from the Jenkins Agent to AWS EC2.

```text
Jenkins Agent
     │
     │ docker save
     ▼
   gzip
     │
     │ SSH
     ▼
   gunzip
     │
     ▼
 docker load
     │
     ▼
AWS EC2 Docker
```

After loading the image, Jenkins:

1. Stops the existing application container.
2. Removes the existing container.
3. Starts the new container.
4. Maps EC2 port `80` to container port `5000`.

---

## 🧪 Application

The project uses a small Flask application specifically so the focus remains on the CI/CD infrastructure.

### Endpoints

```text
GET /
GET /health
```

Example response:

```json
{
  "message": "Hello from Jenkins CI/CD Lab!"
}
```

Health endpoint:

```json
{
  "status": "ok"
}
```

---

## 🐳 Docker

The application runs in a Python 3.14 Docker image.

```text
Application container
        │
        │ port 5000
        ▼
     EC2 port 80
```

The repository contains two Dockerfiles:

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the application image |
| `Dockerfile.test` | Builds the test image used by Jenkins |

---

## 🤖 Jenkins Architecture

The project uses separate Jenkins Controller and Agent components.

### Controller

The Jenkins Controller coordinates the pipeline and manages Jenkins configuration.

### Agent

The Jenkins Agent executes the actual pipeline workload.

A custom agent image was created because the standard inbound agent did not contain all the tools required by the pipeline.

### Custom Agent Tools

The custom image provides:

- Jenkins inbound agent
- Java
- Python
- pip
- Git
- Docker CLI
- OpenSSH client

The custom image is defined in:

```text
jenkins-agent.Dockerfile
```

---

## 🔐 Credentials and SSH

The EC2 deployment uses a Jenkins-managed SSH credential.

The private key is stored in **Jenkins Credentials** and is not committed to Git.

The pipeline retrieves the credential at runtime using:

```groovy
withCredentials([
    sshUserPrivateKey(
        credentialsId: "aws-ec2-deploy",
        keyFileVariable: "SSH_KEY",
        usernameVariable: "SSH_USER"
    )
])
```

The private key itself is never stored in the repository.

---

## ☁️ AWS EC2

The deployment target is an Amazon EC2 instance running:

- Amazon Linux 2023
- Docker
- Git

The application is exposed through:

```text
EC2 :80
   ↓
Container :5000
```

The EC2 security group used for the lab allows:

- SSH (`22`) from the configured source IP
- HTTP (`80`) for application access

---

## 📁 Repository Structure

```text
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
├── README.md
└── .gitignore
```

---

## 🧠 Key Troubleshooting Lessons

This project involved several real Jenkins and CI/CD troubleshooting scenarios.

### Jenkins Agent Connection

The inbound agent initially failed to connect because the agent secret was configured incorrectly.

**Resolution:** recreated the agent with the correct secret and WebSocket configuration.

### Missing Agent Tooling

The standard Jenkins inbound agent did not contain the Python and Docker CLI tools required by the pipeline.

**Resolution:** created a custom Jenkins Agent image.

### Docker Socket Access

The Jenkins Agent required Docker daemon access to build images.

For this local Docker Desktop lab, the Docker socket was mounted into the agent.

**Production consideration:** Docker socket access provides significant control over the Docker host and requires stronger isolation and security controls in production.

### Jenkinsfile UTF-8 BOM

The Jenkinsfile initially contained a UTF-8 BOM.

Jenkins consequently failed to recognize the Declarative Pipeline DSL.

**Resolution:** removed the BOM and committed the corrected Jenkinsfile.

### Declarative Pipeline Structure

The deployment stage was initially placed outside the `stages` block.

Jenkins reported:

```text
No such DSL method 'steps'
```

**Resolution:** corrected the Declarative Pipeline structure so every stage resides inside:

```groovy
stages {
    ...
}
```

### Remote Build Number

The deployment initially attempted to use Jenkins' `BUILD_NUMBER` directly inside the remote EC2 shell.

The variable exists in the Jenkins environment, not automatically on EC2.

**Resolution:** the image tag is resolved on the Jenkins Agent first and then passed to the EC2 deployment command.

---

## 🔒 Security Notes

This project is a learning lab, so several areas use simplified configurations.

### SSH Host Verification

The lab deployment uses:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
```

This avoids interactive host-key confirmation during automated deployment.

A production implementation should verify and manage the EC2 host key properly.

### Docker Socket

The Jenkins Agent has Docker socket access so it can build Docker images.

This provides powerful access to the Docker host and should be carefully isolated in production.

### Secrets

Private SSH keys and Jenkins secrets are not stored in Git.

---

## ✅ Deployment Result

The completed pipeline successfully demonstrated:

```text
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
```

The deployment was successfully verified by accessing the application through the EC2 public IP.

---

## 📊 Pipeline Result

A successful pipeline build performs the complete workflow automatically:

| Stage | Result |
|---|---|
| GitHub Checkout | ✅ |
| EC2 SSH Connectivity | ✅ |
| Automated Tests | ✅ |
| Docker Image Build | ✅ |
| Docker Image Transfer | ✅ |
| EC2 Deployment | ✅ |
| Application Deployment | ✅ |

---

## 🔮 Future Improvements

Potential improvements for a more production-oriented implementation:

- GitHub webhook-triggered builds
- Docker BuildKit / buildx
- Amazon ECR for image storage
- HTTPS/TLS
- Proper SSH host-key management
- Terraform-managed AWS infrastructure
- Ansible configuration management
- Kubernetes deployment
- Amazon EKS
- Monitoring and centralized logging
- Deployment rollback strategy
- Blue/green or rolling deployments

These are intentionally outside the scope of this project.

---

## 🛠️ Technology Stack

```text
Git
GitHub
Jenkins
Groovy
Python
Flask
Docker
SSH
AWS EC2
Amazon Linux 2023
PowerShell
```

---

## 📌 Project Status

**Project 3 — Jenkins CI/CD Lab: Completed**

The project demonstrates an end-to-end Jenkins CI/CD workflow that automatically tests, builds, and deploys a Dockerized application to AWS EC2.
