data "databricks_current_user" "me" {
  depends_on = [azurerm_databricks_workspace.this]
}

data "databricks_spark_version" "latest" {
  depends_on = [azurerm_databricks_workspace.this]
  long_term_support = true
}

data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.this]
}

resource "databricks_secret_scope" "this" {
  name = "demo-${data.databricks_current_user.me.alphanumeric}"
}

resource "databricks_token" "pat" {
  comment          = "Created from ${abspath(path.module)}"
  lifetime_seconds = 3600
}

resource "databricks_secret" "token" {
  string_value = databricks_token.pat.token_value
  scope        = databricks_secret_scope.this.name
  key          = "token"
}

resource "databricks_notebook" "this" {
  path     = "${data.databricks_current_user.me.home}/Terraform"
  language = "PYTHON"
  content_base64 = base64encode(<<-EOT
    token = dbutils.secrets.get('${databricks_secret_scope.this.name}', '${databricks_secret.token.key}')
    print(f'This should be redacted: {token}')
    EOT
  )
}

resource "databricks_job" "this" {
  name = "Terraform Demo (${data.databricks_current_user.me.alphanumeric})"

  task {
    task_key = "task1"

    new_cluster {
      num_workers   = 1
      spark_version = data.databricks_spark_version.latest.id
      node_type_id  = data.databricks_node_type.smallest.id
    }

    notebook_task {
      notebook_path = databricks_notebook.this.path
    }
  }
}

resource "databricks_cluster" "this" {
  cluster_name            = "Exploration (${data.databricks_current_user.me.alphanumeric})"
  spark_version           = data.databricks_spark_version.latest.id
  instance_pool_id        = databricks_instance_pool.smallest_nodes.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 10
  }
}

resource "databricks_cluster_policy" "this" {
  name = "Minimal (${data.databricks_current_user.me.alphanumeric})"
  definition = jsonencode({
    "dbus_per_hour" : {
      "type" : "range",
      "maxValue" : 10
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : 20,
      "hidden" : true
    }
  })
}

resource "databricks_instance_pool" "smallest_nodes" {
  instance_pool_name = "Smallest Nodes (${data.databricks_current_user.me.alphanumeric})"
  min_idle_instances = 0
  max_capacity       = 30
  node_type_id       = data.databricks_node_type.smallest.id
  // node_type_id       = data.databricks_node_type.smallest.id
  preloaded_spark_versions = [
    data.databricks_spark_version.latest.id
  ]

  idle_instance_autotermination_minutes = 20
}
