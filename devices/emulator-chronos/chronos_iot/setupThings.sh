#!/bin/sh
if [ "$#" -ne 1 ]; then
	echo 'Invalid number of arguments passed. Require 1 argument (aws endpoint)'
	exit 1
fi

AWS_ENDPOINT=$1
echo "AWS_ENDPOINT=${AWS_ENDPOINT}" > .env

for d in $(find devices/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n') ; do
  SENSOR_NAME=${d}

  echo "Copy terraform script into ${SENSOR_NAME}"
  cp ./setupThing.tf ./devices/$SENSOR_NAME/
  cp ./start.sh ./devices/$SENSOR_NAME/
  cp -r ./aws_iot_client/ ./devices/$SENSOR_NAME/
  cd devices/$SENSOR_NAME

  echo "Start terraform init"
  terraform init

  echo "Start terraform script for setup of ${SENSOR_NAME}"

  terraform apply -var="sensor_name=${SENSOR_NAME}" -auto-approve
  echo 'Finished terraform apply'

  echo 'Create directory /aws_credentials'
  mkdir aws_credentials

  echo 'Move certificate and private key to directory /aws'
  mv ./$SENSOR_NAME.cert.pem aws_credentials/
  mv ./$SENSOR_NAME.private.key aws_credentials/

  cd ../../
  echo "Returned to $(pwd)"
done

echo 'execute docker build'
# docker build -t "${SENSOR_NAME}_image" -f ../Dockerfile .
docker-compose up


