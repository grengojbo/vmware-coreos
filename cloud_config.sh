#

cat > cloud-config/${H_NAME}.yml <<EOF
#cloud-config

hostname: coreos$1
users:
  - name: core
    coreos-ssh-import-github: grengojbo
coreos:
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
    - name: stop-update-engine.service
      command: start
      content: |
        [Unit]
        Description=stop update-engine
        
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl stop update-engine.service
        ExecStartPost=/usr/bin/systemctl mask update-engine.service
  etcd:
    name: coreos$1
    discovery: $DISCOVERY_TOKEN
    addr: $2:4001
    peer-addr: $3:7001
    # give etcd more time if it's under heavy load - prevent leader election thrashing
    peer-election-timeout: 2000
    # heartbeat interval should ideally be 1/4 or 1/5 of peer election timeout, but that's a long time...
    peer-heartbeat-interval: 200
    snapshot-count: 5000
  fleet:
    public-ip: $2
    #etcd-servers: http://10.0.7.235:4001,http://10.0.7.234:4001,http://10.0.7.233:4001
    #verbosity: 1
    metadata: region=ua,deis=yes,node=no,server=hp01
    etcd_request_timeout: 3
write_files:
  - path: /etc/deis-release
    content: |
      DEIS_RELEASE=latest
  - path: /etc/environment
    permissions: 0644
    content: |
      COREOS_PUBLIC_IPV4=$2
      COREOS_PRIVATE_IPV4=$3
  - path: /etc/resolv.conf
    permissions: 0644
    content: |
      nameserver 10.0.103.1
      domain uatv.me
      #nameserver 10.0.7.1
      #domain uawifi.net.ua
      options single-request
  - path: /etc/profile.d/nse-function.sh
    permissions: '0755'
    content: |
      function nse() {
        sudo nsenter --pid --uts --mount --ipc --net --target \$(docker inspect --format="{{ .State.Pid }}" \$1)
      }
  - path: /run/deis/bin/get_image
    permissions: 0755
    content: |
      #!/bin/bash
      # usage: get_image <component_path>
      IMAGE=\`etcdctl get \$1/image 2>/dev/null\`
      
      # if no image was set in etcd, we use the default plus the release string
      if [ \$? -ne 0 ]; then
        RELEASE=\`etcdctl get /deis/release 2>/dev/null\`
        
        # if no release was set in etcd, use the default provisioned with the server
        if [ \$? -ne 0 ]; then
          source /etc/deis-release
          RELEASE=\$DEIS_RELEASE
        fi
        
        IMAGE=\$1:\$RELEASE
      fi
      
      # remove leading slash
      echo \${IMAGE#/}
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyfTLw0YMOWDWl8/vTnTb7T85ll/9bsF8k53PDglz0qU/tivtOKBZ1COKAIekx9WqAE0U+oUWDiFsQqRDwN/6f3MYbjD/uY+0FDygudCY+LVIeeHlOR6RDWi8GKse8MOVnlrlxHTcKWxJkvmPVEUiKAOcgemusSfCwbVrvaEwNSAJHT18kNJZHdlYT+CaAle97td4JL2Yne4WezNLNQi+saxIj7+oPRvlGNkYt9nBS1smZuyJkZ9DKdq+DaK0Arwx1YZCyzgOkC2ynw9UT4QIlQDrvEdkmzYbZmvQLhkynbGlsDll51gqUmun5jVDV7+MbV1Zihdh/miZGuub9qNf1 deis
EOF
