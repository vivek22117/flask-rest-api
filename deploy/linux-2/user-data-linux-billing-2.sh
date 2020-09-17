#! /bin/bash

function initialize_worker() {
  printf "***********************************\n\t\tSetting up host \n******************************\n"
  echo ========== Cleaning Up For Fresh Start ===============
  echo 'before install process.....'
  rm -rf /opt/billing/*


  echo ======= Creating Directory ========
  mkdir /opt/billing/logs
  chmod +rw /opt/billing/logs
  touch /opt/billing/logs/stdout.log
  touch /opt/billing/logs/stderr.log

  chown -R ec2-user:ec2-user /opt/billing
  chown -R ec2-user:ec2-user /opt/jar

  mv /opt/jar/billing/EnvDemo-*.jar /opt/billing/EnvDemo-1.0-SNAPSHOT-jar-with-dependencies.jar

  # Export environment settings
  echo ======= Exporting environment settings =======
  export environment=dit1

  echo "Environment: ${environment}"
}

function launch_app() {
  printf "******************\n\t\tSetup Application\n**********************\n"
  DAEMON="java"
  NAME="billing"
  BILL_ROLLUP=/opt/${NAME}
  LOG_FOLDER=${BILL_ROLLUP}/logs
  PID_FILE=${LOG_FOLDER}/${NAME}.pid
  DAEMONOPTS="-jar /opt/${NAME}/EnvDemo-1.0-SNAPSHOT-jar-with-dependencies.jar"

  JAVAOPTS=""
  if [[ "${environment}" == "prod" ]]; then
    JAVAOPTS="-Xms1024m -Xmx2048m"
  else
    JAVAOPTS="-Xms512m -Xmx1024m"
  fi

  rm -f ${LOG_FOLDER}/sysout.log

  printf "%-50s" "Starting $NAME..." >> ${LOG_FOLDER}/start.log
  PID=`${DAEMON} ${JAVAOPTS} ${DAEMONOPTS} > ${LOG_FOLDER}/sysout.log 2>&1 & echo $!`
  echo "${PID}" >> ${LOG_FOLDER}/start.log
  echo "${PID}" > ${PID_FILE}
  printf "%s\n" "Ok" >> ${LOG_FOLDER}/start.log
}


initialize_worker
launch_app
