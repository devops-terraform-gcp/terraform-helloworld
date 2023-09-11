#!/bin/bash
npm i --silent
docker build . -t gcr.io/gcp-terraform-env/app
docker push gcr.io/gcp-terraform-env/app
docker rmi gcr.io/gcp-terraform-env/app
