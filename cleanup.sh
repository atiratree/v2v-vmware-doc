#!/usr/bin/env bash
DOC_DIR="$(dirname "$(readlink -f "$0")")"

visit(){
    pushd "$1" &> /dev/null
}

leave(){
    popd &> /dev/null
}

visit "$DOC_DIR"

    visit vm

        oc delete -f vm.yaml
    leave

    visit v2v-conversion

        oc delete -f v2v-conversion-role-binding.yaml
        oc delete -f v2v-conversion-role.yaml
        oc delete -f v2v-conversion-secret.yaml
        oc delete -f v2v-conversion-service-account.yaml
        oc delete -f v2v-conversion-temp-pvc.yaml
        oc delete -f v2v-conversion-vddk-pvc.yaml
    leave

    visit v2v-vmware-resource
        oc delete -f v2v-vmware-resource.yaml
        oc delete -f v2v-vmware-secret.yaml
    leave

    visit v2v-vmware
        oc delete -f v2v-vmware-pod.yaml
        oc delete -f v2v-vmware-role-binding.yaml
        oc delete -f v2v-vmware-role.yaml
        oc delete -f v2v-vmware-service-account.yaml
    leave

leave
