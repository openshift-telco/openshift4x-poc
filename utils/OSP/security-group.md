# Reference SecurityGroups for OCP over OSP

```
export OSP_EXT_NET=10.134.0.0/16
export OSP_TENANT_NET=192.168.50.0/24
```

Reference SecurityGroup for Bastion Node:
```
openstack security group create bastion-sg

openstack security group rule create --ingress --dst-port 22    --protocol tcp --remote-ip ${OSP_EXT_NET}    bastion-sg

openstack security group rule create --ingress --dst-port 6443  --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 22623 --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 80    --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 443   --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 53    --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 53    --protocol udp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 8000  --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
openstack security group rule create --ingress --dst-port 22    --protocol tcp --remote-ip ${OSP_TENANT_NET} bastion-sg
```

SecurityGroup for OCP Nodes:
```
openstack security group create ocp-cluster-sg

openstack security group rule create --ingress --protocol tcp  --remote-ip ${OSP_TENANT_NET} ocp-cluster-sg
openstack security group rule create --ingress --protocol udp  --remote-ip ${OSP_TENANT_NET} ocp-cluster-sg
openstack security group rule create --ingress --protocol icmp --remote-ip ${OSP_TENANT_NET} ocp-cluster-sg

# Allow external access for K8s API and OCP Ingress
openstack security group rule create --ingress --dst-port 6443  --protocol tcp --remote-ip ${OSP_EXT_NET} ocp-cluster-sg
openstack security group rule create --ingress --dst-port 80    --protocol tcp --remote-ip ${OSP_EXT_NET} ocp-cluster-sg
openstack security group rule create --ingress --dst-port 443   --protocol tcp --remote-ip ${OSP_EXT_NET} ocp-cluster-sg
```

## If using secondary networks with MACVLAN

```bash
openstack port set --no-security-group --disable-port-security <id or name of the neutron port>
```
