
vim ~/.ssh/
Host wmvareHost
  HostName 127.0.0.1
  User root
  
VyOS
configure
edit service dhcp-server shared-network-name VLAN103 subnet 10.0.103.0/24
set static-mapping test03 ip-address 10.0.103.105
set static-mapping test03 mac-address 00:50:56:aa:bb:01
top
edit system static-host-mapping
set host-name test03.uatv.me alias test03
set host-name test03.uatv.me inet 10.0.103.105
top
commit
save
exit


  Found Lua: /usr/lib/x86_64-linux-gnu/liblua5.1.so;/usr/lib/x86_64-linux-gnu/libm.so (found version "5.1.4")
  liblua5.1.so.0

 git clone https://github.com/axkibe/lsyncd.git
 cd lsyncd/
 cmake .
 make
 make install
 /usr/lib/x86_64-linux-gnu/liblua5.2.so.0 
mv /usr/local/bin/lsyncd /tmp/rootfs/usr/local/

 mkdir build
 cd build
 cmake CMAKE_INSTALL_PREFIX= ..
    make
    sudo make install