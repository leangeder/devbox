#! /usr/bin/env sh
set -x
#################################################################################
#     File Name           :     set_scale_all.sh
#     Created By          :
#     Creation Date       :     [2017-08-09 10:08]
#     Last Modified       :     [2017-11-30 11:48]
#     Description         :
#################################################################################
kubectl create -f ./deployment/namespace.yaml 2>1
kubectl replace -f ./deployment/config.yaml --force
kubectl replace -f ./deployment/rbac.yaml --force
kubectl replace -f ./deployment/service.yaml --force
kubectl replace -f ./deployment/statefulset.yaml --force
