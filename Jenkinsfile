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
                       sh "docker build -t DevSecOps-Nuxt-Vuetify ."
                       sh "docker tag DevSecOps-Nuxt-Vuetify viswampc/DevSecOps-Nuxt-Vuetify:latest"
                       //  sh "docker push viswampc/DevSecOps-Nuxt-Vuetify:latest"
                    }
                }
            }
        }

        stage("Trivy Image Scan"){
            steps{
                sh "trivy image viswampc/DevSecOps-Nuxt-Vuetify:latest > trivyimage.txt" 
            }
        }

        stage('Docker Start Image') {
            steps {
                sh "docker run --rm -d -p 3000:3000 --name devsecops-nuxt-vuetify viswampc/DevSecOps-Nuxt-Vuetify:latest"
            }
        }

        stage('OWASP Zap Scan (DAST)') {
            steps {
                script {
                    docker.image('owasp/zap2docker-live:latest').withRun('-u zap -p 8080:8080 -p 8090:8090') {
                        sh 'zap-baseline.py -t http://localhost:3000 -r zap-report.html'
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
                try {
                    docker.image('devsecops-nuxt-vuetify').stop()
                } finally {
                    docker.image('devsecops-nuxt-vuetify').remove()
                }
            }

            script {
                publishHTML(target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: 'zap-reports',
                    reportFiles: 'zap-report.html',
                    reportName: 'ZAP Report'
                ])
            }
        }
    }
}
