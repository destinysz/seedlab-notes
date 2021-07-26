# 特权程序

特权程序有两种常见的方式存在:   
守护进程(服务机制): 系统使用一个root守护进程来完成任务。当用户需要root权限的操作当向该进程请求。  
Set-UID: 采用一个比特位来标记程序，告诉系统这是一个特殊的程序，在运行时区别对待。主要是区别用户ID。**_(下面主要是讲这种方式)_**    

#### 进程的三个用户
真实用户ID(ruid)：进程的真正拥有者，即运行该进程的用户。  
有效用户ID(euid)： 访问控制中使用的ID，代表了进程拥有什么权限。  
保留用户ID  

对于非set-uid程序，真实用户id与有效用户id相同  
当一个普通程序被set-uid后，他的ruid不变，但是euid变为程序拥有者的id  

**常用chmod指令设置特权**  
chmod +(4)(7)(5)(5) file  
第一个参数为是否为特权程序，为4时代表这是特权程序，可无  
第二个参数为文件所有者权限  
第三个参数为同组用户权限  
第四个参数为其他组用户权限

**通过列子查看**
```
ubuntu@VM-0-17-ubuntu:~$ cp /bin/id ./myid
ubuntu@VM-0-17-ubuntu:~$ sudo chown root myid
ubuntu@VM-0-17-ubuntu:~$ ./myid 
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
ubuntu@VM-0-17-ubuntu:~$ ll  # 即便程序的拥有者是root，仍然不是一个特权程序
-rwxr-xr-x 1 root   ubuntu 47480 Jul  1 14:32 myid*
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 myid
ubuntu@VM-0-17-ubuntu:~$ ./myid # # 设置了set-uid比特位后，有效id变成了0，即拥有了root权限
uid=1000(ubuntu) gid=1000(ubuntu) euid=0(root) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
ubuntu@VM-0-17-ubuntu:~$ ll
-rwsr-xr-x 1 root   ubuntu 47480 Jul  1 14:32 myid*
```

!!! note  
    因为chown命令会清空suid比特，所以chown需要在chmod之前。

其他两个特殊权限[Linux 特殊权限 SUID,SGID,SBIT](https://www.cnblogs.com/sparkdev/p/9651622.html?_blank})

&emsp;
#### 特权cat程序例子
```
szww@sjp-zww:~$ cat /etc/shadow
cat: /etc/shadow: 权限不够
szww@sjp-zww:~$ which cat
/bin/cat
szww@sjp-zww:~$ cp /bin/cat ./mycat
szww@sjp-zww:~$ sudo chown root mycat
szww@sjp-zww:~$ sudo chmod 4755 mycat
szww@sjp-zww:~$ ./mycat /etc/shadow
root:$6$x5R4srlV$Pg.qSryuKl1w4UjVUqqnid0oB21kxT2SLEQ9/gmfYUpvfF7u6R7GKC4.wJX57gCn9oynfkaSIo.QA/icQuOYx.:18065:0:99999:7:::
daemon:*:17737:0:99999:7:::
bin:*:17737:0:99999:7:::
sys:*:17737:0:99999:7:::
```

&emsp;
#### Set-UID机制的安全性
本质上Set-UID机制是安全的。因为用户只能执行特权程序中定义好的操作,也就是用户的行为是受限的。
但是并非所有程序变成特权程序后都是安全的。比如：  
1. /bin/sh变成特权程序后可以执行用户任意指定的命令。  
2. vi程序变成特权程序后可以在编辑器内执行任意外部命令。  


