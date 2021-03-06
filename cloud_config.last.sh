#

cat > cloud-config/${H_NAME}.yml <<EOF
#cloud-config

hostname: $H_NAME
users:
  - name: core
    coreos-ssh-import-github: $U_GITHUB
coreos:
  etcd:
    ## name: $H_NAME
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    # uncomment the following line and replace it with your discovery URL
    # discovery: https://discovery.etcd.io/12345693838asdfasfadf13939923
    discovery: $DISCOVERY_TOKEN
    addr: $H_IP:4001
    #bind-addr: 0.0.0.0
    peer-addr: $H_IP:7001
    # give etcd more time if it's under heavy load - prevent leader election thrashing
    peer-election-timeout: 2000
    # heartbeat interval should ideally be 1/4 or 1/5 of peer election timeout, but that's a long time...
    peer-heartbeat-interval: 500
    # snapshot-count: 5000
  fleet:
    # We have to set the public_ip here so this works on Vagrant -- otherwise, Vagrant VMs
    # will all publish the same private IP. This is harmless for cloud providers.
    public-ip: $H_IP
    #etcd-servers: http://10.0.7.235:4001,http://10.0.7.234:4001,http://10.0.7.233:4001
    #verbosity: 1
    # metadata: region=ua,deis=no,router=no,cluster=yes,server=all
    metadata: $H_METADATA
    etcd_request_timeout: 3.0
    # heartbeat interval should ideally be 1/4 or 1/5 of peer election timeout
    ## peer-heartbeat-interval: 500
  update:
    reboot-strategy: off
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
    - name: install-deisctl.service
      command: start
      content: |
        [Unit]
        Description=Install deisctl utility

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/sh -c 'curl -sSL --retry 5 --retry-delay 2 http://deis.io/deisctl/install.sh | sh -s 1.3.1'
    - name: fleet.socket
      command: start
      content: |
        [Socket]
        # Talk to the API over a Unix domain socket (default)
        ListenStream=/var/run/fleet.sock
        Service=fleet.service

        [Install]
        WantedBy=sockets.target
    - name: stop-locksmithd.service
      command: start
      content: |
        [Unit]
        Description=stop locksmithd.service

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl stop locksmithd.service
        ExecStartPost=/usr/bin/systemctl mask locksmithd.service
    - name: install-deisctl.service
      command: start
      content: |
        [Unit]
        Description=Install deisctl utility

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/sh -c 'curl -sSL  --retry 5 --retry-delay 2 http://deis.io/deisctl/install.sh | sh -s 1.0.0'
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the timezone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone $H_TZ
        RemainAfterExit=yes
        Type=oneshot
    - name: vmtoolsd.service
      command: start
      content: |
        [Unit]
        Description=VMware Tools Agent
        Documentation=http://open-vm-tools.sourceforge.net/
        ConditionVirtualization=vmware

        [Service]
        ExecStartPre=/usr/bin/ln -sfT /usr/share/oem/vmware-tools /etc/vmware-tools
        ExecStart=/usr/share/oem/bin/vmtoolsd
        TimeoutStopSec=5
  oem:
    bug-report-url: "https://github.com/coreos/bugs/issues"
    id: vmware
    name: VMWare
    version-id: "9.4.6.1770165"
write_files:
  - path: /etc/deis-release
    content: |
      DEIS_RELEASE=v1.0.0
  - path: /etc/environment
    permissions: '0644'
    content: |
      COREOS_PUBLIC_IPV4=$H_IP
      COREOS_PRIVATE_IPV4=$H_IP
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
        # sudo nsenter --pid --uts --mount --ipc --net --target \$(docker inspect --format="{{ .State.Pid }}" \$1)
        docker exec -it \$1 bash
      }
  - path: /run/deis/bin/get_image
    permissions: '0755'
    content: |
      #!/bin/bash
      # usage: get_image <component_path>
      IMAGE=\`etcdctl get \$1/image 2>/dev/null\`

      # if no image was set in etcd, we use the default plus the release string
      if [ \$? -ne 0 ]; then
        RELEASE=\`etcdctl get /deis/platform/version 2>/dev/null\`

        # if no release was set in etcd, use the default provisioned with the server
        if [ \$? -ne 0 ]; then
          source /etc/deis-release
          RELEASE=\$DEIS_RELEASE
        fi

        IMAGE=\$1:\$RELEASE
      fi

      # remove leading slash
      echo \${IMAGE#/}
  - path: /opt/bin/deis-debug-logs
    permissions: '0755'
    content: |
      #!/bin/bash

      echo '--- VERSIONS ---'
      source /etc/os-release
      echo $PRETTY_NAME
      source /etc/deis-release
      echo "Deis $DEIS_RELEASE"
      etcd -version
      fleet -version
      printf "\n"

      echo '--- SYSTEM STATUS ---'
      journalctl -n 50 -u etcd --no-pager
      journalctl -n 50 -u fleet --no-pager
      printf "\n"

      echo '--- DEIS STATUS ---'
      deisctl list
      etcdctl ls --recursive /deis
      printf "\n"
  - path: /home/core/.toolboxrc
    owner: core
    content: |
      TOOLBOX_DOCKER_IMAGE=ubuntu-debootstrap
      TOOLBOX_DOCKER_TAG=14.04
      TOOLBOX_USER=root
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
ssh_authorized_keys:
  - $KEY_PUB
EOF

echo "Generate cloud-config/${H_NAME}.yml ..."
