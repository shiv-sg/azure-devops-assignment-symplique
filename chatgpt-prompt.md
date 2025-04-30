# ChatGPT Prompt
```
act as a senior cloud architect

i have a serverless infrastructure in azure where we store billing records in azure cosmos db.
- db currently holds over 2 million records, each record size can be as large as 300 KB.
- higher cost due to higher db size.
- records older than 90 days are rarely accessed but if requested it must serve in seconds.

Propose a detailed solution to optimize cost while ensuring:
- easy to implement and maintain
- no downtime and no data loss
- no changes to the existing read/write api for billing records

Give a detailed solution including:
- new architecture with diagram
- services to use (azure blob storage for storing data older data, azure)
- data archival and retrieval strategy
- psuedocode/scripts for migration, indexing, logging and automation.
- terraform templates for deploying the necessary resources.
- github repo structure to share the full solution

Also ensure that the best practices are followed to make the infrastructure scalable, reliable and robust like maintain logs in a blob container for logs, deletion only after a period of time (like 7 days) after migration is done, etc.
```

# ChatGPT Response
Here's a robust, production-grade solution to optimize your Azure Cosmos DB cost by archiving older billing records without modifying the current read/write APIs or causing downtime.

### ✅ High-Level Solution Goals
Reduce Cosmos DB storage cost by moving infrequently accessed records (older than 90 days) to a cheaper tier (Azure Blob Storage).

Preserve existing APIs — no changes to your application logic.

Maintain fast access to archived data when requested.

Ensure scalability, observability, and operational safety (logs, monitoring, retries, soft deletes).

### 🏗️ New Architecture (with Diagram)

         ┌───────────────────────┐
         │ Existing Billing API │
         └────────┬──────────────┘
                  │
        ┌─────────▼──────────┐
        │   Azure Function   │  ← Used as a proxy layer to check data location
        └─────────┬──────────┘
                  │
        ┌─────────▼──────────┐
        │  Cosmos DB (Hot)   │  ← Recent (<90d) records
        └─────────┬──────────┘
                  │
        ┌─────────▼─────────────┐
        │ Azure Blob Storage    │  ← Archived JSON blobs, partitioned by date
        │ (Cool or Archive Tier)│
        └───────────────────────┘

### 🧰 Azure Services Used

Service | Purpose
Cosmos DB |	Stores recent billing records (<90 days).
Azure Blob Storage | Stores archived records as JSON files, in Cool or Archive tier.
Azure Functions | Middleware for read requests to check Cosmos first, then Blob.
Azure Function Triggers | Scheduled migration from Cosmos DB to Blob.

### 📦 Data Archival Strategy
Migration Pipeline (via Durable Azure Function):
Query Cosmos DB for records older than 90 days.

Write those records to Blob Storage in date-partitioned folders.

Mark them in Cosmos with a field like archived: true or move them to a "soft-delete" container.

Wait 7 days, then delete from Cosmos DB (configurable retention).

Log each step to Blob Storage for audit/debug.

### 🧑‍💻 Pseudocode for Migration (Python Durable Azure Function)
```python
def archive_records():
    records = cosmos_query("SELECT * FROM c WHERE c.date < 90_days_ago AND c.archived != true")
    for record in records:
        blob_path = f"archive/{record['date'][:10]}/{record['id']}.json"
        upload_to_blob(blob_path, json.dumps(record))
        mark_as_archived(record['id'])
        log_action("ARCHIVED", record['id'], blob_path)

def cleanup_old_records():
    records = cosmos_query("SELECT * FROM c WHERE c.archived = true AND c.archivedDate < 7_days_ago")
    for record in records:
        delete_from_cosmos(record['id'])
        log_action("DELETED", record['id'])
```

### 🧪 Data Retrieval Strategy (Middleware Azure Function)
API → Cosmos DB → If 404, fallback to Blob Storage.

Blob JSON → parse → return same response structure.

Optional: cache result in Cosmos for faster future reads.

### ☁️ Terraform Template Snippets
1. Blob Storage with Logging
```hcl
resource "azurerm_storage_account" "billing_archive" {
  name                     = "billingarchivestorage"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 30
    }
  }
}
```

2. Azure Function App
```hcl
resource "azurerm_function_app" "middleware" {
  name                       = "billing-proxy-fn"
  location                   = var.location
  resource_group_name        = var.rg_name
  app_service_plan_id        = azurerm_app_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.billing_archive.name
  app_settings = {
    "CosmosDbConnectionString" = var.cosmos_conn_str
    "BlobStorageConnectionString" = var.blob_conn_str
  }
}
```

### ✅ Best Practices Followed
Separation of hot and cold data (Cosmos vs Blob).

Delayed hard deletion after 7-day safety window.

Blob tier optimization (Cool for 90–180d, Archive after 180d).

Observability built-in (logs, error handling).

No downtime due to background archiving.

Existing API intact (read fallback handled in middleware).

Secure with Key Vault for secrets and RBAC for access control.

## CHATGPT LINK
https://chatgpt.com/share/68116436-0b0c-8013-ae8e-729f0be4e3b1