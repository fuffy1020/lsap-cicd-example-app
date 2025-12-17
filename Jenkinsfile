pipeline {
    agent any

    tools {
        nodejs 'node-20'
    }

    environment {
        DOCKER_HUB_USER = 'fuffy1020'
        IMAGE_NAME = 'im3014-hw6'
        DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1450091759664238695/nIVp79hGZbrMRqTmeYSdjBdI8W_MTsO2Hi-zZpF742zH9CH6QKGSgjhvRJpUGvjDIY82'

        FULL_IMAGE = "${DOCKER_HUB_USER}/${IMAGE_NAME}"
        DOCKER_CREDS_ID = 'docker-hub-creds'
    }

    stages {
        stage('Static Analysis') {
            steps {
                echo 'Running Quality Gate...'
                sh 'node -v'
                sh 'npm install'
                sh 'npm run lint' 
            }
        }

        stage('Build & Deploy Staging') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    def pkgVersion = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
                    def semanticTag = "v${pkgVersion}"
                    
                    def devTag = "dev-${env.BUILD_NUMBER}"
                    echo "Building Staging Artifact: ${devTag} AND Semantic Tag: ${semanticTag}"
                    
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        
                        sh "docker build -t ${FULL_IMAGE}:${devTag} ."
                        sh "docker push ${FULL_IMAGE}:${devTag}"

                        sh "docker tag ${FULL_IMAGE}:${devTag} ${FULL_IMAGE}:${semanticTag}"
                        sh "docker push ${FULL_IMAGE}:${semanticTag}"
                    }
                    
                    sh "docker ps | grep dev-app && docker rm -f dev-app || true"
                    sh "docker run -d -p 8081:8080 --name dev-app ${FULL_IMAGE}:${devTag}"
                    
                    sleep 5
                    sh "docker ps | grep dev-app || exit 1"
                }
            }
        }

        stage('Promote to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def targetTag = readFile('deploy.config').trim()
                    def prodTag = "prod-${env.BUILD_NUMBER}"
                    
                    echo "Promoting version ${targetTag} to Production as ${prodTag}"
                    
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker pull ${FULL_IMAGE}:${targetTag}"
                        sh "docker tag ${FULL_IMAGE}:${targetTag} ${FULL_IMAGE}:${prodTag}"
                        sh "docker push ${FULL_IMAGE}:${prodTag}"
                    }
                    
                    sh "docker rm -f prod-app || true"
                    sh "docker run -d -p 8082:8080 --name prod-app ${FULL_IMAGE}:${prodTag}"
                }
            }
        }
    }

    post {
        failure {
            script {
                echo "Attempting to send Discord notification..."
                def webhookUrl = env.DISCORD_WEBHOOK
                
                if (webhookUrl) {
                    def message = """
                    {
                        "content": "🚨 **Build Failed!** 🚨\\n**Name:** 朱冠宇\\n**ID:** B10705043\\n**Job:** ${env.JOB_NAME}\\n**Build:** ${env.BUILD_NUMBER}\\n**Branch:** ${env.BRANCH_NAME}\\n**Repo:** ${env.GIT_URL}\\n**Status:** FAILURE"
                    }
                    """
                    sh "curl -H 'Content-Type: application/json' -d '${message}' ${webhookUrl}"
                } else {
                    echo "Error: DISCORD_WEBHOOK variable is missing!"
                }
            }
        }
    }
}