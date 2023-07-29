terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.9.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  
}

resource "aws_iam_policy" "policy" {
  name        = "-policy111"
  description = "My test policy"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
    ]
}
EOT
}

resource "aws_iam_role" "role" {
  name = "s3-access-to-ec2-role111"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "profile111"
  role = aws_iam_role.role.name
}

resource "aws_instance" "ec2" {
  ami           = "ami-040d60c831d02d41c"
  instance_type = "t3.large"
  key_name = "stockholm.pem"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  iam_instance_profile = aws_iam_instance_profile.profile.name
  user_data = <<EOF
#!/bin/bash
BUCKET=takemichi1
sudo yum update 
sudo yum install java-1.8.0-amazon-corretto-devel.x86_64  -y 
wget https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.91/bin/apache-tomcat-8.5.91.zip
sudo yum install zip  -y 
sudo unzip apache-tomcat-8.5.91.zip
sudo mv apache-tomcat-8.5.91 /mnt/tomcat
KEY=`aws s3 ls $BUCKET --recursive | sort | tail -n 1 | awk '{print $4}'`
aws s3 cp s3://$BUCKET/$KEY /mnt/tomcat/webapps/
sudo mv /mnt/tomcat/webapps/$KEY /mnt/tomcat/webapps/student
sudo chown -R ec2-user: /mnt/tomcat
cd /mnt/tomcat/bin
sudo chmod 755 *
sudo ./catalina.sh start 

  EOF
   tags = {
    Name = "tf-ec2-sample"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
