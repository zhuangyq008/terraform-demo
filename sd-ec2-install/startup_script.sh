#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
newgrp docker
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
ln -s /usr/bin/aws aws
aws ecr get-login-password --region ap-southeast-1 |docker login --username AWS --password-stdin 284367710968.dkr.ecr.ap-southeast-1.amazonaws.com
docker pull 284367710968.dkr.ecr.ap-southeast-1.amazonaws.com/stable_diffusion_fp32:latest
docker run -p 80:3000  --gpus all 284367710968.dkr.ecr.ap-southeast-1.amazonaws.com/stable_diffusion_fp32:latest