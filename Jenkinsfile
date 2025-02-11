pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE_NAME = 'vignesh4devops/container-id-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clean workspace before cloning
                cleanWs()
                // Clone the repository
                git branch: 'main',
                    url: 'https://github.com/Vignesh-4-devops/project_primary.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir('Task_3') {
                    script {
                        // Build the Docker image with build number tag
                        sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
                        // Also tag as latest
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    // Login to Docker Hub
                    sh "echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin"
                    
                    // Push both tags
                    sh "docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                    sh "docker push ${DOCKER_IMAGE_NAME}:latest"
                    
                    // Logout for security
                    sh "docker logout"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                dir('Task_3/kubernetes') {
                    script {
                        // Update the image tag in deployment yaml
                        sh """
                            sed -i.bak 's|image: .*|image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|' deployment.yaml
                            kubectl apply -f deployment.yaml
                            kubectl apply -f service.yaml
                            kubectl apply -f hpa.yaml
                        """
                        
                        // Wait for deployment to complete
                        sh """
                            kubectl rollout status deployment/container-id-app
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up local Docker images
            script {
                sh "docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest || true"
            }
        }
    }
} 