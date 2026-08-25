---
title: Web 实时消息推送详解
description: 消息推送通常是指网站的运营工作等人员，通过某种工具对用户当前网页或移动设备 APP 进行的主动消息推送。
category: 系统设计
icon: "mdi:message-text-outline"
head:
  - - meta
    - name: keywords
      content: Web消息推送,实时消息,WebSocket,SSE,长轮询,短轮询,MQTT,实时通信方案
---

> 原文地址：<https://juejin.cn/post/7122014462181113887，JavaGuide> 对本文进行了完善总结。

我有一个朋友做了一个小破站，现在要实现一个站内信 Web 消息推送的功能，对，就是下图这个小红点，一个很常用的功能。

![站内信 Web 消息推送](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192380.png)

不过他还没想好用什么方式做，这里我帮他整理了一下几种方案，并简单做了实现。

## 什么是消息推送？

推送的场景比较多，比如有人关注我的公众号，这时我就会收到一条推送消息，以此来吸引我点击打开应用。

消息推送通常是指网站的运营工作等人员，通过某种工具对用户当前网页或移动设备 APP 进行的主动消息推送。

消息推送一般又分为 Web 端消息推送和移动端消息推送。

移动端消息推送示例：

![移动端消息推送示例](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/IKleJ9auR1Ojdicyr0bH.png)

Web 端消息推送示例：

![Web 端消息推送示例](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/image-20220819100512941.png)

在具体实现之前，咱们再来分析一下前边的需求，其实功能很简单，只要触发某个事件（主动分享了资源或者后台主动推送消息），Web 页面的通知小红点就会实时的 `+1` 就可以了。

通常在服务端会有若干张消息推送表，用来记录用户触发不同事件所推送不同类型的消息，前端主动查询（拉）或者被动接收（推）用户所有未读的消息数。

![消息推送表](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192384.png)

消息推送无非是推（push）和拉（pull）两种形式，下边我们逐个了解下。

## 消息推送常见方案

![Web 实时消息推送方案总览](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/web-real-time-message-push-overview.webp)

### 短轮询

**轮询(polling)** 应该是实现消息推送方案中最简单的一种，这里我们暂且将轮询分为短轮询和长轮询。

短轮询很好理解，指定的时间间隔，由浏览器向服务器发出 HTTP 请求，服务器实时返回未读消息数据给客户端，浏览器再做渲染显示。

一个简单的 JS 定时器就可以搞定，每秒钟请求一次未读消息数接口，返回的数据展示即可。

```typescript
setInterval(() => {
  // 方法请求
  messageCount().then((res) => {
    if (res.code === 200) {
      this.messageCount = res.data;
    }
  });
}, 1000);
```

效果还是可以的，短轮询实现固然简单，缺点也是显而易见，由于推送数据并不会频繁变更，无论后端此时是否有新的消息产生，客户端都会进行请求，势必会对服务端造成很大压力，浪费带宽和服务器资源。

### 长轮询

长轮询是对上边短轮询的一种改进版本，在尽可能减少对服务器资源浪费的同时，保证消息的相对实时性。长轮询在中间件中应用的很广泛，比如 Nacos 和 Apollo 配置中心，消息队列 Kafka、RocketMQ 中都有用到长轮询。

