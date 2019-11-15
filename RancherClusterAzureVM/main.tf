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
    size="Standard_D2_v2"
    availability_set="docker-machine"
    environment="AzurePublicCloud"
    subnet="docker-machine"
    subnet_prefix="192.168.0.0/16"
    vnet="docker-machine-vnet"
    static_public_ip=false
    image="canonical:UbuntuServer:16.04.0-LTS:latest"
    docker_port=2376
    open_port=["6443/tcp","2379/tcp","2380/tcp","8472/udp","4789/udp","9796/tcp","10256/tcp","10250/tcp","10251/tcp","10252/tcp"]
    ssh_user="docker-user"
    storage_type="Standard_LRS"
  }
}

# Create a new rancher2 RKE Cluster
resource "rancher2_cluster" "main" {
  name = "cluster"
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
  name = "mlcluster-master"
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
  name = "mlcluster-worker"
  hostname_prefix =  "mlcluster"
  node_template_id = "${rancher2_node_template.main.id}"
  quantity = "${var.number_of_worker_nodes}"
  control_plane = false
  etcd = false
  worker = true
}