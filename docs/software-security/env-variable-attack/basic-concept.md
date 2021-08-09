# 环境变量
环境变量是储存在进程的一系列动态键值。

#### 访问环境变量
在c中有两种方式访问环境变量，main()函数的第三个参数和全局变量environ。推荐使用environ，原因后面段落说明。

main()函数的第三个参数
```
# include <stdio.h>

int main(int argc, char const *argv[], char* envp[])
{
    int i = 0;
    while (envp[i] != NULL)
    {
        printf("%s\n", envp[i++]);
    }
    return 0;
}
```

全局变量environ
```
#include <stdio.h>

extern char **environ;

int main(int argc, char const *argv[])
{
    int i = 0;
    while (environ[i] != NULL)
    {
        printf("%s\n", environ[i++]);
    }
    return 0;
}
```


#### 进程获取环境变量
进程在被初始化时通过两种方式获取环境变量。    
1. 新创建的进程(使用fork系统调用生成的进程)会继承父进程所有环境变量。  
2. 进程自身通过execve()系统调用运行的一个新的程序，进程的内存会被新程序覆盖(也就是新程序的环境变量取决区execve的第三个参数)。

通过例子来看execve是怎么决定进程的环境变量的
```
// execve_env.c
#include <stdio.h>
#include <unistd.h>

extern char **environ;

int main(int argc, char const *argv[])
{
    if (argc < 2)
        return 0;
    int i = 0;
    char *v[2];
    char *newenv[3];
    v[0] = "/usr/bin/env";
    v[1] = NULL;

    newenv[0] = "shan=6";
    newenv[1] = "jia=66";
    newenv[2] = NULL;

    switch (argv[1][0])
    {
    case '1':
        execve(v[0], v, NULL);
    case '2':
        execve(v[0], v, newenv);
    case '3':
        execve(v[0], v, environ);
    default:
        execve(v[0], v, NULL);
    }
    return 0;
}
```
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o execve_env execve_env.c
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./execve_env 2
shan=6
jia=66
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./execve_env 1
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./execve_env 3
SHELL=/bin/bash
SESSION_MANAGER=local/shan-GV62-8RC:@/tmp/.ICE-unix/1871,unix/shan-GV62-8RC:/tmp/.ICE-unix/1871
QT_ACCESSIBILITY=1
```

!!! note
    /* Replace the current process, executing PATH with arguments ARGV and environment ENVP.  ARGV and ENVP are terminated by NULL pointers.  */    
    extern int execve (const char *__path, char *const __argv[], char *const __envp[]) __THROW __nonnull ((1, 2));    
    从函数源码注释上可以看到argv数组和envp数组最后一位都必须是NULL空指针。


&emsp;
#### 环境变量在内存的位置
![](/software-security/img/env1.png)  
标记4的位置是main()函数的栈帧，envp参数指向环境变量数组的起始位置。全局变量environ也是指向环境变量数组的起始位置。但是当环境变量发生变化导致标记1和2的区域空间不够，整个环境变量块可能转移到其他位置。全部变量environ会做相应的修改指向最新的环境变量数组。而envp参数不会，还是指向老的地址从而导致错误。


&emsp;
#### shell变量&环境变量
shell变量和环境变量是不同的。shell程序会为每个环境变量创建一个相同名称和值的shell变量。他们是相互独立的，对shell变量修改不会影响同名的环境变量。反之亦然。  
通过`strings /proc/$$/environ`打印当前进程环境变量  
通过`echo`打印shell变量
```
shan@shan-GV62-8RC:~$ strings /proc/$$/environ | grep LOGNAME
LOGNAME=shan
shan@shan-GV62-8RC:~$ 
shan@shan-GV62-8RC:~$ echo $LOGNAME
shan
shan@shan-GV62-8RC:~$ LOGNAME=666
shan@shan-GV62-8RC:~$ echo $LOGNAME
666
shan@shan-GV62-8RC:~$ strings /proc/$$/environ | grep LOGNAME
LOGNAME=shan

```


**shell变量会影响子进程变量**  
当在新进程中执行新程序时，shell程序会为新程序设置环境变量(就是把shell自身的变量给新程序)。  
并不是所有shell变量都会给新程序。只有以下两种才会：  
1. 从环境变量复制得到的shell变量  
2. 用户自定义且用export导出的shell变量(export只对当前shell/BASH有效,临时的)


!!! note
    在终端使用env命令shell会创建一个子进程来运行，所以打印的实际是子进程的环境变量。
```
shan@shan-GV62-8RC:~$ strings /proc/$$/environ | grep LOGNAME
LOGNAME=shan
shan@shan-GV62-8RC:~$ LOGNAME2=jia  # 没导出
shan@shan-GV62-8RC:~$ export LOGNAME3=ping  # 导出了
shan@shan-GV62-8RC:~$ env | grep LOGNAME  # 可以看到导出的才会给子进程
LOGNAME=666
LOGNAME3=ping
shan@shan-GV62-8RC:~$ unset LOGNAME  # 删除该shell变量
shan@shan-GV62-8RC:~$ env | grep LOGNAME # 子进程中也没了
LOGNAME3=ping
```    




















