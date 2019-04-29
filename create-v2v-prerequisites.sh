#!/usr/bin/env bash
DOC_DIR="$(dirname "$(readlink -f "$0")")"


visit(){
    pushd "$1" &> /dev/null
}

leave(){
    popd &> /dev/null
}

CONVERSION_DATA="${CONVERSION_DATA:-}"


visit "$DOC_DIR"

    visit v2v-conversion
        oc create -f v2v-conversion-vddk-pvc.yaml
        sed "s!CONVERSION_DATA!$CONVERSION_DATA!" v2v-conversion-secret.yaml | oc create -f -
        oc create -f v2v-conversion-service-account.yaml
        oc create -f v2v-conversion-role.yaml
        oc create -f v2v-conversion-role-binding.yaml
        oc create -f v2v-conversion-temp-pvc.yaml
    leave

leave
