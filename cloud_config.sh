#

cat > cloud-config/${H_NAME}.yml <<EOF
#cloud-config

hostname: $H_NAME
users:
  - name: core
    coreos-ssh-import-github: $U_GITHUB
coreos:
  update:
    reboot-strategy: off
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
    - name: fleet.socket
      command: start
      content: |
        [Socket]
        # Talk to the API over a Unix domain socket (default)
        ListenStream=/var/run/fleet.sock
        Service=fleet.service

        [Install]
        WantedBy=sockets.target
    - name: stop-update-engine.service
      command: start
      content: |
        [Unit]
        Description=stop update-engine
        
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl stop update-engine.service
        ExecStartPost=/usr/bin/systemctl mask update-engine.service
    - name: docker-tcp.socket
      command: start
      enable: yes
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
    - name: enable-docker-tcp.service
      command: start
      content: |
        [Unit]
        Description=Enable the Docker Socket for the API

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl enable docker-tcp.socket
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the timezone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone $H_TZ
        RemainAfterExit=yes
        Type=oneshot
    # - name: lsyncd.service
    #   command: start
    #   content: |
    #     [Unit]
    #     Description=lsyncd
    #     After=docker.service
    #     Requires=docker.service

    #     [Service]
    #     EnvironmentFile=/etc/environment
    #     Restart=always
    #     RestartSec=10s
    #     ExecStartPre=-/usr/bin/docker kill lsyncd
    #     ExecStartPre=-/usr/bin/docker rm lsyncd
    #     ExecStartPre=/bin/sh -c "IMAGE=grengojbo/lsyncd; docker history $IMAGE >/dev/null 2>&1 || docker pull $IMAGE"
    #     ExecStart=/usr/bin/docker run --rm -p 2022:22 -e PUBLISH=22 -e HOST=$COREOS_PRIVATE_IPV4 -e PORT=2022 -v /storage:/storage -v /root:/root --name lsyncd --privileged grengojbo/lsyncd
    #     ExecStopPost=/usr/bin/docker stop lsyncd

    #     [Install]
    #     WantedBy=multi-user.target
  etcd:
    name: $H_NAME
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    # uncomment the following line and replace it with your discovery URL
    # discovery: https://discovery.etcd.io/12345693838asdfasfadf13939923
    discovery: $DISCOVERY_TOKEN
    addr: $H_IP:4001
    #bind-addr: 0.0.0.0:4001
    peer-addr: $H_IP:7001
    # give etcd more time if it's under heavy load - prevent leader election thrashing
    peer-election-timeout: 2000
    # heartbeat interval should ideally be 1/4 or 1/5 of peer election timeout, but that's a long time...
    peer-heartbeat-interval: 500
    snapshot-count: 5000
  fleet:
    # We have to set the public_ip here so this works on Vagrant -- otherwise, Vagrant VMs
    # will all publish the same private IP. This is harmless for cloud providers.
    public-ip: $H_IP
    #etcd-servers: http://10.0.7.235:4001,http://10.0.7.234:4001,http://10.0.7.233:4001
    #verbosity: 1
    # metadata: region=ua,deis=no,router=no,cluster=yes,server=hp01
    metadata: region=ua,deis=no,router=no,cluster=yes,server=all
    etcd_request_timeout: 3
write_files:
  - path: /etc/deis-release
    content: |
      DEIS_RELEASE=latest
  - path: /etc/environment
    permissions: '0644'
    content: |
      COREOS_PUBLIC_IPV4=$2
      COREOS_PRIVATE_IPV4=$3
  - path: /etc/resolv.conf
    permissions: '0644'
    content: |
      nameserver $C_NAMESERVER
      domain $H_DOMAIN
      options single-request
  - path: /etc/motd
    content: " \e[31m* *    \e[34m*   \e[32m*****    \e[39mddddd   eeeeeee iiiiiii   ssss\n\e[31m*   *  \e[34m* *  \e[32m*   *     \e[39md   d   e    e    i     s    s\n \e[31m* *  \e[34m***** \e[32m*****     \e[39md    d  e         i    s\n\e[32m*****  \e[31m* *    \e[34m*       \e[39md     d e         i     s\n\e[32m*   * \e[31m*   *  \e[34m* *      \e[39md     d eee       i      sss\n\e[32m*****  \e[31m* *  \e[34m*****     \e[39md     d e         i         s\n  \e[34m*   \e[32m*****  \e[31m* *      \e[39md    d  e         i          s\n \e[34m* *  \e[32m*   * \e[31m*   *     \e[39md   d   e    e    i    s    s\n\e[34m***** \e[32m*****  \e[31m* *     \e[39mddddd   eeeeeee iiiiiii  ssss\n\n\e[39mWelcome to Deis\t\t\tPowered by Core\e[38;5;45mO\e[38;5;206mS\e[39m\n"
  - path: /etc/profile.d/nse-function.sh
    permissions: '0755'
    content: |
      function nse() {
        sudo nsenter --pid --uts --mount --ipc --net --target \$(docker inspect --format="{{ .State.Pid }}" \$1)
      }
  - path: /run/deis/bin/get_image
    permissions: '0755'
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
  - path: /etc/ntp.conf
    content: |
      # Common pool
      server $NTP_SERVER1
      server $NTP_SERVER2
      server $NTP_SERVER3

      # - Allow only time queries, at a limited rate.
      # - Allow all local queries (IPv4, IPv6)
      restrict default nomodify nopeer noquery limited kod
      restrict 127.0.0.1
      restrict [::1]
  - path: /etc/ntp.conf
    content: |
      settings {
        logfile    = "/var/log/lsyncd.log",
        statusFile = "/var/log/lsyncd.status",
        statusInterval = 10,
        nodaemon   = true,
      }

      sync{
        default.rsync,
        source = "/storage",
        target = "127.0.0.1:/storage/nodes",
        delete = false,
        maxProcesses = 4,
        rsync = {
          rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no",
        }
      }
ssh_authorized_keys:
  - $KEY_PUB
EOF

echo "Generate cloud-config/${H_NAME}.yml ..."
