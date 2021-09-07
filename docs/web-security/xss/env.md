#

#### 环境说明
为了省去自己软件的安装搭建，seedlab提供了virtualbox方式和docker方式。下面使用docker方式

#### 文件下载
官网  
```
wget https://seedsecuritylabs.org/Labs_20.04/Files/Web_SQL_Injection/Labsetup.zip
unzip Labsetup.zip
```
或者 网盘链接: https://pan.baidu.com/s/1vgMrKhwsIMPK6X6OPLlv6w  密码: tuan  


#### docker文件说明和配置
```
shan@shan-GV62-8RC:~/下载/Labsetup$ ls
docker-compose.yml  image_mysql  image_www  mysql_data
```

查看`docker-compose.yml`可以看到服务地址10.9.0.5


查看服务的配置文件  
```	   
shan@shan-GV62-8RC:~/下载/Labsetup/image_www$ cat apache_elgg.conf 
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


因此在/etc/hosts文件里追加    
```
10.9.0.5 www.seed-server.com
```


内置账号密码
![](/web-security/img/xss-1.png)







