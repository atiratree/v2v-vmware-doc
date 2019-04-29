#!/usr/bin/env bash
DOC_DIR="$(dirname "$(readlink -f "$0")")"

set -u

visit(){
    pushd "$1" &> /dev/null
}

leave(){
    popd &> /dev/null
}

wait_for_connection(){
    sleep 2 # phase change
    echo "waiting for connection"
    while ! oc describe V2VVmware $1 | grep "Phase:  ConnectionVerified" -q; do
        if oc describe V2VVmware $1 | grep "Phase:  Failed" -q; then
            echo "Failed, are the credentials correct?"
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo connected
}


VCENTER_HOSTNAME="${VCENTER_HOSTNAME:-}"
VCENTER_USERNAME="${VCENTER_USERNAME:-}"
VCENTER_PASSWORD="${VCENTER_PASSWORD:-}"

VM_NAME="${VM_NAME:-}"

V2V_INSTANCE_NAME="v2v-vmware-connect"


visit "$DOC_DIR"

    visit v2v-vmware
        oc create -f v2v-vmware-service-account.yaml
        oc create -f v2v-vmware-role.yaml
        oc create -f v2v-vmware-role-binding.yaml
        oc create -f v2v-vmware-pod.yaml
    leave

    visit v2v-vmware-resource
        sed "s!USERNAME_BASE_64!$VCENTER_USERNAME!;s!PASSWORD_BASE_64!$VCENTER_PASSWORD!;s!URL_BASE_64!$VCENTER_HOSTNAME!" v2v-vmware-secret.yaml | oc create -f -
        oc create -f v2v-vmware-resource.yaml


        wait_for_connection "$V2V_INSTANCE_NAME"

        VM_NAME="`oc describe V2VVmware "$V2V_INSTANCE_NAME" | grep "$VM_NAME" -o`" # choose VM name
        VM_INDEX="$((`oc describe V2VVmware "$V2V_INSTANCE_NAME" | grep "Name:" | grep -n "$VM_NAME" | cut -d : -f 1` - 1))"

        echo "getting data of $VM_NAME at index $VM_INDEX"
        oc  patch  V2VVmware  v2v-vmware-connect --type json -p '[{"op": "add", "path": "/spec/vms/'"$VM_INDEX"'/detailRequest", "value": true }]'

        wait_for_connection "$V2V_INSTANCE_NAME"

        echo
        echo "$VM_NAME data:"
        echo
        echo
        DESCRIPTION="` oc describe V2VVmware "$V2V_INSTANCE_NAME"`"

        echo "$DESCRIPTION"  | grep "Thumbprint:"
        echo "$DESCRIPTION"  | grep "$VM_NAME" -A 2
        echo "$DESCRIPTION"  | grep "$VM_NAME" -A 3 | grep Raw | grep '{.*' -o | jq
    leave



leave
