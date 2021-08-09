
#
#### 实验环境说明
小单使用的是腾讯的云服务器，并且安装的ubuntu 16.04。在脏牛漏洞概述得知ubuntu 16.04在4.4.0-45.66版本之后就被修复了(亲测4.4.0-47版本确实攻击不成功)。为了满足试验场景需要降低内核版本。下面使用了4.4.0-38版本.  


#### 查看当前内核版本
```
ubuntu@VM-0-17-ubuntu:~$ uname -r
4.4.0-92-generic
```

#### 安装内核
```
ubuntu@VM-0-17-ubuntu:~$ apt-cache search linux| grep 4.4.0-38
linux-headers-4.4.0-38 - Header files related to Linux kernel version 4.4.0
linux-cloud-tools-4.4.0-38 - Linux kernel version specific cloud tools for version 4.4.0-38
linux-cloud-tools-4.4.0-38-generic - Linux kernel version specific cloud tools for version 4.4.0-38
linux-cloud-tools-4.4.0-38-lowlatency - Linux kernel version specific cloud tools for version 4.4.0-38
linux-headers-4.4.0-38-generic - Linux kernel headers for version 4.4.0 on 32 bit x86 SMP
linux-headers-4.4.0-38-lowlatency - Linux kernel headers for version 4.4.0 on 32 bit x86 SMP
linux-image-4.4.0-38-generic - Linux kernel image for version 4.4.0 on 32 bit x86 SMP
linux-image-4.4.0-38-lowlatency - Linux kernel image for version 4.4.0 on 32 bit x86 SMP
linux-image-extra-4.4.0-38-generic - Linux kernel extra modules for version 4.4.0 on 32 bit x86 SMP
linux-tools-4.4.0-38 - Linux kernel version specific tools for version 4.4.0-38
linux-tools-4.4.0-38-generic - Linux kernel version specific tools for version 4.4.0-38
linux-tools-4.4.0-38-lowlatency - Linux kernel version specific tools for version 4.4.0-38


ubuntu@VM-0-17-ubuntu:~$ sudo apt install linux-headers-4.4.0-38-generic linux-image-4.4.0-38-generic  
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  linux-headers-4.4.0-38
Suggested packages:
  fdutils linux-doc-4.4.0 | linux-source-4.4.0 linux-tools
The following NEW packages will be installed:
  linux-headers-4.4.0-38 linux-headers-4.4.0-38-generic
  linux-image-4.4.0-38-generic
0 upgraded, 3 newly installed, 0 to remove and 279 not upgraded.
Need to get 28.2 MB of archives.
After this operation, 118 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://mirrors.tencentyun.com/ubuntu xenial-security/main i386 linux-headers-4.4.0-38 all 4.4.0-38.57 [9,948 kB]
Get:2 http://mirrors.tencentyun.com/ubuntu xenial-security/main i386 linux-headers-4.4.0-38-generic i386 4.4.0-38.57 [769 kB]
Get:3 http://mirrors.tencentyun.com/ubuntu xenial-security/main i386 linux-image-4.4.0-38-generic i386 4.4.0-38.57 [17.5 MB]
Fetched 28.2 MB in 1s (22.2 MB/s)                  
Selecting previously unselected package linux-headers-4.4.0-38.
(Reading database ... 65295 files and directories currently installed.)
Preparing to unpack .../linux-headers-4.4.0-38_4.4.0-38.57_all.deb ...
Unpacking linux-headers-4.4.0-38 (4.4.0-38.57) ...
Selecting previously unselected package linux-headers-4.4.0-38-generic.
Preparing to unpack .../linux-headers-4.4.0-38-generic_4.4.0-38.57_i386.deb ...
Unpacking linux-headers-4.4.0-38-generic (4.4.0-38.57) ...
Selecting previously unselected package linux-image-4.4.0-38-generic.
Preparing to unpack .../linux-image-4.4.0-38-generic_4.4.0-38.57_i386.deb ...
Done.
Unpacking linux-image-4.4.0-38-generic (4.4.0-38.57) ...
Setting up linux-headers-4.4.0-38 (4.4.0-38.57) ...
Setting up linux-headers-4.4.0-38-generic (4.4.0-38.57) ...
Setting up linux-image-4.4.0-38-generic (4.4.0-38.57) ...
Running depmod.
update-initramfs: deferring update (hook will be called later)
Examining /etc/kernel/postinst.d.
run-parts: executing /etc/kernel/postinst.d/apt-auto-removal 4.4.0-38-generic /b
oot/vmlinuz-4.4.0-38-generic
run-parts: executing /etc/kernel/postinst.d/initramfs-tools 4.4.0-38-generic /bo
ot/vmlinuz-4.4.0-38-generic
update-initramfs: Generating /boot/initrd.img-4.4.0-38-generic
cryptsetup: WARNING: failed to detect canonical device of /dev/vda1
cryptsetup: WARNING: could not determine root device from /etc/fstab
W: mdadm: /etc/mdadm/mdadm.conf defines no arrays.
run-parts: executing /etc/kernel/postinst.d/kdump-tools 4.4.0-38-generic /boot/v
mlinuz-4.4.0-38-generic
kdump-tools: Generating /var/lib/kdump/initrd.img-4.4.0-38-generic
cryptsetup: WARNING: failed to detect canonical device of /dev/vda1
cryptsetup: WARNING: could not determine root device from /etc/fstab
W: mdadm: /etc/mdadm/mdadm.conf defines no arrays.
run-parts: executing /etc/kernel/postinst.d/unattended-upgrades 4.4.0-38-generic
 /boot/vmlinuz-4.4.0-38-generic
run-parts: executing /etc/kernel/postinst.d/update-notifier 4.4.0-38-generic /bo
ot/vmlinuz-4.4.0-38-generic
run-parts: executing /etc/kernel/postinst.d/zz-update-grub 4.4.0-38-generic /boo
t/vmlinuz-4.4.0-38-generic
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-4.4.0-92-generic
Found initrd image: /boot/initrd.img-4.4.0-92-generic
Found linux image: /boot/vmlinuz-4.4.0-38-generic
Found initrd image: /boot/initrd.img-4.4.0-38-generic
done

```

