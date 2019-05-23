provider "kubernetes" {
  config_context_auth_info  = "${var.config_context_auth_info}"
  config_context_cluster    = "${var.config_context_cluster}"
}

provider "helm" {
  install_tiller  = true
  namespace       = "kube-system"
  service_account = "tiller"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.11.0"
}

provider "google" {
  version     = "~> 2.2"
  region      = "${var.region}"
  zone        = "${var.zone}"
  project     = "${var.project_id}"
}

provider "aws" {
  region                    = "${var.region_aws}"
  shared_credentials_file   = "${var.aws_credentials_file}"
  profile                   = "${var.aws_profile}"
}

data "helm_repository" "legion" {
    name = "legion_github"
    url  = "${var.legion_helm_repo}"
}

########################################################
# K8S Cluster Setup
########################################################
data "aws_s3_bucket_object" "tls-secret-key" {
  bucket = "${var.secrets_storage}"
  key    = "${var.cluster_name}/tls/${var.cluster_name}.key"
}

data "aws_s3_bucket_object" "tls-secret-crt" {
  bucket   = "${var.secrets_storage}"
  key      = "${var.cluster_name}/tls/${var.cluster_name}.fullchain.crt"
}

# Install TLS cert as a secret
resource "kubernetes_secret" "tls_default" {
  count   = "${length(var.tls_namespaces)}"
  metadata {
    name        = "${var.cluster_name}-tls"
    namespace   = "${element(var.tls_namespaces, count.index)}"
  }
  data {
    "tls.key"   = "${data.aws_s3_bucket_object.tls-secret-key.body}}"
    "tls.crt"   = "${data.aws_s3_bucket_object.tls-secret-crt.body}}"
  }
  type          = "kubernetes.io/tls"
}

########################################################
# Nginx Ingress
########################################################
resource "google_compute_address" "ingress_lb_address" {
  name              = "${var.cluster_name}-ingress-main"
  region            = "${var.region}"
  address_type      = "EXTERNAL"
}

resource "google_dns_record_set" "ingress_lb" {
  name          = "*.${var.cluster_name}.${var.root_domain}."
  type          = "A"
  ttl           = 300
  managed_zone  = "${var.dns_zone_name}"
  rrdatas       = ["${google_compute_address.ingress_lb_address.address}"]
}

resource "helm_release" "nginx-ingress" {
    name        = "nginx-ingress"
    chart       = "stable/nginx-ingress"
    namespace   = "kube-system"
    version     = "0.20.1"
    set {
        name    = "controller.service.loadBalancerSourceRanges"
        value   = "{${join(",", var.allowed_ips)}}"
    }
    set {
        name    = "defaultBackend.service.loadBalancerSourceRanges"
        value   = "{${join(",", var.allowed_ips)}}"
    }
    set {
      name      = "defaultBackend.service.type"
      value     = "LoadBalancer"
    }
    set {
      name      = "controller.service.loadBalancerIP"
      value     = "${google_compute_address.ingress_lb_address.address}"
    }
    depends_on  = ["google_compute_address.ingress_lb_address"]
}

########################################################
# Kubernetes Dashboard
########################################################
data "template_file" "dashboard_values" {
  template = "${file("${path.module}/templates/dashboard-ingress.yaml")}"
  vars = {
    cluster_name              = "${var.cluster_name}"
    root_domain               = "${var.root_domain}"
    dashboard_tls_secret_name = "${var.dashboard_tls_secret_name}"
  }
}

resource "helm_release" "kubernetes-dashboard" {
    name      = "kubernetes-dashboard"
    chart     = "stable/kubernetes-dashboard"
    namespace = "kube-system"
    version   = "0.6.8"
    values = [
      "${data.template_file.dashboard_values.rendered}"
    ]
}

