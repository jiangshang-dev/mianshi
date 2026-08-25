---
title: Java 定时任务详解
category: 系统设计
icon: "mdi:clock-outline"
description: 系统讲解 Java 定时任务与延时任务：Timer、ScheduledThreadPoolExecutor、DelayQueue、时间轮、Spring @Scheduled（Cron 表达式），以及 Quartz、XXL-JOB、ElasticJob、PowerJob 等分布式任务调度框架的选型对比与适用场景（订单超时取消/定时备份/定时抓取）。
head:
  - - meta
    - name: keywords
      content: 定时任务,Quartz,Elastic-Job,XXL-JOB,PowerJob
---

## 为什么需要定时任务？

我们来看一下几个非常常见的业务场景：

1. 某系统凌晨 1 点要进行数据备份。
2. 某电商平台，用户下单半个小时未支付的情况下需要自动取消订单。
3. 某媒体聚合平台，每 10 分钟动态抓取某某网站的数据为自己所用。
4. 某博客平台，支持定时发送文章。
5. 某基金平台，每晚定时计算用户当日收益情况并推送给用户最新的数据。
6. ……

这些场景往往都要求我们在某个特定的时间去做某个事情，也就是定时或者延时去做某个事情。

- 定时任务：在指定时间点执行特定的任务，例如每天早上 8 点，每周一下午 3 点等。定时任务可以用来做一些周期性的工作，如数据备份，日志清理，报表生成等。
- 延时任务：一定的延迟时间后执行特定的任务，例如 10 分钟后，3 小时后等。延时任务可以用来做一些异步的工作，如订单取消，推送通知，红包撤回等。

尽管二者的适用场景有所区别，但它们的核心思想都是将任务的执行时间安排在未来的某个点上，以达到预期的调度效果。

## 单机定时任务

### Timer

`java.util.Timer`是 JDK 1.3 开始就已经支持的一种定时任务的实现方式。

`Timer` 内部使用一个叫做 `TaskQueue` 的类存放定时任务，它是一个基于最小堆实现的优先级队列。`TaskQueue` 会按照任务距离下一次执行时间的大小将任务排序，保证在堆顶的任务最先执行。这样在需要执行任务时，每次只需要取出堆顶的任务运行即可！

`Timer` 使用起来比较简单，通过下面的方式我们就能创建一个 1s 之后执行的定时任务。

```java
// 示例代码：
TimerTask task = new TimerTask() {
    public void run() {
        System.out.println("当前时间: " + new Date() + "\n" +
                "线程名称: " + Thread.currentThread().getName());
    }
};
System.out.println("当前时间: " + new Date() + "\n" +
        "线程名称: " + Thread.currentThread().getName());
Timer timer = new Timer("Timer");
long delay = 1000L;
timer.schedule(task, delay);


//输出：
当前时间: Fri May 28 15:18:47 CST 2021
线程名称: main
当前时间: Fri May 28 15:18:48 CST 2021
线程名称: Timer
```

不过其缺陷较多。每个 `Timer` 只使用一个后台线程串行执行所有任务，某个任务执行过久会推迟其他任务。如果 `TimerTask#run()` 抛出未捕获的运行时异常或错误，该 `Timer` 的唯一执行线程会终止，后续任务也无法继续调度。这不是“`Timer` 只捕获 `InterruptedException`”可以准确概括的行为。

`Timer` 类上的有一段注释是这样写的：

```JAVA
 * This class does not offer real-time guarantees: it schedules
 * tasks using the <tt>Object.wait(long)</tt> method.
 *Java 5.0 introduced the {@code java.util.concurrent} package and
 * one of the concurrency utilities therein is the {@link
 * java.util.concurrent.ScheduledThreadPoolExecutor
 * ScheduledThreadPoolExecutor} which is a thread pool for repeatedly
 * executing tasks at a given rate or delay.  It is effectively a more
 * versatile replacement for the {@code Timer}/{@code TimerTask}
 * combination, as it allows multiple service threads, accepts various
 * time units, and doesn't require subclassing {@code TimerTask} (just
 * implement {@code Runnable}).  Configuring {@code
 * ScheduledThreadPoolExecutor} with one thread makes it equivalent to
 * {@code Timer}.
```

