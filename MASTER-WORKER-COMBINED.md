# Combined `Master` and `Worker` Roles on Masters Nodes

The OCP4.2 UPI deployment may configure the Master nodes with `master` and `worker` roles. If this is not the desired configuration:

## Disable combined `master` + `worker` role from the Master Nodes
- Edit the cluster scheduler operator configuration to remove the `worker` role from the Master nodes and set `mastersSchedulable: false`
    ```
    oc edit schedulers cluster
    ```

- The end result should be similar to the following:
    ```
    apiVersion: config.openshift.io/v1
    kind: Scheduler
    metadata:
    name: cluster
    spec:
        mastersSchedulable: false
    ```

## Enable combined `master` + `worker` role from the Master Nodes

- To re-enable `worker` role into the Master Nodes set `mastersSchedulable: true`. 
    ```
    oc edit schedulers cluster
    ```
- The end result should be similar to the following:
    ```
    apiVersion: config.openshift.io/v1
    kind: Scheduler
    metadata:
    name: cluster
    spec:
        mastersSchedulable: true
    ```
