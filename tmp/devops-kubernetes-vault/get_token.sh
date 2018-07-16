#!/usr/bin/env sh
#
# ./get_tokken.sh name_of_the_role
# Ex: ./get_tokken.sh devops

export VAULT_ADDR="https://vault.beamery.com:8200"
# [START PARAMS]
ROLE=$1
# PROJECT="beamery-global"
# SERVICE_ACCOUNT="vault-auth-dev@beamery-global.iam.gserviceaccount.com"
SERVICE_ACCOUNT="vault-auth-global@beamery-global.iam.gserviceaccount.com"

# OAUTH_TOKEN=$(oauth2l header cloud-platform)
# # [END PARAMS]
# 
# EXPIRE_DATE=$(date -d "now + 3 minutes" +'%s')
# # EXPIRE_DATE=$(date -d "now + 60 minutes" +'%Y-%m-%d %H:%M:%S.%N')
# 
# PAYLOAD=$(echo "{ \"aud\": \"vault/$ROLE\", \"sub\": \"$SERVICE_ACCOUNT\"}" | sed -e 's/"/\\&/g')
# # PAYLOAD=$(echo "{ \"aud\": \"vault/$ROLE\", \"exp\": \"$EXPIRE_DATE\", \"sub\": \"$SERVICE_ACCOUNT\"}" | sed -e 's/"/\\&/g')
# curl -s -H "$OAUTH_TOKEN" \
#     -H "Content-Type: application/json" \
#     -X POST -d "{\"payload\":\"$PAYLOAD\"}" https://iam.googleapis.com/v1/projects/$PROJECT/serviceAccounts/$SERVICE_ACCOUNT:signJwt -o /tmp/token.json


GOOGLE_PROJECT="beamery-global"
SERVICE_ACCOUNT="vault-auth-global@${GOOGLE_PROJECT}.iam.gserviceaccount.com"

cat - > /tmp/login_request.json <<EOF
{
  "aud": "vault/$ROLE",
  "sub": "${SERVICE_ACCOUNT}",
  "exp": $((EXP=$(date +%s)+600))
}
EOF

JWT=$(gcloud beta iam service-accounts sign-jwt /tmp/login_request.json /tmp/signed_jwt.json --iam-account=${SERVICE_ACCOUNT} --project=${GOOGLE_PROJECT} && cat /tmp/signed_jwt.json)

# JWT=$(cat /tmp/token.json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["signedJwt"]')

VAULT_TOKEN=$(vault write auth/gcp/login role="$ROLE" jwt="${JWT}" --format=json | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["auth"]["client_token"]')

printf "Please run:\n\t%s\n\t%s\n" "export VAULT_ADDR=${VAULT_ADDR}" "vault login ${VAULT_TOKEN}"
