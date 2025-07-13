# Azure DevOps Assignment – Symplique

> A cost-optimized, serverless solution to archive billing records from Azure Cosmos DB to Azure Blob Storage after 90 days — with **zero downtime** and **no API changes**.

---

## 🧩 Problem & Solution

- **Problem**: Cosmos DB cost is rising due to ~2M large billing records (~300KB each), many of which are rarely accessed.
- **Goal**: Archive older records (90+ days) to reduce cost while ensuring fast access when needed.
- **Solution**: A serverless proxy architecture that:
  - Uses Azure Functions to archive and retrieve records.
  - Preserves existing APIs.
  - Leverages Blob Storage's Cool/Archive tier.

---

## 🏗️ Architecture Overview

![Architecture Diagram](docs/new_architecture.png)

The architecture comprises two main Azure Functions:

- [`billing_records_archival`](azure-functions/billing_records_archival/)  
  Scheduled function that moves data older than 90 days from Cosmos DB to Blob Storage.

- [`billing_records_retrieval`](azure-functions/billing_records_retrieval/)  
  An on-demand retrieval function that queries Cosmos DB or falls back to Blob Storage if the record is archived.

Infrastructure is provisioned using [Terraform](terraform/).

More details available in [docs/new_architecture.md](docs/new_architecture.md).

---

## 📁 Project Structure

```text
.
├── terraform/                 # Infrastructure as Code (IaC)
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
|
|── azure-functions/
|   ├── billing_records_archival/   # Daily archiver function
|   │   ├── function.json
|   │   ├── __init__.py
|   │   └── requirements.txt
|   │
|   └── billing_records_retrieval/  # HTTP retrieval function
|       ├── function.json
|       ├── __init__.py
|       └── requirements.txt
|
├── README.md
└── chatgpt-prompt.md
```

---

## 🧰 Technologies Used

- Azure Functions (Python)
- Azure Blob Storage
- Azure Cosmos DB
- Azure Storage Account
- Terraform (AzureRM Provider)
- Python 3.10+

---

## 📦 Terraform Overview
- `main.tf`: Provisions function apps, storage, Cosmos DB, and required settings
- `variables.tf`: Centralized configuration
- `outputs.tf`: Exposes useful info like Function App URLs

---

## 🚀 Getting Started
### ✅ Prerequisites
- Azure CLI (az login)
- Terraform v1.0+
- Python 3.10 with Azure Functions Core Tools

### 🛠️ Infrastructure Deployment
```bash
cd terraform
terraform init
terraform plan
terraform apply
```
This deploys:
- Two Azure Function Apps
- Storage account with two containers:
  - archived → for old billing records
  - logs → for archival logs
- Cosmos DB instance
- Application Insights

> Make sure to configure `backend` and other environment-specific variables.

### ⚙️ Azure Functions Deployment
Install dependencies and publish:
```bash
pip install -r requirements.txt
cd azure-functions/billing_records_archival
func azure functionapp publish <your-function-app-name>
```
Repeat the same for billing_records_retrieval.

> **Note:**  
> The code provided in the `azure-functions` folders is **pseudocode** and serves as a template or reference.  
> You will need to implement the actual logic and configure the functions before deploying to Azure.

### 🧪 Example Usage
- **Archival**: Triggered by a time-based schedule.
- **Retrieval**: Queries Cosmos DB; fetches from Blob Storage if the record is archived.
- Input/output formats can be defined in each function's README.

---

## ✅ Best Practices Followed
- Zero downtime and backward-compatible API design
- Data retention strategy with a delay before deletion
- Logs all actions as function output stream
- Infrastructure managed using Terraform
- Separation of compute and storage for cost efficiency
- Blob storage lifecycle tiers (Cool/Archive)

---

## 📈 Monitoring & Observability
> Planned for future enhancement.
- Integrate with Azure Monitor and Application Insights.
- Add custom logging and metrics.

---

## ✅ To-Do / Enhancements
- Add CI/CD pipeline (e.g., GitHub Actions or Azure Pipelines) for automated infra deployments.
- create indexing for faster retrival from blob.
- Improve error handling & retry policies.
- Secret management for the sensitive data (eg. Azure Key Vault to store secrets).

---

## 🙋‍♂️ Maintainer
Built with ❤️ by Shivam Gupta
