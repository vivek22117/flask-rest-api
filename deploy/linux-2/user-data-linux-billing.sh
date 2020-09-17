#! /bin/bash

function initialize_worker() {
  printf "***********************************\n\t\tSetting up host \n******************************\n"

  echo ======= Creating Directory ========
  mkdir /opt/billing/logs
  chmod +rw /opt/billing/logs
  touch /opt/billing/logs/stdout.log
  touch /opt/billing/logs/stderr.log

  chown -R [USER_NAME]:[GROUP_NAME] /opt/billing

  mv /opt/billing/billing-*.jar /opt/billing/lib/billing-processor-1.0.jar

  # Export environment settings
  echo ======= Exporting environment settings =======
  export environment=dit1
}

function launch_app() {
  printf "******************\n\t\tSetup Application\n**********************\n"
  DAEMON="java"
  NAME="billing"
  BILL_ROLLUP=/opt/${NAME}
  LOG_FOLDER=${BILL_ROLLUP}/logs
  PID_FILE=${LOG_FOLDER}/${NAME}.pid
  DAEMONOPTS="-jar /opt/${NAME}/lib/billing-processor-1.0.jar"

  JAVAOPTS=""
  if [[ "${environment}" == "prod" ]]; then
    JAVAOPTS="-Xms1024m -Xmx2048m"
  else
    JAVAOPTS="-Xms512m -Xmx1024m"
  fi

  rm -f ${LOG_FOLDER}/sysout.log

  printf "%-50s" "Starting $NAME..." >> ${LOG_FOLDER}/start.log
  PID=$(${DAEMON} "${JAVAOPTS}" "${DAEMONOPTS}" > ${LOG_FOLDER}/sysout.log 2>&1 & echo $!)
  echo "${PID}" >> ${LOG_FOLDER}/start.log
  echo "${PID}" > ${PID_FILE}
  printf "%s\n" "Ok" >> ${LOG_FOLDER}/start.log
}


initialize_worker
launch_app
