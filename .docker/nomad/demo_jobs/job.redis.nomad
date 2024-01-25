job "job-redis" {
  datacenters = ["dc1"]

  group "cache" {
    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7"
        ports = ["db"]
      }

      // пример переменных окружения
      //env {
      //  DB_HOST = "db01.example.com"
      //}

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }

      service {
        name = "weave-redis"
        port = "db"
        address = "host.docker.internal"

        check {
          name     = "host-redis-check"
          type     = "tcp"
          port     = "db"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
