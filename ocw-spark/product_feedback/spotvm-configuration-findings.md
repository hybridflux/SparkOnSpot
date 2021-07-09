### Findings on configuration settings used to control Spot VMs changing to regular VMs.

**first_on_demand** - The [docs](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/clusters#--azureattributes) say that setting a value **greater than 0** will result in the first few nodes with *on-demand* pricing, which is consistent with the test results. However, setting this value to **0** does not fail the cluster creation as the docs say. After trial-and-error, discovered that the **driver** node (first node) is always placed on *on-demand* instances. So in effect, a setting of **first_on_demand=1** is used even if you set the value to 0 or do not specify the value at all. This is not a problem for our design as we wanted the driver node to be on-demand to ensure a stable cluster.

**availability=SPOT_WITH_FALLBACK_AZURE** - In order to test if in fact it resorts to on-demand instances in case the Spot instances are not available, the **spot_max_bid_price** was set to a value just below the current Spot asking price. The expectation was that the cluster worker node would be created on on-demand instances. However the cluster creation fails consistently. The possible explanation is that the settings for SPOT_WITH_FALLBACK_AZURE only go into effect once a cluster is up and running and that it initially tries to use Spot VMs for the worker node. Off-course this will fail since the Spot price is too low. Changing the **spot_max_bid_price** to a value just above the current Spot asking price results in the cluster successfully being created. The only way we can validate that it switches to Spot VMs is to cause an eviction.