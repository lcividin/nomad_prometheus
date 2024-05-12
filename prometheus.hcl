job "prometheus" {
  datacenters = ["dc1"]
  type = "service"

  group "prometheus" {
    count = 1

    task "server" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.29.1"
        ports = ["http"]
      }

      template {
        data = <<EOH
        global:
          scrape_interval: 15s
        scrape_configs:
          - job_name: 'consul-services'
            consul_sd_configs:
              - server: '{{ env "NOMAD_IP_http" }}:8500'
                services: []
        EOH
        destination = "local/prometheus.yml"
      }

      resources {
        cpu    = 500
        memory = 1024
        network {
          mbits = 10
          port "http" {
            static = 9090
          }
        }
      }

      service {
        name = "prometheus"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.prometheus.rule=Host(`grafana.suburbansystems.com`)",
          "traefik.http.routers.prometheus.entrypoints=https",
          "traefik.http.routers.prometheus.tls.certresolver=myresolver",
          "traefik.http.services.prometheus.loadbalancer.server.port=${NOMAD_PORT_http}"
        ]
        port = "http"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
