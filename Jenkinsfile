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
                // 檢查 node 版本，確認安裝成功
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
                    def devTag = "dev-${env.BUILD_NUMBER}"
                    echo "Building Staging Artifact: ${devTag}"
                    
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDS_ID, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        // 登入 Docker Hub
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        
                        // 建置與推送
                        sh "docker build -t ${FULL_IMAGE}:${devTag} ."
                        sh "docker push ${FULL_IMAGE}:${devTag}"
                    }
                    
                    // 部署與驗證
                    sh "docker rm -f dev-app || true"
                    sh "docker run -d -p 8081:8080 --name dev-app ${FULL_IMAGE}:${devTag}"
                    sleep 10 // 等待久一點讓服務啟動
                    sh "curl -f http://localhost:8081/ || exit 1"
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
                // 使用 env.DISCORD_WEBHOOK 確保讀得到變數
                def webhookUrl = env.DISCORD_WEBHOOK
                
                if (webhookUrl) {
                    def message = """
                    {
                        "content": "🚨 **Build Failed!** 🚨\\n**Name:** 你的名字\\n**ID:** 你的學號\\n**Job:** ${env.JOB_NAME}\\n**Build:** ${env.BUILD_NUMBER}\\n**Branch:** ${env.BRANCH_NAME}\\n**Repo:** ${env.GIT_URL}\\n**Status:** FAILURE"
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