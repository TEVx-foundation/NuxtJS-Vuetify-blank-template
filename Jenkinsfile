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
                sh "docker run -d -p 3000:3000 --name DevSecOps-Nuxt-Vuetify viswampc/DevSecOps-Nuxt-Vuetify:latest"
            }
        }

        stage('OWASP Zap Scan (DAST)') {
            steps {
                sh "docker run --rm -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:3000 -g gen.conf -r zap-report.html"
            }
        }

        stage('Deploy to container'){
            steps{
                sh 'echo "Deploying to container."'
            }
        }
    }

    post {
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
