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
