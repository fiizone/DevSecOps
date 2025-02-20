syslog for k8sevents

```yaml
#<source>
#  @type syslog
#  port 514
#  bind 0.0.0.0
#  tag k8sEvents
#  protocol_type udp
#</source>

<source>
  @type udp
  port 514
  bind 0.0.0.0
  tag k8sEvents
  <parse>
    @type regexp
    expression /<(?<priority>\d+)>(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z) (?<hostname>[^ ]+) (?<tag>[^:]+): (?<message>.*)/
    time_key timestamp
    time_format %Y-%m-%dT%H:%M:%SZ
  </parse>
</source>


<match k8sEvents.**>
  @type remote_syslog
  host 192.168.72.166
  port 514
  severity info
  program '"component"="k8sEvents"'
  hostname ${tag[0]}
  facility local6
  packet_size 9216

  <buffer tag>
  </buffer>

#  <format>
#    @type json
#  </format>
  <format>
    @type single_value
    message_key message
  </format>
</match>

```

roles.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: monitoring
  name: event-exporter
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: event-exporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: event-exporter
subjects:
  - kind: ServiceAccount
    namespace: monitoring
    name: event-exporter
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: event-exporter
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["*"]

```

configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: event-exporter-cfg
  namespace: monitoring
data:
  config.yaml: |
    logLevel: warn
    logFormat: json
    metricsNamePrefix: event_exporter_
    route:
      routes:
        - match:
            - receiver: "syslog"
    receivers:
      - name: "syslog"
        syslog:
          network: "udp"
          address: "fluentd-service.monitoring.svc.cluster.local:514"
          tag: "k8s.event"
```

deployment.yaml

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-exporter
  namespace: monitoring
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: event-exporter
        version: v1
      annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '2112'
        prometheus.io/path: '/metrics'
    spec:
      serviceAccountName: event-exporter
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: event-exporter
          # The good practice would be to pin the version. This is just a reference so that we don't
          # have to update this file in each release.
          #latest version is v1.7
          image: ghcr.io/resmoio/kubernetes-event-exporter:latest
          #image: ghcr.io/resmoio/kubernetes-event-exporter@sha256:36e5ce64dad3d22426c1e7a0f1dd5d5ae0e9ff53aa86e6bcf7429d483582a317
          imagePullPolicy: IfNotPresent
          args:
            - -conf=/data/config.yaml
          volumeMounts:
            - mountPath: /data
              name: cfg
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: [ALL]
      volumes:
        - name: cfg
          configMap:
            name: event-exporter-cfg
  selector:
    matchLabels:
      app: event-exporter
      version: v1



```




