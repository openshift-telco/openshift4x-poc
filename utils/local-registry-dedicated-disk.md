# (optional) Using Dedicate Disk for registry

- NOTE: If you see following error message while uploading images into your local registry then either you create dedciated disk with fstype=1 or re-install your server with disk setup as fstype=1

  Error message:
    ```
    "Could not get runtime: kernel does not support overlay fs: overlay: the backing xfs filesystem is formatted without d_type support, which leads to incorrect behavior. Reformat the filesystem with ftype=1 to enable d_type support. Running without d_type is not supported.: driver not supported"
    ```

1. Create partition in disk
   
```
fdisk /dev/sdb
 type (t): 8e
```

2. Create physical volume

```
pvcreate /dev/sdb1
```

3. Create volume group  

```
vgcreate vg_registry /dev/sdb1

vgs 
```

4. Create logical volume

```
lvcreate -l 100%FREE -n lv_registry vg_registry

lvdisplay vg_registry/lv_registry
```

5. Format logical volume
```
mkfs.ext4 /dev/vg_registry/lv_registry
```

6. Identify devices UUID
```
blkid /dev/vg_registry/lv_registry

[root@bastion ~]# blkid /dev/vg_registry/lv_registry
/dev/vg_registry/lv_registry: UUID="60c3366b-1c3d-41da-bf62-7e00d88d3f0b" TYPE="ext4"

```

7. /etc/fstab

```
UUID=<uuid-here>    /opt/registry   ext4    defaults    0 0
```
