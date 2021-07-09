import sys
import json

from pathlib import Path

from pyspark import SparkConf
from pyspark.sql import SparkSession
from pyspark.sql import DataFrame
from pyspark.sql.functions import col, from_json, lit
from pyspark.sql.types import StructType, StringType, TimestampType, DecimalType

message_schema: StructType = StructType()\
    .add("MeterId", StringType(), False)\
    .add("SupplierId", StringType(), False)\
    .add("Measurement", StructType()
        .add("Value", DecimalType(), False)
        .add("Unit", StringType(), True), False)\
    .add("ObservationTime", TimestampType(), False)

def event_hub_parse(raw_data: DataFrame):
    return raw_data \
        .select(from_json(col("body").cast("string"), message_schema).alias("message"), col("enqueuedTime")) \
        .select(col("message.*"), col("enqueuedTime").alias("EventHubEnqueueTime"))

def preview_stream(df_stream: DataFrame, await_seconds: int = 5):
    df_stream.printSchema()
    exec = df_stream \
        .writeStream \
        .foreachBatch(lambda df, i: df.show()) \
        .start()
    exec.awaitTermination(await_seconds)
    exec.stop()

def filter_by_supplier(df: DataFrame, supplierId: str):
    supplier = str(supplierId)
    supplier_df = df.filter(col("SupplierId") == lit(supplier))
    return supplier_df

def store_data(batch_df: DataFrame, output_delta_lake_path):
    """
    Utility stores streaming dataframe to Data Lake Gen 2
    using Delta lake framework
    """
    batch_df.select(col("MeterId"), col("SupplierId"), col("Measurement"), col("ObservationTime")) \
        .repartition("SupplierId") \
        .write \
        .partitionBy("SupplierId") \
        .format("delta") \
        .mode("append") \
        .save(output_delta_lake_path)

# set up agruments
storageAccountName = str(sys.argv[1])
storageAccountKey = str(sys.argv[2])
storageContainerName = str(sys.argv[3])# Default = data
outputPath = str(sys.argv[4])# Default = delta/streaming-data/
inputEHConnectionString = str(sys.argv[5])
maxEventsPerTrigger = int(sys.argv[6])# Default = 10000
triggerInterval = str(sys.argv[7])# Default = 1 second
streamingCheckpointPath = str(sys.argv[8])# Default = checkpoints/streaming

#print(storageAccountName)
#print(storageAccountKey)
#print(storageContainerName)
#print(outputPath)
#print(inputEHConnectionString)
#print(maxEventsPerTrigger)
#print(triggerInterval)
#print(streamingCheckpointPath)

# build spark context
spark_conf = SparkConf(loadDefaults=True) \
    .set('fs.azure.account.key.{0}.dfs.core.windows.net'.format(storageAccountName), storageAccountKey)

spark = SparkSession\
    .builder\
    .config(conf=spark_conf)\
    .getOrCreate()

sc = spark.sparkContext
#print("Spark Configuration:")
#_ = [print(k + '=' + v) for k, v in sc.getConf().getAll()]

# configure event hub reading
input_eh_starting_position = {
    "offset": "-1",# - 1 : starting from beginning of stream
    "seqNo": -1,# not in use
    "enqueuedTime": None,   # not in use
    "isInclusive": True
}
input_eh_connection_string = inputEHConnectionString
input_eh_conf = {
    # Version 2.3.15 and up requires encryption
    'eventhubs.connectionString': \
    sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(input_eh_connection_string),
    'eventhubs.startingPosition': json.dumps(input_eh_starting_position),
    'maxEventsPerTrigger': maxEventsPerTrigger,
}

#print("Input event hub config:", input_eh_conf)

# Read from Event Hub
raw_data = spark \
    .readStream \
    .format("eventhubs") \
    .options(**input_eh_conf) \
    .option("inferSchema", True)\
    .load()

#print("Input stream schema:")
#raw_data.printSchema()

# parse event hub message 
eh_data = event_hub_parse(raw_data)

#print("Parsed stream schema:")
#eh_data.printSchema()

#print("Stream preview:")
#preview_stream(eh_data, await_seconds=5)

# store data to data lake 
BASE_STORAGE_PATH = "abfss://{0}@{1}.dfs.core.windows.net/".format(storageContainerName, storageAccountName)

#print("Base storage url:", BASE_STORAGE_PATH)

output_delta_lake_path = BASE_STORAGE_PATH + outputPath
checkpoint_path = BASE_STORAGE_PATH + streamingCheckpointPath

def __store_data_frame(batch_df: DataFrame, _: int):
    try:
        # Cache the batch in order to avoid the risk of recalculation in each write operation
        # Cache the batch in order to avoid the risk
        # of recalculation in each write operation
        batch_df = batch_df.persist()

        # Make valid time series points available to aggregations (by storing in Delta lake)
        # Make valid time series points available to post processing
        # (by storing in Delta lake)
        store_data(batch_df, output_delta_lake_path)

        # <other operations may go here>

        batch_df = batch_df.unpersist()

    except Exception as err:
        raise err

print("Writing stream to delta lake...")
out_stream = eh_data \
    .writeStream \
    .outputMode("append") \
    .option("checkpointLocation", checkpoint_path) \
    .trigger(processingTime="1 second") \
    .foreachBatch(__store_data_frame)


execution = out_stream.start()
execution.awaitTermination()
execution.stop()

print("Job complete.")

