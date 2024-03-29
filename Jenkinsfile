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
                // sh "docker run --rm -d -p 3000:3000 --network DevSecOps --name devsecops-nuxt-vuetify viswampc/devsecops-nuxt-vuetify:latest"
                sh "docker run --rm -d -p 3000:3000 --network DevSecOps --name devsecops-nuxt-vuetify viswampc/nuxtjs-vuetify-blank-template:v5"
            }
        }

        stage('OWASP Zap Scan (DAST)') {
            steps {
                script {
                    def nuxtAddress = sh(script: 'docker inspect -f \'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\' devsecops-nuxt-vuetify', returnStdout: true).trim()

                    sh 'mkdir -p $WORKSPACE/zap-work'
                    sh 'docker run -itd --rm -u zap --network DevSecOps -v $WORKSPACE/zap-work:/zap/wrk -p 8081:8080 -p 8090:8090 -d --name owasp-zap owasp/zap2docker-live:latest'
                    sh 'docker exec owasp-zap mkdir -p /zap/wrk'
                    sh 'docker exec owasp-zap mkdir -p /home/zap'

                    sh 'docker exec -u 0 owasp-zap chmod 777 /zap/wrk'
                    sh 'docker exec -u 0 owasp-zap chmod 777 /home/zap'

                    try {
                        sh 'docker exec owasp-zap zap-baseline.py -t http://172.19.0.2:3000 -r nuxt-zap-report.html'
                    } catch (err) {
                        echo "ZAP Scan Completed with Errors and Warnings."
                    }

                    // docker.image('owasp/zap2docker-live:latest').withRun('-u zap -v $WORKSPACE/zap-work:/zap/wrk -p 8081:8080 -p 8090:8090 --rm --name zap2docker') {
                    //     sh '/zap/zap-baseline.py -t http://localhost:3000 -r /zap/wrk/nuxt-zap-report.html'
                    // }

                    sh 'docker stop owasp-zap'
                    sh 'docker container prune --force'
                }
            }
        }

        stage('Deploy Container'){
            steps{
                sh 'echo "Deploying to container."'
            }
        }
    }

    post {
      always {
            script {
                sh "docker stop devsecops-nuxt-vuetify"
                sh "docker rmi devsecops-nuxt-vuetify:latest --force"
                sh "docker rmi viswampc/devsecops-nuxt-vuetify:latest --force"
            }
        }
    }
}
