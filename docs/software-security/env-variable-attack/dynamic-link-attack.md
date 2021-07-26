#
#### 静态链接&动态链接
程序在执行前要经历一个链接的阶段。链接器找到程序中引用的外部程序库代码，并将代码链接到程序中。  

**在编译时链接称为静态链接**：在gcc编译是可以使用`-static`参数指定静态链接。静态链接会把外部程序代码都都放到可执行文件中，所以可执行文件会很大。并且如果修改了外部程序，可执行文件也无法得到更新。 
```
// hello.c
# include <stdio.h>

void main()
{
    printf("hello shan");
}
```
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o hello_dymainc hello.c 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o hello_static -static  hello.c 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ll | grep hello
-rw-r--r-- 1 shan root     67 7月   3 13:11 hello.c
-rwxr-xr-x 1 shan root  16696 7月   3 13:11 hello_dymainc*
-rwxr-xr-x 1 shan root 871688 7月   3 13:12 hello_static*
```


**在运行时链接称为动态链接：动态链接使用环境变量，从而成为了攻击面。**    
支持动态链接的库被称为共享库。linux是以.so为扩展名。在windows中被称为动态链接库DLL(dynamic link library)  

可执行文件被载入内存后，装载器将控制权交给动态连接器。它从一系列共享库中找到printf()函数的实现，并将可执行文件中对该函数的调用链接到它的实现代码，一旦链接完成。动态链接器把控制权交给main()函数。实际程序运行时，这个链接过程可能被推迟到函数第一次调用的时候。

![](/software-security/img/daynamic_link.png)  



**通过ldd查看程序所依赖的共享库**
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ldd hello_dymainc 
        linux-vdso.so.1 (0x00007ffda7b0a000)  //提供系统调用函数的库
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f71ba8c5000)  // libc库，提供了标准的c语言函数库，printf就是
        /lib64/ld-linux-x86-64.so.2 (0x00007f71baacf000)  // 动态连接器本身
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ldd hello_static 
        不是动态可执行文件
```

&emsp;

#### LD_PRELOAD和LD_LIBRARY_PATH
在链接阶段，Linux动态链接器会在默认目录寻找使用到的库。用户可以使用LD_PRELOAD和LD_LIBRARY_PATH环境变量来增加搜索目录和库文件。  
LD_PRELOAD被称为预先加载，所以动态链接器会优先在这个目录下寻找。然后才是在默认和LD_LIBRARY_PATH列表下寻找。  
!!! 动态库的加载顺序
    LD_PRELOAD>LD_LIBRARY_PATH>/etc/ld.so.cache>/lib>/usr/lib。  
下面使用由标准库libc.so提供的sleep()函数来测试  

```
// sleep.c
# include <stdio.h>

void sleep(int a)
{
    printf("没想到吧，少年\n");
}
```

```
// test.c
# include <unistd.h>

void main(){
    sleep(1);
}
```
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o test test.c
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./test  # 睡了1s
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -c sleep.c  # -c 只编译不链接：产生.o文件
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -shared -o mylib.so sleep.o
shan@shan-GV62-8RC:~/s/codes/c/testProject$ export LD_PRELOAD=./mylib.so  # 使用相对路径不行
ERROR: ld.so: object './mylib.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
ERROR: ld.so: object './mylib.so' from LD_PRELOAD cannot be preloaded (cannot open shared object file): ignored.
shan@shan-GV62-8RC:~/s/codes/c/testProject$ export LD_PRELOAD=~/s/codes/c/testProject/mylib.so 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./test 
没想到吧，少年
shan@shan-GV62-8RC:~/s/codes/c/testProject$ unset LD_PRELOAD
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./test # 睡了1s
```

&emsp;

**Set-UID屏蔽了LD_PRELOAD和LD_LIBRARY_PATH**
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ export LD_PRELOAD=~/s/codes/c/testProject/mylib.so 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./test 没想到吧，少年
shan@shan-GV62-8RC:~/s/codes/c/testProject$ sudo chown root test
shan@shan-GV62-8RC:~/s/codes/c/testProject$ sudo chmod 4755 test
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./test   # 睡了1s
```
可以看到这两个环境变量因为特权程序的原因不会被使用，所以对特权程序没有安全威胁。


#### 苹果OS X 10.10案例
OS X 10.10的动态链接器dyld使用了`DYLD_PRINT_TO_FILE`的环境变量。用户可以使用这个环境变量制定日志存放的路径。用户可以设置成一个用户无法修改的受保护的文件(如/etc/passwd)。但是用户无法控制写入文件的内容，攻击造成的后果有限。但是dyld还有一个致命的错误，没有关闭打开的文件，造成权限泄漏(忘了的可以回顾set-uid中的攻击面)。






