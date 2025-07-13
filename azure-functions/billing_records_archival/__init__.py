import os
import json
from datetime import datetime, timedelta
import logging

import azure.functions as func
from azure.cosmos import CosmosClient, PartitionKey
from azure.storage.blob import BlobServiceClient

# Load config from environment variables
COSMOS_ENDPOINT = os.environ["COSMOS_ENDPOINT"]
COSMOS_KEY = os.environ["COSMOS_KEY"]
COSMOS_DB = os.environ["COSMOS_DB"]
COSMOS_CONTAINER = os.environ["COSMOS_CONTAINER"]

BLOB_CONN_STR = os.environ["BLOB_CONN_STR"]
BLOB_CONTAINER = os.environ["BLOB_CONTAINER"]

# Initialize clients
cosmos_client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
container = cosmos_client.get_database_client(COSMOS_DB).get_container_client(COSMOS_CONTAINER)
blob_service = BlobServiceClient.from_connection_string(BLOB_CONN_STR)
blob_container = blob_service.get_container_client(BLOB_CONTAINER)

ARCHIVE_THRESHOLD_DAYS = 90
DELETE_DELAY_DAYS = 7

def main(mytimer: func.TimerRequest) -> None:
    logging.info('Starting billing record archival...')

    threshold_date = datetime.utcnow() - timedelta(days=ARCHIVE_THRESHOLD_DAYS)
    delete_eligible_date = datetime.utcnow() - timedelta(days=ARCHIVE_THRESHOLD_DAYS + DELETE_DELAY_DAYS)

    query = {
        "query": f"SELECT * FROM c WHERE c.createdAt < @threshold_date AND (IS_NULL(c.archived) OR c.archived = false)",
        "parameters": [{"name": "@threshold_date", "value": threshold_date.isoformat()}]
    }
    records = list(container.query_items(query=query, enable_cross_partition_query=True))

    logging.info(f"Found {len(records)} records to archive.")

    for record in records:
        try:
            archive_record(record)
        except Exception as e:
            logging.error(f"Error archiving record {record['id']}: {str(e)}")

    cleanup_old_records(delete_eligible_date)
    logging.info("Archival run complete.")

def archive_record(record):
    record_id = record["id"]
    record_year = record["createdAt"][:4]  # 'YYYY'
    record_month = record["createdAt"][5:7]  # 'MM'
    record_date = record["createdAt"][8:10]  # 'DD'
    blob_path = f"archived/{record_year}/{record_month}/{record_date}/{record_id}.json"

    # Upload to Blob Storage
    blob_client = blob_container.get_blob_client(blob_path)
    blob_client.upload_blob(json.dumps(record), overwrite=True)

    # Mark as archived
    record["archived"] = True
    record["archivedAt"] = datetime.utcnow().isoformat()
    container.upsert_item(record)

    logging.info(f"Archived record {record_id} to blob path: {blob_path}")

def cleanup_old_records(delete_before):
    query = {
        "query": f"SELECT * FROM c WHERE c.archived = true AND c.archivedAt < @delete_before",
        "parameters": [{"name": "@delete_before", "value": delete_before.isoformat()}]
    }
    old_records = list(container.query_items(query=query, enable_cross_partition_query=True))

    logging.info(f"Found {len(old_records)} records eligible for deletion.")

    for record in old_records:
        try:
            container.delete_item(item=record["id"], partition_key=record["partitionKey"])
            logging.info(f"Deleted record {record['id']} from Cosmos DB")
        except Exception as e:
            logging.error(f"Error deleting record {record['id']}: {str(e)}")