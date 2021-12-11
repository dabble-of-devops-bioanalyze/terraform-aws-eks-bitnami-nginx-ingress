provider "aws" {
  region = var.region
}

provider "http" {

}

provider "tls" {
}

#############################################################
# Networking
#############################################################

data "aws_availability_zones" "available" {
  # exclude us-east-1e, not allowed
  # exclude_names = ["us-east-1e"]
}

data "aws_caller_identity" "current" {}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

output "vpc" {
  value = aws_default_vpc.default
}

resource "aws_default_subnet" "default_az" {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

output "aws_default_subnet" {
  value = aws_default_subnet.default_az
}

locals {
  # create vpc and subnets
  vpc_id     = aws_default_vpc.default.id
  subnet_ids = aws_default_subnet.default_az[*].id
}

output "subnet_ids" {
  value = local.subnet_ids
}

#############################################################
# Admin EKS Cluster
#############################################################

# https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
module "eks" {
  source  = "dabble-of-devops-bioanalyze/eks-autoscaling/aws"
  version = ">= 1.20.0"

  region                                        = var.region
  vpc_id                                        = local.vpc_id
  subnet_ids                                    = local.subnet_ids
  kubernetes_version                            = "1.19"
  oidc_provider_enabled                         = true
  cluster_encryption_config_enabled             = true
  eks_node_groups                               = var.eks_node_groups
  eks_node_group_autoscaling_enabled            = true
  eks_worker_group_autoscaling_policies_enabled = true
  install_ingress                               = true
  letsencrypt_email                             = "jillian@dabbleofdevops.com"

  context = module.this.context
}

data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks.eks_cluster_id
    kubernetes_config_map_id = module.eks.eks_cluster.kubernetes_config_map_id
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_id]
      command     = "aws"
    }
  }
}

resource "null_resource" "kubectl_update" {
  depends_on = [
    module.eks,
  ]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks --region $AWS_REGION update-kubeconfig --name $NAME"
    environment = {
      AWS_REGION = var.region
      NAME       = module.eks.eks_cluster_id
    }
  }
}

# Check to make sure that the ingress is installed
data "kubernetes_service" "ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    module.eks
  ]
  metadata {
    name = "nginx-ingress-ingress-nginx-ingress-controller"
    namespace = "default"
  }
}

data "aws_elb" "ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    data.kubernetes_service.ingress
  ]
  name = split("-", data.kubernetes_service.ingress[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}

module "ingress" {
  source = "./../../"
  depends_on = [
    module.eks
  ]
  install_ingress = false
  use_existing_ingress = true
  existing_ingress_name = "nginx-ingress-ingress-nginx-ingress-controller"
  existing_ingress_namespace = "default"
}

output "ingress" {
  value = module.ingress
}