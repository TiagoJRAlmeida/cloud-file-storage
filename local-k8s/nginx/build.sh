#!/bin/bash

set -e 

echo -e "\n1. Building the image...\n" 
docker build -t local-k8s-nginx .

echo -e "\n2. Do you want to push to the DockerHub? [y/N]"
read -s -n 1 response
lower_case_response="${response,,}"

if [[ $lower_case_response = "y" ]]; then
    echo -e "\nPushing to the registry (DockerHub)...\n"
    docker push local-k8s-nginx
fi

echo -e "\nDone! =D"
