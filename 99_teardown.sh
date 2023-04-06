#! /usr/bin/env bash
source helper.sh

minikube delete -p cluster-1
docker-compose down
rm -rvf vault.volume/file/*
rm -fv vault.volume/logs/*
