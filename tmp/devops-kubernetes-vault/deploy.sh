#! /usr/bin/env sh
#################################################################################
#     File Name           :     set_scale_all.sh
#     Created By          :
#     Creation Date       :     [2017-08-09 10:08]
#     Last Modified       :     [2017-11-30 11:48]
#     Description         :
#################################################################################
kubectl create -f ./deployment/namespace.yaml 2>1
kubectl apply -f ./deployment/config.yaml --overwrite=true
kubectl apply -f ./deployment/secret.yaml --overwrite=true
kubectl apply -f ./deployment/service.yaml --overwrite=true
kubectl apply -f ./deployment/deploy.yaml --overwrite=true