大概的意思就是：`ScheduledThreadPoolExecutor` 支持多线程执行定时任务并且功能更强大，是 `Timer` 的替代品。

### ScheduledExecutorService

`ScheduledExecutorService` 是一个接口，有多个实现类，比较常用的是 `ScheduledThreadPoolExecutor` 。

![](https://oss.javaguide.cn/javaguide/20210607154324712.png)

`ScheduledThreadPoolExecutor` 本身就是一个线程池，支持任务并发执行。并且，其内部使用 `DelayedWorkQueue` 作为任务队列。

```java
// 示例代码：
TimerTask repeatedTask = new TimerTask() {
    @SneakyThrows
    public void run() {
        System.out.println("当前时间: " + new Date() + "\n" +
                "线程名称: " + Thread.currentThread().getName());
    }
};
System.out.println("当前时间: " + new Date() + "\n" +
        "线程名称: " + Thread.currentThread().getName());
ScheduledExecutorService executor = Executors.newScheduledThreadPool(3);
long delay  = 1000L;
long period = 1000L;
executor.scheduleAtFixedRate(repeatedTask, delay, period, TimeUnit.MILLISECONDS);
Thread.sleep(delay + period * 5);
executor.shutdown();
//输出：
当前时间: Fri May 28 15:40:46 CST 2021
线程名称: main
当前时间: Fri May 28 15:40:47 CST 2021
线程名称: pool-1-thread-1
当前时间: Fri May 28 15:40:48 CST 2021
线程名称: pool-1-thread-1
当前时间: Fri May 28 15:40:49 CST 2021
线程名称: pool-1-thread-2
当前时间: Fri May 28 15:40:50 CST 2021
线程名称: pool-1-thread-2
当前时间: Fri May 28 15:40:51 CST 2021
线程名称: pool-1-thread-2
当前时间: Fri May 28 15:40:52 CST 2021
线程名称: pool-1-thread-2
```

不论是使用 `Timer` 还是 `ScheduledExecutorService` 都无法使用 Cron 表达式指定任务执行的具体时间。

### DelayQueue

`DelayQueue` 是 JUC 包(`java.util.concurrent)`为我们提供的延迟队列，用于实现延时任务比如订单下单 15 分钟未支付直接取消。它是 `BlockingQueue` 的一种，底层是一个基于 `PriorityQueue` 实现的一个无界队列，是线程安全的。关于`PriorityQueue`可以参考笔者编写的这篇文章：[PriorityQueue 源码分析](https://javaguide.cn/java/collection/priorityqueue-source-code.html) 。

![BlockingQueue 的实现类](https://oss.javaguide.cn/github/javaguide/java/collection/blocking-queue-hierarchy.png)

`DelayQueue` 和 `Timer/TimerTask` 都可以作为延时调度的基础。`DelayQueue` 使用优先级队列管理实现了 `Delayed` 接口的元素，只有延迟到期的元素才能被取出，但它本身不负责创建线程执行任务；通常还需要编写消费循环并选择合适的执行器。`Timer` 则自带一个执行线程。两者都可以在创建后继续添加任务，也都支持取消或移除任务，“`Timer` 只能在创建时指定任务”并不成立。

关于 `DelayQueue` 的详细介绍，请参考我写的这篇文章：[`DelayQueue` 源码分析](https://javaguide.cn/java/collection/delayqueue-source-code.html)。

### Spring Task

我们直接通过 Spring 提供的 `@Scheduled` 注解即可定义定时任务，非常方便！

```java
/**
 * cron：使用Cron表达式。　每分钟的1，2秒运行
 */
@Scheduled(cron = "1-2 * * * * ? ")
public void reportCurrentTimeWithCronExpression() {
  log.info("Cron Expression: The time is now {}", dateFormat.format(new Date()));
}

```

我在大学那会做的一个 SSM 的企业级项目，就是用的 Spring Task 来做的定时任务。

并且，Spring Task 还是支持 **Cron 表达式** 的。Cron 表达式主要用于定时作业(定时任务)系统定义执行时间或执行频率的表达式，非常厉害，你可以通过 Cron 表达式进行设置定时任务每天或者每个月什么时候执行等等操作。咱们要学习定时任务的话，Cron 表达式是一定是要重点关注的。推荐一个在线 Cron 表达式生成器：[http://cron.qqe2.com/](http://cron.qqe2.com/) 。

但是，Spring 自带的定时调度只支持单机，并且提供的功能比较单一。之前写过一篇文章:[《5 分钟搞懂如何在 Spring Boot 中 Schedule Tasks》](https://mp.weixin.qq.com/s?__biz=Mzg2OTA0Njk0OA==&mid=2247485563&idx=1&sn=7419341f04036a10b141b74624a3f8c9&chksm=cea247b0f9d5cea6440759e6d49b4e77d06f4c99470243a10c1463834e873ca90266413fbc92&token=2133161636&lang=zh_CN#rd) ，不了解的小伙伴可以参考一下。

Spring 通过 `TaskScheduler` 提供调度抽象，并不固定只有一种底层实现。常用的 `ThreadPoolTaskScheduler` 内部委托给 `ScheduledExecutorService`；在 Jakarta EE 等环境中也可以使用容器管理的调度器。`@Scheduled` 本身不提供集群协调，同一应用部署多个实例时，每个实例都可能触发任务。

**优缺点总结：**

- 优点：简单，轻量，支持 Cron 表达式
- 缺点：功能单一

### 时间轮

Kafka、Dubbo、ZooKeeper、Netty、Caffeine、Akka 中都有对时间轮的实现。

时间轮简单来说就是一个环形的队列（底层一般基于数组实现），队列中的每一个元素（时间格）都可以存放一个定时任务列表。

时间轮中的每个时间格代表了时间轮的基本时间跨度或者说时间精度，假如时间一秒走一个时间格的话，那么这个时间轮的最高精度就是 1 秒（也就是说 3 s 和 3.9s 会在同一个时间格中）。

下图是一个有 12 个时间格的时间轮，转完一圈需要 12 s。当我们需要新建一个 3s 后执行的定时任务，只需要将定时任务放在下标为 3 的时间格中即可。当我们需要新建一个 9s 后执行的定时任务，只需要将定时任务放在下标为 9 的时间格中即可。

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/one-layers-of-time-wheel.png)

那当我们需要创建一个 13s 后执行的定时任务怎么办呢？这个时候可以引入 **圈数/轮数** 的概念。任务仍位于下标为 1 的时间格，同时记录它需要等待的剩余轮数，完整走过一轮再经过 1s 后才执行。不同实现对“当前格是否计入轮数”的约定可能不同，不应脱离具体实现固定写成 2 圈。

除了增加圈数这种方法之外，还有一种 **多层次时间轮** （类似手表），Kafka 采用的就是这种方案。

针对下图的时间轮，我来举一个例子便于大家理解。

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/three-layers-of-time-wheel.png)

上图的时间轮(ms -> s)，第 1 层的时间精度为 1 ，第 2 层的时间精度为 20 ，第 3 层的时间精度为 400。假如我们需要添加一个 350s 后执行的任务 A 的话（当前时间是 0s），这个任务会被放在第 2 层（因为第二层的时间跨度为 20\*20=400>350）的第 350/20=17 个时间格子。

当第一层转了 17 圈之后，时间过去了 340s ，第 2 层的指针此时来到第 17 个时间格子。此时，第 2 层第 17 个格子的任务会被移动到第 1 层。

任务 A 当前是 10s 之后执行，因此它会被移动到第 1 层的第 10 个时间格子。

这里在层与层之间的移动也叫做时间轮的升降级。参考手表来理解就好！

**时间轮比较适合管理大量定时器的场景。在时间轮层数和每层槽数有界的典型实现中，定位槽位、插入和推进指针的开销通常可以做到接近 O(1)；但某个刻度的实际执行开销仍取决于到期任务数、级联迁移和具体实现。**

## 分布式定时任务

### Redis

Redis 是可以用来做延时任务的，基于 Redis 实现延时任务的功能无非就下面两种方案：

1. Redis 过期事件监听
2. Redisson 内置的延时队列

这部分内容的详细介绍我放在了[《后端面试高频系统设计&场景题》](https://javaguide.cn/zhuanlan/back-end-interview-high-frequency-system-design-and-scenario-questions.html)中，有需要的同学可以进入星球后阅读学习。篇幅太多，这里就不重复分享了。

![《后端面试高频系统设计&场景题》](https://oss.javaguide.cn/xingqiu/back-end-interview-high-frequency-system-design-and-scenario-questions-fengmian.png)

### MQ

大部分消息队列，例如 RocketMQ、RabbitMQ，都支持定时/延时消息。定时消息和延时消息本质其实是相同的，都是服务端根据消息设置的定时时间在某一固定时刻将消息投递给消费者消费。

不过，在使用 MQ 定时消息之前一定要看清具体产品和版本的限制。例如，RocketMQ 4.x 的官方实现提供 18 个固定延时级别，最长为 2 小时；RocketMQ 5.x 改为按毫秒级 Unix 时间戳设置投递时间，默认允许的最大定时范围为 24 小时。不能把这两套版本机制合并为同一条限制。

**优缺点总结：**

- **优点**：可以与 Spring 集成、支持分布式、支持集群、性能不错
- **缺点**：功能性较差、不灵活、需要保障消息可靠性

## 分布式任务调度框架

如果我们需要一些高级特性比如支持任务在分布式场景下的分片和高可用的话，我们就需要用到分布式任务调度框架了。

通常情况下，一个分布式定时任务的执行往往涉及到下面这些角色：

- **任务**：首先肯定是要执行的任务，这个任务就是具体的业务逻辑比如定时发送文章。
- **调度器**：其次是调度中心，调度中心主要负责任务管理，会分配任务给执行器。
- **执行器**：最后就是执行器，执行器接收调度器分派的任务并执行。

### Quartz

一个很火的开源任务调度框架，完全由 Java 写成。Quartz 可以说是 Java 定时任务领域的老大哥或者说参考标准，其他的任务调度框架基本都是基于 Quartz 开发的，比如当当网的`elastic-job`就是基于 Quartz 二次开发之后的分布式调度解决方案。

使用 Quartz 可以很方便地与 Spring 集成，并且支持动态添加任务和集群。但是，Quartz 使用起来也比较麻烦，API 繁琐。

并且，Quartz 并没有内置 UI 管理控制台，不过你可以使用 [quartzui](https://github.com/zhaopeiym/quartzui) 这个开源项目来解决这个问题。

另外，Quartz 虽然也支持分布式任务。但是，它是在数据库层面，通过数据库的锁机制做的，有非常多的弊端比如系统侵入性严重、节点负载不均衡。有点伪分布式的味道。

**优缺点总结：**

- 优点：可以与 Spring 集成，并且支持动态添加任务和集群。
- 缺点：分布式支持不友好，不支持任务可视化管理、使用麻烦（相比于其他同类型框架来说）

### Elastic-Job

ElasticJob 最初由当当网开源，历史上曾分为 ElasticJob-Lite 和 ElasticJob-Cloud 两个子项目。这种分类以及 ElasticJob-Cloud 对 Mesos 的依赖属于早期版本语境，不应作为当前选型表。当前官方将 ElasticJob 描述为提供分布式任务分片的轻量级、去中心化解决方案，注册中心支持 ZooKeeper 和 etcd。

`ElasticJob` 支持任务在分布式场景下的分片和高可用、任务可视化管理等功能。

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/elasticjob-feature-list.png)

下面是早期 ElasticJob-Lite 以 ZooKeeper 为注册中心的架构图，用于理解其去中心化调度思路；当前版本还支持 etcd，不能把图中的组件当成唯一部署方式。

![ElasticJob-Lite 的架构设计](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/elasticjob-lite-architecture-design.png)

在这种部署中，ElasticJob 不设置中心化调度服务，而是使用 ZooKeeper 协调各节点的任务分片。当前版本也可以选择 etcd 作为注册中心。

Elastic-Job 中的定时调度都是由执行器自行触发，这种设计也被称为去中心化设计（调度和处理都是执行器单独完成）。

当前官方 Spring Boot Starter 通过 Spring Bean 和配置文件注册任务，不提供 `@ElasticJobConf` 注解。下面以 ZooKeeper 注册中心为例：

```java
@Component
public class TestJob implements SimpleJob {
    @Override
    public void execute(ShardingContext context) {
        System.out.printf("任务名：%s，分片总数：%d，当前分片参数：%s%n",
                context.getJobName(),
                context.getShardingTotalCount(),
                context.getShardingParameter());
    }
}
```

```yaml
elasticjob:
  regCenter:
    serverLists: localhost:2181
    namespace: elasticjob-demo
  jobs:
    dayJob:
      elasticJobClass: com.example.job.TestJob
      cron: 0/10 * * * * ?
      shardingTotalCount: 2
      shardingItemParameters: 0=AAAA,1=BBBB
```

配置属性和注册中心类型会随版本演进，接入时应以所用版本的 [Spring Boot Starter 文档](https://shardingsphere.apache.org/elasticjob/current/en/user-manual/usage/job-api/spring-boot-starter/)和[注册中心文档](https://shardingsphere.apache.org/elasticjob/current/en/user-manual/configuration/registry-center/)为准。

**相关地址：**

- GitHub 地址：<https://github.com/apache/shardingsphere-elasticjob>。
- 官方网站：<https://shardingsphere.apache.org/elasticjob/index_zh.html> 。

**优缺点总结：**

- 优点：可以与 Spring 集成、支持分布式、支持集群、性能不错、支持任务可视化管理
- 缺点：需要额外部署 ZooKeeper 或 etcd 等注册中心，会增加系统复杂度和维护成本

### XXL-JOB

`XXL-JOB` 于 2015 年开源，是一款优秀的轻量级分布式任务调度框架，支持任务可视化管理、弹性扩容缩容、任务失败重试和告警、任务分片等功能，

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/xxljob-feature-list.png)

根据 `XXL-JOB` 官网介绍，其解决了很多 Quartz 的不足。

> Quartz 作为开源作业调度中的佼佼者，是作业调度的首选。但是集群环境中 Quartz 采用 API 的方式对任务进行管理，从而可以避免上述问题，但是同样存在以下问题：
>
> - 问题一：调用 API 的方式操作任务，不人性化；
> - 问题二：需要持久化业务 QuartzJobBean 到底层数据表中，系统侵入性相当严重。
> - 问题三：调度逻辑和 QuartzJobBean 耦合在同一个项目中，这将导致一个问题，在调度任务数量逐渐增多，同时调度任务逻辑逐渐加重的情况下，此时调度系统的性能将大大受限于业务；
> - 问题四：quartz 底层以“抢占式”获取 DB 锁并由抢占成功节点负责运行任务，会导致节点负载悬殊非常大；而 XXL-JOB 通过执行器实现“协同分配式”运行任务，充分发挥集群优势，负载各节点均衡。
>
> XXL-JOB 弥补了 quartz 的上述不足之处。

`XXL-JOB` 的架构设计如下图所示：

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/xxljob-architecture-design-v2.1.0.png)

从上图可以看出，`XXL-JOB` 由 **调度中心** 和 **执行器** 两大部分组成。调度中心主要负责任务管理、执行器管理以及日志管理。执行器主要是接收调度信号并处理。另外，调度中心进行任务调度时，是通过自研 RPC 来实现的。

不同于 Elastic-Job 的去中心化设计， `XXL-JOB` 的这种设计也被称为中心化设计（调度中心调度多个执行器执行任务）。

和 `Quzrtz` 类似 `XXL-JOB` 也是基于数据库锁调度任务，存在性能瓶颈。不过，一般在任务量不是特别大的情况下，没有什么影响的，可以满足绝大部分公司的要求。

当前版本推荐在 Spring Bean 的无参 `void` 方法上使用 `@XxlJob`。任务参数、日志和执行结果通过 `XxlJobHelper` 处理；`@JobHandler`、带 `String` 入参并返回 `ReturnT` 的写法属于旧版 API。

```java
@Component
public class MyApiJobHandler {

    @XxlJob("myApiJobHandler")
    public void execute() {
        String param = XxlJobHelper.getJobParam();
        XxlJobHelper.log("任务参数：{}", param);
        // 执行业务逻辑；默认执行结果为成功，失败时可调用 XxlJobHelper.handleFail(...)
    }
}
```

![](https://oss.javaguide.cn/github/javaguide/system-design/schedule-task/xxljob-admin-task-management.png)

**相关地址：**

- GitHub 地址：<https://github.com/xuxueli/xxl-job/>。
- 官方介绍：<https://www.xuxueli.com/xxl-job/> 。

**优缺点总结：**

- 优点：开箱即用（学习成本比较低）、与 Spring 集成、支持分布式、支持集群、支持任务可视化管理。
- 缺点：不支持动态添加任务（如果一定想要动态创建任务也是支持的，参见：[xxl-job issue277](https://github.com/xuxueli/xxl-job/issues/277)）。

### PowerJob

非常值得关注的一个分布式任务调度框架，分布式任务调度领域的新星。目前，已经有很多公司接入比如 OPPO、京东、中通、思科。

这个框架的诞生也挺有意思的，PowerJob 的作者当时在阿里巴巴实习过，阿里巴巴那会使用的是内部自研的 SchedulerX（阿里云付费产品）。实习期满之后，PowerJob 的作者离开了阿里巴巴。想着说自研一个 SchedulerX，防止哪天 SchedulerX 满足不了需求，于是 PowerJob 就诞生了。

更多关于 PowerJob 的故事，小伙伴们可以去看看 PowerJob 作者的视频 [《我和我的任务调度中间件》](https://www.bilibili.com/video/BV1SK411A7F3/)。简单点概括就是：“游戏没啥意思了，我要扛起了新一代分布式任务调度与计算框架的大旗！”。

由于 SchedulerX 属于人民币产品，我这里就不过多介绍。PowerJob 官方也对比过其和 QuartZ、XXL-JOB 以及 SchedulerX。下表是项目方的功能对比，不是独立基准测试；性能和容量仍需结合版本、数据库、部署规模与业务负载验证。

|                | QuartZ                                      | xxl-job                                    | SchedulerX 2.0                                       | PowerJob                                                        |
| -------------- | ------------------------------------------- | ------------------------------------------ | ---------------------------------------------------- | --------------------------------------------------------------- |
| 定时类型       | CRON                                        | CRON                                       | CRON、固定频率、固定延迟、OpenAPI                    | **CRON、固定频率、固定延迟、OpenAPI**                           |
| 任务类型       | 内置 Java                                   | 内置 Java、GLUE Java、Shell、Python 等脚本 | 内置 Java、外置 Java（FatJar）、Shell、Python 等脚本 | **内置 Java、外置 Java（容器）、Shell、Python 等脚本**          |
| 分布式计算     | 无                                          | 静态分片                                   | MapReduce 动态分片                                   | **MapReduce 动态分片**                                          |
| 在线任务治理   | 不支持                                      | 支持                                       | 支持                                                 | **支持**                                                        |
| 日志白屏化     | 不支持                                      | 支持                                       | 不支持                                               | **支持**                                                        |
| 调度方式及性能 | 基于数据库锁，有性能瓶颈                    | 基于数据库锁，有性能瓶颈                   | 不详                                                 | **项目方称采用无锁化设计，实际容量需压测**                      |
| 报警监控       | 无                                          | 邮件                                       | 短信                                                 | **WebHook、邮件、钉钉与自定义扩展**                             |
| 系统依赖       | JDBC 支持的关系型数据库（MySQL、Oracle...） | MySQL                                      | 人民币                                               | **任意 Spring Data Jpa 支持的关系型数据库（MySQL、Oracle...）** |
| DAG 工作流     | 不支持                                      | 不支持                                     | 支持                                                 | **支持**                                                        |

## 定时任务方案总结

单机定时任务的常见解决方案有 `Timer`、`ScheduledExecutorService`、`DelayQueue`、Spring Task 和时间轮。对普通 Java 周期或延时任务，通常优先使用 `ScheduledExecutorService` 或 Spring Task；时间轮更适合大量定时器、允许一定时间精度换取调度性能的场景，并不是所有单机任务的默认最佳方案。

Redis 和 MQ 虽然可以实现分布式延时触发，但它们通常不提供完整的任务编排、分片、失败补偿和可视化管理。可靠 MQ 的常见交付语义是“至少一次”，在超时、重试或故障切换时可能出现重复投递，因此消费端必须做幂等处理。周期任务需要调度器持续产生新的触发事件，与一条消息能否被“消费多次”没有直接关系。MQ 仍然很适合订单超时取消等一次性延时触发，也能用于解耦调度与执行。

无论选择哪种方案，上生产前都应明确以下语义：

- 任务是否幂等，如何处理重复执行；
- 应用停机或错过执行时间后，是补执行、跳过还是合并执行；
- 超时、重试、退避、最大尝试次数和死信/人工补偿策略；
- 时区、夏令时、时钟回拨以及集群时钟偏差的处理方式；
- 集群中如何避免非预期的重复调度，并对延迟、成功率、重试和积压建立监控告警。

Quartz、Elastic-Job、XXL-JOB 和 PowerJob 这几个是专门用来做分布式调度的框架，提供的分布式定时任务的功能更为完善和强大，更加适合执行周期性的定时任务。除了 Quartz 之外，另外三者都是支持任务可视化管理的。

XXL-JOB 2015 年推出，使用门槛相对较低，采用中心化调度；ElasticJob 采用去中心化调度，并通过 ZooKeeper 或 etcd 协调任务分片。两者的架构和运维依赖不同，不能据此直接断言某一个框架“性能更好”。选型时应针对实际版本、任务数量、触发频率、分片规模、故障恢复要求和数据库或注册中心负载进行压测。PowerJob 等其他框架也应按相同维度验证，不宜只依据项目方的功能对比表下结论。

这篇文章并没有介绍到实际使用，但是，并不代表实际使用不重要。我在写这篇文章之前，已经动手写过相应的 Demo。像 Quartz，我在大学那会就用过。不过，当时用的是 Spring 。为了能够更好地体验，我自己又在 Spring Boot 上实际体验了一下。如果你并没有实际使用某个框架，就直接说它并不好用的话，是站不住脚的。

<!-- @include: @article-footer.snippet.md -->
