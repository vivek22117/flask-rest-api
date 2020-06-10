#! /bin/bash

function initialize_worker() {
    printf "***************************************************\n\t\tSetting up host \n***************************************************\n"
    # Update packages
    echo ======= Updating packages ========
    sudo apt-get update

    # Export language locale settings
    echo ======= Exporting language locale settings =======
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Install pip3
    echo ======= Installing pip3 =======
    sudo apt-get install -y python3-pip
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
    if [[ -d ~/flask-app ]]; then
        sudo rm -rf ~/flask-app
        git clone -b master https://github.com/vivek22117/flask-rest-api.git ~/flask-app
        cd ~/flask-app/
    else
        git clone -b master https://github.com/vivek22117/flask-rest-api.git ~/flask-app
        cd ~/flask-app/
    fi
}

function setup_app() {
    printf "***************************************************\n    Installing App dependencies and Env Variables \n***************************************************\n"
    setup_env
    # Install required packages
    echo ======= Installing required packages ========
    pip3 install -r requirements.txt

}

# Create and Export required environment variable
function setup_env() {
    echo ======= Exporting the necessary environment variables ========
    sudo cat > ~/.env << EOF
    export APP_CONFIG="production"
    export FLASK_APP=run.py
    export IS_RUNNING_LOCAL="false"
EOF
    echo ======= Exporting the necessary environment variables ========
    source ~/.env
}

# Add a launch script
function create_launch_script () {
    printf "***************************************************\n\t\tCreating a Launch script \n***************************************************\n"

    sudo cat > /home/ubuntu/launch.sh <<EOF
    #!/bin/bash
    cd ~/flask-app
    source ~/.env
    source ~/venv/bin/activate
    flask run --host=0.0.0.0 > sysout.txt 2>&1 &
EOF
    sudo chmod 744 /home/ubuntu/launch.sh
    echo ====== Ensuring script is executable =======
    ls -la ~/launch.sh
}

function configure_startup_service () {
    printf "***************************************************\n\t\tConfiguring startup service \n***************************************************\n"

    sudo bash -c 'cat > /etc/systemd/system/flask-rest.service <<EOF
    [Unit]
    Description=flask-rest startup service
    After=network.target

    [Service]
    User=ubuntu
    ExecStart=/bin/bash /home/ubuntu/launch.sh

    [Install]
    WantedBy=multi-user.target
EOF'

    sudo chmod 664 /etc/systemd/system/flask-rest.service
    sudo systemctl daemon-reload
    sudo systemctl enable flask-rest.service
    sudo systemctl start flask-rest.service
    sudo service flask-rest status
}

# Serve the web app through gunicorn
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
create_launch_script
configure_startup_service
launch_app