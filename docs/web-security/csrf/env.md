#

#### 环境说明
为了省去自己软件的安装搭建，seedlab提供了virtualbox方式和docker方式。下面使用docker方式

#### 文件下载
官网  
```
wget https://seedsecuritylabs.org/Labs_20.04/Files/Web_CSRF_Elgg/Labsetup.zip
unzip Labsetup.zip
```
或者 网盘链接: https://pan.baidu.com/s/1eex7iym_yZozkyeRPof0sA  密码: o66j  


#### docker文件说明和配置
```
shan@shan-GV62-8RC:~/下载/test/Labsetup$ ls
attacker            image_attacker  image_www
docker-compose.yml  image_mysql     mysql_data

```

查看`docker-compose.yml`可以看到有两个服务elgg(目标网站)和attacker(恶意网站)。  
elgg对应的ip是10.9.0.5  
attacker对应的ip是10.9.0.105  

查看elgg服务的配置文件  
```	   
shan@shan-GV62-8RC:~/下载/test/Labsetup$ cat image_www/apache_elgg.conf 
<VirtualHost *:80>
     DocumentRoot /var/www/elgg
     ServerName   www.seed-server.com
     <Directory /var/www/elgg>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>
</VirtualHost>
```


查看attacker服务的配置文件  
```
shan@shan-GV62-8RC:~/下载/test/Labsetup$ cat image_attacker/apache_attacker.conf 
<VirtualHost *:80>
    ServerName www.attacker32.com
    DocumentRoot "/var/www/attacker"
</VirtualHost>
```

因此在/etc/hosts文件里追加  
```
10.9.0.5 www.seed-server.com
10.9.0.105 www.attacker32.com                        
```


用户密码  
![](/web-security/img/csrf-2.png)




















