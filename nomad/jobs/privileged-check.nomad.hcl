# Runs a privileged container on every client. It only gets placed and completes
# when the Docker driver has allow_privileged = true, so it is functional proof.
variable "image" {
  type    = string
  default = "busybox:1.36.1"
}

job "privileged-check" {
  datacenters = ["dc1"]
  type        = "sysbatch"

  group "check" {
    task "priv" {
      driver = "docker"

      config {
        image      = var.image
        privileged = true
        command    = "sh"
        args       = ["-c", "echo privileged-container-ok on $(hostname); grep CapEff /proc/self/status"]
      }

      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
