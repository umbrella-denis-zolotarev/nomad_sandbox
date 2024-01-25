job "job-nginx" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"

  group "group-webs" {
    # number of tasks
    count = 1

    network {
      port "http" {
        static = 80
      }
    }

    service {
      name = "service-nginx"
      tags = ["nginx-tag", "urlprefix-/"]
      address = "host.docker.internal"
      port = "http"

      check {
        type = "tcp"
        name = "service group-webs-nginx check"
        path = "/"
        interval = "10s"
        timeout = "2s"
      }
    }

    task "task-docker-nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }
  }
}
