# Create ports with static IPs

```
openstack port create ocp.sdn.port.bootstrap  --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.10

openstack port create ocp.sdn.port.master-0   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.11
openstack port create ocp.sdn.port.master-1   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.12
openstack port create ocp.sdn.port.master-2   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.13

openstack port create ocp.sdn.port.worker-0   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.15
openstack port create ocp.sdn.port.worker-1   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.16
openstack port create ocp.sdn.port.worker-2   --network ocp.sdn.net --security-group ocp-cluster-sg --fixed-ip subnet=ocp.sdn.subnet,ip-address=192.168.1.17
```

## Create Bootstrap
```
openstack server create --image rhcos-4.3.0 --flavor <flavor-name-or-id> --key-name ocp-key --user-data bootstrap.json --port ocp.sdn.port.bootstrap bootstrap.ocp4.example.com
```

## Create Master nodes
```
for i in {0..2}; do
    openstack server create --image rhcos4.3.0 --flavor <flavor-name-or-id> --key-name ocp-key --user-data master-${i}.json --port ocp.sdn.port.master-${i} master-${i}.ocp4.example.com
done
```

## Create Worker nodes
```
for i in {0..2}; do
    openstack server create --image rhcos4.3.0 --flavor <flavor-name-or-id> --key-name ocp-key --user-data worker-${i}.json --port ocp.sdn.port.worker-${i} worker-${i}.ocp4.example.com
done
```

## Troubleshooting
- Retrieve console URL for instance
```
openstack console url show bootstap.ocp4.example.com
```