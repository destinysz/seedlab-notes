#
#### 漏洞程序
目标:利用格式化漏洞任意目标地址写入任意值。  
为了简化试验：直接打印出了ebp的值和返回地址，不然需要像缓冲区溢出那章节中那样通过gdb找到这些值  
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


#### 攻击策略





















