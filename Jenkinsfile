pipeline {
    agent any
    
    environment {

        // JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
        // PATH = "${JAVA_HOME}/bin:${env.PATH}"
        
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'us-east-1'

        SONAR_TOKEN = credentials('sonar-token')
        SONAR_PROJECT_KEY = 'com.attainx:USCIS-springboot'
        SONAR_HOST_URL = 'http://3.238.8.141:9000'
        // SONAR_LOGIN = credentials('sonar-login')
    }

    stages {
        stage('Checkout') {
            steps {
                git(
                    url: 'https://github.com/AttainX/USCIS-springboot',
                    branch: 'dev'
                )
            }
        }

        stage('Prepare Environment') {
            steps {
                sh 'docker --version'
                sh 'ls -la'
            }
        }

        stage('Build') {
            steps {
                sh './gradlew bootJar'
            }
        }

        
                stage('SonarQube Analysis') {
            agent {
                any {
                    image 'sonarsource/sonar-scanner-cli'
                    args '-v $WORKSPACE:/usr/src -v $WORKSPACE/sonar_cache:/opt/sonar-scanner/.sonar/cache'
                }
            }
                    
            steps {
                
                withSonarQubeEnv('SonarQube') {

                    
                    
                    sh '''

                        echo "SONAR_TOKEN: $SONAR_TOKEN"
                        echo "SONAR_PROJECT_KEY: $SONAR_PROJECT_KEY"
                        echo "SONAR_HOST_URL: $SONAR_HOST_URL"

                        pwd
                        ls -a
    
                        /opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                        -Dsonar.projectName="uscis" \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.java.binaries=build/classes \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.host.url=http://3.238.8.141:9000 \
                        -Dsonar.login=sqp_2572f8f643881371be927f2e55ed9225208d04d5
                    '''
// /                        -Dsonar.login=$SONAR_LOGIN

                }
            }
        }

        stage('Build Docker Image and Push to ECR') {
            steps {
                sh """
                    echo $USER
                    aws ecr get-login-password | docker login -u AWS --password-stdin 537792915666.dkr.ecr.us-east-1.amazonaws.com

                    docker buildx build --platform linux/amd64 -t 537792915666.dkr.ecr.us-east-1.amazonaws.com/spring-uscis:springuscis-latest --push .
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Install Trivy
                    // sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin'

                    // Run Trivy scan
                    sh 'trivy image 537792915666.dkr.ecr.us-east-1.amazonaws.com/spring-uscis:springuscis-latest || true'
                }
            }
        }

        
        stage('Deploy to EKS') {
            steps {
                script {
                    def clusterName = "jenkins-spring-cluster"
                    def existingClusters = sh(script: 'aws eks list-clusters --query "clusters" --output text', returnStdout: true).trim()
                    
                    if (!existingClusters.contains(clusterName)) {
                        sh """
                            eksctl create cluster --name ${clusterName} --region us-east-1 --nodegroup-name spring-nodes --node-type t3.medium --nodes 3
                        """
                    } else {
                        echo "Cluster ${clusterName} already exists."
                    }

                    sh """
                        aws eks update-kubeconfig --name ${clusterName}

                        kubectl apply -f scripts/deployment.yaml
                        kubectl apply -f scripts/service.yaml
                        kubectl get svc spring-boot-app2
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
