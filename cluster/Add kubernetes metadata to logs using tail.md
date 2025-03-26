## Add kubernetes metadata to logs using tail

by default logs are getting stored in kubernetes cluster by having this structure

`/var/log/pods/<namespace>_<pod_name>_<pod_id>/<container_name>/`

so when we use tail for fluentd we can have path of the log being read and have namespace and pod nmae and node name in every log record by having this sample config:

```bash
<source>
  @type tail
  @id input_kube-apiserver
  path /var/log/pods/kube-system_kube-apiserver*/kube-apiserver/*.log
  pos_file /var/log/fluentd/kube-apiserver.pos
  tag kubernetes.kube-apiserver
  path_key path
  <parse>
    @type cri
    merge_cri_fields false
    <parse>
      @type json
    </parse>
  </parse>
</source>

<filter kubernetes.kube-apiserver>
  @type record_transformer
  enable_ruby true
  <record>
    namespace       "${record['path'].split('/')[4].split('_')[0]}"
    pod_name        "${record['path'].split('/', -1)[4].split('_')[1].sub(ENV['K8S_NODE_NAME'], '').chomp('-')}"
    container_name  "${record['path'].split('/', -1)[5]}"
    node_name        "${ENV['K8S_NODE_NAME'] || 'k8s-cluster'}"
  </record>
</filter>

<filter kubernetes.kube-apiserver>
  @type record_transformer
  remove_keys path
</filter>

<filter kubernetes.kube-apiserver>
  @type stdout
</filter>
```

this below filter works fine too, but not tested too much to see wether it works in different scenarios or not; this one uses regex instead of splitting the path:

```bash
<filter kubernetes.kube-apiserver>
  @type record_transformer
  enable_ruby true
  <record>
    namespace       ${record['path'].match(/\/var\/log\/pods\/([^_]+)_[^\/]+\/[^\/]+\/\d+\.log/)[1]}
    pod_name        ${record['path'].match(/\/var\/log\/pods\/[^_]+_([^_]+)-[^\/]+\/[^\/]+\/\d+\.log/)[1].sub(ENV['K8S_NODE_NAME'], '').chomp('-')}
    container_name  ${record['path'].match(/\/var\/log\/pods\/[^\/]+\/([^\/]+)\/\d+\.log/)[1]}
    node_name       ${ENV['K8S_NODE_NAME'] || 'k8s-cluster'}
  </record>
</filter>
```

to have node name we have to have `K8S_NODE_NAME` as environment variable passed to the fluentd server like this in container `env` section:

```yaml
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.17
        env:
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
```

sample logs:

full path looks like this:

`/var/log/pods/kube-system_kube-apiserver-k8sCluster_716c61465a1ed087000aa3395afab579/kube-apiserver/0.log`

the output would look like this:

```json
{"ts":1742989802565.2078,"caller":"openapiv3/controller.go:126","msg":"OpenAPI AggregationController: action for item v1beta1.metrics.k8s.io: Rate Limited Requeue.","v":0,"namespace":"kube-system","pod_name":"kube-apiserver","container_name":"kube-apiserver","node_name":"k8sCluster"}
```




