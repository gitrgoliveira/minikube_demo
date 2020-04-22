#! /usr/bin/env bash
source helper.sh

minikube delete -p cluster-1
minikube delete -p cluster-2
docker-compose down
rm -rvf vault.volume/file/*
rm -fv vault.volume/logs/*
rm -rvf v0.*
rm -rvf master
rm -rvf vault