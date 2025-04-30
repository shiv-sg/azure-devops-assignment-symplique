import os
import json
import logging
from azure.cosmos import CosmosClient
from azure.storage.blob import BlobServiceClient
import azure.functions as func

# Config
COSMOS_ENDPOINT = os.environ["COSMOS_ENDPOINT"]
COSMOS_KEY = os.environ["COSMOS_KEY"]
COSMOS_DB = os.environ["COSMOS_DB"]
COSMOS_CONTAINER = os.environ["COSMOS_CONTAINER"]

BLOB_CONN_STR = os.environ["BLOB_CONN_STR"]
BLOB_CONTAINER = os.environ["BLOB_CONTAINER"]

# Clients
cosmos_client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
cosmos_container = cosmos_client.get_database_client(COSMOS_DB).get_container_client(COSMOS_CONTAINER)

blob_service = BlobServiceClient.from_connection_string(BLOB_CONN_STR)
blob_container = blob_service.get_container_client(BLOB_CONTAINER)

def main(req: func.HttpRequest) -> func.HttpResponse:
    record_id = req.route_params.get('record_id')

    if not record_id:
        return func.HttpResponse("Missing record_id.", status_code=400)

    try:
        # Step 1: Try Cosmos DB
        cosmos_record = fetch_from_cosmos(record_id)
        if cosmos_record:
            return func.HttpResponse(json.dumps(cosmos_record), status_code=200, mimetype="application/json")

        # Step 2: Fallback to Blob
        blob_record = fetch_from_blob(record_id)
        if blob_record:
            return func.HttpResponse(json.dumps(blob_record), status_code=200, mimetype="application/json")

        return func.HttpResponse(f"Record {record_id} not found.", status_code=404)

    except Exception as e:
        logging.error(f"Error retrieving record {record_id}: {str(e)}")
        return func.HttpResponse("Internal server error", status_code=500)

def fetch_from_cosmos(record_id):
    query = f"SELECT * FROM c WHERE c.id = '{record_id}'"
    items = list(cosmos_container.query_items(query=query, enable_cross_partition_query=True))
    return items[0] if items else None

def fetch_from_blob(record_id):
    """
    Attempts to retrieve the archived record from Blob Storage
    following the folder structure: archived/yyyy/mm/dd/<record_id>.json
    Searches up to 1 year back from today.
    """
    today = datetime.utcnow()
    for day_offset in range(0, 365):  # Search up to 1 year of archived records
        check_date = today - timedelta(days=day_offset)
        year = check_date.strftime("%Y")
        month = check_date.strftime("%m")
        day = check_date.strftime("%d")
        
        blob_path = f"archived/{year}/{month}/{day}/{record_id}.json"

        try:
            blob_client = blob_container.get_blob_client(blob_path)
            blob_data = blob_client.download_blob().readall()
            return json.loads(blob_data)
        except Exception:
            continue  # If not found, try previous day

    return None
