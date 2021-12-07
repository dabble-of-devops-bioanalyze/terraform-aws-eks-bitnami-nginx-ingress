resource "helm_release" "ingress" {
  name             = "${var.helm_release_name}-ingress"
  repository       = var.helm_release_repository
  chart            = var.helm_release_chart
  namespace        = var.helm_release_namespace
  create_namespace = var.helm_release_create_namespace
  wait             = var.helm_release_wait
}

data "kubernetes_service" "ingress" {
  depends_on = [
    helm_release.ingress,
  ]
  metadata {
    name      = "${var.helm_release_name}-ingress-nginx-ingress-controller"
    namespace = var.helm_release_namespace
  }
}

data "aws_elb" "ingress" {
  depends_on = [
    helm_release.ingress,
    data.kubernetes_service.ingress
  ]
  name = split("-", data.kubernetes_service.ingress.status.0.load_balancer.0.ingress.0.hostname)[0]
}


data "template_file" "cluster_issuer" {
  template = file("${path.module}/cluster-issuer.yaml.tpl")
  vars = {
    name              = var.helm_release_name
    letsencrypt_email = var.letsencrypt_email
  }
}

resource "local_file" "cluster_issuer" {
  count = var.render_cluster_issuer == true ? 1 : 0
  depends_on = [
    data.template_file.cluster_issuer
  ]
  content  = data.template_file.cluster_issuer.rendered
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
