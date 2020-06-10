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


function initialize_node_exporter() {
    printf "*********************************\n\t\t Install Node-Exporter \n************************\n"

    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
    tar -xf node_exporter-0.18.1.linux-amd64.tar.gz
    sudo mv node_exporter-0.18.1.linux-amd64/node_exporter /usr/local/bin/
    sudo useradd -rs /bin/false node_exporter
    chown node_exporter:node_exporter /usr/local/bin/node_exporter
    rm -rf /tmp/node_exporter-0.18.1.linux-amd64*

    sudo cat << EOF > /etc/systemd/system/node_exporter.service
    [Unit]
    Description=Node Exporter
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    ExecStart=/usr/local/bin/node_exporter

    [Install]
    WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl enable node_exporter
}

function initialize_prometheus() {
    printf "*********************************\n\t\t Install Prometheus \n************************\n"

    cd /tmp
    wget https://github.com/prometheus/prometheus/releases/download/v2.18.1/prometheus-2.18.1.linux-amd64.tar.gz
    tar xfz prometheus-2.18.1.linux-amd64.tar.gz
    sudo cp prometheus-2.18.1.linux-amd64/{prometheus,promtool} /usr/local/bin/

    sudo useradd -rs /bin/false prometheus
    sudo mkdir /etc/prometheus
    sudo mkdir /var/lib/prometheus
    sudo chown prometheus:prometheus /etc/prometheus
    chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}

    sudo mv prometheus-2.18.1.linux-amd64/{consoles,console_libraries} /etc/prometheus/
    sudo chown -R prometheus:prometheus /etc/prometheus

    aws s3 cp s3://eks-doubledigit-aritifactory-eks-dev-us-east-1/prometheus.yml /etc/prometheus/
    sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
    sudo chown prometheus:prometheus /var/lib/prometheus
    rm -rf /tmp/prometheus-*

    sudo cat << EOF > /etc/systemd/system/prometheus.service
		[Unit]
		Description=Prometheus Time Series Collection and Processing Server
		Wants=network-online.target
		After=network-online.target

		[Service]
		User=prometheus
		Group=prometheus
		Type=simple
		ExecStart=/usr/local/bin/prometheus \
			--config.file /etc/prometheus/prometheus.yml \
			--storage.tsdb.path /var/lib/prometheus/ \
			--web.console.templates=/etc/prometheus/consoles \
			--web.console.libraries=/etc/prometheus/console_libraries

		[Install]
		WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start prometheus
    sudo systemctl enable prometheus
}

function setup_grafana() {
    printf "*********************************\n\t\tSetup Grafana \n**************************************\n"
    # Install Grafana
    echo ======= Installing Grafana =======
    wget https://dl.grafana.com/oss/release/grafana_7.0.0_amd64.deb
    sudo apt-get install -y adduser libfontconfig
    sudo dpkg -i grafana_7.0.0_amd64.deb

    sudo systemctl daemon-reload && sudo systemctl enable grafana-server && sudo systemctl start grafana-server
}

######################################################################
########################      RUNTIME       ##########################
######################################################################

initialize_worker
initialize_node_exporter
initialize_prometheus
setup_grafana