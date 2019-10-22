variable "legion_helm_repo" {
  description = "Legion helm repo"
}

variable "istio_helm_repo" {
  description = "Istio helm repo"
}

variable "tiller_image" {
  default = "gcr.io/kubernetes-helm/tiller:v2.15.0"
}
