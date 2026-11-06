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



    # Grafana alert rules (SOAR detection)
    mkdir -p /etc/grafana/provisioning/alerting
    cat > /etc/grafana/provisioning/alerting/ssh-bruteforce.yaml <<'YAML'
    apiVersion: 1
    groups:
      - orgId: 1
        name: ssh
        folder: SOAR
        interval: 1m
        rules:
          - uid: dg3f454xg4d8gc
            title: SSH bruteforce
            condition: C
            data:
              - refId: A
                queryType: instant
                relativeTimeRange:
                  from: 600
                  to: 0
                datasourceUid: loki
                model:
                  editorMode: code
                  expr: |-
                    sum by (host, src_ip) (
                      count_over_time(
                        {job="journal", app=~"sshd|sshd-session"}
                          |= "Failed password"
                          | regexp `from (?P<src_ip>\d+\.\d+\.\d+\.\d+)`
                        [10m]
                      )
                    )
                  instant: true
                  queryType: instant
                  refId: A
              - refId: C
                queryType: expression
                datasourceUid: __expr__
                model:
                  type: threshold
                  expression: A
                  refId: C
                  datasource:
                    type: __expr__
                    uid: __expr__
                  conditions:
                    - type: query
                      evaluator:
                        type: gt
                        params: [5]
                      operator:
                        type: and
                      query:
                        params: [C]
                      reducer:
                        type: last
                        params: []
            noDataState: OK
            execErrState: Error
            keepFiringFor: 5m
            annotations:
              summary: SSH brute force from {{ $labels.src_ip }} against {{ $labels.host }}
              description: "{{ $values.A.Value }} failed SSH logins in the last 10 minutes from {{ $labels.src_ip }} to {{ $labels.host }}."
            labels:
              playbook: ssh_bruteforce
              severity: high
            isPaused: false
            notification_settings:
              receiver: soar-sns
              group_by: ['alertname', 'src_ip']
              group_wait: 10s
              group_interval: 1m
              repeat_interval: 4h

    YAML



    # Grafana notification template: JSON message for email + Lambda
    cat > /etc/grafana/provisioning/alerting/templates.yaml <<'YAML'
    apiVersion: 1
    templates:
      - orgId: 1
        name: soar
        template: |
          {{ define "soar.subject" }}[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }} {{ .CommonLabels.src_ip }}{{ end }}

          {{ define "soar.message" -}}
          {
            "status": "{{ .Status }}",
            "alerts": [
          {{- range $i, $a := .Alerts }}{{ if $i }},{{ end }}
              {
                "status": "{{ $a.Status }}",
                "alertname": "{{ $a.Labels.alertname }}",
                "playbook": "{{ $a.Labels.playbook }}",
                "severity": "{{ $a.Labels.severity }}",
                "src_ip": "{{ $a.Labels.src_ip }}",
                "host": "{{ $a.Labels.host }}",
                "summary": "{{ $a.Annotations.summary }}",
                "description": "{{ $a.Annotations.description }}",
                "starts_at": "{{ $a.StartsAt.Format "2006-01-02T15:04:05Z07:00" }}",
                "fingerprint": "{{ $a.Fingerprint }}"
              }
          {{- end }}
            ]
          }
          {{- end }}
    YAML

     


    # Grafana contact point: publish alerts to the SOAR SNS topic
    cat > /etc/grafana/provisioning/alerting/contact-points.yaml <<'YAML'
    apiVersion: 1
    contactPoints:
      - orgId: 1
        name: soar-sns
        receivers:
          - uid: ag3f9r87pbncwb
            type: sns
            settings:
              sigv4:
                region: eu-central-1
              topic_arn: ${var.soar_alerts_topic_arn}
              subject: '{{ template "soar.subject" . }}'
              message: '{{ template "soar.message" . }}'
            disableResolveMessage: false
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
