output "notebook_url" {
  value = databricks_notebook.this.url
}

output "job_url" {
  value = databricks_job.this.url
}

output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}