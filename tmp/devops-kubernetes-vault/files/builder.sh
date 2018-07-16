#! /bin/sh

set -eu

usage() {
    >&2 cat << EOF
$(basename "$0") -- info

This script will build the vault-init docker image using
the builder pattern used prior to multi-stage builds.

Usage:
> $(basename "$0") [-h]
EOF
}

while getopts ":h" opt; do
    case $opt in
    h)
        usage
        exit 0
        ;;
    \?)
        >&2 echo "Unknown option ${OPTARG}"
        exit 1
        ;;
    esac
done

shift $(( OPTIND - 1 ))

## Old school multi-stage build
# Remove the vault-init app once this script exits
trap 'rm -f vault-init' EXIT

# Builds the go binary ready for use to use
docker build --pull --no-cache -t vault-init:build -f build.Dockerfile .

# Copies the contents over to the host's disk
docker container create --name extract vault-init:build
docker container cp extract:/go/src/app/vault-init ./vault-init
docker container rm -f extract

# Creating the final container to deploy
docker build --no-cache --pull -t vault-init:latest .
