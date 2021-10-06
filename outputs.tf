output "cluster_issuer_yaml_file" {
  description = "Location of the cluster-issuer.yaml file"
  value       = abspath("${var.helm_release_values_dir}/cluster-issuer.yaml")
}

output "kubernetes_service_ingress" {
  description = "Kubernetes Services Ingress"
  value       = data.kubernetes_service.ingress
}

output "aws_elb_ingress" {
  description = "AWS ELB of the ingress"
  value       = data.aws_elb.ingress
}

output "helm_release" {
  description = "helm release"
  value       = helm_release.ingress
}

output "helm_release_name" {
  description = "Release name given to the ingress release"
  value       = helm_release.ingress.name
}
