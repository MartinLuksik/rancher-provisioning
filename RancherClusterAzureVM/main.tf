variable "rancher_api_url" {
  default     = "https://rancher.mldedicated.net/v3"
  description = "Rancher Server Version"
}
variable "rancher2_access_key" {
  default     = "latest"
  description = "Rancher Server Access Key"
}
variable "rancher2_secret_key" {
  default     = "latest"
  description = "Rancher Server Secret key"
}

variable "azure_client_id" {
  default     = "latest"
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  default     = "latest"
  description = "Azure Client Secret"
}

variable "azure_subscription_id" {
  default     = "latest"
  description = "Azure Client Subscription"
}

variable "resource_group" {
  default     = "ranchercluster"
  description = "Resource group of the Rancher Cluster"
}

variable "number_of_worker_nodes" {
  default     = 1
  description = "Number of default worker nodes in the worker node pool."
}

# Configure the Rancher2 provider to admin
provider "rancher2" {
  api_url    = "${var.rancher_api_url}"
  access_key = "${var.rancher2_access_key}"
  secret_key = "${var.rancher2_secret_key}"
  insecure = true
}

# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "main" {
  name = "azcred"
  description = "accred"
  azure_credential_config {
    client_id = "${var.azure_client_id}"
    client_secret = "${var.azure_client_secret}"
    subscription_id= "${var.azure_subscription_id}"    
  }
}

# Create a new rancher2 Node Template from Rancher 2.2.x
resource "rancher2_node_template" "main" {
  name = "nodetemplate"
  description = "Node template"
  cloud_credential_id = "${rancher2_cloud_credential.main.id}"
  azure_config {
    location ="westeurope"
    resource_group="${var.resource_group}"
    size="Standard_A2"
  }
}

# Create a new rancher2 RKE Cluster
resource "rancher2_cluster" "main" {
  name = "Cluster"
  description = "Custom RKE Cluster"
  rke_config {
    network {
      plugin = "canal"
    }
  }
}

# Create a new rancher2 Node Pool - Master (with a worker role)
resource "rancher2_node_pool" "master" {
  cluster_id =  "${rancher2_cluster.main.id}"
  name = "MLCluster"
  hostname_prefix =  "mlcluster"
  node_template_id = "${rancher2_node_template.main.id}"
  quantity = 1
  control_plane = true
  etcd = true
  worker = true
}

# Create a new rancher2 Node Pool - Workers
resource "rancher2_node_pool" "worker" {
  cluster_id =  "${rancher2_cluster.main.id}"
  name = "MLCluster"
  hostname_prefix =  "mlcluster"
  node_template_id = "${rancher2_node_template.main.id}"
  quantity = "${var.number_of_worker_nodes}"
  control_plane = false
  etcd = false
  worker = true
}