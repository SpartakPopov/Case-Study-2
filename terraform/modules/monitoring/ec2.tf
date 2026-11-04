data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.monitoring_subnet_id
  private_ip                  = var.private_ip
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # wait until internet works (TGW -> DMZ NAT may still be coming up)
    until curl -fsS https://apt.grafana.com/gpg.key -o /tmp/grafana.key; do sleep 10; done

    # Grafana apt repo (same one the on-prem Alloy hosts use)
    apt-get update -y
    apt-get install -y gpg
    mkdir -p /etc/apt/keyrings
    gpg --dearmor -o /etc/apt/keyrings/grafana.gpg /tmp/grafana.key
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
    apt-get update -y
    apt-get install -y loki grafana prometheus

    # Loki: single node, chunks + index on local disk
    mkdir -p /var/lib/loki
    chown loki /var/lib/loki
    cat > /etc/loki/config.yml <<'YAML'
    auth_enabled: false

    server:
      http_listen_port: 3100
      grpc_listen_port: 9096

    common:
      instance_addr: 127.0.0.1
      path_prefix: /var/lib/loki
      storage:
        filesystem:
          chunks_directory: /var/lib/loki/chunks
          rules_directory: /var/lib/loki/rules
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    schema_config:
      configs:
        - from: 2024-01-01
          store: tsdb
          object_store: filesystem
          schema: v13
          index:
            prefix: index_
            period: 24h
    YAML


    # Prometheus: accept pushed metrics from the on-prem collector
    cat > /etc/prometheus/prometheus.yml <<'YAML'
    global:
      scrape_interval: 30s

    storage:
      tsdb:
        out_of_order_time_window: 1h

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets: ["localhost:9090"]
      - job_name: monitoring-node
        static_configs:
          - targets: ["localhost:9100"]
    YAML

    echo 'ARGS="--web.enable-remote-write-receiver --storage.tsdb.retention.time=7d"' > /etc/default/prometheus


        # Grafana: Loki + Prometheus as data sources
    cat > /etc/grafana/provisioning/datasources/datasources.yaml <<'YAML'
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        uid: loki
        access: proxy
        url: http://localhost:3100
        isDefault: true
      - name: Prometheus
        type: prometheus
        uid: prometheus
        access: proxy
        url: http://localhost:9090
    YAML


    systemctl enable loki grafana-server prometheus
    systemctl restart loki grafana-server prometheus

  EOF

  tags = {
    Name = "innovatech-monitoring"
  }
}

resource "aws_route53_record" "loki" {
  zone_id = var.zone_id
  name    = "loki"
  type    = "A"
  ttl     = 60
  records = [aws_instance.monitoring.private_ip]
}

resource "aws_route53_record" "grafana" {
  zone_id = var.zone_id
  name    = "grafana"
  type    = "A"
  ttl     = 60
  records = [aws_instance.monitoring.private_ip]
}
