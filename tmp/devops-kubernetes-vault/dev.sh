#! /usr/bin/env sh
sh -x deploy.sh

VAULT_NS=$(kubectl get pods --all-namespaces -l "app=vault" -o jsonpath="{.items[0].metadata.namespace}")
kubectl delete pod --namespace=$VAULT_NS -l "app=vault" --force --grace-period=0
killall kubectl
sleep 5
VAULT_POD=$(kubectl get pods --all-namespaces -l "app=vault" -o jsonpath="{.items[0].metadata.name}")
export VAULT_TOKEN=$(kubectl logs --namespace $VAULT_NS $VAULT_POD | grep 'Root Token' | cut -d' ' -f3)
export VAULT_ADDR=http://127.0.0.1:8200
kubectl port-forward --namespace $VAULT_NS $VAULT_POD 8200 &
echo $VAULT_TOKEN | vault login -

kubectl apply -f rbac.yaml --overwrite
export VAULT_SA_NAME=$(kubectl get sa vault -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT="$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)"
export K8S_HOST="192.168.99.100"

vault auth enable kubernetes
vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="https://$K8S_HOST:8443" kubernetes_ca_cert="$SA_CA_CRT"
vault write auth/kubernetes/role/rabbitmq_dev bound_service_account_names=rabbitmq bound_service_account_namespaces=rabbitmq policies=rabbitmq_dev ttl=24h