[Nacos 配置中心交互模型是 push 还是 pull？](https://mp.weixin.qq.com/s/94ftESkDoZI9gAGflLiGwg)一文中我详细介绍过 Nacos 长轮询的实现原理，感兴趣的小伙伴可以瞅瞅。

长轮询其实原理跟轮询差不多，都是采用轮询的方式。不过，如果服务端的数据没有发生变更，会 一直 hold 住请求，直到服务端的数据发生变化，或者等待一定时间超时才会返回。返回后，客户端又会立即再次发起下一次长轮询。

这次我使用 Apollo 配置中心实现长轮询的方式，应用了一个类`DeferredResult`，它是在 Servlet3.0 后经过 Spring 封装提供的一种异步请求机制，直意就是延迟结果。

![长轮询示意图](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192386.png)

`DeferredResult` 可以让容器先释放处理当前请求的 Servlet 线程，稍后再由应用选择的任意线程、消息回调或其他事件源调用 `setResult()` 恢复响应处理。`DeferredResult` 本身不会自动启动一个工作线程，实际业务在哪个线程上执行由应用决定。

下边我们用长轮询来实现消息推送。

因为一个 ID 可能会被多个长轮询请求监听，所以我采用了 Guava 包提供的 `Multimap` 结构存放长轮询，一个 key 可以对应多个 value。一旦监听到 key 发生变化，对应的所有长轮询都会响应。前端收到新的版本号后，主动查询未读消息数接口并更新页面数据。

```java
@Controller
@RequestMapping("/polling")
public class PollingController {

    // 存放监听某个Id的长轮询集合
    // 线程同步结构
    private static final Multimap<String, DeferredResult<String>> watchRequests =
            Multimaps.synchronizedMultimap(HashMultimap.create());
    // 演示用的内存版本号；生产环境通常应使用业务数据自身的持久化版本
    private static final Map<String, Long> versions = new HashMap<>();

    /**
     * 设置监听
     */
    @GetMapping(path = "watch/{id}")
    @ResponseBody
    public DeferredResult<String> watch(@PathVariable String id,
                                        @RequestParam(defaultValue = "0") long version) {
        // 延迟对象设置超时时间
        DeferredResult<String> deferredResult = new DeferredResult<>(TIME_OUT, "timeout");
        // 异步请求完成时移除 key，防止内存溢出
        deferredResult.onCompletion(() -> {
            watchRequests.remove(id, deferredResult);
        });
        // 版本比较和监听注册必须处于同一临界区，避免发布发生在二者之间而丢通知
        synchronized (watchRequests) {
            long currentVersion = versions.getOrDefault(id, 0L);
            if (currentVersion != version) {
                deferredResult.setResult(Long.toString(currentVersion));
            } else {
                watchRequests.put(id, deferredResult);
            }
        }
        return deferredResult;
    }

    /**
     * 变更数据
     */
    @PostMapping(path = "publish/{id}")
    @ResponseBody
    public String publish(@PathVariable String id) {
        // 在同一同步块内先更新版本，再移除并复制监听快照
        Collection<DeferredResult<String>> deferredResults;
        long currentVersion;
        synchronized (watchRequests) {
            currentVersion = versions.merge(id, 1L, Long::sum);
            deferredResults = new ArrayList<>(watchRequests.removeAll(id));
        }
        for (DeferredResult<String> deferredResult : deferredResults) {
            deferredResult.setResult(Long.toString(currentVersion));
        }
        return "success";
    }
}
```

这里通过 `DeferredResult` 的超时结果返回约定好的 `"timeout"`，前端收到后携带原版本号立即发起下一次长轮询。收到新版本号时，前端先查询最新业务数据，再把该版本号用于下一次监听。版本比较、监听注册和发布递增版本都在同一个临界区内完成，因此即使更新恰好发生在两次请求交接期间，下一次监听也会立即发现版本变化。示例中的内存版本会随进程重启丢失，生产环境应优先使用数据库版本、消息位点等持久化标识，并设计清理策略。

不要把 HTTP 304 用作普通的“请求超时”状态：304 专用于条件请求中表示已缓存的表现仍未修改，且不能包含响应内容。生产项目也可以约定 204 等无内容响应，关键是让服务端和客户端对超时语义保持一致。

我们来测试一下，首先页面携带已知版本发起长轮询请求 `/polling/watch/10086?version=0` 监听消息变更，请求被挂起；紧接着手动变更数据 `/polling/publish/10086`，长轮询返回新版本。前端查询最新数据后，再携带新版本发起下一次请求，如此循环往复。

长轮询相比于短轮询在性能上提升了很多，但依然会产生较多的请求，这是它的一点不完美的地方。

### iframe 流

iframe 流就是在页面中插入一个隐藏的`<iframe>`标签，通过在`src`中请求消息数量 API 接口，由此在服务端和客户端之间创建一条长连接，服务端持续向`iframe`传输数据。

传输的数据通常是 HTML、或是内嵌的 JavaScript 脚本，来达到实时更新页面的效果。

![iframe 流示意图](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192388.png)

这种方式实现简单，前端只要一个`<iframe>`标签搞定了

```html
<iframe src="/iframe/message" style="display:none"></iframe>
```

服务端需要保持响应并在有新数据时写入、及时刷新缓冲区。不能在 Servlet 请求线程中使用不带等待、中断和异常处理的 `while (true)` 循环持续写响应：这会空转消耗 CPU、长时间占用容器线程，还无法在客户端断开时正常收敛。如果必须维护旧式 iframe 流，应使用容器异步 I/O 和事件驱动的写入模型；新系统通常直接选择 SSE 或 WebSocket。

iframe 流的服务器开销很大，而且 IE、Chrome 等浏览器一直会处于 loading 状态，图标会不停旋转，简直是强迫症杀手。

![iframe 流效果](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192389.png)

iframe 流非常不友好，强烈不推荐。

### SSE (推荐)

很多人可能不知道，服务端向客户端推送消息，其实除了可以用`WebSocket`这种耳熟能详的机制外，还有一种服务器发送事件(Server-Sent Events)，简称 SSE。这是一种服务器端到客户端(浏览器)的单向消息推送。

流式对话是 SSE 的一个典型应用场景。服务端可以把已经生成的部分内容持续写入事件流，用户无需等到全部计算完成才看到结果。

![ChatGPT 使用 SSE 实现对话](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/chatgpt-sse.png)

SSE 基于 HTTP，它不是让服务端在没有请求的情况下凭空建立连接，而是让客户端先发起请求，服务端保持该 HTTP 响应并持续写入事件。

![SSE 图解](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192390.png)

SSE 在服务器和客户端之间打开一个单向通道，服务端响应的不再是一次性的数据包而是`text/event-stream`类型的数据流信息，在有数据变更时从服务器流式传输到客户端。

整体的实现思路有点类似于在线视频播放，视频流会连续不断的推送到浏览器，你也可以理解成，客户端在完成一次用时很长（网络不畅）的下载。

![SSE 示意图](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192391.png)

SSE 与 WebSocket 作用相似，都可以建立服务端与浏览器之间的通信，实现服务端向客户端推送消息，但还是有些许不同：

- SSE 使用 HTTP 和 `text/event-stream`，通常更容易接入现有 Web 服务；WebSocket 需要服务器或容器支持协议升级和 WebSocket 帧。它不要求必须单独部署一台服务器。
- SSE 单向通信，只能由服务端向客户端单向通信；WebSocket 全双工通信，即通信的双方可以同时发送和接受信息。
- SSE 实现简单开发成本低，无需引入其他组件；WebSocket 传输数据需做二次解析，开发门槛高一些。
- SSE 默认支持断线重连；WebSocket 则需要自己实现。
- SSE 只能传送文本消息，二进制数据需要经过编码后传送；WebSocket 默认支持传送二进制数据。

![SSE 和 WebSocket 对比](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/sse-vs-websocket-comparison.webp)

**SSE 与 WebSocket 该如何选择？**

> 技术并没有好坏之分，只有哪个更合适。

SSE 好像一直不被大家所熟知，一部分原因是出现了 WebSocket，这个提供了更丰富的协议来执行双向、全双工通信。对于游戏、即时通信以及需要双向近乎实时更新的场景，拥有双向通道更具吸引力。

但是，在某些情况下，不需要从客户端发送数据。而你只需要一些服务器操作的更新。比如：站内信、未读消息数、状态更新、股票行情、监控数量等场景，SSE 不管是从实现的难易和成本上都更加有优势。此外，SSE 具有 WebSocket 在设计上缺乏的多种功能，例如：自动重新连接、事件 ID 和发送任意事件的能力。

前端只需进行一次 HTTP 请求，带上唯一 ID，打开事件流，监听服务端推送的事件就可以了

```javascript
<script>
    let source = null;
    let userId = 7777
    if (window.EventSource) {
        // 建立连接
        source = new EventSource('http://localhost:7777/sse/sub/'+userId);
        setMessageInnerHTML("连接用户=" + userId);
        /**
         * 连接一旦建立，就会触发open事件
         * 另一种写法：source.onopen = function (event) {}
         */
        source.addEventListener('open', function (e) {
            setMessageInnerHTML("建立连接。。。");
        }, false);
        /**
         * 客户端收到服务器发来的数据
         * 另一种写法：source.onmessage = function (event) {}
         */
        source.addEventListener('message', function (e) {
            setMessageInnerHTML(e.data);
        });
    } else {
        setMessageInnerHTML("你的浏览器不支持SSE");
    }
</script>
```

服务端的实现更简单，创建一个`SseEmitter`对象放入`sseEmitterMap`进行管理

```java
private static Map<String, SseEmitter> sseEmitterMap = new ConcurrentHashMap<>();

/**
 * 创建连接
 */
public static SseEmitter connect(String userId) {
    try {
        // 0 表示不设置应用层超时，并非“默认 30 秒”
        SseEmitter sseEmitter = new SseEmitter(0L);
        // 注册回调
        sseEmitter.onCompletion(completionCallBack(userId));
        sseEmitter.onError(errorCallBack(userId));
        sseEmitter.onTimeout(timeoutCallBack(userId));
        sseEmitterMap.put(userId, sseEmitter);
        count.getAndIncrement();
        return sseEmitter;
    } catch (Exception e) {
        log.info("创建新的sse连接异常，当前用户：{}", userId);
    }
    return null;
}

/**
 * 给指定用户发送消息
 */
public static void sendMessage(String userId, String message) {

    if (sseEmitterMap.containsKey(userId)) {
        try {
            sseEmitterMap.get(userId).send(message);
        } catch (IOException e) {
            log.error("用户[{}]推送异常:{}", userId, e.getMessage());
            removeUser(userId);
        }
    }
}
```

上面的 `Map<String, SseEmitter>` 示例每个用户只保留一个连接，新连接会覆盖旧连接。如果要支持多标签页或多设备，应为每个用户维护一组 `SseEmitter`，并在完成、超时和错误回调中移除对应连接。`0L` 也不代表代理、网关和容器永不会断开连接，生产环境需要配置心跳、超时和客户端重连策略。

**注意：** SSE 不支持 IE 浏览器，对其他主流浏览器兼容性做的还不错。

![SSE 兼容性](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192393.png)

### Websocket

Websocket 应该是大家都比较熟悉的一种实现消息推送的方式，上边我们在讲 SSE 的时候也和 Websocket 进行过比较。

这是一种在 TCP 连接上进行全双工通信的协议，建立客户端和服务器之间的通信渠道。浏览器和服务器仅需一次握手，两者之间就直接可以创建持久性的连接，并进行双向数据传输。

![Websocket 示意图](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192394.png)

WebSocket 的工作过程可以分为以下几个步骤：

1. 客户端向服务器发送一个 HTTP 请求，请求头中包含 `Upgrade: websocket` 和 `Sec-WebSocket-Key` 等字段，表示要求升级协议为 WebSocket；
2. 服务器收到这个请求后，会进行升级协议的操作，如果支持 WebSocket，它将回复一个 HTTP 101 状态码，响应头中包含 ，`Connection: Upgrade`和 `Sec-WebSocket-Accept: xxx` 等字段、表示成功升级到 WebSocket 协议。
3. 客户端和服务器之间建立了一个 WebSocket 连接，可以进行双向的数据传输。数据以帧（frames）的形式进行传送，而不是传统的 HTTP 请求和响应。WebSocket 的每条消息可能会被切分成多个数据帧（最小单位）。发送端会将消息切割成多个帧发送给接收端，接收端接收消息帧，并将关联的帧重新组装成完整的消息。
4. 客户端或服务器可以主动发送一个关闭帧，表示要断开连接。另一方收到后，也会回复一个关闭帧，然后双方关闭 TCP 连接。

另外，建立 WebSocket 连接之后，通过心跳机制来保持 WebSocket 连接的稳定性和活跃性。

SpringBoot 整合 WebSocket，先引入 WebSocket 相关的工具包，和 SSE 相比有额外的开发成本。

```xml
<!-- 引入websocket -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```

服务端使用 `@ServerEndpoint` 注解标注当前类为一个 WebSocket 端点，客户端可以通过 `ws://localhost:7777/websocket/10086` 连接到服务端。路径中的 `userId` 只适合用于演示路由；生产环境必须在握手时验证用户身份，并把连接绑定到已认证的主体，不能相信客户端自行填写的 `userId`。

```java
@Component
@Slf4j
@ServerEndpoint("/websocket/{userId}")
public class WebSocketServer {
    //与某个客户端的连接会话，需要通过它来给客户端发送数据
    private Session session;
    private String userId;
    private static final CopyOnWriteArraySet<WebSocketServer> webSockets = new CopyOnWriteArraySet<>();
    // 用来存在线连接数
    private static final Map<String, Session> sessionPool = new ConcurrentHashMap<>();
    /**
     * 链接成功调用的方法
     */
    @OnOpen
    public void onOpen(Session session, @PathParam(value = "userId") String userId) {
        try {
            this.session = session;
            this.userId = userId;
            webSockets.add(this);
            sessionPool.put(userId, session);
            log.info("websocket消息: 有新的连接，总数为:" + webSockets.size());
        } catch (Exception e) {
            log.error("WebSocket 连接初始化失败，userId={}", userId, e);
        }
    }
    /**
     * 连接关闭时清理当前会话
     */
    @OnClose
    public void onClose() {
        webSockets.remove(this);
        if (userId != null && session != null) {
            sessionPool.remove(userId, session);
        }
    }
    @OnError
    public void onError(Throwable error) {
        log.error("WebSocket 连接异常，userId={}", userId, error);
    }
    /**
     * 收到客户端消息后调用的方法
     */
    @OnMessage
    public void onMessage(String message) {
        log.info("websocket消息: 收到客户端消息:" + message);
    }
    /**
     * 此为单点消息
     */
    public static boolean sendOneMessage(String userId, String message) {
        Session session = sessionPool.get(userId);
        if (session != null && session.isOpen()) {
            try {
                log.info("websocket消: 单点消息:" + message);
                session.getAsyncRemote().sendText(message);
                return true;
            } catch (Exception e) {
                log.error("WebSocket 消息发送失败，userId={}", userId, e);
            }
        }
        return false;
    }
}
```

该示例的 `sessionPool` 同样只保留每个 `userId` 的一个连接。支持多标签页或多设备时，应将值改为会话集合，并为每个连接独立执行发送、心跳、背压和清理逻辑。

如果希望通过 HTTP 接口触发一次服务端推送，可以增加一个与前端参数保持一致的控制器：

```java
@RestController
@RequestMapping("/socket")
public class SocketController {

    @PostMapping("/publish")
    public ResponseEntity<Void> publish(@RequestParam String userId,
                                        @RequestParam String message) {
        return WebSocketServer.sendOneMessage(userId, message)
                ? ResponseEntity.accepted().build()
                : ResponseEntity.notFound().build();
    }
}
```

这个控制器只用于演示请求契约。生产环境还必须对发布接口进行身份认证和授权，不能允许调用方通过任意 `userId` 向其他用户推送消息；同时应限制消息大小和请求频率。

在使用内嵌 Servlet 容器的 Spring Boot 应用中，通常还需要注入 `ServerEndpointExporter`，由它注册使用了 `@ServerEndpoint` 注解的 WebSocket 端点。

```java
@Configuration
public class WebSocketConfiguration {

    /**
     * 用于注册使用了 @ServerEndpoint 注解的 WebSocket 服务器
     */
    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
```

前端初始化打开 WebSocket 连接，并监听连接状态，接收服务端数据或向服务端发送数据。

```javascript
<script>
    var ws = new WebSocket('ws://localhost:7777/websocket/10086');
    // 获取连接状态
    console.log('ws连接状态：' + ws.readyState);
    //监听是否连接成功
    ws.onopen = function () {
        console.log('ws连接状态：' + ws.readyState);
        //连接成功则发送一个数据
        ws.send('test1');
    }
    // 接听服务器发回的信息并处理展示
    ws.onmessage = function (data) {
        console.log('接收到来自服务器的消息：');
        console.log(data);
        //完成通信后关闭WebSocket连接
        ws.close();
    }
    // 监听连接关闭事件
    ws.onclose = function () {
        // 监听整个过程中websocket的状态
        console.log('ws连接状态：' + ws.readyState);
    }
    // 监听并处理error事件
    ws.onerror = function (error) {
        console.log(error);
    }
    function sendMessage() {
        var content = $("#message").val();
        $.ajax({
            url: '/socket/publish',
            type: 'POST',
            data: { "userId": "10086", "message": content },
            success: function (data) {
                console.log(data)
            }
        })
    }
</script>
```

页面初始化建立 WebSocket 连接，之后就可以进行双向通信了，效果还不错。

![](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000042192395.png)

### MQTT

**什么是 MQTT 协议？**

MQTT 是一种基于发布/订阅（publish/subscribe）模式的轻量级消息协议，通过订阅主题来获取消息，广泛应用于物联网场景。当前 OASIS 规范直接使用“MQTT”这一名称，不再将其展开为“Message Queue Telemetry Transport”。

该协议将消息的发布者（publisher）与订阅者（subscriber）进行分离，因此可以在不可靠的网络环境中，为远程连接的设备提供可靠的消息服务，使用方式与传统的 MQ 有点类似。

![MQTT 协议示例](https://oss.javaguide.cn/github/javaguide/system-design/web-real-time-message-push/1460000022986325.png)

MQTT 位于应用层，需要运行在有序、无损、双向的字节流传输上。最常见的承载方式是 TCP（生产环境通常配合 TLS），也可以通过 WebSocket 等能提供这种字节流语义的传输承载，因此不应简化为“只要有 TCP/IP 就一定能直接使用”。

**为什么要用 MQTT 协议？**

MQTT 协议为什么在物联网（IOT）中如此受偏爱？而不是其它协议，比如我们更为熟悉的 HTTP 协议呢？

- 经典的短连接 HTTP 请求-响应模式需要设备定期请求或保持长连接才能获取服务端更新；MQTT 则直接提供长连接上的异步发布/订阅模型。HTTP 本身不能笼统定义为“同步协议”，HTTP/2、HTTP/3、SSE 和 WebSocket 升级等机制的行为并不等同于经典的短轮询。
- HTTP 请求由客户端发起，但不意味着服务端永远无法流式返回数据，也不意味着设备不能接收命令。MQTT 的优势是把长连接、主题路由、订阅、QoS 和会话状态等能力标准化了。
- 需要向多个设备发送命令时，MQTT broker 可以按主题将消息分发给所有订阅者；HTTP 也能实现类似功能，但往往需要应用自行管理连接、设备组和重试语义。

具体的 MQTT 协议介绍和实践，这里我就不再赘述了，大家可以参考我之前的两篇文章，里边写的也都很详细了。

- MQTT 协议的介绍：[我也没想到 SpringBoot + RabbitMQ 做智能家居，会这么简单](https://mp.weixin.qq.com/s/udFE6k9pPetIWsa6KeErrA)
- MQTT 实现消息推送：[未读消息（小红点），前端 与 RabbitMQ 实时消息推送实践，贼简单~](https://mp.weixin.qq.com/s/U-fUGr9i1MVa4PoVyiDFCg)

## 总结

> 以下内容为 JavaGuide 补充

|           | 介绍                                                                                                          | 优点                   | 缺点                                                 |
| --------- | ------------------------------------------------------------------------------------------------------------- | ---------------------- | ---------------------------------------------------- |
| 短轮询    | 客户端定时向服务端发送请求，服务端直接返回响应数据（即使没有数据更新）                                        | 简单、易理解、易实现   | 实时性太差，无效请求太多，频繁建立连接太耗费资源     |
| 长轮询    | 与短轮询不同是，长轮询接收到客户端请求之后等到有数据更新才返回请求                                            | 减少了无效请求         | 挂起请求会导致资源浪费                               |
| iframe 流 | 服务端和客户端之间创建一条长连接，服务端持续向`iframe`传输数据。                                              | 简单、易理解、易实现   | 维护一个长连接会增加开销，效果太差（图标会不停旋转） |
| SSE       | 一种服务器端到客户端(浏览器)的单向消息推送。                                                                  | 简单、易实现，功能丰富 | 不支持双向通信                                       |
| WebSocket | 除了最初建立连接时用 HTTP 协议，其他时候都是直接基于 TCP 协议进行通信的，可以实现客户端和服务端的全双工通信。 | 性能高、开销小         | 对开发人员要求更高，实现相对复杂一些                 |
| MQTT      | 基于发布/订阅（publish/subscribe）模式的轻量级通讯协议，通过订阅相应的主题来获取消息。                        | 成熟稳定，轻量级       | 对开发人员要求更高，实现相对复杂一些                 |

<!-- @include: @article-footer.snippet.md -->