resource "kubernetes_secret" "tls_dashboard" {
  metadata {
    name        = "${var.dashboard_tls_secret_name}"
    namespace   = "kube-system"
  }
  data {
    "tls.key"   = "${data.aws_s3_bucket_object.tls-secret-key.body}}"
    "tls.crt"   = "${data.aws_s3_bucket_object.tls-secret-crt.body}}"
  }
  type          = "kubernetes.io/tls"
}

########################################################
# Auth setup
########################################################

# Dex
# TODO: set dex dns automtically (now should be updated manually)
# resource "google_compute_address" "dex_lb_address" {
#   name              = "${var.cluster_name}-dex"
#   region            = "${var.region}"
#   address_type      = "EXTERNAL"
# }

# resource "google_dns_record_set" "dex_lb" {
#   name          = "dex.${var.cluster_name}.${var.root_domain}."
#   type          = "A"
#   ttl           = 300
#   managed_zone  = "${var.dns_zone_name}"
#   rrdatas       = ["${google_compute_address.dex_lb_address.address}"]
# }


data "template_file" "dex_values" {
  template = "${file("${path.module}/templates/dex.yaml")}"
  vars = {
    cluster_name              = "${var.cluster_name}"
    root_domain               = "${var.root_domain}"
    dex_replicas              = "${var.dex_replicas}"
    dex_github_clientid       = "${var.dex_github_clientid}"
    dex_github_clientSecret   = "${var.dex_github_clientSecret}"
    github_org_name           = "${var.github_org_name}"
    dex_client_id             = "${var.dex_client_id}"
    dex_client_secret         = "${var.dex_client_secret}"
    dex_static_user_email     = "${var.dex_static_user_email}"
    dex_static_user_pass      = "${var.dex_static_user_pass}"
    dex_static_user_hash      = "${var.dex_static_user_hash}"
    dex_static_user_name      = "${var.dex_static_user_name}"
    dex_static_user_id        = "${var.dex_static_user_id}"
  }
}

resource "helm_release" "dex" {
    name        = "dex"
    chart       = "legion_github/dex"
    version     = "${var.legion_infra_version}"
    namespace   = "kube-system"
    repository  = "${data.helm_repository.legion.metadata.0.name}"

    values = [
      "${data.template_file.dex_values.rendered}"
    ]
}

# Oauth2 proxy
data "template_file" "oauth2-proxy_values" {
  template = "${file("${path.module}/templates/oauth2-proxy.yaml")}"
  vars = {
    cluster_name              = "${var.cluster_name}"
    root_domain               = "${var.root_domain}"
    dex_client_id             = "${var.dex_client_id}"
    dex_client_secret         = "${var.dex_client_secret}"
    dex_cookie_expire         = "${var.dex_cookie_expire}"
  }
}

resource "helm_release" "oauth2-proxy" {
    name        = "oauth2-proxy"
    chart       = "legion_github/oauth2-proxy"
    version     = "${var.legion_infra_version}"
    namespace   = "kube-system"
    repository  = "${data.helm_repository.legion.metadata.0.name}"

    values = [
      "${data.template_file.oauth2-proxy_values.rendered}"
    ]
}

resource "helm_release" "oauth2-proxy" {
    name        = "oauth2-proxy"
    chart       = "legion_github/oauth2-proxy"
    version     = "${var.legion_infra_version}"
    namespace   = "kube-system"
    repository  = "${data.helm_repository.legion.metadata.0.name}"

    values = [
      "${data.template_file.oauth2-proxy_values.rendered}"
    ]
}

# Keycloak sso
data "helm_repository" "codecentric" {
    name = "codecentric"
    url  = "${var.codecentric_helm_repo}"
}

data "template_file" "keycloak_values" {
  template = "${file("${path.module}/templates/keycloak.yaml")}"
  vars = {
    cluster_name              = "${var.cluster_name}"
    root_domain               = "${var.root_domain}"
    keycloak_admin_user       = "${var.keycloak_admin_user}"
    keycloak_admin_pass       = "${var.keycloak_admin_pass}"
    keycloak_db_user          = "${var.keycloak_db_user}"
    keycloak_db_pass          = "${var.keycloak_db_pass}"
    keycloak_pg_user          = "${var.keycloak_pg_user}"
    keycloak_pg_pass          = "${var.keycloak_pg_pass}"
  }
}

