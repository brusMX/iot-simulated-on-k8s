#!/bin/bash
source .env
# Check variables are set

# Check if RG exists

# If not, then create Resource group
az group create -n $RESOURCE_GROUP -l -$LOCATION

az iot hub create -g $RESOURCE_GROUP -n $IOT_HUB_NAME --sku S1 -l $LOCATION


