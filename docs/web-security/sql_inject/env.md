#

#### 环境说明
为了省去自己软件的安装搭建，seedlab提供了virtualbox方式和docker方式。下面使用docker方式

#### 文件下载
官网  
```
wget https://seedsecuritylabs.org/Labs_20.04/Files/Web_SQL_Injection/Labsetup.zip
unzip Labsetup.zip
```
或者 网盘链接: https://pan.baidu.com/s/1Q5n-Lnrhi_VGPzywvuzgYA  密码: krtc  


#### docker文件说明和配置
```
shan@shan-GV62-8RC:~/下载/Labsetup$ ls
docker-compose.yml  image_mysql  image_www  mysql_data
```

查看`docker-compose.yml`可以看到服务地址10.9.0.5


查看服务的配置文件  
```	   
shan@shan-GV62-8RC:~/下载/Labsetup/image_www$ cat apache_sql_injection.conf 
<VirtualHost *:80>
        DocumentRoot /var/www/SQL_Injection
        ServerName   www.seed-server.com
</VirtualHost>

```


因此在/etc/hosts文件里追加    
```
10.9.0.5 www.seed-server.com
```

![](/web-security/img/sql-1.png)




查看sql文件，可以看到Boby，Ryan等几个初始用户。  
```
shan@shan-GV62-8RC:~/下载/Labsetup/image_mysql$ cat sqllab_users.sql 


CREATE TABLE credential (
  ID int(6) unsigned NOT NULL AUTO_INCREMENT,
  Name varchar(30) NOT NULL,
  EID varchar(20) DEFAULT NULL,
  Salary int(9) DEFAULT NULL,
  birth varchar(20) DEFAULT NULL,
  SSN varchar(20) DEFAULT NULL,
  PhoneNumber` varchar(20) DEFAULT NULL,
  Address varchar(300) DEFAULT NULL,
  Email varchar(300) DEFAULT NULL,
  NickName varchar(300) DEFAULT NULL,
  Password varchar(300) DEFAULT NULL,
  PRIMARY KEY (ID)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

LOCK TABLES credential WRITE;

INSERT INTO credential VALUES (1,'Alice','10000',20000,'9/20','10211002','','','','','fdbe918bdae83000aa54747fc95fe0470fff4976'),(2,'Boby','20000',30000,'4/20','10213352','','','','','b78ed97677c161c1c82c142906674ad15242b2d4'),(3,'Ryan','30000',50000,'4/10','98993524','','','','','a3c50276cb120637cca669eb38fb9928b017e9ef'),(4,'Samy','40000',90000,'1/11','32193525','','','','','995b8b8c183f349b3cab0ae7fccd39133508d2af'),(5,'Ted','50000',110000,'11/3','32111111','','','','','99343bff28a7bb51cb6f22cb20a618701a2c2f58'),(6,'Admin','99999','400000','3/5','43254314','','','','','a5bdf35a1df4ea895905f6f6618e83951a6effc0');
/*!40000 ALTER TABLE credential ENABLE KEYS */;
UNLOCK TABLES;
```


但这边只能看到加密后的密码，原始密码可以在官网pdf看到`https://seedsecuritylabs.org/Labs_20.04/Files/Web_SQL_Injection/Web_SQL_Injection.pdf`
![](/web-security/img/sql-6.png)











