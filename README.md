

Настроить DNS и DHCP

Пример для VyOS

```bash
configure
edit service dhcp-server shared-network-name VLANTEST subnet 10.0.0.0/24
set static-mapping test01 ip-address 10.0.0.10
set static-mapping test01 mac-address 00:50:56:00:00:10
top
edit system static-host-mapping
set host-name test01.example.com alias test01
set host-name test01.example.com inet 10.0.0.10
top
commit
save
exit
```

**w-coreos install <WMvare Host> <CoreOS Host> [cache|clean]**

```bash
$ ./w-coreos install esxi/vmware01.sh host/test01.sh cache
$ ./w-coreos gen host/test01.sh
$ ./w-coreos deploy host/test01.sh
```



```bash
$ ./w-coreos gen host/test01.sh
$ ./w-coreos update host/test01.sh
```



```bash
$ ./w-stop host/test01.sh
```



```bash
$ ./w-start host/test01.sh
```



```bash
$ ./w-coreos ssh host/test01.sh
```

