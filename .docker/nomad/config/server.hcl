datacenter = "dc1"
# data_dir = "/nomad/data/"
# data_dir  = "/var/lib/nomad"

bind_addr = "nomad_in_docker"

advertise {
  http = "nomad_in_docker:4646"
  rpc  = "nomad_in_docker:4647"
  serf = "nomad_in_docker:4648"
}

consul {
  address             = "consul_server:8500"
  # имя сервиса в консуле
  server_service_name = "nomad-1-server"
  client_service_name = "nomad-1-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}

server {
  enabled = true
  bootstrap_expect = 1

  ////encrypt gossip communication (openssl rand -base64 16)
  //encrypt = "QunAVaCIiKAfgASyWGtLYw=="
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

client {
  enabled = true
  ////может быть и в server{}
  //server_join {
  //  retry_join = ["consul_server"]
  //}
}
