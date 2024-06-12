locals {
  cockroachdb_labels = { "app" = "cockroachdb" }
}

resource "kubernetes_stateful_set" "cockroachdb" {
  metadata {
    namespace = var.cockroachdb_namespace
    name      = "cockroachdb"
    labels    = locals.cockroachdb_labels
  }

  spec {
    service_name          = "cockroachdb"
    replicas              = 3
    pod_management_policy = "Parallel"

    selector {
      match_labels = locals.cockroachdb_labels
    }

    template {
      metadata {
        labels = locals.cockroachdb_labels
      }

      spec {
        termination_grace_period_seconds = 60

        container {
          name              = "cockroachdb"
          image             = var.cockroachdb_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 26257
            name           = "grpc"
          }

          port {
            container_port = 8080
            name           = "http"
          }

          readiness_probe {
            http_get {
              path = "/health?ready=1"
              port = "http"
            }

            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 2
          }

          volume_mount {
            name       = "datadir"
            mount_path = "/cockroach/cockroach-data"
          }

          env {
            name  = "COCKROACH_CHANNEL"
            value = "kubernetes-insecure"
          }

          command = [
            "/bin/bash",
            "-ecx",
            "exec /cockroach/cockroach start --logtostderr --insecure --advertise-host $(hostname -f) --http-addr 0.0.0.0 --join cockroachdb-0.cockroachdb,cockroachdb-1.cockroachdb,cockroachdb-2.cockroachdb --cache 25% --max-sql-memory 25%"
          ]
        }

        volume {
          name = "datadir"

          persistent_volume_claim {
            claim_name = "datadir"
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"
    }

    volume_claim_template {
      metadata {
        name = "datadir"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            "storage" = var.cockroachdb_storage
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cockroachdb_public" {
  metadata {
    namespace = var.cockroachdb_namespace
    name      = "cockroachdb"
    labels    = locals.cockroachdb_labels
  }

  spec {
    port {
      name        = "grpc"
      port        = 26257
      target_port = "grpc"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = "http"
    }

    selector = locals.cockroachdb_labels
  }
}

resource "kubernetes_service" "cockroachdb" {
  metadata {
    namespace = var.cockroachdb_namespace
    name      = "cockroachdb"
    labels    = locals.cockroachdb_labels
    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true"
    }
  }

  spec {
    port {
      name        = "grpc"
      port        = 26257
      target_port = "grpc"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = "http"
    }

    publish_not_ready_addresses = true
    cluster_ip                  = "None"
    selector                    = locals.cockroachdb_labels
  }
}

resource "kubernetes_pod_disruption_budget" "cockroachdb" {
  metadata {
    namespace = var.cockroachdb_namespace
    name      = "cockroachdb"
    labels    = locals.cockroachdb_labels
  }

  spec {
    max_unavailable = 1

    selector {
      match_labels = locals.cockroachdb_labels
    }
  }
}
