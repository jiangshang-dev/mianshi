---
title: J2EE 基础知识
description: J2EE基础知识详解，涵盖Servlet生命周期、请求转发与重定向、Session与Cookie机制等Java Web核心概念。
category: 系统设计
head:
  - - meta
    - name: keywords
      content: J2EE,Java Web,Servlet,JSP,HTTP请求响应,Servlet生命周期,Session,Cookie
---

## Servlet 总结

> 说明：J2EE 是历史名称，后续更名为 Java EE，当前规范名称为 Jakarta EE。本文主要介绍传统 Servlet/JSP 编程模型。

在 Java Web 程序中，**Servlet** 主要负责接收用户请求 `HttpServletRequest`，在 `doGet()`、`doPost()` 等方法中进行处理，并通过 `HttpServletResponse` 返回响应。Servlet 可以设置初始化参数，供 Servlet 内部使用。在非分布式环境中，Servlet 容器通常为**每个 Servlet 声明**使用一个实例；同一个 Servlet 类如果有多个声明，仍可能有多个实例。容器在初始化时调用 `init()`，在实例退出服务时调用 `destroy()`。Servlet 可以通过 `@WebServlet`、`web.xml` 或程序化 API 声明，一个 Servlet 声明也可映射多个 URL。容器可能让多个线程并发执行同一实例的 `service()` 方法，因此不要在实例字段中保存每次请求的可变状态。

## 阐述 Servlet 和 CGI 的区别?

### CGI 的不足之处

1，需要为每个请求启动一个操作 CGI 程序的系统进程。如果请求频繁，这将会带来很大的开销。

2，需要为每个请求加载和运行一个 CGI 程序，这将带来很大的开销

3，需要重复编写处理网络协议的代码以及编码，这些工作都是非常耗时的。

### Servlet 的优点

1，只需要启动一个操作系统进程以及加载一个 JVM，大大降低了系统的开销

2，如果多个请求需要做同样处理的时候，这时候只需要加载一个类，这也大大降低了开销

3，所有动态加载的类可以实现对网络协议以及请求解码的共享，大大降低了工作量。

4，Servlet 能直接和 Web 服务器交互，而普通的 CGI 程序不能。Servlet 还能在各个程序之间共享数据，使数据库连接池之类的功能很容易实现。

补充：Sun Microsystems 公司在 1996 年发布 Servlet 技术就是为了和 CGI 进行竞争，Servlet 是一个特殊的 Java 程序，一个基于 Java 的 Web 应用通常包含一个或多个 Servlet 类。Servlet 不能够自行创建并执行，它是在 Servlet 容器中运行的，容器将用户的请求传递给 Servlet 程序，并将 Servlet 的响应回传给用户。通常一个 Servlet 会关联一个或多个 JSP 页面。以前 CGI 经常因为性能开销上的问题被诟病，然而 Fast CGI 早就已经解决了 CGI 效率上的问题，所以面试的时候大可不必信口开河的诟病 CGI，事实上有很多你熟悉的网站都使用了 CGI 技术。

参考：《javaweb 整合开发王者归来》P7

## Servlet 接口中有哪些方法及 Servlet 生命周期探秘

Servlet 接口定义了 5 个方法，其中**前三个方法与 Servlet 生命周期相关**：

- `void init(ServletConfig config) throws ServletException`
- `void service(ServletRequest req, ServletResponse resp) throws ServletException, java.io.IOException`
- `void destroy()`
- `java.lang.String getServletInfo()`
- `ServletConfig getServletConfig()`

**生命周期：** **Web 容器加载 Servlet 并将其实例化后，Servlet 生命周期开始**，容器运行其**init()方法**进行 Servlet 的初始化；请求到达时调用 Servlet 的**service()方法**，service()方法会根据需要调用与请求对应的**doGet 或 doPost**等方法；当服务器关闭或项目被卸载时服务器会将 Servlet 实例销毁，此时会调用 Servlet 的**destroy()方法**。**init 方法和 destroy 方法只会执行一次，service 方法客户端每次请求 Servlet 都会执行**。Servlet 中有时会用到一些需要初始化与销毁的资源，因此可以把初始化资源的代码放入 init 方法中，销毁资源的代码放入 destroy 方法中，这样就不需要每次处理客户端的请求都要初始化与销毁资源。

