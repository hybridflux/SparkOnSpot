# Sustainability Through Spot VMs

## Project Intention

[Azure Spot Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms) (Spot VMs) utilize unused capacity in existing data center infrastructure. When the capacity is needed again, you are given a 30-second notice that your Spot VM will be evicted. The question that usually follows is whether or not it's truly feasible to run production-grade workloads on ever-evicting VMs.

> We set out to prove it possible.

We want to investigate strategies to work with and compensate eviction of Spot VMs. Initially, this project was implemented as a part of [OneCSEWeek](#backstory-whats-onecseweek) with the intention to prove out that you can run production-grade workloads utilizing Spot VMs. We chose an existing production Spark workload to learn about challenges and capture successful patterns in a migration playbook.

We plan to extend this playbook with other workloads running on additional Azure services going forward and welcome contributions to this document relating to your experience with running workloads on Spot.

Before jumping into the project, let's talk a little more about the **sustainability** piece. The EPA has defined different scopes, or types, of carbon emissions. Utilizing Spot VMs helps reduce [scope 3 carbon emissions](https://www.epa.gov/climateleadership/scope-3-inventory-guidance). By taking advantage of existing infrastructure, we are able to reduce the need for more hardware and energy to run that new hardware in our data centers.

## General Approach

This approach applies to many scenarios, regardless of the workload and Azure service used.

### Eviction Detection

In order to react to an eviction, it first has to be detected. The recommended approach for [detecting evictions](https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms#eviction-policy) is to use the [Scheduled Events API](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/scheduled-events).

The scheduled events API imposes the following constraints

- The api must be polled. There is no push notification.
- The polling interval needs to be less than the minimum notice for the event (30 seconds for Spot VM eviction).
- **The API is only accessible from within the VM.**

> Given the eviction must be detected from within the VM that will be evicted, there is an extremely small window (smaller than 30 seconds) to react to the event.

### Simulation

Evictions can be simulated in cases where the VM is not part of a managed platform such as Azure Databricks or HDInsight. Eviction can be simulated for these VM's using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az_vm_simulate_eviction)

```shell
az vm simulate-eviction --resource-group MyResourceGroup --name MyVm
```

### Eviction Compensation

As noted above, the eviction can only be detected from within the VM that will be evicted. The time between detection and eviction could be under 30 seconds, depending on when it is detected. Compensation strategies will likely involve interactions with AzureRM to spin up new VMs, which could take minutes. This imposes another constraint:

- The compensation strategy will need to be able to run after the VM has been evicted (asynchronous execution).

#### Compensation strategies

There are several possibilities to complensate an eviction. The choices could depend on

- the type of workload,
- the type of Azure Service used (managed service vs. unmanaged), or
- the SLAs required (length of run, near real-time reponse).

#### All on Spot

As an example, an organization could choose to deploy Spot VMs to process workloads which are not time-critical and which could be re-run in case the Spot instances get evicted while processing the workload. When an eviction gets detected, a call could be made to a custom service (i.e. Azure Functions) to compensate the eviction by

- restarting a deallocated VM,
- deploying other available Spot VM types,
- or deploying on-demand VMs to the cluster.

> Note: Information about the probability of a Spot VM type to be evicted in a region can be obtained from the Azure portal when creating a Spot VM. A specific VM type could be chosen by least probability of eviction in the region. Currently, this information cannot be obtained programmatically.

#### Mixed Spot and on-demand VMs

A deployment within a cluster could initially be a mixture of on-demand and Spot VMs, with on-demand VMs to pick up processing once Spot VMs get evicted. Once the eviction is detected, other Spot instances or on-demand VMs could be added to the cluster to distribute the load. This could apply to vanilla Spark workloads running in a VM scale set. A mixed deployment of Spot and on-demand VMs allows for the Spark workload to continue on on-demand instances while evicted Spot VMs are replaced and restarted.

Another example could be a temporary burst-out scenario, leveraging Spot VMs in addition to on-demand instances. Azure Kubernetes Services supports non-default node pools to run Spot VMs. Services could be deployed on the default, secondary Spot node pool, *or both*. In the time frame eviction occurs and the compensation strategy takes effect, the service still runs on the default on-demand pool and is available.

> Future Action: Investigate AKS workload with Spot VMs

In the particular scenario we investigated below, the Azure Service running the workload is Databricks, which is a managed service with settings to control the behaviour of the cluster when deploying Spot VMs. The driver node, which controls job and task execution on worker nodes, is by default deployed on an on-demand VM and cannot be changed to run on Spot. When evicted, worker node Spot VMs can be replaced by on-demand VMs if a specific setting is used. Databricks manages the eviction with a specific compensation in this scenario.

### Solution Requirements

Given the concerns above, the solution NFRs can be summarized as:

- Schedule events API must be polled from each Spot VM at an interval smaller than or equals to 30 seconds
- The eviction compensation strategy must execute despite the VM having been evicted

## List of projects/workloads

- [**Migration of production Spark workload to SpotVMs**](./ocw-spark/README.md): 
At OneCSEWeek, we migrated a production workload on Databricks to Spot VMs and investigated compensation strategies for the same workload running on a vanilla Spark cluster with a mix of Spot and on-demand VMs.

## Backstory: What's OneCSEWeek?

Commercial Software Engineering team (CSE) is a global engineering organization at Microsoft that works directly with engineers from the largest companies and not-for-profits in the world. We work in a code-with manner to tackle the world's most significant technical challenges.

OneCSEWeek is an opportunity for members of that organization to come together internally for one week. During this week, we pause all customer-related work and pick projects that drive our passions and improve the world. This year, our OCW team chose a project that drives sustainability through the utilization of Spot VMs.
