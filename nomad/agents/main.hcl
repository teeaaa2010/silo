# Main agent: server + client #1 (node name: nomad-main)
name      = "nomad-main"
data_dir  = "/opt/silo-nomad/main"
log_level = "INFO"
bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled          = true
  min_dynamic_port = 20000
  max_dynamic_port = 24999

  # Host volume that backs Silo's /data
  host_volume "silo-data" {
    path      = "/opt/silo-nomad/silo-data"
    read_only = false
  }
}

plugin "docker" {
  config {
    allow_privileged = true # CSI node plugins (later sub-tasks) need this
    volumes {
      enabled = true
    }
  }
}
