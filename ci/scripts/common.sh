#!/bin/bash

exec >&2
set -e

[[ "${DEBUG,,}" == "true" ]] && set -x


function load_custom_ca_certs(){
  if [[ ! -z "$CUSTOM_ROOT_CA" ]] ; then
    echo -e "$CUSTOM_ROOT_CA" > /etc/ssl/certs/custom_root_ca.crt
  fi

  if [[ ! -z "$CUSTOM_INTERMEDIATE_CA" ]] ; then
    echo -e "$CUSTOM_INTERMEDIATE_CA" > /etc/ssl/certs/custom_intermediate_ca.crt
  fi

  update-ca-certificates
}

function log() {
  green='\033[0;32m'
  reset='\033[0m'

  echo -e "${green}$1${reset}"
}

function warning() {
  orange='\033[1;33m'
  reset='\033[0m'

  echo -e "${orange}$1${reset}"
}

function error() {
  red='\033[0;31m'
  reset='\033[0m'

  echo -e "${red}$1${reset}"
  exit 1
}

load_custom_ca_certs
