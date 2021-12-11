##################################################
# Helm Release Variables - General
# corresponds to input to resource "helm_release"
##################################################

variable "helm_release_name" {
  type        = string
  description = "helm release name"
  default     = "ingress"
}

variable "helm_release_repository" {
  type        = string
  description = "helm release chart repository"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "helm_release_chart" {
  type        = string
  description = "helm release chart"
  default     = "nginx-ingress-controller"
}

variable "helm_release_namespace" {
  type        = string
  description = "helm release namespace"
  default     = "default"
}

variable "helm_release_version" {
  type        = string
  description = "helm release version"
  default     = "7.6.21"
}

variable "helm_release_wait" {
  type    = bool
  default = true
}

variable "helm_release_create_namespace" {
  type    = bool
  default = true
}

variable "helm_release_values_dir" {
  type        = string
  description = "Directory to put rendered values template files or additional keys. Should be helm_charts/{helm_release_name}"
  default     = "helm_charts"
}

variable "helm_release_values_files" {
  type        = list(string)
  description = "helm release values files - paths values files to add to helm install --values {}"
  default     = []
}

##################################################
# Helm Release Variables - Enable SSL
# corresponds to input to resource "helm_release"
##################################################

variable "enable_ssl" {
  description = "Enable SSL Support?"
  type        = bool
  default     = true
}

# these variables are only needed if enable_ssl == true

variable "letsencrypt_email" {
  type        = string
  description = "Email to use for https setup. Not needed unless enable_ssl"
  default     = "hello@gmail.com"
}

variable "aws_route53_zone_name" {
  type        = string
  description = "Name of the zone to add records. Do not forget the trailing '.' - 'test.com.'"
  default     = "test.com."
}

variable "aws_route53_record_name" {
  type        = string
  description = "Record name to add to aws_route_53. Must be a valid subdomain - www,app,etc"
  default     = "www"
}

variable "render_cluster_issuer" {
  type        = bool
  description = "Create a cluster-issuer.yaml file"
  default     = true
}

variable "install_ingress" {
  description = "Install the ingress. You generally won't do this directly, as it is done when bootstrapping a cluster."
  type    = bool
  default = false
}

variable "use_existing_ingress" {
  type        = bool
  description = "Use existing ingress"
  default     = true
}

variable "render_ingress" {
  type        = bool
  default     = true
  description = "Render ingress.yaml file - only useful if installing an additional service such as nginx"
}

variable "existing_ingress_name" {
  type        = string
  description = "Existing ingress release name"
  default     = "nginx-ingress-ingress-nginx-ingress-controller"
}

variable "existing_ingress_namespace" {
  type        = string
  description = "Existing ingress release namespace"
  default     = "default"
}

##################################################
# Template file paths
# Default is "", which will use the local templates
# Otherwise, supply a template path
##################################################

variable "ingress_template" {
  type        = string
  description = "Path to ingress template. Ingress compatible with bitnami is given."
  default     = ""
}

variable "cluster_issuer_template" {
  type        = string
  description = "Path to cluster issuer template. Default cluster issuer is supplied."
  default     = ""
}