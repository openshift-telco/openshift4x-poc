# Troubleshooting

```
oc get cm -n openshift-kube-apiserver -o yaml
oc get cm -n openshift-config -o yaml 
```

By default the OpenStack credentials are set via a Secret:
- secret-name: `openstack-credentials`
- secret-namespace: `kube-system`

```
oc get secret -n kube-system openstack-credentials --template='{{index .data "clouds.yaml"}}' | base64 -d
oc get secret -n kube-system openstack-credentials --template='{{index .data "clouds.conf"}}' | base64 -d
```