#!/usr/bin/env sh
set -x
ENV=$1
_PATH_TEMPLATE="templates"
_PATH_DESTINATION="deployment"
_PATH_ENVIRONMENT="./environments/${ENV}.yaml"

if test "X${ENV}" = "X"
then
    >&2 echo "ERROR - Please precise the environement name"
    exit 1
fi

echo "Building for environment ${ENV}"

rm -rf ${_PATH_DESTINATION}

vortex --template ${_PATH_TEMPLATE} --output ${_PATH_DESTINATION} -varpath "${_PATH_ENVIRONMENT}"
