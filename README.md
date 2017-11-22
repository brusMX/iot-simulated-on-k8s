# Two-way communication with IoT devices

This project emulates a two-way communication pattern between different types of IoT devices using IoT hub, stream analytics. For this specific scenario, we will part from having a kubernetes cluster that will enroll new IoT sensors that will send information to the IoT hub, then the stream analytics will aggregate that information and trigger changes on the IoT relevators based on a quorum decision.

## Requirements

- VS Code
- Azure CLI 2.0.20
- Azure subscription
- Docker hub credentials
- NPM for the NodeJS IoT hub explorer

## Initial Setup

Let's start by connecting our Azure CLI to the cloud

``` bash
az login
```

Make sure you have a valid Azure CLI connected to your desired Azure subscription, it will be marked as `'isDefault'`.

``` bash
az account list -o table
```

Copy the `.env.example` file into `.env` and fill it up with your desired configuration

``` bash
cp .env.example .env
code .env
```

After you are done updating the `.env` file, save it and source it from your current shell.

``` bash
source .env
```

Create a resource group to host our project

``` bash
az group create -n $RESOURCE_GROUP -l $LOCATION
```

### Setting up a Kubernetes cluster to emulate the environment

Create your kubernetes cluster, this can take up to ten minutes.

```bash
az acs create -t kubernetes -g $RESOURCE_GROUP -n $ACS_NAME --generate-ssh-keys
```

Get the credentials to your cluster

``` bash
az acs kubernetes get-credentials -g $RESOURCE_GROUP -n $ACS_NAME
```

If you don't have `kubectl` install it:

```bash
az acs kubernetes install-cli
```

Confirm you can access the cluster with the following commands:

```bash
kubectl get nodes
```

And you can make sure you are connecting to the right cluster under the right context:

```bash
kubectl cluster-info
```

## IoT Hub

Let's create a hub to handle all the communications between our IoT sensors and the application.

```bash
az iot hub create -g $RESOURCE_GROUP -n $IOT_HUB_NAME --sku S1 -l $LOCATION
```

We obtain the credentials:

```bash
IOT_CON_STRING=`az iot hub show-connection-string -n $IOT_HUB_NAME -g $RESOURCE_GROUP -o tsv`
```

### Installing the IoT Hub Explorer 

If you are using Mac or Linux let's use the [Node version of the IoT hub explorer](https://github.com/Azure/iothub-explorer). Make sure you have NodeJS installed with the latest version of npm and let's install it:

```bash
npm install -g iothub-explorer
```

**Note** If you are using windows you can use the [IoT Hub Explorer Desktop Application](https://github.com/Azure/azure-iot-sdk-csharp/tree/master/tools/DeviceExplorer) as well

Let's connect to the hub:

```bash
iothub-explorer login $IOT_CON_STRING
```

## IoT sensors (Senders)

After we have our environment up and running is time to create our sensors. We will create a simulated IoT sensor that will provide the information captured by our device and push it into the IoT Hub

### Create a new device in IoT Hub

Let's create a random sufix for our devices that will be used in the creation of all the devices:

```bash
export RAND_SUFIX=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 4 | head -n 1)
```

Create a random number for our sensor:

```bash
export SENSOR_ID=sensor-${RAND_SUFIX}
```

Create a new entry in IoT hub:

```bash
az iot device create -d $SENSOR_ID --hub-name $IOT_HUB_NAME -g $RESOURCE_GROUP
```

This connection string will be used later to associate the actual simulated device to the hub. Let's save this connection for later:

```bash
export SENSOR_CS=$(az iot device show-connection-string -d $SENSOR_ID --hub-name $IOT_HUB_NAME -g $RESOURCE_GROUP -o tsv)
```

**Note:** You can persist your data by dumping these variables into a file:

```bash
echo "export SENSOR_ID=\"${SENSOR_ID}\"" >> devices.env
echo "export SENSOR_CS=\"${SENSOR_CS}\"" >> devices.env
```

Whenever you want to have all these variables back in your terminal's environment you can simply do `source devices.env`, if you want to start from scratch simply remove the file.

#### Try it in your local docker

If you have docker installed in your local machine you can try this command, just remember that it will put random data inside your IoT Hub from this particular device:

```bash
docker run -e "CONNECTION_STRING=${SENSOR_CS}" -e "DEVICE_ID=${SENSOR_ID}" -t brusmx/iot-hub-experiment
```

![alt text][ingest-send]

And now we ca start seeing our connections in the IoT hub explorer:

```bash
iothub-explorer monitor-events $SENSOR_ID --login $IOT_CON_STRING
```

![alt text][ingest]

### Deploy the simulated device on Kubernetes

The next yaml file will be the base to deploy the simulated devices in our cluster, copy the full command and paste it in your terminal:

``` bash
cat <<EOT >> sensors.yaml
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
```
Start your IoT Hub explorer to monitor the communications:

```bash
iothub-explorer monitor-events $SENSOR_ID --login $IOT_CON_STRING
```

Deploy to your kubernetes cluster:

``` bash
kubectl apply -f sensor-${SENSOR_ID}.yaml
```

It should take a couple of minutes to start working, you can check it's status by getting the current pods:

``` bash
kubectl get pods
```

Finally, you will see the messages going through the IoT hub explorer monitor.

![alt text][ingest]

If you run into trouble obtain the pod name and run `kubectl decribe << pod name >>`. You can also get the logs from it by running `kubectl logs << pod name >>`.

### Let's scale this puppy

For instructional purposes, we will be only using yaml files to keep track of the all the multiple sensors we create.

First, lets make sure that you have the `.env` file in the same directory as your `add-sensor.sh` script

``` bash
ls -la

-rw-r--r--    1 brusmx  group     132 Nov 15 13:25 .env
-rw-r--r--    1 brusmx  group     874 Nov 21 17:07 add-sensor.sh
```

Second, add execution permissions to your script.

```bash
chmod +x add-sensor.sh
```

Execute the script:

```bash
./add-sensor.sh
```

Now you can see that the new device has been added to the IoT hub portal, and you can start reading the information in the explorer.

![alt text][portal]

![alt text][ingest2]

**Note:** If you need to remove one of the devices you will have to delete it by hand, first remove the element from the sensors.yaml file, then remove it from kubernetes `kubectl delete pod << name of the pod>>` and finally remove it from the IoT Hub. If you need to remove all of them just run `kubectl delete -f sensors.yaml` then remove the yaml file and finally remove all the elements in the IoT Hub.

### Confirm connection (Telemetry and Portal)

## IoT relevators (Receivers)





[ingest-send]: img/ingestion-sending.png  "Ingesting..."

[ingest]: img/ingestion.png "Receiving..."
[ingest2]: img/ingestion-2.png "Second element..."

[portal]: img/portal-devices.png "New element created"