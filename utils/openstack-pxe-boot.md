# Creating PXE-Boot Image for OpenStack

1. Create an empty disk file with DOS filesysm
    ```
    dd if=/dev/zero of=pxeboot.img bs=1M count=4
    mkdosfs pxeboot.img
    ```
2. Make it bootable
    ```
    losetup /dev/loop0 pxeboot.img
    mount /dev/loop0 /mnt
    syslinux --install /dev/loop0
    ```
3. Install iPXE Kernel. Stup syslinux.cfg to load it at boot time
    ```
    curl -O http://boot.ipxe.org/ipxe.iso

    mount -o loop,ro ipxe.iso /media

    cp /media/ipxe.krn /mnt
    cat > /mnt/syslinux.cfg <<EOF
    DEFAULT ipxe
    LABEL ipxe
    KERNEL ipxe.krn
    EOF

    umount /media/
    umount /mnt
    ```
4. Uploade the resulting `pxeboot.img` to Glance

5. Disable port security for the OCP subnet
    ```
    openstack network set --disable-port-security <subnet>
    openstack subnet set --port-security-enabled=False <subnet>
    ```

# Credits

This information is based on work by kimizhang at https://kimizhang.wordpress.com/2013/08/26/create-pxe-boot-image-for-openstack/