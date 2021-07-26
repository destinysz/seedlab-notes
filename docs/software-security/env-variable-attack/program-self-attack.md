# 通过程序本身的代码进行攻击
程序可能直接使用环境变量，导致不信任的输入，影响程序行为。

#### getenv()函数
比如一个需要知道程序运行的当前目录的程序
```
// pwd.c
# include <stdio.h>
# include <stdlib.h>

void main()
{
    char arr[64];
    char *ptr;

    ptr = getenv("PWD");

    if(ptr != NULL)
    {
        sprintf(arr, "Present working dir is: %s", ptr);
        printf("%s\n", arr);
    }

}
```

```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./pwd
Present working dir is: /home/shan/s/codes/c/testProject
shan@shan-GV62-8RC:~/s/codes/c/testProject$ export PWD="everything i can do"
shan@shan-GV62-8RC:everything i can do$ ./pwd
Present working dir is: everything i can do
```
上面程序会把环境变量的值复制到缓冲区arr中，复制前没有检查输入，可能会导致缓冲区溢出漏洞。



#### 防御措施
在特权程序使用环境变量时，必须要检查环境变量的合法性。在需要使用getenv()函数的时候，可以使用相同功能的安全函数secure_getenv()，它会判断程序的真实用户和有效用户，如果不一致则返回NULL。


&emsp;
#### 环境变量 & Set-UID/服务机制的比较
![](/software-security/img/set-uid&service.png)  

可以看出在Set-UID中，环境变量时从用户进程得到的。   
服务机制中，环境变量是特权父进程给的，普通用户没法通过环境变量攻击。  
**正是因为Set-UID攻击面大很多，基于linux内核的安卓完全弃用了Set-UID机制**

