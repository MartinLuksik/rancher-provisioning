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

variable "aws_access_key" {
  default     = "latest"
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  default     = "latest"
  description = "AWS Secret Key"
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
  name = "awscred"
  description = "awscred"
  amazonec2_credential_config {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
  }
}

# Create a new rancher2 Node Template from Rancher 2.2.x
resource "rancher2_node_template" "main" {
  name = "t2node"
  description = "t2node"
  cloud_credential_id = "${rancher2_cloud_credential.main.id}"
  amazonec2_config {
    ami =  "ami-0079d316193c1c1f2"
    region = "eu-central-1"
    security_group = ["rancher-nodes"]
    subnet_id = "subnet-d2744c9f"
    vpc_id = "vpc-c93225a2"
    zone = "c"
    instance_type="t2.medium"
    ssh_user="rancher"
    iam_instance_profile="rancherpassrole"
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
  hostname_prefix =  "master"
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
  hostname_prefix =  "worker"
  node_template_id = "${rancher2_node_template.main.id}"
  quantity = "${var.number_of_worker_nodes}"
  control_plane = false
  etcd = false
  worker = true
}