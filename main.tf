#######################################################
# Ingress
# Case - install new ingress
#######################################################

resource "helm_release" "ingress" {
  count = var.install_ingress == true ? 1 : 0
  name             = "${var.helm_release_name}-ingress"
  repository       = var.helm_release_repository
  chart            = var.helm_release_chart
  namespace        = var.helm_release_namespace
  create_namespace = var.helm_release_create_namespace
  wait             = var.helm_release_wait
}

output "helm_release_ingress" {
  description = "Helm release ingress"
  value = helm_release.ingress
}

data "kubernetes_service" "ingress" {
  count = var.install_ingress == true ? 1 : 0
  depends_on = [
    helm_release.ingress,
  ]
  metadata {
    name      = "${var.helm_release_name}-ingress-nginx-ingress-controller"
    namespace = var.helm_release_namespace
  }
}

output "kubernetes_service_ingress" {
  value = data.kubernetes_service.ingress
}

data "aws_elb" "ingress" {
  count = var.install_ingress == true ? 1 : 0
  depends_on = [
    helm_release.ingress,
    data.kubernetes_service.ingress
  ]
  name = split("-", data.kubernetes_service.ingress[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}

output "aws_elb_ingress" {
  value = data.aws_elb.ingress
}

#################################################################
# Case: Use Existing Ingress
#################################################################

data "kubernetes_service" "helm_ingress_existing" {
  count = var.use_existing_ingress == true ? 1 : 0
  metadata {
    name      = var.existing_ingress_name
    namespace = var.existing_ingress_namespace
  }
}

output "kubernetes_service_helm_ingress_existing" {
  value = data.kubernetes_service.helm_ingress_existing
}

data "aws_elb" "helm_ingress_existing" {
  count =  var.use_existing_ingress == true ? 1 : 0
  depends_on = [
    data.kubernetes_service.helm_ingress_existing
  ]
  name = split("-", data.kubernetes_service.helm_ingress_existing[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}

output "aws_elb_helm_ingress_existing" {
  value = data.aws_elb.helm_ingress_existing
}

#################################################################
# Ingress - grab the ingress data and put it back out
#################################################################

locals {
  kubernetes_service = var.use_existing_ingress == true ? data.kubernetes_service.helm_ingress_existing[0] : data.kubernetes_service.ingress[0]
  # if not using an ingress the aws_elb should point to the loadbalancer
  aws_elb = var.use_existing_ingress == true ? data.aws_elb.helm_ingress_existing[0] : data.aws_elb.ingress[0]
}

output "kubernetes_service" {
  value = local.kubernetes_service
}

output "aws_elb" {
  value = local.aws_elb
}

#######################################################
# Cluster Issuer
# If installing a new ingress we probably want
# a new cluster issuer too
#######################################################

locals {
  ingress_template        = length(var.ingress_template) > 0 ? var.ingress_template : "${path.module}/helm_charts/bitnami/ingress.yaml.tpl"
  cluster_issuer_template = length(var.cluster_issuer_template) > 0 ? var.cluster_issuer_template : "${path.module}/helm_charts/cluster-issuer.yaml.tpl"
}

output "ingress_template_path" {
  value = local.ingress_template
}

output "cluster_issuer_template_path" {
  value = local.cluster_issuer_template
}

data "template_file" "cluster_issuer" {
  count    = var.render_cluster_issuer == true ? 1 : 0
  template = file(local.cluster_issuer_template)
  vars = {
    name              = trimspace(var.helm_release_name)
    letsencrypt_email = trimspace(var.letsencrypt_email)
  }
}

resource "local_file" "cluster_issuer" {
  count = var.render_cluster_issuer == true ? 1 : 0
  depends_on = [
    data.template_file.cluster_issuer
  ]
  content  = data.template_file.cluster_issuer[0].rendered
  filename = "${var.helm_release_values_dir}/cluster-issuer.yaml"
}

resource "null_resource" "kubectl_apply_cluster_issuer" {
  count = var.render_cluster_issuer == true ? 1 : 0
  depends_on = [
    local_file.cluster_issuer
  ]
  provisioner "local-exec" {
    command = <<EOT
     mkdir -p ${var.helm_release_values_dir}
     kubectl apply -f ${var.helm_release_values_dir}/cluster-issuer.yaml
     EOT
  }
}
