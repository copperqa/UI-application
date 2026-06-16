pipeline {
    agent any
    environment {
        EC2_USER = "ubuntu"
        EC2_HOST = "54.167.38.50"
        SSH_CREDENTIALS = "EC2-UI-application"
        GITHUB_REPO = "https://github.com/copperqa/UI-application.git"
        IMAGE_NAME = "ui-app"
        CONTAINER_NAME = "ui-container"
    }
    stages {
        stage('SSH To EC2') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} \
                    "echo Connected to EC2"
                    """
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} '
                    if ! command -v docker >/dev/null
                    then
                        echo Installing Docker
                        sudo apt update
                        sudo apt install docker.io -y
                        sudo systemctl start docker
                        sudo systemctl enable docker
                    else
                        echo Docker already installed
                    fi

                    docker --version

                    if ! command -v trivy >/dev/null
                    then
                        echo Installing Trivy
                        sudo apt update
                        sudo apt install wget apt-transport-https gnupg lsb-release -y

                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
                        | gpg --dearmor \
                        | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

                        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main" \
                        | sudo tee /etc/apt/sources.list.d/trivy.list

                        sudo apt update
                        sudo apt install trivy -y
                    else
                        echo Trivy already installed
                    fi

                    trivy --version

                    echo Dependencies Installed Successfully
                    '
                    """

                }
            }
        }
        stage('Copy Code From GitHub') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} '
                    rm -rf ui-deployment
                    git clone ${GITHUB_REPO} ui-deployment
                    cd ui-deployment
                    echo "Code downloaded"
                    '
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} '
                    cd ui-deployment
                    docker build \
                    -t ${IMAGE_NAME}:latest . || exit 1
                    echo Image Build Completed
                    '
                    """
                }
            }
        }

        stage('Scan Docker Image') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} '
                    echo Scanning image ${IMAGE_NAME}:latest

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    ${IMAGE_NAME}:latest
                    '
                    """
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                sshagent(["${SSH_CREDENTIALS}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ${EC2_USER}@${EC2_HOST} '
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p 80:80 \
                    ${IMAGE_NAME}:latest
                    docker ps
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "UI Deployment Successful 🚀"
        }
        failure {
            echo "Deployment Failed ❌"
        }
    }
}