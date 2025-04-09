What This Script Does:
✅ Creates an Azure Resource Group

✅ Deploys an Azure Log Analytics Workspace for monitoring

✅ Creates an Azure Container Apps Environment

✅ Deploys an Azure Key Vault and stores MySQL password & Storage connection

✅ Creates an Azure Blob Storage container for ZenML artifacts

✅ Deploys an Azure MySQL Flexible Server with a zenml database

✅ Deploys ZenML on Azure Container Apps with environment variables

This setup ensures secure secrets management, persistent database storage, and artifact storage in the Azure ecosystem. 🚀

## TF command :
terraform plan -out plan.txt -var-file values.tfvars
