pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'jeevanjacob11'
        BACKEND_IMAGE  = "${DOCKERHUB_USER}/cloudops-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/cloudops-frontend"
        IMAGE_TAG      = "1.0.${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test Backend') {
            steps {
                dir('app/backend') {
                    sh '''
                        npm install
                        npm test
                    '''
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('app/frontend') {
                    sh '''
                        npm install
                        npm run build
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build \
                      -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                      -t ${BACKEND_IMAGE}:latest \
                      ./app/backend

                    docker build \
                      -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                      -t ${FRONTEND_IMAGE}:latest \
                      ./app/frontend
                '''
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                          -u "$DOCKER_USERNAME" \
                          --password-stdin

                        docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${BACKEND_IMAGE}:latest

                        docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${FRONTEND_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                      --region ap-southeast-2 \
                      --name cloudops-platform-dev-eks

                    helm upgrade cloudops-app ./helm/cloudops-app \
                      --namespace cloudops \
                      --install \
                      --set backend.image.tag=${IMAGE_TAG} \
                      --set frontend.image.tag=${IMAGE_TAG}

                    kubectl rollout status deployment/cloudops-app-backend \
                      -n cloudops \
                      --timeout=180s

                    kubectl rollout status deployment/cloudops-app-frontend \
                      -n cloudops \
                      --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get pods -n cloudops
                    helm status cloudops-app -n cloudops
                '''
            }
        }
    }

    post {
        success {
            echo 'CloudOps Platform deployment completed successfully.'
        }

        failure {
            echo 'CloudOps Platform pipeline failed.'
        }
    }
}