#### 查看内核启动顺序
```
ubuntu@VM-0-17-ubuntu:~$ grep menuentry /boot/grub/grub.cfg
if [ x"${feature_menuentry_id}" = xy ]; then
  menuentry_id_option="--id"
  menuentry_id_option=""
export menuentry_id_option
menuentry 'Ubuntu' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-481dd046-a8a2-4dd9-8c57-b7801999494c' {
submenu 'Advanced options for Ubuntu' $menuentry_id_option 'gnulinux-advanced-481dd046-a8a2-4dd9-8c57-b7801999494c' {
	menuentry 'Ubuntu, with Linux 4.4.0-92-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-4.4.0-92-generic-advanced-481dd046-a8a2-4dd9-8c57-b7801999494c' {
	menuentry 'Ubuntu, with Linux 4.4.0-92-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-4.4.0-92-generic-recovery-481dd046-a8a2-4dd9-8c57-b7801999494c' {
	menuentry 'Ubuntu, with Linux 4.4.0-38-generic' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-4.4.0-38-generic-advanced-481dd046-a8a2-4dd9-8c57-b7801999494c' {
	menuentry 'Ubuntu, with Linux 4.4.0-38-generic (recovery mode)' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-4.4.0-38-generic-recovery-481dd046-a8a2-4dd9-8c57-b7801999494c' {
```

#### 修改启动顺序
```
ubuntu@VM-0-17-ubuntu:~$ sudo vi /etc/default/grub

# 默认GRUB_DEFAULT=0
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 4.4.0-38-generic"
```

#### 生效配置
```
ubuntu@VM-0-17-ubuntu:~$ sudo update-grub
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-4.4.0-92-generic
Found initrd image: /boot/initrd.img-4.4.0-92-generic
Found linux image: /boot/vmlinuz-4.4.0-38-generic
Found initrd image: /boot/initrd.img-4.4.0-38-generic
done
```

#### 重启查看是否生效
```
ubuntu@VM-0-17-ubuntu:~$ sudo reboot
Connection to 212.64.56.231 closed by remote host.
Connection to 212.64.56.231 closed.
shan@shan-GV62-8RC:~$ ssh ubuntu@212.64.56.231
ubuntu@212.64.56.231's password: 
Welcome to Ubuntu 16.04.1 LTS (GNU/Linux 4.4.0-38-generic i686)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage
New release '18.04.5 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


Last login: Sat Jul 31 19:22:42 2021 from 114.82.66.146
ubuntu@VM-0-17-ubuntu:~$ uname -r
4.4.0-38-generic
```

#### 移除不必要内核(非必要)
```
# 查询不包括当前内核版本的其它所有内核版本
ubuntu@VM-0-17-ubuntu:~$ dpkg -l | tail -n +6| grep -E 'linux-image-[0-9]+'| grep -Fv $(uname -r)
ii  linux-image-4.4.0-92-generic       4.4.0-92.115                               i386         Linux kernel image for version 4.4.0 on 32 bit x86 SMP

ubuntu@VM-0-17-ubuntu:~$ sudo apt remove linux-image-4.4.0-92-generi
```
rc：表示已经被移除  
ii：表示符合移除条件（可移除）  
iU：已进入 apt 安装队列，但还未被安装（不可移除  
