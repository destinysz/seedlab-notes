#
#### 漏洞介绍
脏牛漏洞是利用linux内核中的竞态条件漏洞。这个漏洞存在于**内存映射**有关的**写时拷贝(Copy-on-Write)**中。通过该漏洞，即使攻击者对文件只有可读的权限也能修改它。   

该漏洞存在Linux内核中已经有长达9年的时间，直到2016年10月才被修复。

漏洞编号：CVE-2016-5195  
如果内核版本低于下面这些版本(下面是修复后的版本)，就还可能还存在这个漏洞
```
Centos7 /RHEL7    3.10.0-327.36.3.el7
Cetnos6/RHEL6     2.6.32-642.6.2.el6
Ubuntu 16.10         4.8.0-26.28
Ubuntu 16.04         4.4.0-45.66
Ubuntu 14.04         3.13.0-100.147
Debian 8                3.16.36-1+deb8u2
Debian 7                3.2.82-1
```


#### 内存映射  
```
// mmap_example.c
#include <sys/mman.h>
#include <fcntl.h>  // for open
#include <unistd.h> // for close
#include <sys/stat.h>
#include <string.h>
#include <stdio.h>

int main()
{
    struct stat st;
    char content[20];
    char *new_content = "New Content";
    void *map;
    int f = open("./zzz", O_RDWR);
    fstat(f, &st);
    map = mmap(NULL, st.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, f, 0);  //映射整个文件
    memcpy((void*)content, map, 10);
    printf("read: %s\n", content);
    memcpy(map+5, new_content, strlen(new_content));

    munmap(map, st.st_size);
    close(f);
    return 0;
}
```
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ echo 1111111111111111111111111 > zzz
shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o mmap_example mmap_example.c shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./mmap_example read: 1111111111��U
shan@shan-GV62-8RC:~/s/codes/c/testProject$ 
```
查看文件zzz，发现内容已被修改  


**函数说明**   
fstat()用来将f所指的文件状态，复制到st所指的结构中(struct stat)。  

mmap()用来将某个文件内容映射到内存中，对该内存区域的存取即是直接对该文件内容的读写。    
void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset)    

删除映射关系  
int munmap(void *start, size_t length)  

memcpy()将数据从一个内存地址复制到另一个内存地址，第三个参数是要复制的字节数  

**mmap & munmap参数说明:**   
start: 映射开始的地方，通常设为NULL，代表让系统自动选定地址  
length: 映射区的长度  
prot: 期望的内存保护标志，不能与文件的打开模式冲突。PROT_EXEC可执行、PROT_READ可读、PROT_WRITE可写、PROT_NONE不可访问  
flags: 映射对象的类型。常见类型MAP_SHARED、MAP_PRIVATE  
fd: 文件描述符，指定那个文件被映射。  
offset: 被映射对象的起点。  
 

**MAP_SHARED & MAP_PRIVATE**
MAP_SHARED: 与其它所有映射这个对象的进程共享映射空间。对于映射区的修改会反映到物理内存。  
MAP_PRIVATE: 建立一个写入时拷贝的私有映射。内存区域的写入不会影响到原文件。当进程写入内存时，内核会分配一块物理内存，把数据复制到内存中，然后操作系统会更新进程页表，另映射的虚拟地址指向新的物理地址（即写时拷贝）。

![](/software-security/img/cow-1.png)


#### MAP_PRIVATE映射只读文件
创建一个只有root才能修改的文件
```
shan@shan-GV62-8RC:~/s/codes/c/testProject$ chmod 644 zzz 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ sudo chown root zzz
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ll zzz
-rw-r--r-- 1 root root 33 8月   1 16:31 zzz
```

程序
```
// mmap_example.c
#include <sys/mman.h>
#include <fcntl.h>  // for open
#include <unistd.h> // for close
#include <sys/stat.h>
#include <string.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    char *content = "**New content";
    char buffer[30];
    struct stat st;
    void *map;

    int f = open("./zzz", O_RDONLY);
    fstat(f, &st);

    map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, f, 0);
    int fm = open("/proc/self/mem", O_RDWR);
    lseek(fm, (off_t)map + 5, SEEK_SET);  //
    write(fm, content, strlen(content));
    memcpy(buffer, map, 29);
    printf("Content after write: %s\n", buffer);

    madvise(map, st.st_size, MADV_DONTNEED);
    memcpy(buffer, map, 29);
    printf("Content after madvise: %s\n", buffer);
    close(f);

    return 0;
}
```
```
111111111111111111shan@shan-GV62-8RC:~/s/codes/c/testProject$ gcc -o mmap_example mmap_example.c 
shan@shan-GV62-8RC:~/s/codes/c/testProject$ ./mmap_example 
Content after write: 11111**New content11111111111V
Content after madvise: 11111111111111111111111111111V
```
可以看见在madvise之前内存里的值确实变了。


**函数说明**  
lseek()： 每一个已打开的文件都有一个读写位置, 当打开文件时通常其读写位置是指向文件开头。lseek()便是用来控制该文件的读写位置  

madvise(): 在映射的内存私有拷贝后，可以使用该函数处理内存。MADV_DONTNEED表示告诉内核不再需要这部分内存地址。内核释放这部分地址空间资源，并修改进程页表，重新指向原来的物理地址。  



#### 脏牛漏洞
对于写时拷贝的需要三个步骤：  
1.对映射的物理内存做一份拷贝。  
2.更新页表，让虚拟内存指向新创建的物理内存。  
3.写入内存。  

由于这既不不是原子化的，可以被其他**线程**打断，造成竞态条件  

![](/software-security/img/cow2.png)
 
当madvise()发生在步骤2和3之间时，会使得步骤2新创建的私有拷贝无效，重新指回原来的物理内存，这个时候在修改就导致了源文件被修改了。



