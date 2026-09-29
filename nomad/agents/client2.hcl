# Second client on the same machine: own data dir, own ports (node name: nomad-client2)
name      = "nomad-client2"
data_dir  = "/opt/silo-nomad/client2"
log_level = "INFO"
bind_addr = "0.0.0.0"

ports {
  http = 5646
  rpc  = 5647
  serf = 5648
}

client {
  enabled          = true
  servers          = ["127.0.0.1:4647"]
  min_dynamic_port = 25000
  max_dynamic_port = 29999
}

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
  }
}
