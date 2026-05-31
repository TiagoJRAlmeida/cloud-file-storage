#!/bin/bash

set -e

echo -e "1. Reseting the Kind Cluster...\n"
kind delete cluster
kind create cluster --config kind-config.yaml

echo -e "2. Loading the api docker image into the Kind Cluster...\n"
kind load docker-image local-k8s-api:latest

echo -e "Done! =D" 
