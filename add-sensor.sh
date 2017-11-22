#!/bin/bash
#Lets get the keys to the kingdom
source .env
export IOT_CON_STRING=`az iot hub show-connection-string -n $IOT_HUB_NAME -g $RESOURCE_GROUP -o tsv`
export RAND_SUFIX=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 4 | head -n 1)
export SENSOR_ID=sensor-${RAND_SUFIX}
az iot device create -d $SENSOR_ID --hub-name $IOT_HUB_NAME -g $RESOURCE_GROUP
export SENSOR_CS=$(az iot device show-connection-string -d $SENSOR_ID --hub-name $IOT_HUB_NAME -g $RESOURCE_GROUP -o tsv)
cat <<EOT >> sensors.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: `echo $SENSOR_ID`
spec:
  containers:
  - name: `echo $SENSOR_ID`
    image: brusmx/iot-hub-experiment
    env:
    - name: CONNECTION_STRING
      value: "`echo $SENSOR_CS`"
    - name: DEVICE_ID
      value: "`echo $SENSOR_ID`"
    imagePullPolicy: Always
EOT
kubectl apply -f sensors.yaml
kubectl get pods