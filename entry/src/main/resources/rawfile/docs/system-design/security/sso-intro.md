---
title: SSO 单点登录详解
description: SSO单点登录原理详解，涵盖统一认证中心设计、CAS协议、跨域登录实现及登录态同步机制。
category: 系统设计
tag:
  - 安全
head:
  - - meta
    - name: keywords
      content: SSO,单点登录,统一认证,登录态,票据,TGT,ST,CAS协议,跨域登录
---

> 本文授权转载自：<https://ken.io/note/sso-design-implement> 作者：ken.io

## SSO 介绍

### 什么是 SSO？

SSO 英文全称 Single Sign On，单点登录。SSO 是在多个应用系统中，用户只需要登录一次就可以访问所有相互信任的应用系统。

例如你登录网易账号中心（<https://reg.163.com/> ）之后访问以下站点都是登录状态。

- 网易直播 [https://v.163.com](https://v.163.com/)
- 网易博客 [https://blog.163.com](https://blog.163.com/)
- 网易花田 [https://love.163.com](https://love.163.com/)
- 网易考拉 [https://www.kaola.com](https://www.kaola.com/)
- 网易 Lofter [http://www.lofter.com](http://www.lofter.com/)

### SSO 有什么好处？

1. **用户角度** :用户能够做到一次登录多次使用，无需记录多套用户名和密码，省心。
2. **系统管理员角度** : 管理员只需维护好一个统一的账号中心就可以了，方便。
3. **新系统开发角度:** 新系统开发时只需直接对接统一的账号中心即可，简化开发流程，省时。

## SSO 设计与实现

本篇文章也主要是为了探讨如何设计&实现一个 SSO 系统

以下为需要实现的核心功能：

- 单点登录
- 单点登出
- 支持跨域单点登录
- 支持跨域单点登出

### 核心应用与依赖

![单点登录（SSO）设计](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-system.png-kblb.png)

| 应用/模块/对象    | 说明                                |
| ----------------- | ----------------------------------- |
| 前台站点          | 需要登录的站点                      |
| SSO 站点-登录     | 提供登录的页面                      |
| SSO 站点-登出     | 提供注销登录的入口                  |
| SSO 服务-登录     | 提供登录服务                        |
| SSO 服务-登录状态 | 提供登录状态校验/登录信息查询的服务 |
| SSO 服务-登出     | 提供用户注销登录的服务              |
| 数据库            | 存储用户账户信息                    |
| 缓存              | 存储用户的登录信息，通常使用 Redis  |

### 用户登录状态的存储与校验

常见的 Web 框架对于 Session 的实现都是生成一个 SessionId 存储在浏览器 Cookie 中。然后将 Session 内容存储在服务器端内存中，这个 [ken.io](https://ken.io/) 在之前[Session 工作原理](https://ken.io/note/session-principle-skill)中也提到过。整体也是借鉴这个思路。

用户登录成功后，SSO 站点建立自己的登录会话。浏览器中的会话标识应保存在设置了 `Secure`、`HttpOnly` 和合适 `SameSite` 属性的 Cookie 中；Cookie 尽量只作用于当前主机，不要为了共享登录态而直接扩大到整个父域。手机 App 则应使用系统浏览器完成标准授权流程，并把必要凭据保存在 Keychain、Keystore 等安全存储中。本篇主要探讨基于 Web 站点的 SSO。

用户在浏览需要登录的页面时，客户端将 AuthToken 提交给 SSO 服务校验登录状态/获取用户登录信息

对于登录信息的存储，建议采用 Redis，使用 Redis 集群来存储登录信息，既可以保证高可用，又可以线性扩充。同时也可以让 SSO 服务满足负载均衡/可伸缩的需求。

| 对象      | 说明                                                                                                                                                 |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| AuthToken | 使用密码学安全随机数生成的高熵、不可预测标识，并设置过期、轮换和撤销机制。不要使用可预测的 UUID 版本，也不要自行把 UserName+时间戳加密后当作会话令牌 |
| 登录信息  | 通常是将 UserId，UserName 缓存起来                                                                                                                   |

### 用户登录/登录校验

**登录时序图**

![SSO系统设计-登录时序图](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-login-sequence.png-kbrb.png)

上图展示的是通过父域 Cookie 在多个子域间共享 AuthToken 的做法。新系统不建议把认证 Cookie 的 `Domain` 设置为 `.test.com`：这样会把同一凭据发送给所有匹配的子域，任一薄弱、废弃或被接管的子域都可能扩大攻击面。

更稳妥的做法是让 SSO 站点和各业务站点分别维护 host-only 会话。业务站点需要登录时跳转到 SSO 站点，SSO 站点利用自己的 Cookie 判断用户是否已登录，再通过一次性、短时有效的授权码把认证结果返回业务站点，由业务站点后端换取用户信息并建立本地会话。

**登录信息获取/登录状态校验**

![SSO系统设计-登录信息获取/登录状态校验](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-logincheck-sequence.png-kbrb.png)

### 用户登出

SSO 登出不只是删除一个 Cookie：

1. SSO 服务端撤销中央登录会话和相关刷新授权。
2. SSO 站点清除自己的会话 Cookie。
3. 根据协议和业务风险，通过前通道或后通道通知各业务站点清理本地会话，并处理通知失败、站点离线等情况。

**登出时序图**

![SSO系统设计-用户登出](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-logout-sequence.png-kbrb.png)

### 跨域登录、登出

跨域 SSO 不应尝试解决 Cookie 的跨域读写问题，而应通过标准的浏览器重定向和后端令牌交换建立各站点自己的会话。常见选择是 OpenID Connect Authorization Code Flow。

解决跨域的核心思路就是：

- 登录完成后，SSO 服务只向预先登记并严格匹配的回调地址返回一次性、短时有效的授权码。业务站点后端使用该授权码换取认证结果，并建立自己的会话，不在多个域之间复制同一个长期 Bearer Token。
- 授权请求需要校验 `state`；使用 OpenID Connect 时还要校验 Issuer、Audience 和签名，并在使用 `nonce` 时核对其值。公共客户端使用 Authorization Code Flow 时还应使用 PKCE。
- 跨站登出使用协议定义的前通道或后通道通知，并允许业务站点在通知失败时通过会话过期、令牌撤销和重新校验收敛状态。

**跨域登录（主域名已登录）**

![SSO系统设计-跨域登录（主域名已登录）](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-crossdomain-login-loggedin-sequence.png-kbrb.png)

**跨域登录（主域名未登录）**

![SSO系统设计-跨域登录（主域名未登录）](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-crossdomain-login-unlogin-sequence.png-kbrb.png)

**跨域登出**

![SSO系统设计-跨域登出](https://oss.javaguide.cn/github/javaguide/system-design/security/sso/sso-crossdomain-logout-sequence.png-kbrb.png)

上面的时序图来自原转载方案，主要用于帮助理解登录跳转和通知关系，其中直接传递 AuthToken、共享父域 Cookie 等细节不应作为新系统的实现依据。新系统应以所选 OpenID Connect/OAuth 协议的当前安全规范为准。

## 说明

- 关于方案：这次设计方案更多是提供实现思路。APP 用户登录不应只增加一个自定义“APP 签名”就作为安全方案，推荐使用系统浏览器完成 OpenID Connect/OAuth Authorization Code Flow，并使用 PKCE；APP 不能被当作能够永久保守客户端密钥的可信环境。
- 关于时序图：时序图中并没有包含所有场景，只列举了核心/主要场景，另外对于一些不影响理解思路的消息能省就省了。

## 参考

- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0-18.html)
- [RFC 9700：Best Current Practice for OAuth 2.0 Security](https://www.rfc-editor.org/rfc/rfc9700.html)

<!-- @include: @article-footer.snippet.md -->
