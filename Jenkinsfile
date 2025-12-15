pipeline {
    agent any

    tools {
        nodejs 'node-20'
    }

    environment {
        DOCKER_HUB_USER = 'fuffy1020'
        IMAGE_NAME = 'hw6-cicd'
        DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1450091759664238695/nIVp79hGZbrMRqTmeYSdjBdI8W_MTsO2Hi-zZpF742zH9CH6QKGSgjhvRJpUGvjDIY82'

        FULL_IMAGE = "${DOCKER_HUB_USER}/${IMAGE_NAME}"
    }

    stages {
        stage('Static Analysis') {
            steps {
                echo 'Running Quality Gate...'
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

                    sh 'docker build -t ${FULL_IMAGE}:${devTag} .'
                    sh 'docker push ${FULL_IMAGE}:${devTag}'

                    sh 'docker rm -f dev-app || true'
                    sh "docker run -d -p 8081:8080 --name dev-app ${FULL_IMAGE}:${devTag}"

                    sleep 5
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

                    sh 'docker pull ${FULL_IMAGE}:${targetTag}'
                    sh 'docker tag ${FULL_IMAGE}:${targetTag} ${FULL_IMAGE}:${prodTag}'
                    sh 'docker push ${FULL_IMAGE}:${prodTag}'

                    sh 'docker rm -f prod-app || true'
                    sh "docker run -d -p 8082:8080 --name prod-app ${FULL_IMAGE}:${prodTag}"
                }
            }
        }
    }
    post {
        failure {
            script {
                def message = """ 
                {
                    "content": "🚨 **Build Failed!** 🚨\\n**Name:** 你的名字\\n**ID:** 你的學號\\n**Job:** ${env.JOB_NAME}\\n**Build:** ${env.BUILD_NUMBER}\\n**Branch:** ${env.BRANCH_NAME}\\n**Repo:** ${env.GIT_URL}\\n**Status:** ${currentBuild.currentResult}"
                }
                """
                sh "curl -H 'Content-Type: application/json' -d '${message}' ${DISCORD_WEBHOOK}"
            }
        }
    }
}