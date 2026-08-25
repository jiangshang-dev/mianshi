---
title: DNS 域名系统详解（应用层）
description: 详解 DNS 的层次结构与解析流程，覆盖递归/迭代、缓存与权威服务器，明确应用层端口与性能优化要点。
category: 计算机基础
tag:
  - 计算机网络
head:
  - - meta
    - name: keywords
      content: DNS,域名解析,递归查询,迭代查询,缓存,权威DNS,端口53,UDP
---

在浏览器地址栏输入域名之后，真正发起 HTTP 请求之前，通常要先经过 DNS 解析。

DNS 要解决的是**域名和 IP 地址的映射问题**。它看起来只是“把域名翻译成 IP”，但背后涉及本地缓存、递归查询、迭代查询、权威服务器、根服务器、UDP/TCP 切换等一整套机制。

这篇文章主要回答几个问题：

1. DNS 为什么需要分层设计？
2. 一次完整的域名解析通常会经过哪些步骤？
3. 递归查询和迭代查询有什么区别？
4. DNS 为什么通常基于 UDP，什么情况下会改用 TCP？

![DNS 将域名解析为 IP 地址的系统概览](https://oss.javaguide.cn/github/javaguide/cs-basics/network/dns-overview.png)

在实际使用中，有一种情况下，浏览器是可以不必动用 DNS 就可以获知域名和 IP 地址的映射的。浏览器在本地会维护一个 `hosts` 列表，一般来说浏览器要先查看要访问的域名是否在 `hosts` 列表中，如果有的话，直接提取对应的 IP 地址记录，就好了。如果本地 `hosts` 列表内没有域名-IP 对应记录的话，那么 DNS 就闪亮登场了。

目前 DNS 的设计采用的是分布式、层次数据库结构，**DNS 是应用层协议，通常基于 UDP 协议，端口为 53**。当响应数据超过 UDP 报文长度限制（512 字节，EDNS0 可扩展至更大）或进行区域传送（Zone Transfer）时，会改用 TCP 协议以保证数据完整性。

![TCP/IP 各层协议概览](https://oss.javaguide.cn/github/javaguide/cs-basics/network/network-protocol-overview.png)

## DNS 服务器

DNS 可以从两个维度描述。权威层次包括根、顶级域和具体区域的权威服务器；查询侧则包括存根解析器、递归解析器和转发器等角色。同一套软件或同一台服务器也可能承担多个角色，因此这些类别不是互斥且穷尽的“服务器类型”。

- 根 DNS 服务器。根服务器向查询方提供顶级域服务器的转介信息。
- 顶级域 DNS 服务器（TLD 服务器）。顶级域是指域名的后缀，如 `com`、`org`、`net` 和 `edu` 等。国家和地区也有自己的顶级域，如 `uk`、`fr` 和 `ca`。TLD 服务器通常返回目标域权威服务器的转介信息。
- 权威 DNS 服务器。权威服务器保存一个或多个 DNS 区域的数据，并对这些区域内的查询给出权威回答。
- 递归解析器。本地网络、ISP 或公共 DNS 服务通常会提供递归解析器。它接收客户端查询，先检查缓存，必要时再向根、TLD 和权威服务器逐级查询。递归解析器属于查询侧角色，不是权威 DNS 层次的一层。

**世界上真的只有 13 台根服务器吗？** 这是一个流传已久的技术误解。如果你在网上搜索，仍能看到许多陈旧文章宣称“全球仅有 13 台根服务器，且全部由美国控制”。

**事实并非如此。**

根服务器系统逻辑上有 13 个命名的根服务器标识，从 `a.root-servers.net` 到 `m.root-servers.net`，由 12 个独立运营组织负责。这个数量与早期 DNS 使用 UDP 传输时的报文大小约束有关，但不能理解为全球只有 13 台物理服务器。

每个根服务器标识背后可以通过 **IP 任播（Anycast）** 部署多个物理实例。BGP 会根据当前网络路由把查询引导到路径上合适的实例，而不一定是地理距离最近的实例。实例数量和地点会持续变化，应以 **[Root-Servers.org](https://root-servers.org/)** 的实时数据为准。

![Root-Servers.org 展示全球根服务器实例分布](https://oss.javaguide.cn/github/javaguide/cs-basics/network/root-servers-org.png)

## DNS 工作流程

以下图为例，介绍 DNS 的查询解析过程。DNS 的查询解析过程分为两种模式：

- **迭代**
- **递归**

下图是实践中常采用的方式，从请求主机到本地 DNS 服务器的查询是递归的，其余的查询时迭代的。

![DNS 递归查询与迭代查询结合的解析流程](https://oss.javaguide.cn/github/javaguide/cs-basics/network/DNS-process.png)

现在，主机 `cis.poly.edu` 想知道 `gaia.cs.umass.edu` 的 IP 地址。假设主机 `cis.poly.edu` 的本地 DNS 服务器为 `dns.poly.edu`，并且 `gaia.cs.umass.edu` 的权威 DNS 服务器为 `dns.cs.umass.edu`。

1. 首先，主机 `cis.poly.edu` 向本地 DNS 服务器 `dns.poly.edu` 发送一个 DNS 请求，该查询报文包含被转换的域名 `gaia.cs.umass.edu`。
2. 本地 DNS 服务器 `dns.poly.edu` 检查本机缓存，发现并无记录，也不知道 `gaia.cs.umass.edu` 的 IP 地址该在何处，不得不向根服务器发送请求。
3. 根服务器注意到请求报文中含有 `edu` 顶级域，因此告诉本地 DNS，你可以向 `edu` 的 TLD DNS 发送请求，因为目标域名的 IP 地址很可能在那里。
4. 本地 DNS 获取到了 `edu` 的 TLD DNS 服务器地址，向其发送请求，询问 `gaia.cs.umass.edu` 的 IP 地址。
5. `edu` 的 TLD DNS 服务器仍不清楚请求域名的 IP 地址，但是它注意到该域名有 `umass.edu` 前缀，因此返回告知本地 DNS，`umass.edu` 的权威服务器可能记录了目标域名的 IP 地址。
6. 这一次，本地 DNS 将请求发送给权威 DNS 服务器 `dns.cs.umass.edu`。
7. 终于，由于 `gaia.cs.umass.edu` 向权威 DNS 服务器备案过，在这里有它的 IP 地址记录，权威 DNS 成功地将 IP 地址返回给本地 DNS。
8. 最后，本地 DNS 获取到了目标域名的 IP 地址，将其返回给请求主机。

除了迭代式查询，还有一种递归式查询如下图，具体过程和上述类似，只是顺序有所不同。

![DNS 递归查询解析域名的流程](https://oss.javaguide.cn/github/javaguide/cs-basics/network/DNS-process2.png)

递归解析器会缓存此前查询得到的转介和资源记录，因此很多查询不需要每次都从根服务器开始。只要相关缓存仍在 TTL 有效期内，解析器就可以直接联系已知的 TLD 或权威服务器，从而缩短查询路径并减少上游服务器负担。

## DNS 报文格式

DNS 的报文格式如下图所示：

![DNS 查询报文和回答报文的字段格式](https://oss.javaguide.cn/github/javaguide/cs-basics/network/DNS-packet.png)

DNS 报文分为查询和回答报文，两种形式的报文结构相同。

- 标识符。16 比特，用于标识该查询。这个标识符会被复制到对查询的回答报文中，以便让客户用它来匹配发送的请求和接收到的回答。
- 标志。1 比特的“查询/回答”标识位，`0` 表示查询报文，`1` 表示回答报文；1 比特的“权威的”标志位（当某 DNS 服务器是所请求名字的权威 DNS 服务器时，且是回答报文，使用“权威的”标志）；1 比特的“希望递归”标志位，显式地要求执行递归查询；1 比特的“递归可用”标志位，用于回答报文中，表示 DNS 服务器支持递归查询。
- 问题数、回答 RR 数、权威 RR 数、附加 RR 数。分别指示了后面 4 类数据区域出现的数量。
- 问题区域。包含正在被查询的主机名字，以及正被询问的问题类型。
- 回答区域。包含了对最初请求的名字的资源记录。**在回答报文的回答区域中可以包含多条 RR，因此一个主机名能够有多个 IP 地址。**
- 权威区域。包含了其他权威服务器的记录。
- 附加区域。包含了其他有帮助的记录。

## DNS 记录

DNS 服务器在响应查询时，需要查询自己的数据库，数据库中的条目被称为 **资源记录（Resource Record，RR）**。RR 提供了主机名到 IP 地址的映射。RR 是一个包含了 `Name`、`Value`、`Type`、`TTL` 四个字段的四元组。

![DNS 资源记录的四元组字段](https://oss.javaguide.cn/github/javaguide/cs-basics/network/20210506174303797.png)

`TTL` 是该记录的生存时间，它决定了资源记录应当从缓存中删除的时间。

`Name` 和 `Value` 字段的取值取决于 `Type`：

![不同 DNS 资源记录类型的 Name 和 Value 含义](https://oss.javaguide.cn/github/javaguide/cs-basics/network/20210506170307897.png)

- 如果 `Type=A`，则 `Name` 是主机名信息，`Value` 是该主机名对应的 IP 地址。这样的 RR 记录了一条主机名到 IP 地址的映射。
- 如果 `Type=AAAA`（与 `A` 记录非常相似），唯一的区别是 A 记录使用的是 IPv4，而 `AAAA` 记录使用的是 IPv6。
- 如果 `Type=CNAME`（Canonical Name Record，真实名称记录），则 `Value` 是别名为 `Name` 的主机对应的规范主机名。`Value` 值才是规范主机名。`CNAME` 记录将一个主机名映射到另一个主机名。`CNAME` 记录用于为现有的 `A` 记录创建别名。下文有示例。
- 如果 `Type=NS`，则 `Name` 是个域，而 `Value` 是个知道如何获得该域中主机 IP 地址的权威 DNS 服务器的主机名。通常这样的 RR 是由 TLD 服务器发布的。
- 如果 `Type=MX`，则 `Value` 是个别名为 `Name` 的邮件服务器的规范主机名。既然有了 `MX` 记录，那么邮件服务器可以和其他服务器使用相同的别名。为了获得邮件服务器的规范主机名，需要请求 `MX` 记录；为了获得其他服务器的规范主机名，需要请求 `CNAME` 记录。

`CNAME` 记录总是指向另一则域名，而非 IP 地址。假设有下述 DNS zone：

```plain
NAME                    TYPE   VALUE
--------------------------------------------------
bar.example.com.        CNAME  foo.example.com.
foo.example.com.        A      192.0.2.23
```

当用户查询 `bar.example.com` 的时候，DNS Server 实际返回的是 `foo.example.com` 的 IP 地址。

## 参考

- DNS 服务器类型：<https://www.cloudflare.com/zh-cn/learning/dns/dns-server-types/>
- DNS Message Resource Record Field Formats：<http://www.tcpipguide.com/free/t_DNSMessageResourceRecordFieldFormats-2.htm>
- Understanding Different Types of Record in DNS Server：<https://www.mustbegeek.com/understanding-different-types-of-record-in-dns-server/>

<!-- @include: @article-footer.snippet.md -->
