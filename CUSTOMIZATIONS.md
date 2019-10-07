# Working with Customizations

There are two ways to apply customizations to OpenShift 4.x:
- Customziations to RHCOS before the OCP platform is operational. These customizations require editing the initial Ignition file. 
- Customizations after the platform is up and running. At that time we use MachineConfig resources for the customization.

## Customization of RHCOS for bootstrap and installation processes

This type of customization is used to setup advanced RHCOS parameters like:
- Customized Disk Partitions
- Advanced Networking Configurations

These cutomization use a `filetranspiler` tool that reads a `root disk` layout structure (`/`) from a specific folder and encodes it into the corresponding Ignition file.

The installation script in this repo can do this for `bootstrap`, `master` and `worker` Ignition files. It will apply these if it detect the corresponding `fake root layout` under the `./customizations/<role>` path.

The following is an example of injecting network configurations into the `worker` Nodes.

```
$ tree customizations
customizations
└── worker
    └── etc
        ├── resolve.conf
        └── sysconfig
            └── network-scripts
                ├── ifcfg-blah
                └── ifcfg-fake
```

## Customization after deployment of the platform

This type of customization uses MachineConfig resources. The installation script in this repo assumes any YAML file under `./customizations/*.yaml` is a MachineConfig and will inject those into the customization of the deployment.

The following is an example of injecting MachineConfig for customizations.

```
$ tree ./customizations/
./customizations/
├── 10-master-nm-workaround.yaml
└── 10-worker-nm-workaround.yaml
```
