# 
#### 程序的内存布局
![](/software-security/img/buffer1.png)  
代码段: 存放程序的可执行代码  
数据段： 存放初始化的静态/全局变量  
BBS段： 存放未初始化的静态/全局变量  
堆： 动态内存分配，由malloc()、calloc()、free()等函数管理  
栈： 存放函数内定义的局部变量，或者和函数调用相关的数据，如返回地址和参数等。  

代码举例：
```
int x = 100;  // 数据段

int main()
{
    int a=2;  // 栈
    float b=2.5; // 栈
    static int y; // BBS段

    int *ptr = (int *) malloc(2*sizeof(int)); // 栈 指针ptr是局部变量，指向的是动态分配的内存块

    ptr[0] = 5;  // 堆
    ptr[1] = 6;  // 堆

    free(ptr);  // 释放堆中的内存
    
    return 1;  // 栈

}
```


#### 栈的内存布局

```
void func(int a, int b)
{
    int x, y;

    x = a + b;
    y = a - b;
}
```


![](/software-security/img/buffer2.png)  

参数b比参数a先入栈  
返回地址： 在函数调用前，计算机把新函数调用前的下一条指令的地址。因此决定了函数返回后跳转何处执行  
前帧指针： 上一个栈帧的指针  

#### 帧指针
在一个函数中，需要访问参数、全局变量等，这些地址在编译的时候不能确定，因为编译器无法预测栈运行时的状态。因此CPU引入了叫帧指针的寄存器，帧指针时一个固定的地址，因此参数、全局变量可以通过计算偏移得到。  

gcc使用-S参数把上面func编译成汇编代码
```
movl	8(%ebp), %edx  
movl	12(%ebp), %eax
addl	%edx, %eax
movl	%eax, -8(%ebp)
```
**对于32位系统而言**，返回地址和帧指针各占4个字节。  
由于参数b比参数a先入栈，所以a的地址时ebp+8，b的地址是ebp+12  
x的返回值是ebp-8  

!!! ebpesp
    ebp：栈指针寄存器(extended stack pointer)，指向当前函数帧栈的栈底  
    esp： 基址指针寄存器(extended base pointer)，永远指向栈顶


**前帧指针**

![](/software-security/img/buffer3.png)  
CPU中仅存在一个帧指针寄存器，它总是指向当前函数的帧栈(栈底)  
所以需要记录上一个函数的帧栈位置，只有这样当被调用函数返回时，才能恢复调用者的帧栈。  


#### 栈的缓冲区溢出
内存复制在程序中很常见。在复制数据前，如果程序没有给目标区域足够大的内存就会导致缓冲区溢出。在java，python等语言都会自动检测溢出，但是c，c++等就没有检测。  
c语言有很多函数用于复制数据，包括strcpy(),strcat(),memcpy()等  

!!! strcpy
    strcpy把从src地址开始且含有’\0’结束符的字符串复制到以dest开始的地址空间
    不只是strcpy，用strlen读字符串的长度，也是以\0为结束

```
// copy.c
# include <string.h>

void foo(char *str)
{
    char buffer[12];
    strcpy(buffer, str);
}

int main()
{
    char *str = "This is definitely longer than 12";
    foo(str);
    return 1;
}
```
![](/software-security/img/buffer4.png)

栈是高地址向低地址生长，缓冲区的数据依然是低地址向高地址生长。  
buffer数组上的区域是一些关键数据，如返回地址和前帧指针。当buffer超出长度导致溢出就会修改了返回地址。这可能导致多个情况发生:  
1.新地址没有被映射到任何物理地址，跳转失败，程序崩溃  
2.新地址映射到物理地址，但是受保护的空间，跳转失败，程序崩溃  
3.新地址映射到物理地址，不是有效指令(可能是数据区)，跳转失败，程序崩溃  
4.新地址恰好是有效的机器指令，程序逻辑彻底改变。  

















