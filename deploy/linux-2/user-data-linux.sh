#! /bin/bash

function initialize_worker() {
  printf "***********************************\n\t\tSetting up host \n******************************\n"
  # Update packages
  echo ======= Creating Directory ========
  sudo yum update -y

  # Export language locale settings
  echo ======= Exporting language locale settings =======
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8

  # Install pip3
  echo ======= Installing pip3 =======
  sudo yum install -y python3-pip
  sudo yum install unzip -y

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install

  aws --version
  aws s3 cp s3://eks-doubledigit-aritifactory-eks-dev-us-east-1/install-monitoring-tools-linux.sh .
}

function launch_app() {
  printf "*********************************\n\t\tServing the App \n************************************\n"
  bash install-monitoring-tools-linux.sh
}

initialize_worker
launch_app
