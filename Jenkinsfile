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
  
        stage('Install Application Dependencies') {
            steps {
                sh "npm install -g yarn"
                sh "yarn install"
            }
        }

        stage('OWASP SCA Analysis') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit',   odcInstallation: 'owasp-dependency-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Trivy FS Analysis') {
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
                sh "trivy image viswampc/DevSecOps-Nuxt-Vuetify:latest > trivyimage.txt" 
            }
        }

        stage('Deploy to container'){
            steps{
                sh 'echo "Deploying to container."'
            }
        }
    }
}
