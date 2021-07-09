# Detecting Evictions on Spot VMs

Azure Spot VMs can be evicted at any time. To take actions for a "controlled" shutdown, the VM receives eviction notifications via the [Azure Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/scheduled-events) 

This script runs every 10 seconds to detect the VM's impeding doom. When an eviction notification is detected, the script POSTs to an HTTP endpoint to take action. The POST includes data includes information about the VM being evicted:

```json
{
  "name": "myspotvm",
  "rgname": "myvm_group",
  "location": "southcentralus",
  "privateIP": "10.2.0.5",
  "sku": "18.04-LTS"
  "vmSize": "Standard_A1_v2"
  "vmPrice": 0.043
  "spotVmPrice": 0.009485
}
```
The metadata of VMs doesn't contain any information that this VM is actually a Spot VM. That's why prices for both regular VM and Spot VM for a given SKU were added in case if eviction log is triggered by regular VM eviction.

Pricing information is being retrieved from the [Azure retail prices API](https://docs.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices).  

## Installation

This script is intended to be installed via [Databricks Cluster Init Script](https://docs.microsoft.com/en-us/azure/databricks/clusters/init-scripts). When deploying a Databricks job with Terraform, it requires adding a `databricks_global_init_script` resource (see [this reference]( https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/global_init_script)):

```terraform
resource "databricks_global_init_script" "evictionnotice" {
  source = "${path.module}/scripts/detecteviction.sh"
  name = "Eviction notice"
}
```

It can also be installed from the command line via

```bash
chmod 777 detecteviction.sh
sudo detecteviction.sh
```

## Verification

The script writes diagnostics messages to: /tmp/evlog.txt 

The output should look similar to this:

```bash
Detection eviction running Tue May 18 22:41:01 UTC 2021
No eviction at  Tue May 18 22:41:11 UTC 2021
```

## The Theory

This script was written with the intent of minimizing dependencies on other tools and runtimes. As such, it relies only on `bash`, `curl`, and `cron` - all of which should be available on Spot VMs by default. 

The cron job runs the script every minute. A minute is the shortest cron interval available. Since this interval is too long to reliably detect an eviction notification, the script runs a loop in which it checks for notifications every 10 seconds before exiting.

Added dependencies: 
- `jq` for parsing the JSON from the metadata service
 - Azure CLI for checking prices, but this does not require loging in

## Future Suggestions

- Parameterize the URL to invoke
- DONE - Send diagnostics details with the HTTP request
- DONE - Parse the _Recieved Notifications_ to take more granular actions.
