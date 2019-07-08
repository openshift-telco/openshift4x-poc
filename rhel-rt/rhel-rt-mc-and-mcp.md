#  RHEL-RT MachineConfig (MC) and MachineConfigPool (MCP)

Create a `worker-rt` MachineConfigPool with the corresponding `MachineConfig`

## Step 1
```
oc get machineconfig --selector='machineconfiguration.openshift.io/role=worker'
```

Output should be similar to this.
```
$ oc get machineconfig --selector='machineconfiguration.openshift.io/role=worker'
NAME                                                        GENERATEDBYCONTROLLER                      IGNITIONVERSION   CREATED
00-worker                                                   02c07496ba0417b3e12b78fb32baf6293d314f79   2.2.0             12d
01-worker-container-runtime                                 02c07496ba0417b3e12b78fb32baf6293d314f79   2.2.0             12d
01-worker-kubelet                                           02c07496ba0417b3e12b78fb32baf6293d314f79   2.2.0             12d
98-worker-registries                                                                                   2.2.0             10d
99-worker-d75f2daf-9778-11e9-83e8-001a4a16010a-registries   02c07496ba0417b3e12b78fb32baf6293d314f79   2.2.0             12d
99-worker-ssh                                                                                          2.2.0             12d
```

In this case `99-worker-d75f2daf-9778-11e9-83e8-001a4a16010a-registries` will be ignored.

## Step 2
For every non-generated MachineConfig listed in `Step 1` export a copy and remove the `ownerReferences` section and any `selfLink` and `annotations` sections.

```
oc get --export machineconfig 00-worker -o yaml > 00-worker-rt.yaml
oc get --export machineconfig 01-worker-container-runtime -o yaml > 01-worker-rt-container-runtime.yaml
oc get --export machineconfig 01-worker-kubelet -o yaml > 01-worker-rt-kubelet.yaml
oc get --export machineconfig 98-worker-registries -o yaml > 98-worker-rt-registries.yaml
oc get --export machineconfig 99-worker-ssh -o yaml > 99-worker-rt-ssh.yaml

sed -i 's/worker/worker-rt/g' 00-worker-rt.yaml 
sed -i '/ownerReferences/,+7d' 00-worker-rt.yaml
sed -i '/annotations/,+1d' 00-worker-rt.yaml

sed -i 's/worker/worker-rt/g' 01-worker-rt-container-runtime.yaml 
sed -i '/ownerReferences/,+7d' 01-worker-rt-container-runtime.yaml 
sed -i '/annotations/,+1d' 01-worker-rt-container-runtime.yaml 

sed -i 's/worker/worker-rt/g' 01-worker-rt-kubelet.yaml
sed -i '/ownerReferences/,+7d' 01-worker-rt-kubelet.yaml
sed -i '/annotations/,+1d' 01-worker-rt-kubelet.yaml

sed -i 's/worker/worker-rt/g' 98-worker-rt-registries.yaml 
sed -i '/ownerReferences/,+7d' 98-worker-rt-registries.yaml 
sed -i '/annotations/,+1d' 98-worker-rt-registries.yaml 
sed -i '/selfLink/d' 98-worker-rt-registries.yaml 


sed -i 's/worker/worker-rt/g' 99-worker-rt-ssh.yaml
sed -i '/ownerReferences/,+7d' 99-worker-rt-ssh.yaml
sed -i '/annotations/,+1d' 99-worker-rt-ssh.yaml
sed -i '/selfLink/d' 99-worker-rt-ssh.yaml
```

## Step 3

Crete the new MachineConfigs

```
oc create -f 00-worker-rt.yaml
oc create -f 01-worker-rt-container-runtime.yaml
oc create -f 01-worker-rt-kubelet.yaml
oc create -f 98-worker-rt-registries.yaml
oc create -f 99-worker-rt-ssh.yaml
```

Create a new MachineConfigPool for the new configurations.

```
cat <<EOF > ./mcp-worker-rt.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  generation: 1
  name: worker-rt
spec:
  machineConfigSelector:
    matchLabels:
      machineconfiguration.openshift.io/role: worker-rt
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker-rt: ""
EOF
```

```
oc create -f mcp-worker-rt.yaml
```

## Step 4

***NOTE:*** These steps need to be documented.

Apply the real-time `tuned` profile to `worker-rt` MCP.
