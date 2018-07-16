#!/usr/bin/env bash
ENV=$1

echo "Building for environment ${ENV}"

rm -rf deployment || true


# Set cookie if not present
if [[ $(grep -c cookie  environments/${ENV}.yaml) < 1 ]]
then
   #_cookie=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '' | base64)
   _cookie="dGVzdDEyMzQ="
	 printf "cookie: %s\n" "${_cookie}" >> ./environments/${ENV}.yaml
fi

vortex --template templates --output deployment -varpath ./environments/$1.yaml
