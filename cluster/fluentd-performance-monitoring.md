## add metrics to our fluentd config

```yaml
# Input: Tail logs from Kubernetes container log files
<source>
  @type tail
  path /var/log/res/1.log
  pos_file /var/log/fluentd/cursor/k8s.log.pos
  tag kubernetes.logs
  read_from_head true
  <parse>
    @type cri
    merge_cri_fields false
    <parse>
      @type json
    </parse>
  </parse>
</source>

#expose prometheus HTTP
<source>
  @type prometheus
  bind 0.0.0.0
  port 24231
  metrics_path /metrics
</source>

<source>
  @type prometheus_output_monitor
  interval 10
  <labels>
    hostname ${hostname}
  </labels>
</source>


#filter for metrics
<filter kubernetes.logs>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records from 1log
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</filter>
<source>                                                                                                                                                                                             [61/1640]
  @type tail
  path /var/log/res/2.log
  pos_file /var/log/fluentd/cursor/k8s2.log.pos
  tag kuber.logs.second
  read_from_head true
  <parse>
    @type cri
    merge_cri_fields false
    <parse>
      @type json
    </parse>
  </parse>
</source>

#filter for metrics
<filter kuber.logs.second>
  @type prometheus
  <metric>
    name fluentd_input_status_num_records_total
    type counter
    desc The total number of incoming records from 2nd app
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</filter>

#<filter kubernetes.logs>
#  @type record_transformer
#  <record>
#    hostname "#{Socket.gethostname}"
#  </record>
#</filter>

<filter kubernetes.logs*>
  @type stdout
</filter>

<match kubernetes.logs>
  @type copy
  <store>
  @type forward
  <server>
    host 192.168.1.104  # Replace with the target Fluentd server IP
    port 24224          # Default Fluentd forward port
  </server>
  <buffer>
    @type memory
    flush_interval 5s
  </buffer>
  </store>
  <store>
  @type file
  path /var/log/res/k8s.log
  <buffer>
    @type file
    path /var/log/fluentd/buffer
    flush_interval 10s
  </buffer>
  <format>
    @type json
  </format>
</store>
<store>
  @type prometheus
  <metric>
    name fluentd_output_status_num_records_total
    type counter
    desc The total number of outgoing records for first app
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</store>
</match>

<match kuber.logs.second>
  @type copy
  <store>
  @type forward
  <server>
    host 192.168.1.104  # Replace with the target Fluentd server IP
    port 24224          # Default Fluentd forward port
  </server>
  <buffer>
    @type memory
    flush_interval 5s
  </buffer>
  </store>
  <store>
  @type file
  path /var/log/res/k8s-second.log
  <buffer>
    @type file
    path /var/log/fluentd/buffer-second
    flush_interval 10s
  </buffer>
  <format>
    @type json
  </format>
</store>
<store>
  @type prometheus
  <metric>
    name fluentd_output_status_num_records_total
    type counter
    desc The total number of outgoing records for second app
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
</store>
</match>
```

and this `prometheus.yaml` file:

```yaml
global:
  scrape_interval: 10s # Set the scrape interval to every 10 seconds. Default is every 1 minute.

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'fluentd'
    static_configs:
      - targets: ['localhost:24231']
```
