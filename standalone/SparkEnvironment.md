# Spark Standalone Environment

## Environment Definition
- Resource Group - `CSE-DTD-OCW2021-Spark-RG`
- Jumpbox VM - `CSE-DTD-OCW2021-JumpVM1`
- Spark Driver - `CSE-DTD-OCW2021-Spark-DriverVM1`
- Spark Worker (Non-Spot) - `CSE-DTD-OCW2021-Spark-WorkerVM1`
- Spark Worker (Spot) - `CSE-DTD-OCW2021-WorkerVM2`

## Startup Process

To get things running, start all four of the VMs.  Once the VMs are running:
- Get set up for monitoring:
  - Use Bastion to connect to the Jumpbox VM
  - On the Jumpbox VM, open IE
  - Navigate to the Spark cluster page (http://172.16.1.4:8080)
- Get set up for job submission:
  - Use Bastion to connect to the Spark Driver VM
  - Using the `spark-submit` command, run the `workload.py` script, with the following positional arguments:
    - Storage Account Name
    - Storage Account Key
    - Storage Container Name
    - Output Path
    - Input Event Hubs Connection String
    - Maximum Events per Trigger
    - Trigger Interval
    - Streaming Checkpoint Path

At this point, you can evict the spot VM to test eviction resiliency.

## Environment Setup

This environment was built manually rather than from a script.  The Jump Box is a standard instll of Windows Server 2019 Datacenter.  The Spark machines are Ubuntu 18.04 LTS.  The following steps were taken after the OS installation:
- Set the root password (`sudo passwd root`)
- Install the JRE (`sudo apt install default-jre`)
- Install Python 3 (`sudo apt install python3`)
- Get the Spark binaries (`wget https://downloads.apache.org/spark/spark-3.1.1/spark-3.1.1-bin-hadoop3.2.tgz`)
- Unzip and move the spark binaries:
  - `tar xvf spark-3.1.1-bin-hadoop3.2.tgz`
  - `sudo mv spark-3.1.1-bin-hadoop3.2/ /opt/spark`
- Set SPARK_HOME and PATH
  - `sudo vi ~/.bashrc`
  - Add the following lines to the end of the file:
    - `export SPARK_HOME=/opt/spark`
    - `export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin`
- On the driver node, create the /opt/spark/conf/spark-env.sh file (with sudo), and add the line `SPARK_MASTER_HOST=172.16.1.4`
- On the driver node, create the /opt/spark/conf/spark-defaults.conf file, and add the following lines:
  - `spark.master spark://172.16.1.4:7077`
  - `spark.jars.packages com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18,org.apache.hadoop:hadoop-azure:3.2.2,io.delta:delta-core_2.12:0.8.0`
- Use the instructions [here](https://datasciencenovice.wordpress.com/2016/11/30/spark-stand-alone-cluster-as-a-systemd-service-ubuntu-16-04centos-7/) to turn spark into a service, with the following commands per node:
  - Driver node:
    - Start - `start-master.sh`
    - Stop - `stop-master.sh`
  - Worker nodes:
    - Start - `start-worker.sh`
    - Stop - `stop-worker.sh`
