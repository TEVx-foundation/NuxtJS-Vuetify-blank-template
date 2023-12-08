pipeline{
    agent any
    tools{
        nodejs 'nodejs-20-lts'
    }
    environment {
        SCANNER_HOME=tool 'sonarqube-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }

        stage('Clone Vuetify-Nuxt-Template Repo'){
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
  
        stage('Install Dependencies') {
            steps {
                sh "npm install -g yarn"
                sh "yarn install"
                sh "export NODE_OPTIONS=--openssl-legacy-provider"
                sh "yarn build"
            }
        }

        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',   odcInstallation: 'owasp-dependency-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){   
                       sh "docker build -t DevSecOps-Nuxt-Vuetify ."
                       sh "docker tag DevSecOps-Nuxt-Vuetify viswampc/DevSecOps-Nuxt-Vuetify:latest "
                       sh "docker push viswampc/DevSecOps-Nuxt-Vuetify:latest "
                    }
                }
            }
        }

        stage("TRIVY"){
            steps{
                sh "trivy image viswampc/ExaQuo:latest > trivyimage.txt" 
            }
        }

        stage('Deploy to container'){
            steps{
                sh 'docker run -d --name ExaQuo-lts -p 3000:3000 viswampc/ExaQuo:latest'
            }
        }
    }
}
