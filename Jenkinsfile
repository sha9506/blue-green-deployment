pipeline {
    agent any
    environment {
        REGISTRY = "docker.io/sh9506"
        BLUE_IMAGE = "${REGISTRY}/flask-blue:latest"
        GREEN_IMAGE = "${REGISTRY}/flask-green:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/sha9506/blue-green-deployment.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def color = sh(script: "kubectl get svc flask-service -o=jsonpath='{.spec.selector.version}'", returnStdout: true).trim()
                    def nextColor = (color == "blue") ? "green" : "blue"
                    sh "docker build -t ${REGISTRY}/flask-${nextColor}:latest ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
                    def nextColor = (color == "blue") ? "green" : "blue"
                    sh "docker push ${REGISTRY}/flask-${nextColor}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def color = sh(script: "kubectl get svc flask-service -o=jsonpath='{.spec.selector.version}'", returnStdout: true).trim()
                    def nextColor = (color == "blue") ? "green" : "blue"
                    sh "kubectl apply -f k8s/deployment-${nextColor}.yaml"
                    sh "kubectl patch service flask-service -p '{\"spec\":{\"selector\":{\"app\":\"flask\",\"version\":\"${nextColor}\"}}}'"
                }
            }
        }
    }
}
