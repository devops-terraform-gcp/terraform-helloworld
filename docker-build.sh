#!/bin/bash
npm i --silent
docker build . -t gcr.io/terraform-env-100-${env}/app
docker push gcr.io/terraform-env-100-${env}/app
docker rmi gcr.io/terraform-env-100-${env}/app
