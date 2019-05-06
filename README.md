


# Step 1: Run v2v-vmware pod
1. go to `v2v-vmware` dir
2. create role service account, role, role-binding and pod (can be automatically created in Step 2)

# Step 2: Create V2VVmware resource
1. go to `v2v-vmware-resource` dir
2. create secret with VCenter hostname, username and password (Base64 encoded)
3. create V2VVmware resource. It is used for passing information about VMs from the VCenter,
4. Parse and pick relevant data for your VM

creating v2v-vmware pod and getting vm data can be done with:

```
VCENTER_HOSTNAME="aG9zdG5hbWUuY29t" \
VCENTER_USERNAME="YWRtaW5pc3RyYXRvckB2c3BoZXJlLmxvY2Fs" \
VCENTER_PASSWORD="cGFzc3dvcmQ=" \
VM_NAME="vm-to-import=" ./get-import-vm-data.sh
```


# Step 3: Create conversion Pod prerequisites

1. download `VMware-vix-disklib`
2. create empty PVC called `vddk-pvc` in the same namespace the conversion will occur (automated by script)
3. extract data from `VMware-vix-disklib` archive into the PVC which will be mounted at `/opt/vmware-vix-disklib-distrib` inside the Pod
4. create conversion data (all the values are vanilla (no Base64))

```bash
{
  "daemonize": false,
  "vm_name": "$VM_NAME",
  "transport_method": "vddk",
  "vmware_fingerprint": "$THUMBPRINT", # fetch `Thumbprint:` with script
  "vmware_uri": "vpx://$VCENTER_USERNAME_URI_ENC@$VCENTER_HOSTNAME$HOST_PATH?no_verify=1", # fetch `Host Path:` with script
  "vmware_password": "$VCENTER_PASSWORD",
  "source_disks": ["[a_v2v] RHEL7_2/RHEL7_2.vmdk"] # fetch "Config.Hardware.Device.DeviceInfo.Label.Backing.FileName" with script
}
```

5. encode the conversion data in Base64
6. pass it to the  script

```
CONVERSION_DATA="ZGF0YQ==" ./create-v2v-prerequisites.sh
```

7. create additional PVCs - depending on the number of vm disks

# Step 4: Invoke conversion Pod
1. fill in additional PVCs into `v2v-conversion/v2v-conversion-pod.yaml` volumes
2. invoke conversion

```
oc create -f v2v-conversion/v2v-conversion-pod.yaml
```

# Step 5: Create VirtualMachine
1. fill in any desired data found in `Step 2` and created PVCs in `Step 4` into `vm/vm.yaml`
2. create virtual machine

```
oc create -f vm/vm.yaml
```

# Step 6: Final
1. observe the progress annotation and status of conversion in `oc describe pod v2v-conversion`
2. start the VM after the conversion has finished (can terminate the conversion)

# Cleanup
You can clean up all the resources created:

```
./cleanup.sh
```
