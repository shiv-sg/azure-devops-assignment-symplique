# Billing Records Retrieval Function

This Azure Function is designed to retrieve billing records from **Azure Cosmos DB** or **Azure Blob Storage**. It first attempts to fetch the record from Cosmos DB, and if not found, it falls back to searching for the record in Blob Storage. This function is useful for accessing both active and archived billing records.

## Features

- **Cosmos DB Query**: Retrieves records by `record_id` from Azure Cosmos DB.
- **Blob Storage Fallback**: If the record is not found in Cosmos DB, it searches for the record in Azure Blob Storage.
- **Date-Based Blob Search**: Searches for archived records in Blob Storage using a structured date-based path (`archived/YYYY/MM/DD/<record_id>.json`).
- **Error Handling**: Logs errors and returns appropriate HTTP status codes for different scenarios.

## How It Works

1. **Retrieve from Cosmos DB**:
   - Queries Cosmos DB for the record using the provided `record_id`.

2. **Fallback to Blob Storage**:
   - If the record is not found in Cosmos DB, it searches Blob Storage for the record in JSON format under a structured path.

3. **Return Record**:
   - If the record is found in either Cosmos DB or Blob Storage, it is returned as a JSON response.
   - If the record is not found in both, a `404 Not Found` response is returned.

4. **Error Logging**:
   - Logs any errors encountered during the retrieval process for debugging and monitoring.

## Configuration

The function uses the following environment variables for configuration:

- **Cosmos DB Configuration**:
  - `COSMOS_ENDPOINT`: The endpoint URL of your Cosmos DB account.
  - `COSMOS_KEY`: The primary key for your Cosmos DB account.
  - `COSMOS_DB`: The name of the Cosmos DB database.
  - `COSMOS_CONTAINER`: The name of the Cosmos DB container.

- **Blob Storage Configuration**:
  - `BLOB_CONN_STR`: The connection string for your Azure Blob Storage account.
  - `BLOB_CONTAINER`: The name of the Blob Storage container where archived records are stored.

## Usage

1. Deploy the function to an Azure Function App.
2. Configure the required environment variables in the Azure portal or your local environment.
3. Call the function via an HTTP GET request with the `record_id` as a route parameter.

### Example Request

```http
GET https://<your-function-app>.azurewebsites.net/api/billing_records_retrieval/{record_id}

```

### Example Response (Record Found in Cosmos DB)
```json
{
  "id": "12345",
  "accountId": "67890",
  "createdAt": "2023-01-01T12:00:00Z",
  "amount": 100.0
}
```

### Example Response (Record Found in Blob Storage)
```json
{
  "id": "12345",
  "accountId": "67890",
  "createdAt": "2023-01-01T12:00:00Z",
  "amount": 100.0,
  "archived": true
}
```

### Example Response (Record Not Found)
```json
{
  "error": "Record not found"
}
```

### Example Response (Error)
```json
{
  "error": "Internal Server Error"
}
```

### Blob Storage Path Structure
The function searches for archived records in Blob Storage using the following path structure:

`archived/YYYY/MM/DD/<record_id>.json`

Where:
- `YYYY`: Year of the record creation date.
- `MM`: Month of the record creation date.
- `DD`: Day of the record creation date.
- `<record_id>`: The unique identifier of the record.
- `.json`: The file format of the archived record.
- The function uses the `record_id` to construct the path to the archived record in Blob Storage.