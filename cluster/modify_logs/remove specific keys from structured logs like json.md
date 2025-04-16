# Modify logs - remove specific keys from structured logs like json

- we have a sample log like this:

```json
2025-02-03T04:44:00.904275576+00:00 stderr F {"ts":1738557840904.059,"logger":"UnhandledError","caller":"resourcequota/resource_quota_controller.go:446","msg":"Unhandled Error","err":"unable to retrieve the complete list of server APIs: metrics.k8s.io/v1beta1: stale GroupVersion discovery: metrics.k8s.io/v1beta1", "error_code": "ERR001","test_key": "test_value"}
```

- we want to delete some keys from the log:

```yaml
<filter kubernetes.logs>
  @type record_transformer
  remove_keys test_key,error_code,ts
</filter>
```

- modify conditionally: in this case we make the value of `test_key` null if its value equals `11`:

```yaml
<filter kubernetes.logs>
  @type record_transformer
  enable_ruby true
  auto_typecast true
  <record>
    # Replace test_key with nil or leave it as-is
    test_key ${record["test_key"].to_s.strip == "11" ? nil : record["test_key"]}
  </record>
  remove_keys error_code,ts
</filter>
```

- smaple input and output are as follows:

```json
2025-02-03T04:44:00.904275576+00:00 stderr F {"ts":1738557840904.059,"logger":"UnhandledError","caller":"resourcequota/resource_quota_controller.go:446","msg":"Unhandled Error","err":"unable to retrieve the complete list of server APIs: metrics.k8s.io/v1beta1: stale GroupVersion discovery: metrics.k8s.io/v1beta1", "error_code": "ERR001","test_key": "11"}
2025-04-13 13:06:13.458655666 -0400 kubernetes.logs: {"logger":"UnhandledError","caller":"resourcequota/resource_quota_controller.go:446","msg":"Unhandled Error","err":"unable to retrieve the complete list of server APIs: metrics.k8s.io/v1beta1: stale GroupVersion discovery: metrics.k8s.io/v1beta1","test_key":null}
```