resource "helm_release" "keycloak" {
    name        = "keycloak"
    chart       = "codecentric/keycloak"
    version     = "4.14.0"
    namespace   = "kube-system"
    repository  = "${data.helm_repository.codecentric.metadata.0.name}"

    values = [
      "${data.template_file.keycloak_values.rendered}"
    ]
}

# # Keycloak gatekeeper proxy
# data "helm_repository" "gatekeeper" {
#     name = "gabibbo97"
#     url  = "${var.gatekeeper_helm_repo}"
# }

# data "template_file" "gatekeeper_values" {
#   template = "${file("${path.module}/templates/gatekeeper.yaml")}"
#   vars = {
#     cluster_name              = "${var.cluster_name}"
#     root_domain               = "${var.root_domain}"
#   }
# }

# resource "helm_release" "gatekeeper" {
#     name        = "keycloak-gatekeeper"
#     chart       = "gabibbo97/keycloak-gatekeeper"
#     version     = "1.2.1"
#     namespace   = "kube-system"
#     repository  = "${data.helm_repository.gatekeeper.metadata.0.name}"

#     values = [
#       "${data.template_file.gatekeeper_values.rendered}"
#     ]
# }

########################################################
# Prometheus monitoring
########################################################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations {
      name = "${var.monitoring_namespace}"
    }
    labels {
      project         = "legion"
      k8s-component   = "monitoring"
    }
    name = "${var.monitoring_namespace}"
  }
}

# TODO: consider optional custom storage class for the cluster
# resource "kubernetes_storage_class" "pd_standard" {
#   metadata {
#     name = "${var.grafana_storage_class}"
#   }
#   storage_provisioner = "kubernetes.io/gce-pd"
#   reclaim_policy = "Retain"
#   parameters {
#     type = "${var.grafana_storage_class}"
#     zone = "${var.zone}"
#   }
# }

resource "kubernetes_secret" "tls_monitoring" {
  metadata {
    name        = "${var.cluster_name}-tls"
    namespace   = "${var.monitoring_namespace}"
  }
  data {
    "tls.key"   = "${data.aws_s3_bucket_object.tls-secret-key.body}"
    "tls.crt"   = "${data.aws_s3_bucket_object.tls-secret-crt.body}}"
  }
  type          = "kubernetes.io/tls"
  depends_on    = ["kubernetes_namespace.monitoring"]
}

# TODO: replace raw exec after terraform crd resource release
resource "null_resource" "prometheus_crd_alertmanager" {
  count   = "${length(var.prometheus_crds)}"
  provisioner "local-exec" {
    command = "kubectl --context ${var.cluster_context} apply -f ${var.monitoring_prometheus_operator_crd_url}/${element(var.prometheus_crds, count.index)}.crd.yaml"
  }
}

data "template_file" "monitoring_values" {
  template = "${file("${path.module}/templates/monitoring.yaml")}"
  vars = {
    monitoring_namespace      = "${var.monitoring_namespace}"
    legion_infra_version      = "${var.legion_infra_version}"
    cluster_name              = "${var.cluster_name}"
    root_domain               = "${var.root_domain}"
    docker_repo               = "${var.docker_repo}"
    alert_slack_url           = "${var.alert_slack_url}"
    grafana_admin             = "${var.grafana_admin}"
    grafana_pass              = "${var.grafana_pass}"
    grafana_storage_class     = "${var.grafana_storage_class}"
  }
}

resource "helm_release" "monitoring" {
    name        = "monitoring"
    chart       = "monitoring"
    version     = "${var.legion_infra_version}"
    namespace   = "${var.monitoring_namespace}"
    repository  = "${data.helm_repository.legion.metadata.0.name}"

    values = [
      "${data.template_file.monitoring_values.rendered}"
    ]
}
