pipeline {
    agent any

    stages {
        stage('git checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sandhyakp/pipeline-script.git'
            }
        }
         stage('tf init') {
            steps {
                sh 'sudo terraform init'
                sh 'sudo terraform plan'
                sh 'sudo terraform apply --auto-approve'
            }
        }
    }
}
