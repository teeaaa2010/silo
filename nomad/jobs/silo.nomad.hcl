# Single-node Silo (S3 backend) as a plain Nomad job.
# Deploy: nomad job run -var "silo_image=<repo>:<tag>@<digest>" nomad/jobs/silo.nomad.hcl
variable "silo_image" {
  type        = string
  description = "Pinned image reference, tag plus digest"
}

variable "node_name" {
  type    = string
  default = "nomad-main" # node that owns the silo-data host volume
}

job "silo" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.unique.name}"
    value     = var.node_name
  }

  group "silo" {
    count = 1

    network {
      port "api" {
        static = 9000
      }
      port "console" {
        static = 9001
      }
    }

    volume "data" {
      type      = "host"
      source    = "silo-data"
      read_only = false
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    service {
      name     = "silo-api"
      port     = "api"
      provider = "nomad"

      check {
        name     = "silo-live"
        type     = "http"
        path     = "/minio/health/live"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "silo" {
      driver = "docker"

      config {
        image = var.silo_image
        args  = ["server", "/data", "--console-address", ":9001"]
        ports = ["api", "console"]
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      # Root credentials come from the Nomad variable nomad/jobs/silo
      # (created by scripts/init-secrets.sh); nothing secret lives in git.
      template {
        destination = "secrets/silo.env"
        env         = true
        data        = <<EOT
{{ with nomadVar "nomad/jobs/silo" }}
MINIO_ROOT_USER={{ .root_user }}
MINIO_ROOT_PASSWORD={{ .root_password }}
{{ end }}
EOT
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
