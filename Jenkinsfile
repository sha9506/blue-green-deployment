pipeline {
    agent any

    options {
        // Avoid the implicit checkout and do it explicitly in the Checkout stage
        skipDefaultCheckout(true)
    }

    environment {
        REGISTRY = "docker.io/sh9506"
        BLUE_IMAGE = "${REGISTRY}/flask-blue:latest"
        GREEN_IMAGE = "${REGISTRY}/flask-green:latest"
        NEXT_COLOR = "" // will be set during the build stage
    }

    stages {
        stage('Checkout') {
            steps {
                // Use the same SCM and branch as the multibranch/job configuration (e.g., main)
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Determine current service color; default if service/selector not found
                    def currentColor = "blue"
                    try {
                        currentColor = sh(
                            script: "kubectl get svc flask-service -o=jsonpath='{.spec.selector.version}' 2>/dev/null || echo 'blue'",
                            returnStdout: true
                        ).trim()
                        if (currentColor == "") {
                            currentColor = "blue"
                        }
                    } catch (err) {
                        echo "Could not determine current color from service; defaulting to 'blue'. Details: ${err}"
                        currentColor = "blue"
                    }

                    def nextColor = (currentColor == "blue") ? "green" : "blue"
                    env.NEXT_COLOR = nextColor
                    echo "Current color: ${currentColor}, Next color: ${nextColor}"
                    sh "docker build -t ${REGISTRY}/flask-${nextColor}:latest ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Expect DOCKER_USER and DOCKER_PASS to be provided as env or via Jenkins credentials binding
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push ${REGISTRY}/flask-${env.NEXT_COLOR}:latest"
                }
            }
        }

        // stage('Deploy to Kubernetes') {
        //     steps {
        //         script {
        //             sh "kubectl apply -f k8s/deployment-${env.NEXT_COLOR}.yaml"
        //             sh "kubectl patch service flask-service -p '{\"spec\":{\"selector\":{\"app\":\"flask\",\"version\":\"${env.NEXT_COLOR}\"}}}'"
        //         }
        //     }
        // }
    }
}
