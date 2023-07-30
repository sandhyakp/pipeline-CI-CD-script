pipeline {
    agent any

    stages {
        stage('git checkout') {
            steps {
               sh 'sudo rm -rf *'
               sh 'git clone https://github.com/atulyw/student-ui.git'
            }
        }
        stage('aws-cred copy to container') {
            steps {
               sh 'sudo cp /root/.aws/credentials ./aws'
            }
        }
        stage('docker file') { 
            steps {
                sh '''cat <<EOF> Dockerfile
                FROM ubuntu as builder 
                RUN apt-get update && apt-get install openjdk-8-jdk -y
                RUN apt-get install maven -y
                COPY ./student-ui /mnt/
                WORKDIR /mnt
                RUN mvn clean package
                    
                FROM amazon/aws-cli as sender
                COPY  aws /root/.aws/credentials
                RUN aws s3 ls
                COPY --from=builder /mnt/target/studentapp-2.2-SNAPSHOT.war .                    
                RUN aws s3 cp studentapp-2.2-SNAPSHOT.war s3://takemichi1/studentapp.war
                    
                FROM tomcat
                COPY --from=builder /mnt/target/studentapp-2.2-SNAPSHOT.war webapps/.
                    
                '''
            }
        }
        stage('docker build') {
            steps {
               sh 'sudo aws ecr get-login-password --region ap-south-1 | sudo docker login --username AWS --password-stdin 912606371517.dkr.ecr.ap-south-1.amazonaws.com'
               sh 'sudo docker build -t sandy .'
               sh 'sudo docker tag sandy:latest 912606371517.dkr.ecr.ap-south-1.amazonaws.com/sandy:latest'
               sh 'sudo docker push 912606371517.dkr.ecr.ap-south-1.amazonaws.com/sandy:latest'
            }
        }
    }
}
