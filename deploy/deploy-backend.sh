#! /bin/bash


functin add_newuser() {
	 printf "***************************************************\n\t\tAdding new user \n***************************************************\n"
	 adduser airflow
	 
	 # provide password, name, number others
	 
	 usermod -aG sudo airflow
	 
	 # switch to new user
	 su - airflow    
	 
}
function initialize_worker() {
    printf "***************************************************\n\t\tSetting up host \n***************************************************\n"
    # Update packages
    echo ======= Updating packages ========
    sudo apt-get update
	sudo apt-get install -y python3-pip
    export AIRFLOW_GPL_UNIDECODE=yes

    echo ====== python verison ========
    python3 -v

    # Export language locale settings
    echo ======= Exporting language locale settings =======
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Install pip3
    echo ======= Installing pip3 =======
    


    export AIRFLOW_GPL_UNIDECODE=yes
    export AIRFLOW_HOME=~/airflow
    sudo pip3 install apache-airflow

    airflow initdb

    sudo airflow webserver -p 8080 -D
    sudo airflow scheduler -D
	
	
	
	sudo curl -o /etc/systemd/system/airflow-webserver.service https://raw.githubusercontent.com/apache/airflow/master/scripts/systemd/airflow-webserver.service
	
	sudo vi /etc/systemd/system/airflow-webserver.service
	
	# EnvironmentFile=/etc/sysconfig/airflow (comment out this line)
	Environment="PATH=/home/airflow/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	ExecStart=/home/airflow/.local/bin/airflow webserver — pid /home/airflow/airflow-webserver.pid
	
	
	
	sudo curl -o /etc/systemd/system/airflow-scheduler.service https://raw.githubusercontent.com/apache/airflow/master/scripts/systemd/airflow-scheduler.service

	sudo vi /etc/systemd/system/airflow-scheduler.service
	
	# EnvironmentFile=/etc/sysconfig/airflow (comment out this line)
	Environment="PATH=/home/airflow/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	ExecStart=/home/airflow/.local/bin/airflow scheduler
	
	
	
	sudo systemctl daemon-reload
	
	sudo systemctl enable airflow-webserver
	sudo systemctl enable airflow-scheduler
	
	sudo systemctl start airflow-webserver
	sudo systemctl start airflow-scheduler
	
	sudo systemctl status airflow-webserver
	sudo systemctl status airflow-scheduler
	
	sudo systemctl enable airflow-webserver
	sudo systemctl enable airflow-scheduler
	
	sudo aws s3 cp s3://eks-doubledigit-aritifactory-eks-dev-us-east-1/airflow-api-0.0.1.jar . --region us-east-1
	
	sudo apt install openjdk-8-jdk
	
	java -Xms512m -Xmx1024m -jar airflow-api-0.0.1.jar > sysout.log 2>&1 & echo $!
	
	rm airflow-webserver-monitor.pid airflow-webserver.err
}

function setup_python_venv() {
    printf "***************************************************\n\t\tSetting up Venv \n***************************************************\n"
    # Install virtualenv
    echo ======= Installing virtualenv =======
    pip3 install virtualenv

    # Create virtual environment and activate it
    echo ======== Creating and activating virtual env =======
    virtualenv venv
    source ./venv/bin/activate
}

function clone_app_repository() {
    printf "***************************************************\n\t\tFetching App \n***************************************************\n"
    # Clone and access project directory
    echo ======== Cloning and accessing project directory ========
    if [[ -d ~/yummy-rest ]]; then
        sudo rm -rf ~/yummy-rest
        git clone -b master https://github.com/vivek22117/flask-rest-api.git ~/flask-rest-api
        cd ~/yummy-rest/
    else
        git clone -b develop https://github.com/indungu/yummy-rest.git ~/yummy-rest
        cd ~/yummy-rest/
    fi
}

function setup_app() {
    printf "***************************************************\n    Installing App dependencies and Env Variables \n***************************************************\n"
    setup_env
    # Install required packages
    echo ======= Installing required packages ========
    pip install -r requirements.txt

}

# Create and Export required environment variable
function setup_env() {
    echo ======= Exporting the necessary environment variables ========
    sudo cat > ~/.env << EOF
    export DYNAMODB_TABLE="productManuals"
    export APP_CONFIG="production"
    export FLASK_APP=run.py
EOF
    echo ======= Exporting the necessary environment variables ========
    source ~/.env
}

# Install and configure nginx
function setup_nginx() {
    printf "***************************************************\n\t\tSetting up nginx \n***************************************************\n"
    echo ======= Installing nginx =======
    sudo apt-get install -y nginx

    # Configure nginx routing
    echo ======= Configuring nginx =======
    echo ======= Removing default config =======
    sudo rm -rf /etc/nginx/sites-available/default
    sudo rm -rf /etc/nginx/sites-enabled/default
    echo ======= Replace config file =======
    sudo bash -c 'cat <<EOF > /etc/nginx/sites-available/src
    server {
            listen 80;
            listen [::]:80;

            server_name localhost;

            location / {
                    # reverse proxy and serve the src
                    # running on the localhost:8000
                    proxy_pass http://127.0.0.1:5000/;
                    proxy_set_header HOST \$host;
                    proxy_set_header X-Forwarded-Proto \$scheme;
                    proxy_set_header X-Real-IP \$remote_addr;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            }
    }
EOF'

    echo ======= Create a symbolic link of the file to sites-enabled =======
    sudo ln -s /etc/nginx/sites-available/src /etc/nginx/sites-enabled/

    # Ensure nginx server is running
    echo ====== Checking nginx server status ========
    sudo systemctl restart nginx
    sudo nginx -t
}

# Add a launch script
function create_launch_script () {
    printf "***************************************************\n\t\tCreating a Launch script \n***************************************************\n"

    sudo cat > /home/ubuntu/launch.sh <<EOF
    #!/bin/bash
    cd ~/flask-rest-api
    source ~/.env
    source ~/venv/bin/activate
    gunicorn app:APP -D
EOF
    sudo chmod 744 /home/ubuntu/launch.sh
    echo ====== Ensuring script is executable =======
    ls -la ~/launch.sh
}

function configure_startup_service () {
    printf "***************************************************\n\t\tConfiguring startup service \n***************************************************\n"

    sudo bash -c 'cat > /etc/systemd/system/yummy-rest.service <<EOF
    [Unit]
    Description=yummy-rest startup service
    After=network.target

    [Service]
    User=ubuntu
    ExecStart=/bin/bash /home/ubuntu/launch.sh

    [Install]
    WantedBy=multi-user.target
EOF'

    sudo chmod 664 /etc/systemd/system/yummy-rest.service
    sudo systemctl daemon-reload
    sudo systemctl enable yummy-rest.service
    sudo systemctl start yummy-rest.service
    sudo service yummy-rest status
}

Serve the web src through gunicorn
function launch_app() {
    printf "***************************************************\n\t\tServing the App \n***************************************************\n"
    sudo bash /home/ubuntu/launch.sh
}

######################################################################
########################      RUNTIME       ##########################
######################################################################

initialize_worker
setup_python_venv
clone_app_repository
setup_app
setup_nginx
create_launch_script
configure_startup_service
launch_app