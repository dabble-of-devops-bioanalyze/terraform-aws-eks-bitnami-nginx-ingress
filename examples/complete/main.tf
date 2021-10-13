provider "aws" {
  region = var.region
}


data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}


# Create an EKS cluster or use an existing
module "eks" {
  source = "dabble-of-devops-bioanalyze/eks-autoscaling/aws"
  # version = ""

  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  oidc_provider_enabled             = true
  cluster_encryption_config_enabled = true
  eks_node_groups                   = var.eks_node_groups

  eks_node_group_autoscaling_enabled            = true
  eks_worker_group_autoscaling_policies_enabled = true

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
module "nginx_ingress" {
  count                   = var.enable_ssl == true ? 1 : 0
  source                  = "dabble-of-devops-bioanalyze/eks-bitnami-nginx-ingress/aws"
  version                 = "0.0.2"
  letsencrypt_email       = var.letsencrypt_email
  helm_release_values_dir = var.helm_release_values_dir
  helm_release_name       = var.helm_release_name
}

data "kubernetes_service" "airflow_ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    module.airflow_ingress
  ]
  metadata {
    name = "${var.helm_release_name}-ingress-nginx-ingress-controller"
  }
}

data "aws_elb" "airflow_ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    data.kubernetes_service.airflow_ingress
  ]
  name = split("-", data.kubernetes_service.airflow_ingress[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}
