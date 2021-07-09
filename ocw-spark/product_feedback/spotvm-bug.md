## Unable to deploy SpotVM at a price just above current asking price

### Steps to reproduce

Deploy a Spot VM via the Azure Portal.

Create a vanilla Ubuntu VM and select the Spot instance option. For this reproduction, **Standard_DS3_v2** in the **australiaeast** region. The price for the Spot VM is just above the current asking price (0.125 USD, which is just above 0.1249 USD).

![Create VM confirmation page](./spotbug1.png)

After hitting confirm, the deployment is attempted and fails with an error message that the Spot VM price is too low, even though it is obviously higher than the asking price.

![Error creating Spot VM](./spotbug2.png)

It is unclear where the price **0.13739** is derived from. No such price exists in the entire rate catalog for Azure.

### Expected Result

VM would be created and subject to eviction later in case the Spot price increases.

### Why is there a price mis-match?

Is there some additonal license cost that is not captured in the Spot VM price? Or is this a bug?

### Notes

Other regions/VM sizes were not tested.
