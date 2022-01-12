variable "region" {
  type = string
  default = "us-east-2"
}

variable "eks_node_groups" {
  type = list(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    name           = string
  }))
  description = "EKS Node Groups"
  default = [
    {
      name           = "node-group-1"
      instance_types = ["t3a.medium", "t3a.large"]
      desired_size   = 1
      min_size       = 0
      max_size       = 3
      disk_size      = 20
    }
  ]
}


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
