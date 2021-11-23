terraform {
  required_providers {
    kubernetes = {}
    helm       = {}
  }
}

resource "kubernetes_secret" "codeserver_secret" {
  metadata {
    name      = "codeserver-password"
    namespace = "develop"
  }

  data = {
    password = random_password.code_server_password.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "aws_secretsmanager_secret" "code_server_secret" {
  name                    = "code_server"
  recovery_window_in_days = 0
}

resource "random_password" "code_server_password" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret_version" "code_server_secret_version" {
  secret_id     = aws_secretsmanager_secret.code_server_secret.id
  secret_string = "{\"password\": \"${random_password.code_server_password.result}\"}"
}

resource "helm_release" "code_server" {
  name             = "code-server"
  chart            = var.helm_chart_name
  namespace        = var.namespace
  repository       = var.helm_chart
  timeout          = var.helm_timeout
  version          = var.helm_version
  create_namespace = false
  reset_values     = false

  set {
    name  = "image.tag"
    value = "3.9.3-r1-alpine"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "app.env.PASSWORD"
    value = random_password.code_server_password.result
  }
}

resource "kubernetes_ingress" "ingress" {

  wait_for_load_balancer = true

  metadata {
    name      = "code-server"
    namespace = "develop"

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = "cert-manager"
    }
  }
  spec {
    rule {

      host = "code-server.${var.dns_zone}"

      http {
        path {
          path = "/"
          backend {
            service_name = "code-server"
            service_port = 80
          }
        }
      }
    }

    tls {
      secret_name = "code-server-tls-secret"
    }
  }

  depends_on = [
    helm_release.code_server,
  ]
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.code_server,
  ]
}

data "aws_route53_zone" "vpc" {
  name = var.dns_zone
}

resource "aws_route53_record" "code_server_cname" {
  zone_id = data.aws_route53_zone.vpc.zone_id
  name    = "code-server.${var.dns_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [
    helm_release.code_server
  ]
}

