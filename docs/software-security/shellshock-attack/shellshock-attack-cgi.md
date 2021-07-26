# 
#### CGI
CGI 即 Common Gateway Interface，译作“通用网关接口”  
需要区分CGI和CGI程序，CGI是一种数据传输的标准，而CGI程序是实际处理业务的一个程序。**webserver每请求一次，CGI程序就会fork出一个子进程进行处理。CGI程序的参数通过环境变量和标准输入获得(这个过程和system函数基本一样)**，它的相应通过标准输出传递给webServer。  


#### ubuntu安装Apache+cgi
```
ubuntu@VM-0-17-ubuntu:~$ sudo apt install apache2 -y
ubuntu@VM-0-17-ubuntu:/etc/apache2$ sudo mkdir /var/www/cgi-bin
ubuntu@VM-0-17-ubuntu:/etc/apache2/conf-available$ sudo vi serve-cgi-bin.conf # ScriptAlias /cgi-bin/ /home/ubuntu/cgi-bin/
ubuntu@VM-0-17-ubuntu:/etc/apache2$ sudo ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load
ubuntu@VM-0-17-ubuntu:/etc/apache2$ sudo ln -s /etc/apache2/mods-available/cgid.load /etc/apache2/mods-enabled/cgid.load
ubuntu@VM-0-17-ubuntu:/etc/apache2$ sudo /etc/init.d/apache2 restart



```

待补更
