Fluentd config for controller-manager-modified

```yaml
#<source>
#  @type tail
#  path /var/log/controller-manager/1.log
#  pos_file /var/log/fluentd/cursor/controller-manager.pos
#  tag k8s.controller-manager
#  format none
#</source>

#<filter k8s.controller-manager>
#  @type grep
#  <regexp>
#    key message
#    pattern /{"ts":.*/
#  </regexp>
#</filter>

#<filter k8s.controller-manager>
#  @type parser
#  key_name message
#  reserve_data true
#  <parse>
#    @type json
#  </parse>
#</filter>

#<match k8s.controller-manager>
#  @type stdout
#</match>

###Second criteria of configuration but not matching nested json
#<source>
#  @type tail
#  path /var/log/controller-manager/1.log
#  pos_file /var/log/fluentd/cursor/controller-manager.pos
#  tag k8s.controller-manager
#  format none
#</source>

#<filter k8s.controller-manager>
#  @type parser
#  key_name message
#  reserve_data true
#  <parse>
#    @type regexp
#     expression /^(?<log_timestamp>[^\s]+)\s+(?<stream>\w+)\s+(?<log_level>\w+)\s+(?<json>{.*}$)/
#  </parse>
#</filter>

#<filter k8s.controller-manager>
#  @type parser
#  key_name json
#  reserve_data true
#  <parse>
#    @type json
#  </parse>
#</filter>

#<filter k8s.controller-manager>
#  @type stdout
#</filter>

#<match k8s.controller-manager>
#@type copy
#<store>
#  @type remote_syslog
#  host 192.168.72.166
#  port 514
#  severity info
#  program '"service"="controller-manager"'
#  hostname ${tag[0]}
#  facility local6
#  packet_size 9216

#  <buffer tag>
#  </buffer>

#  <format>
    #@type json
#    @type single_value
#    message_key json
#  </format>
#</store>
#<store>
#@type file
#  @id controller-manager-file
#  path /var/log/fluentd/controller-manager
#  append true
#</store>

#  <format>
#    @type single_value
#    message_key message
#  </format>
#</match>




#<source>
#  @type tail
#  path /var/log/controller-manager/1.log
#  pos_file /var/log/fluentd/cursor/controller-manager.pos
#  tag k8s.controller-manager
#  format none
#</source>

#<filter k8s.controller-manager>
#  @type record_transformer
#  enable_ruby true
#  <record>
#    json ${/.*(\{.*\})/m.match(message)[1]}
#  </record>
#</filter>

#<filter k8s.controller-manager>
#  @type parser
#  key_name json
#  reserve_data true
#  <parse>
#    @type json
#  </parse>
#</filter>

#<match k8s.controller-manager>
#  @type stdout
#</match>


#################
###chnged
#################
#<source>
#  @type tail
#  path /var/log/controller-manager/1.log
#  pos_file /var/log/fluentd/cursor/controller-manager.pos
#  tag k8s.controller-manager
#  format none
#</source>

#<filter k8s.controller-manager>
#  @type record_transformer
#  enable_ruby true
#  <record>
#    # Extract the JSON part of the log line
#    json ${record["message"].match(/\{.*\}/m)&.to_s}
#    # Remove the original message field
#    message ""
#  </record>
#  remove_keys message
#</filter>

#<filter k8s.controller-manager>
#  @type parser
#  key_name json
#  reserve_data true
#  <parse>
#    @type json
#  </parse>
#</filter>

#<filter k8s.controller-manager>
#  @type stdout
#</filter>

#<match k8s.controller-manager>
#  @type copy
#  <store>
#    @type remote_syslog
#    host 192.168.72.166
#    port 514
#    severity info
#    program '"service"="controller-manager"'
#    hostname ${tag[0]}
#    facility local6
#    packet_size 9216

#    <buffer tag>
#    </buffer>

#    <format>
#      @type single_value
#      message_key json
#    </format>
#  </store>
#  <store>
#    @type file
#    @id controller-manager-file
#    path /var/log/fluentd/controller-manager
#    append true
#    <format>
#      @type json
#    </format>
#  </store>
#</match>


#### CHANGED again
<source>
  @type tail
  path /var/log/controller-manager/1.log
  pos_file /var/log/fluentd/cursor/controller-manager.pos
  tag k8s.controller-manager
  format none
</source>

<filter k8s.controller-manager>
  @type record_transformer
  enable_ruby true
  <record>
    # Extract the JSON part of the log line
    json ${record["message"].match(/\{.*\}/m)&.to_s}
    # Remove the original message field
    message ""
  </record>
  remove_keys message
</filter>

<filter k8s.controller-manager>
  @type parser
  key_name json
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

<filter k8s.controller-manager>
  @type record_transformer
  enable_ruby true
  <record>
#  item_name ${record['item']['name']}
#  item_namespace ${record['item']['namespace']}
#  item_apiversion ${record['item']['apiVersion']}
#  item_uid ${record['item']['uid']}
   item_name ${record['item'] && record['item']['name']}
   item_namespace ${record['item'] && record['item']['namespace']}
   item_apiVersion ${record['item'] && record['item']['apiVersion']}
   item_uid ${record['item'] && record['item']['uid']}
  </record>
  remove_keys item
</filter>

<filter k8s.controller-manager>
  @type record_modifier
  remove_keys_if_null true
</filter>

#<filter>
 # @type record_modifier
 # enable_ruby true
 # <script>
 #   record.delete_if { |k, v| v.nil? }
 # </script>
 #</filter>

<filter k8s.controller-manager>
  @type stdout
</filter>

<filter k8s.controller-manager>
  @type record_transformer
  remove_keys json
</filter>

#<filter k8s.controller-manager>
#  @type stdout
#</filter>

<match k8s.controller-manager>
  @type copy
  <store>
    @type remote_syslog
    host 192.168.72.166
    port 514
    severity info
    program '"service"="controller-manager"'
    hostname ${tag[0]}
    facility local6
    packet_size 9216

    <buffer tag>
    </buffer>

    <format>
      @type json
      #@type single_value
      #message_key json
    </format>
  </store>
  <store>
    @type file
    @id controller-manager-file
    path /var/log/fluentd/controller-manager
    append true
    <format>
      @type json
    </format>
  </store>
</match>
```

with cri it looks like this:

```yaml

```