参考：《javaweb 整合开发王者归来》P81

## GET 和 POST 的区别

这个问题在知乎上被讨论的挺火热的，地址：<https://www.zhihu.com/question/28586791> 。

![](https://static001.geekbang.org/infoq/04/0454a5fff1437c32754f1dfcc3881148.png)

GET 和 POST 是 HTTP 协议中两种常用的请求方法，它们在不同的场景和目的下有不同的特点和用法。一般来说，可以从以下几个方面来区分它们：

- 语义上的区别：GET 用于获取目标资源的表现，是安全且幂等的方法。POST 用于请求目标资源按其自身语义处理请求内容，常用于创建资源、提交数据或触发操作，默认不具有幂等语义。
- 格式上的区别：GET 请求的查询条件通常放在 URL 的查询字符串（query string）中，POST 则通常通过请求内容传递数据，可以使用 `application/x-www-form-urlencoded`、`multipart/form-data`、`application/json` 等媒体类型。HTTP 规范没有为 URL 或 POST 请求内容规定一个通用的固定上限，实际限制由浏览器、服务器、网关等组件决定。
- 缓存上的区别：GET 响应默认可缓存，但仍会受 `Cache-Control` 等响应头约束。POST 响应也不是绝对不能缓存，只是需要服务端显式给出可缓存信息，实践中较少这样使用。
- 安全性上的区别：GET 请求和 POST 请求都不是绝对安全的，因为 HTTP 协议本身是明文传输的，无论是 URL、header 还是 body 都可能被窃取或篡改。为了保证安全性，必须使用 HTTPS 协议来加密传输数据。不过，在一些场景下，GET 请求相比 POST 请求更容易泄露敏感数据，因为 GET 请求的参数会出现在 URL 中，而 URL 可能会被记录在浏览器历史、服务器日志、代理日志等地方。因此，一般情况下，私密数据传输应该使用 POST + body。

重点是根据 HTTP 方法的标准语义选择 GET 或 POST。将所有请求都设计为 POST 虽然在技术上可行，但会失去 GET 在缓存、安全重试和中间组件语义上的优势，不应只以“团队达成共识”作为设计依据。

## 什么情况下调用 doGet()和 doPost()

Form 标签里的 method 的属性为 get 时调用 doGet()，为 post 时调用 doPost()。

## 转发(Forward)和重定向(Redirect)的区别

**转发是服务器行为，重定向是客户端行为。**

**转发（Forward）**
通过 RequestDispatcher 对象的 forward（HttpServletRequest request,HttpServletResponse response）方法实现的。RequestDispatcher 可以通过 HttpServletRequest 的 getRequestDispatcher()方法获得。例如下面的代码就是跳转到 login_success.jsp 页面。

```java
     request.getRequestDispatcher("login_success.jsp").forward(request, response);
```

**重定向（Redirect）** 由服务端返回 3xx 状态码和 `Location` 响应头，客户端再向新地址发起请求。Servlet 中通常使用 `HttpServletResponse#sendRedirect()`，也可以手动设置状态码和 `Location`。301、302、303在历史实现中可能将 POST 后续请求改为 GET；需要明确保留原请求方法时，应根据场景使用 307 或 308。

1. **从地址栏显示来说**

   forward 是服务器请求资源,服务器直接访问目标地址的 URL,把那个 URL 的响应内容读取过来,然后把这些内容再发给浏览器.浏览器根本不知道服务器发送的内容从哪里来的,所以它的地址栏还是原来的地址.
   redirect 是服务端根据逻辑,发送一个状态码,告诉浏览器重新去请求那个地址.所以地址栏显示的是新的 URL.

2. **从数据共享来说**

   forward:转发页面和转发到的页面可以共享 request 里面的数据.
   redirect:不能共享数据.

3. **从运用地方来说**

   forward:一般用于用户登陆的时候,根据角色转发到相应的模块.
   redirect:一般用于用户注销登陆时返回主页面和跳转到其它的网站等

4. 从效率来说

   forward:高.
   redirect:低.

## 自动刷新(Refresh)

部分浏览器支持非标准的 `Refresh` 响应头，可以实现延时刷新或跳转。Servlet 中可以通过 `HttpServletResponse` 设置：

```java
response.setHeader("Refresh", "5; url=http://localhost:8080/servlet/example.htm");
```

其中 5 的单位为秒。由于 `Refresh` 不是标准 HTTP 响应头，不应用它替代标准 3xx 重定向；页面刷新也可以根据需求在前端实现。

## Servlet 与线程安全

**Servlet 不是线程安全的，多线程并发的读写会导致数据不同步的问题。** 解决的办法是尽量不要定义 name 属性，而是要把 name 变量分别定义在 doGet()和 doPost()方法内。虽然使用 synchronized(name){}语句块可以解决问题，但是会造成线程的等待，不是很科学的办法。
注意：多线程的并发的读写 Servlet 类属性会导致数据不同步。但是如果只是并发地读取属性而不写入，则不存在数据不同步的问题。因此 Servlet 里的只读属性最好定义为 final 类型的。

参考：《javaweb 整合开发王者归来》P92

## JSP 和 Servlet 是什么关系

其实这个问题在上面已经阐述过了，Servlet 是一个特殊的 Java 程序，它运行于服务器的 JVM 中，能够依靠服务器的支持向浏览器提供显示内容。JSP 本质上是 Servlet 的一种简易形式，JSP 会被服务器处理成一个类似于 Servlet 的 Java 程序，可以简化页面内容的生成。Servlet 和 JSP 最主要的不同点在于，Servlet 的应用逻辑是在 Java 文件中，并且完全从表示层中的 HTML 分离开来。而 JSP 的情况是 Java 和 HTML 可以组合成一个扩展名为.jsp 的文件。有人说，Servlet 就是在 Java 中写 HTML，而 JSP 就是在 HTML 中写 Java 代码，当然这个说法是很片面且不够准确的。JSP 侧重于视图，Servlet 更侧重于控制逻辑，在 MVC 架构模式中，JSP 适合充当视图（view）而 Servlet 适合充当控制器（controller）。

## JSP 工作原理

JSP 页面会由 JSP 容器转换为 Servlet 实现类并编译。对于 HTTP，生成的实现类需要实现 `HttpJspPage` 接口，而 `HttpJspPage` 继承自 `JspPage`。在常见的按需编译配置中，转换和编译发生在第一次请求时；容器也可以预编译 JSP，因此这不是固定发生在首次请求的步骤。生成的 Java 源码和 class 文件通常保存在容器的工作目录中。下面通过实例介绍按需编译的情况。
工程 JspLoginDemo 下有一个名为 login.jsp 的 Jsp 文件，把工程第一次部署到服务器上后访问这个 Jsp 文件，我们发现这个目录下多了下图这两个东东。
.class 文件便是 JSP 对应的 Servlet。编译完毕后再运行 class 文件来响应客户端请求。以后客户端访问 login.jsp 的时候，Tomcat 将不再重新编译 JSP 文件，而是直接调用 class 文件来响应客户端请求。

![JSP工作原理](https://oss.javaguide.cn/github/javaguide/1.jpeg)

在按需编译模式下，首次请求需要完成转换和编译，通常会比后续请求慢。如果删除容器生成的 class 文件，容器在需要该页面时会重新编译 JSP。

开发 Web 程序时经常需要修改 JSP。Tomcat 能够自动检测到 JSP 程序的改动。如果检测到 JSP 源代码发生了改动。Tomcat 会在下次客户端请求 JSP 时重新编译 JSP，而不需要重启 Tomcat。这种自动检测功能是默认开启的，检测改动会消耗少量的时间，在部署 Web 应用的时候可以在 web.xml 中将它关掉。

参考：《javaweb 整合开发王者归来》P97

## JSP 有哪些内置对象、作用分别是什么

[JSP 内置对象 - CSDN 博客](http://blog.csdn.net/qq_34337272/article/details/64310849)

JSP 有 9 个内置对象：

- request：封装客户端的请求，其中包含来自 GET 或 POST 请求的参数；
- response：封装服务器对客户端的响应；
- pageContext：通过该对象可以获取其他对象；
- session：封装用户会话的对象；
- application：封装服务器运行环境的对象；
- out：输出服务器响应的输出流对象；
- config：Web 应用的配置对象；
- page：JSP 页面本身（相当于 Java 程序中的 this）；
- exception：封装页面抛出异常的对象。

## Request 对象的主要方法有哪些

- `setAttribute(String name,Object)`：设置名字为 name 的 request 的参数值
- `getAttribute(String name)`：返回由 name 指定的属性值
- `getAttributeNames()`：返回 request 对象所有属性的名字集合，结果是一个枚举的实例
- `getCookies()`：返回客户端的所有 Cookie 对象，结果是一个 Cookie 数组
- `getCharacterEncoding()`：返回请求使用的字符编码
- `getContentLength()`：返回请求体的字节数，长度未知或超过 `int` 范围时返回 -1；大请求可使用 `getContentLengthLong()`
- `getHeader(String name)`：获得 HTTP 协议定义的文件头信息
- `getHeaders(String name)`：返回指定名字的 request Header 的所有值，结果是一个枚举的实例
- `getHeaderNames()`：返回所以 request Header 的名字，结果是一个枚举的实例
- `getInputStream()`：返回请求的输入流，用于获得请求中的数据
- `getMethod()`：获得客户端向服务器端传送数据的方法
- `getParameter(String name)`：获得客户端传送给服务器端的有 name 指定的参数值
- `getParameterNames()`：获得客户端传送给服务器端的所有参数的名字，结果是一个枚举的实例
- `getParameterValues(String name)`：获得有 name 指定的参数的所有值
- `getProtocol()`：获取客户端向服务器端传送数据所依据的协议名称
- `getQueryString()`：获得查询字符串
- `getRequestURI()`：获取请求行中从协议名到查询字符串之间的 URI 路径部分
- `getRemoteAddr()`：获取客户端的 IP 地址
- `getRemoteHost()`：获取客户端的名字
- `getSession()`：返回与请求关联的 Session，不存在时创建
- `getSession(boolean create)`：返回与请求关联的 Session；当 `create` 为 `false` 且 Session 不存在时返回 `null`
- `getServerName()`：获取服务器的名字
- `getServletPath()`：获取客户端所请求的脚本文件的路径
- `getServerPort()`：获取服务器的端口号
- `removeAttribute(String name)`：删除请求中的一个属性

## request.getAttribute()和 request.getParameter()有何区别

`getParameter()` 读取客户端随请求提交的参数，例如 URL 查询字符串或已解析的表单字段。它返回 `String`，同名参数有多个值时可使用 `getParameterValues()`。

`getAttribute()` 读取服务端代码通过 `setAttribute()` 绑定到当前请求的对象，返回类型为 `Object`。在 `forward` 等服务端请求转发过程中，各组件处理的仍是同一个请求对象，因此可以共享 request attribute；客户端重定向会创建新请求，不会保留原请求的 attribute。这个过程不是容器在页面之间拷贝一块内存。

## include 指令 include 的行为的区别

**include 指令：** JSP 可以通过 include 指令来包含其他文件。被包含的文件可以是 JSP 文件、HTML 文件或文本文件。包含的文件就好像是该 JSP 文件的一部分，会被同时编译执行。 语法格式如下：
<%@ include file="文件相对 url 地址" %>

i**nclude 动作：** `<jsp:include>`动作元素用来包含静态和动态的文件。该动作把指定文件插入正在生成的页面。语法格式如下：
<jsp:include page="相对 URL 地址" flush="true" />

## JSP 九大内置对象，七大动作，三大指令

[JSP 九大内置对象，七大动作，三大指令总结](http://blog.csdn.net/qq_34337272/article/details/64310849)

## 讲解 JSP 中的四种作用域

JSP 中的四种作用域包括 page、request、session 和 application，具体来说：

- **page**代表与一个页面相关的对象和属性。
- **request**代表与 Web 客户机发出的一个请求相关的对象和属性。一个请求可能跨越多个页面，涉及多个 Web 组件；需要在页面显示的临时数据可以置于此作用域。
- **session**代表与某个用户与服务器建立的一次会话相关的对象和属性。跟某个用户相关的数据应该放在用户自己的 session 中。
- **application**代表与整个 Web 应用程序相关的对象和属性，它实质上是跨越整个 Web 应用程序，包括多个页面、请求和会话的一个全局作用域。

## Servlet 并发请求应该如何处理

历史上，JSP 提供过 `<%@ page isThreadSafe="false" %>`，Servlet 也提供过 `SingleThreadModel` 标记接口。`SingleThreadModel` 从 Servlet 2.4 起已废弃，并在 Jakarta Servlet 6.0 中删除；它也不能保证 Session 和静态状态的线程安全，不应作为当前解决方案。

正确做法是尽量让 Servlet 保持无状态，把每次请求的可变数据放在方法局部变量中，不在 Servlet 实例字段中保存。必须共享状态时，应使用适当的并发控制或线程安全数据结构，并尽量缩小临界区。

## 实现会话跟踪的技术有哪些

1. **使用 Cookie**

   向客户端发送 Cookie

   ```java
   Cookie c =new Cookie("name","value"); //创建Cookie
   c.setMaxAge(60*60*24); //设置最大时效，此处设置的最大时效为一天
   response.addCookie(c); //把Cookie放入到HTTP响应中
   ```

   从客户端读取 Cookie

   ```java
   String name ="name";
   Cookie[]cookies =request.getCookies();
   if(cookies !=null){
      for(int i= 0;i<cookies.length;i++){
       Cookie cookie =cookies[i];
       if(name.equals(cookie.getName())) {
         // something is here.
         // you can get the value
         cookie.getValue();
       }

      }
    }

   ```

   **优点:** 数据可以持久保存，不需要服务器资源，简单，基于文本的 Key-Value

   **缺点:** 大小受到限制，用户可以禁用 Cookie 功能，由于保存在本地，有一定的安全风险。

2. URL 重写

   在 URL 中添加用户会话的信息作为请求的参数，或者将唯一的会话 ID 添加到 URL 结尾以标识一个会话。

   **优点：** 在 Cookie 被禁用的时候依然可以使用

   **缺点：** 必须对网站的 URL 进行编码，所有页面必须动态生成，不能用预先记录下来的 URL 进行访问。

3. 隐藏的表单域

   ```html
   <input type="hidden" name="session" value="..." />
   ```

   **优点：** Cookie 被禁时可以使用

   **缺点：** 所有页面必须是表单提交之后的结果。

4. HttpSession

   HttpSession 不会仅因为用户第一次访问网站就必然自动创建。当代码调用 `HttpServletRequest#getSession()`，或某个框架/JSP 功能为当前请求要求 Session 时，容器才会在不存在时创建它。可以通过 `setAttribute()` 和 `getAttribute()` 保存、读取会话属性。HttpSession 数据由服务端管理，具体可保存在内存、分布式存储或持久化介质中，因此不要放入过大对象。在分布式部署或需要会话持久化时，属性通常还需要可序列化，具体要求由容器和会话存储方案决定。

## Cookie 和 Session 的区别

Cookie 和 Session 都是用来跟踪浏览器用户身份的会话方式，但是两者的应用场景不太一样。

**Cookie 一般用来保存用户信息** 比如 ① 我们在 Cookie 中保存已经登录过得用户信息，下次访问网站的时候页面可以自动帮你登录的一些基本信息给填了；② 一般的网站都会有保持登录也就是说下次你再访问网站的时候就不需要重新登录了，这是因为用户登录的时候我们可以存放了一个 Token 在 Cookie 中，下次登录的时候只需要根据 Token 值来查找用户即可(为了安全考虑，重新登录一般要将 Token 重写)；③ 登录一次网站后访问网站其他页面不需要重新登录。**Session 的主要作用就是通过服务端记录用户的状态。** 典型的场景是购物车，当你要添加商品到购物车的时候，系统不知道是哪个用户操作的，因为 HTTP 协议是无状态的。服务端给特定的用户创建特定的 Session 之后就可以标识这个用户并且跟踪这个用户了。

Cookie 数据保存在客户端(浏览器端)，Session 数据保存在服务器端。

Cookie 保存在客户端，Session 状态通常由服务端管理，但这不意味着只要使用 Session 就天然更安全。常见的 Session 仍依赖 Cookie 传递会话标识，该标识一旦被窃取就可能被重放。会话 Cookie 应使用高强度、无业务含义的随机标识，通过 HTTPS 传输，并根据场景设置 `Secure`、`HttpOnly`、`SameSite`、`Path` 和 `Domain` 等属性。不应把密码、银行卡号等敏感业务数据直接写入 Cookie；加密也不能替代完整性保护、过期、撤销和服务端授权校验。

<!-- @include: @article-footer.snippet.md -->
