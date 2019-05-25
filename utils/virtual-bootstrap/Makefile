#
# NOTE: This assume br0 connecting to the OCP nodes
#
# ---------- vi /etc/sysconfig/network-scripts/ifcfg-br0 
# DEVICE=br0
# TYPE=Bridge
# IPADDR=192.168.1.1
# PREFIX=24
# BOOTPROTO=none
# ONBOOT=yes
# DELAY=0
# ---------- vi /etc/sysconfig/network-scripts/ifcfg-eno2 
# DEVICE=eno2 
# TYPE=Ethernet
# HWADDR=02:02:02:02:02:02
# BOOTPROTO=none
# ONBOOT=yes
# BRIDGE=br0
# ----------

all:
	@echo "Usage: make [ disk |  bootstrap ]"
	@echo "NOTE: This script assume br0 connecting to the OCP nodes"

disk:
	qemu-img create -f qcow2 ocp4-pxe.qcow2 40G
	mv ocp4-pxe.qcow2 /var/lib/libvirt/images/ocp4-pxe.qcow2

bootstrap:
	@echo "Destroying any existing bootstrap"
	virsh destroy ocp4bootstrap ; virsh undefine ocp4bootstrap
	@echo "Create new bootstrap node"
	@echo "NOTE: This steps are under development"
	virt-install --os-type linux --os-variant rhel7 --pxe \
	--mac 52:54:00:00:00:01 \
	--name ocp4bootstrap --ram=8000 --vcpus=8 \
	--network=bridge=br0,model=virtio \
	--graphics none \
	--console pty,target_type=serial \
	--disk /var/lib/libvirt/images/ocp4-pxe.qcow2,bus=virtio 

#
# END OF FILE
#