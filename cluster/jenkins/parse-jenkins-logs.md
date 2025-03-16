## configuring fluentd to monitor jenkins log and send it as plain to any destination

a raw log of jekins had s tructure like this:

```json
{
  "instant" : {
    "epochSecond" : 1738563300,
    "nanoOfSecond" : 193474456
  },
  "thread" : "SCM polling for hudson.model.FreeStyleProject@549e822e[helloworld]",
  "level" : "OFF",
  "loggerName" : "AuditLogger",
  "marker" : {
    "name" : "Audit",
    "parents" : [ {
      "name" : "EVENT"
    } ]
  },
  "message" : "Audit [useCredentials fileName=\"Credential id=eb66b7f4-d7ab-4a7a-89dd-54beb4020439 name=root/******\" name=\"Credential id=eb66b7f4-d7ab-4a7a-89dd-54beb4020439 name=root/****
**\" timestamp=\"2025-02-01T12:13:20.491Z\" usage=\"[1,5)\"]",
  "endOfBatch" : false,
  "loggerFqcn" : "org.apache.logging.log4j.audit.AuditLogger",
  "contextMap" : { },
  "threadId" : 30386,
  "threadPriority" : 5
}
```

so it is a multiline json log

here is our fluentd configuration

```yaml
<source>
  @type tail                # Use the tail input plugin
  path /var/log/res/jenkins.log  # Path to your Jenkins log file
  pos_file /var/log/fluentd/jenkins.pos  # Position file to track reading
  tag jenkins.logs          # Tag for routing
  <parse>
    @type multiline         # Use multiline parser for grouped JSON entries
    format_firstline /^\{/  # Detect the start of a JSON entry with an opening brace
    format1 /^(?<log>.*)$/  # Capture the entire multiline entry with a named group 'log'
    <parse>
      @type json            # Nested parser to interpret the multiline content as JSON
      time_key instant.epochSecond  # Use epochSecond as the time field
      time_type integer     # Treat it as an integer (Unix timestamp in seconds)
      time_format %s        # Format for epoch seconds
    </parse>
  </parse>
</source>

# Filter: Remove newlines and flatten the log field
<filter jenkins.logs>
  @type record_transformer
  enable_ruby true
  <record>
    _dummy ${record["log"].gsub(/\n\s*/, '')}
  </record>
  remove_keys log
</filter>

<filter jenkins.logs>
  @type parser
  key_name _dummy
  <parse>
    @type json
  </parse>
  remove_keys _dummy
</filter>

<filter jenkins.logs>
  @type record_transformer
  enable_ruby true
  <record>
    timestamp ${Time.at(record["instant"]["epochSecond"]).utc.strftime('%Y-%m-%d %H:%M:%S UTC')}
  </record>
  remove_keys instant
</filter>

# Output to stdout for debugging
<filter jenkins.logs>
  @type stdout
</filter>
```

we get some output like this:

```json
{"thread":"SCM polling for hudson.model.FreeStyleProject@549e822e[helloworld]","level":"OFF","loggerName":"AuditLogger","marker":{"name":"Audit","parents":[{"name":"EVENT"}]},"message":"Audit [useCredentials fileName=\"Credential id=eb66b7f4-d7ab-4a7a-89dd-54beb4020439 name=root/******\" name=\"Credential id=eb66b7f4-d7ab-4a7a-89dd-54beb4020439 name=root/******\" timestamp=\"2025-02-01T12:13:20.491Z\" usage=\"[1,5)\"]","endOfBatch":false,"loggerFqcn":"org.apache.logging.log4j.audit.AuditLogger","contextMap":{},"threadId":30343,"threadPriority":5,"timestamp":"2025-02-03 06:10:00 UTC"}
```


