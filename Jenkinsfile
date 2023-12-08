pipeline{
    agent any
    tools{
        nodejs 'nodejs-20-lts'
    }

    environment {
        SCANNER_HOME=tool 'sonarqube-scanner'
    }

    stages {
        stage('Clean Workspace'){
            steps{
                cleanWs()
            }
        }

        stage('Clone Github Repo'){
            steps{
                git branch: 'main', url: 'https://github.com/TEVx-foundation/NuxtJS-Vuetify-blank-template.git'
            }
        }

        stage("SonarQube Analysis (SAST)"){
            steps{
                withSonarQubeEnv('sonarqube-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Nuxt-Vuetify \
                    -Dsonar.projectKey=Nuxt-Vuetify -Dsonar.exclusions=**/*.java'''
                }
            }
        }
  
        stage('Install Application Dependencies') {
            steps {
                sh "npm install -g yarn"
                sh "export NODE_OPTIONS=--openssl-legacy-provider"
                sh "yarn install"
                sh "yarn build"
            }
        }

        stage('OWASP SCA Analysis (SCA 1)') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',   odcInstallation: 'owasp-dependency-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy Analysis (SCA 2)') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Docker Build Image"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker-credentials', toolName: 'docker'){   
                       sh "docker build -t devsecops-nuxt-vuetify ."
                       sh "docker tag devsecops-nuxt-vuetify viswampc/devsecops-nuxt-vuetify:latest"
                       //  sh "docker push viswampc/devsecops-nuxt-vuetify:latest"
                    }
                }
            }
        }

        stage("Trivy Image Scan"){
            steps{
                sh "trivy image viswampc/devsecops-nuxt-vuetify:latest > trivyimage.txt" 
            }
        }

        stage('Docker Start Container') {
            steps {
                sh "docker run --rm -d -p 3000:3000 --name devsecops-nuxt-vuetify viswampc/devsecops-nuxt-vuetify:latest"
            }
        }

        stage('OWASP Zap Scan (DAST)') {
            steps {
                script {
                    docker.image('owasp/zap2docker-live:latest').withRun('-u zap -p 8081:8080 -p 8090:8090 --rm --name zap2docker') {
                        sh 'mkdir -p /zap/wrk'
                        sh '/zap/zap-baseline.py -t http://localhost:3000 -r /zap/wrk/nuxt-zap-report.html'
                    }
                }
            }
        }

        stage('Deploy to container'){
            steps{
                sh 'echo "Deploying to container."'
            }
        }
    }

    post {
      always {
            script {
                sh "docker stop devsecops-nuxt-vuetify"
                sh "docker rmi devsecops-nuxt-vuetify:latest"
                sh "docker rmi viswampc/devsecops-nuxt-vuetify:latest"
            }

            script {
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'zap-reports',
                    reportFiles: 'nuxt-zap-report.html',
                    reportName: 'ZAP Report'
                ])
            }
        }
    }
}
