# Billing Records Migration Function

This Azure Function is designed to archive billing records older than a specified threshold from **Azure Cosmos DB** to **Azure Blob Storage**. It also cleans up old archived records from Cosmos DB after a delay period. This process helps optimize storage costs and maintain a clean database.

## Features

- **Archival to Blob Storage**: Moves records older than 90 days (configurable) from Cosmos DB to Blob Storage.
- **Mark Records as Archived**: Updates records in Cosmos DB to indicate they have been archived.
- **Cleanup of Old Records**: Deletes archived records from Cosmos DB after a delay period (default: 7 days).
- **Error Logging**: Logs errors during archival and cleanup for debugging and monitoring.

## How It Works

1. **Identify Records for Archival**:
   - Queries Cosmos DB for records older than the archival threshold (default: 90 days) that have not been archived.

2. **Archive Records to Blob Storage**:
   - Uploads the records to Blob Storage in JSON format under a structured path (`archived/YYYY/MM/DD/<record_id>.json`).
   - Marks the records as archived in Cosmos DB with an `archived` flag and an `archivedAt` timestamp.

3. **Cleanup Old Archived Records**:
   - Deletes records from Cosmos DB that were archived more than 7 days ago (configurable).

4. **Logging**:
   - Logs the number of records processed and any errors encountered during the archival and cleanup processes.

## Configuration

The function uses the following environment variables for configuration:

- **Cosmos DB Configuration**:
  - `COSMOS_ENDPOINT`: The endpoint URL of your Cosmos DB account.
  - `COSMOS_KEY`: The primary key for your Cosmos DB account.
  - `COSMOS_DB`: The name of the Cosmos DB database.
  - `COSMOS_CONTAINER`: The name of the Cosmos DB container.

- **Blob Storage Configuration**:
  - `BLOB_CONN_STR`: The connection string for your Azure Blob Storage account.
  - `BLOB_CONTAINER`: The name of the Blob Storage container where records will be archived.

- **Archival and Cleanup Settings**:
  - `ARCHIVE_THRESHOLD_DAYS`: The number of days after which records are eligible for archival (default: 90 days).
  - `DELETE_DELAY_DAYS`: The number of days to wait before deleting archived records from Cosmos DB (default: 7 days).

## Usage

1. Deploy the function to an Azure Function App.
2. Configure the required environment variables in the Azure portal or your local environment.
3. Schedule the function to run periodically using a timer trigger (e.g., daily).
4. Monitor the logs to track the archival and cleanup processes.

## Example Log Output

```plaintext
INFO: Starting billing record archival...
INFO: Found 25 records to archive.
INFO: Archived record 12345 to blob path: archived/2023/01/01/12345.json
INFO: Archived record 67890 to blob path: archived/2023/01/02/67890.json
INFO: Found 10 records eligible for deletion.
INFO: Deleted record 12345 from Cosmos DB
INFO: Deleted record 67890 from Cosmos DB
INFO: Archival run complete.