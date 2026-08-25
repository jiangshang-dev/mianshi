# AI 面试刷题鸿蒙 App 产品需求文档 V1.0

## 一、项目概述

### 1.1 产品定位

本项目是一款面向程序员、计算机专业学生以及互联网求职人群的 **AI 智能面试学习鸿蒙 App**。

产品核心不是单纯提供面试题，而是围绕：

**看面试题 → 理解知识点 → 随时问 AI → 针对薄弱点学习 → AI 模拟面试 → AI 追问 → 面试评分 → 复盘提升**

形成完整学习闭环。

产品内容可以覆盖：

- Java
- Spring
- Spring Boot
- Spring Cloud
- MySQL
- Redis
- JVM
- Java 并发
- 计算机网络
- 操作系统
- 数据结构与算法
- 消息队列
- Elasticsearch
- 微服务
- 分布式
- 高并发
- 系统设计
- Linux
- Docker
- Kubernetes
- AI / LLM
- RAG
- AI Agent
- MCP
- 大模型应用开发
- 项目面试
- HR 面试

---

# 二、产品核心特色

与传统面试刷题 App 最大的区别是：

## 2.1 AI 全程伴随学习

用户在任何一道面试题详情页，都可以点击右下角：

**AI 悬浮按钮**

打开 AI 助手。

AI 自动知道：

- 用户当前看的是什么题
- 当前答案内容
- 当前知识分类
- 用户之前问过什么
- 用户掌握情况

因此用户不需要重新复制题目。

例如当前正在看：

> Redis 为什么这么快？

点击 AI：

用户：

> IO 多路复用这里没看懂。

AI 自动根据当前面试题上下文解释。

还可以继续：

> 用小白能听懂的话讲。

> 举个实际例子。

> 面试的时候应该怎么回答？

> 面试官还可能追问什么？

> 帮我压缩成 1 分钟回答。

---

# 三、整体产品结构

底部导航建议设计为五个 Tab：

1. 首页
2. 题库
3. AI 面试
4. 学习
5. 我的

---

# 四、首页

首页承担学习入口和个性化推荐。

## 4.1 顶部区域

展示：

- 用户头像
- 欢迎语
- 搜索框
- 消息入口

搜索支持：

- 搜面试题
- 搜知识点
- 搜技术方向
- AI 智能搜索

例如搜索：

> Redis 缓存穿透和缓存击穿有什么区别？

既可以返回相关题目，也可以直接让 AI 回答。

---

## 4.2 今日学习

显示：

今日已学习：

- 23 道题
- 学习 42 分钟
- 掌握 18 道
- 待复习 5 道

提供：

**继续学习**

按钮。

---

# 五、面试题分类

首页展示常用技术方向。

例如：

## Java

- Java 基础
- Java 集合
- Java 并发
- JVM
- Java 新特性

## 数据库

- MySQL
- Redis
- MongoDB
- Elasticsearch

## Java Web

- Spring
- Spring MVC
- Spring Boot
- MyBatis
- Spring Security

## 微服务

- Spring Cloud
- Spring Cloud Alibaba
- Nacos
- Sentinel
- Gateway
- Seata

## 分布式

- 分布式事务
- 分布式锁
- 分布式 ID
- CAP
- BASE

## 消息队列

- RocketMQ
- Kafka
- RabbitMQ

## 系统设计

- 秒杀系统
- 短链系统
- IM 系统
- 评论系统
- Feed 流
- 电商系统
- 高并发系统

## AI

- 大模型基础
- Prompt
- RAG
- Embedding
- 向量数据库
- Function Calling
- MCP
- Agent
- Multi-Agent
- AI 系统设计

---

# 六、专题学习

除了普通分类之外，可以设计：

**专题**

例如：

- Java 高频 100 题
- Redis 高频 50 题
- MySQL 高频 80 题
- JVM 高频面试题
- Spring 高频面试题
- 微服务高频面试题
- 大厂 Java 面试题
- 阿里面试专题
- 字节面试专题
- 腾讯面试专题
- 美团面试专题
- AI Agent 面试专题
- 系统设计专题

专题支持：

- 学习进度
- 收藏
- 错题
- 掌握度
- 最近学习

---

# 七、面试题列表

进入：

Redis

显示：

Redis 面试题

顶部：

- 全部
- 基础
- 中级
- 高级
- 高频
- 收藏
- 未掌握

列表例如：

01 Redis 为什么这么快？

高频

掌握度：

★★★★☆

---

02 Redis 有哪些数据结构？

基础

---

03 Redis 缓存穿透怎么解决？

高频

---

04 Redis 缓存击穿怎么解决？

高频

---

05 Redis 缓存雪崩怎么解决？

高频

---

# 八、面试题详情

这是整个 App 使用频率最高的页面之一。

页面结构：

## 8.1 题目

例如：

# Redis 为什么这么快？

标签：

Redis / 高频 / 中级

---

## 8.2 标准答案

展示适合学习的完整解释。

---

## 8.3 面试回答

单独提供：

### 面试中推荐这样回答

控制在：

30 秒 / 1 分钟 / 3 分钟

三个版本。

避免用户学了一大堆知识，但真正面试时不知道怎么组织语言。

---

# 九、知识点拆解

例如：

Redis 为什么这么快？

拆分为：

1. 内存操作
2. 高效数据结构
3. IO 多路复用
4. 单线程避免上下文切换
5. Redis 6.0 多线程网络 IO

每个知识点均可以继续点击学习。

---

# 十、AI 悬浮助手

所有面试题详情页右下角固定：

**AI 图标**

点击之后从底部弹出 AI 对话框。

建议不是跳转新页面，而是：

**BottomSheet 半屏 / 全屏弹窗**

这样用户仍然知道自己正在看哪道题。

---

# 十一、AI 面试题助手

AI 默认自动读取当前题目上下文。

提供快捷提问：

- 看不懂
- 简单解释
- 举个例子
- 深入讲解
- 面试怎么回答
- 面试官会怎么追问
- 和 XXX 有什么区别
- 给我画思维结构
- 出一道类似题
- 考考我

例如：

题目：

Redis 缓存击穿怎么解决？

点击：

**面试官会怎么追问**

AI：

> 如果使用分布式锁解决缓存击穿，需要注意什么问题？

继续：

> Redisson 的看门狗机制是什么？

形成知识链。

---

# 十二、AI 上下文感知

AI Assistant 调用时自动携带：

```text
用户ID
当前分类
当前专题
当前面试题ID
题目标题
题目正文
标准答案
知识点
最近学习记录
最近AI对话
用户掌握度
```

这样用户不用重复描述上下文。

---

# 十三、AI 模拟面试

底部导航：

**AI 面试**

点击进入 AI 面试中心。

---

# 十四、创建模拟面试

用户选择：

### 面试岗位

- Java 后端
- 高级 Java
- Java 架构师
- 前端
- 测试开发
- DevOps
- AI 应用开发
- AI Agent 开发
- 自定义岗位

---

### 工作经验

- 应届
- 1～3 年
- 3～5 年
- 5～8 年
- 8 年以上

---

### 面试难度

- 简单
- 中等
- 困难
- 大厂

---

### 面试方向

多选：

- Java
- JVM
- MySQL
- Redis
- Spring
- 微服务
- 分布式
- 消息队列
- 系统设计
- 项目经验
- AI
- 算法

---

### 面试时间

- 10 分钟
- 20 分钟
- 30 分钟
- 45 分钟
- 60 分钟

---

# 十五、AI 面试流程

建议完整面试流程：

## 第一阶段

自我介绍

AI：

> 你好，我们今天面试的是高级 Java 开发岗位，请先做一下简单的自我介绍。

---

## 第二阶段

基础知识

AI：

> HashMap 在 JDK 1.8 之后的数据结构是什么？

用户回答。

AI 自动分析回答内容。

---

## 第三阶段

智能追问

如果用户回答：

> 数组 + 链表 + 红黑树。

AI 不直接进入下一题。

继续追问：

> 为什么链表长度达到一定程度之后需要转换成红黑树？

继续：

> 为什么阈值是 8？

继续：

> 为什么红黑树退化阈值是 6？

形成真实面试感。

---

# 十六、AgentScope2 Java 面试 Agent

AI 面试不是简单调用一次 LLM。

建议基于：

**AgentScope 2 Java**

设计多 Agent。

---

# 十七、Agent 架构

建议设计：

```text
InterviewOrchestratorAgent
        │
        ├── InterviewerAgent
        │
        ├── QuestionAgent
        │
        ├── FollowUpAgent
        │
        ├── EvaluationAgent
        │
        ├── KnowledgeAgent
        │
        └── ReportAgent
```

---

# 十八、InterviewOrchestratorAgent

主控 Agent。

负责：

- 控制面试流程
- 判断当前阶段
- 调度不同 Agent
- 判断是否应该追问
- 判断是否切换题目
- 控制面试时长
- 控制题型分布

它相当于整个 AI 面试的主持人。

---

# 十九、QuestionAgent

负责：

**生成 / 选择面试题**

输入：

```text
岗位
工作经验
难度
技术方向
历史题目
薄弱知识点
```

输出：

```json
{
  "question": "Redis 为什么这么快？",
  "category": "Redis",
  "difficulty": "中等",
  "knowledgePoints": [
    "内存",
    "IO多路复用",
    "数据结构"
  ]
}
```

优先从已有题库选择。

AI 只负责：

- 组合
- 推荐
- 动态生成补充题

不能所有题都临时生成。

---

# 二十、FollowUpAgent

专门负责：

**追问**

根据：

用户当前答案

判断：

- 回答正确
- 回答部分正确
- 回答太浅
- 回答有错误
- 有继续深挖价值

例如：

用户：

> Redis 使用单线程，所以性能比较高。

FollowUpAgent 可以判断这个回答存在问题。

追问：

> 单线程为什么反而会提高性能？

然后：

> Redis 6.0 为什么又引入多线程？

---

# 二十一、EvaluationAgent

负责每一道题的回答评价。

输出结构：

```json
{
  "score": 82,
  "accuracy": 85,
  "depth": 75,
  "expression": 80,
  "knowledgeCoverage": 88,
  "advantages": [],
  "problems": [],
  "suggestions": []
}
```

评价维度：

- 正确性
- 完整性
- 深度
- 表达
- 逻辑
- 专业程度

---

# 二十二、KnowledgeAgent

知识 Agent。

负责连接：

面试题库 + RAG 知识库。

用户学习过程中点击 AI：

实际上主要调用：

**KnowledgeAgent**

它负责：

- 当前题目解释
- 知识扩展
- 对比分析
- 举例
- 面试回答优化
- 生成追问题
- 查找关联知识

---

# 二十三、ReportAgent

整场模拟面试结束以后调用。

生成：

# AI 面试报告

总体得分：

82 分

能力雷达：

- Java：90
- JVM：80
- MySQL：75
- Redis：72
- 微服务：86
- 分布式：78
- 系统设计：68

---

## 优势

例如：

Java 基础扎实。

Spring / 微服务掌握较好。

---

## 薄弱点

例如：

Redis 高可用

MySQL 索引优化

系统设计

---

## 推荐学习内容

自动推荐 App 内题目：

- Redis Cluster 原理
- Redis Sentinel 原理
- MySQL Explain
- MySQL 索引失效场景
- 秒杀系统设计

形成：

**AI 面试 → 发现薄弱点 → 回题库学习**

的闭环。

---

# 二十四、学习模式

增加一个：

**AI 考考我**

用户看完一道题以后点击。

AI：

> 好，现在我不告诉你答案，我以面试官身份问你。

然后用户自己回答。

AI 根据回答评分。

这个功能比简单“看答案”更有价值。

---

# 二十五、掌握度体系

每一道题记录：

- 未学习
- 学习中
- 基本掌握
- 已掌握
- 需复习

AI 可以自动更新掌握度。

例如：

看过答案：

掌握度 +5

AI 问答通过：

+10

模拟面试回答正确：

+20

多次回答正确：

标记：

**已掌握**

---

# 二十六、错题 / 薄弱知识库

自动建立：

**我的薄弱知识**

例如：

Redis

- Cluster
- Sentinel
- 缓存一致性

MySQL

- MVCC
- Next-Key Lock

JVM

- G1
- CMS
- 类加载机制

AI 每天自动推荐学习。

---

# 二十七、收藏功能

用户可以收藏：

- 面试题
- 专题
- AI 回答
- 知识点

支持创建收藏夹：

- Java
- 微服务
- 系统设计
- 面试前突击
- 大厂面试

---

# 二十八、学习记录

记录：

- 今日学习
- 连续学习
- 学习题目
- AI 问答次数
- AI 面试次数
- 平均面试分
- 掌握题目数量

---

# 二十九、学习日历

类似 GitHub Contribution。

展示：

```text
一 二 三 四 五 六 日
□ ■ ■ ■ □ ■ ■
■ ■ ■ ■ ■ ■ ■
```

颜色深浅表示学习量。

---

# 三十、每日面试题

首页提供：

**每日 5 题**

根据用户薄弱知识动态推荐。

不是所有用户每天看到相同内容。

---

# 三十一、搜索

支持传统搜索：

```text
Redis
JVM
MVCC
Spring
```

同时支持：

**AI 搜索**

例如：

> 有哪些关于分布式锁的面试题？

AI 返回：

1. Redis 如何实现分布式锁
2. SETNX 有什么问题
3. Redisson 如何实现
4. 看门狗机制
5. Redis 主从切换会导致什么问题

可以直接进入对应题目。

---

# 三十二、岗位学习路线

用户可以选择目标：

Java 初级开发

Java 中级开发

Java 高级开发

Java 架构师

AI 应用开发

Agent 开发

系统自动生成路线。

例如：

Java 高级：

```text
Java基础
 ↓
JVM
 ↓
并发编程
 ↓
MySQL
 ↓
Redis
 ↓
Spring
 ↓
微服务
 ↓
分布式
 ↓
MQ
 ↓
高并发
 ↓
系统设计
```

---

# 三十三、面试冲刺模式

用户设置：

**7 天后面试**

App 生成：

7 天面试冲刺计划。

Day 1：

Java + JVM

Day 2：

MySQL

Day 3：

Redis

Day 4：

Spring / 微服务

Day 5：

分布式

Day 6：

系统设计

Day 7：

AI 综合模拟面试

---

# 三十四、AI 对话页面

除了题目里的悬浮 AI，还提供独立：

**AI 面试助手**

用户可以直接问：

> Spring Boot 自动装配原理是什么？

> 面试怎么回答 Kafka 消息丢失？

> Java 高级面试一般考什么？

> 给我来 10 道 Redis 面试题。

---

# 三十五、语音 AI 面试

V1 可以先做文字。

V2 增加：

**语音模拟面试**

流程：

```text
AI生成问题
↓
TTS
↓
鸿蒙播放语音
↓
用户语音回答
↓
ASR
↓
文字
↓
AgentScope Agent
↓
AI判断
↓
继续追问
```

最终效果接近真实电话 / 视频技术面试。

---

# 三十六、简历面试

后续 V2 可以支持：

上传：

PDF / Word 简历

AI 自动解析：

- 技术栈
- 工作经历
- 项目经历

然后生成：

**针对简历的模拟面试**

例如简历写：

Redis

Spring Cloud

RocketMQ

AI 自动围绕这些技术提问。

---

# 三十七、项目深挖 Agent

这是高级开发和架构岗位非常重要的一部分。

例如简历项目：

电商系统

AI：

> 你这个项目 QPS 最高多少？

继续：

> 秒杀场景怎么防止超卖？

继续：

> Redis 挂了怎么办？

继续：

> RocketMQ 消息重复消费怎么解决？

继续：

> 如果数据库成为瓶颈怎么办？

模拟真实项目深挖。

---

# 三十八、后台管理系统

建议搭建 Vue3 管理后台。

功能：

## 面试题管理

- 新增
- 修改
- 删除
- 分类
- 标签
- 难度
- 高频标识

---

## 专题管理

例如：

Java 高频 100 题

Redis 高频 50 题

---

## 知识分类

支持无限层级：

```text
Java
 ├ Java基础
 ├ 集合
 ├ JVM
 └ 并发

数据库
 ├ MySQL
 ├ Redis
 └ MongoDB
```

---

# 三十九、AI Prompt 管理

后台管理：

- AI 助手 Prompt
- InterviewAgent Prompt
- QuestionAgent Prompt
- FollowUpAgent Prompt
- EvaluationAgent Prompt
- ReportAgent Prompt

支持：

版本管理。

---

# 四十、模型管理

后台配置：

- OpenAI
- DeepSeek
- Qwen
- Kimi
- GLM
- Gemini
- Claude
- 本地模型

统一：

LLM Model Provider。

AgentScope2 Java 通过统一模型适配层调用。

---

# 四十一、推荐技术架构

## 鸿蒙客户端

推荐：

**HarmonyOS NEXT + ArkTS + ArkUI**

模块：

```text
entry

features
 ├ home
 ├ question
 ├ category
 ├ interview
 ├ ai
 ├ study
 └ profile

common
 ├ network
 ├ storage
 ├ components
 └ utils
```

---

# 四十二、Java 后端

建议：

```text
JDK 21
Spring Boot
MyBatis-Plus
MySQL
Redis
AgentScope2 Java
Elasticsearch
Vector Database
```

如果已经有 JeecgBoot 技术体系，也可以直接：

```text
JeecgBoot
+
AgentScope2 Java
```

这样：

- RBAC
- 后台管理
- 字典
- 用户
- 日志
- 文件
- API

都不用重新开发。

---

# 四十三、AI 架构

整体：

```text
HarmonyOS App
       │
       ▼
Spring Boot / JeecgBoot
       │
       ▼
AI Service
       │
       ▼
AgentScope2 Java
       │
       ├ InterviewAgent
       ├ QuestionAgent
       ├ FollowUpAgent
       ├ EvaluationAgent
       ├ KnowledgeAgent
       └ ReportAgent
       │
       ▼
LLM
```

---

# 四十四、RAG 架构

面试知识建议不要全部直接塞 Prompt。

应该构建：

```text
面试题
技术文章
知识点
标准答案
项目案例
```

进入知识库。

流程：

```text
用户问题
↓
Embedding
↓
Vector Search
↓
TopK
↓
Rerank
↓
Context
↓
AgentScope
↓
LLM
```

---

# 四十五、核心数据库

主要表建议：

```text
sys_user

question_category

question

question_answer

question_tag

question_collection

question_learning_record

question_mastery

study_plan

study_record

ai_chat_session

ai_chat_message

interview_session

interview_question

interview_answer

interview_evaluation

interview_report

user_weakness

knowledge_document

knowledge_chunk
```

---

# 四十六、商业模式

可以采用：

免费 + VIP。

免费用户：

- 查看部分题库
- 每天一定次数 AI 问答
- 每天一次简单 AI 模拟面试

VIP：

- 全部题库
- 专题
- 无限或高额度 AI 问答
- AI 模拟面试
- 简历模拟面试
- 项目深挖
- AI 面试报告
- 学习路线
- 面试冲刺计划

---

# 四十七、产品核心闭环

整个 App 最重要的是这条链：

```text
刷题
 ↓
看不懂
 ↓
问AI
 ↓
AI解释
 ↓
AI考你
 ↓
发现不会
 ↓
自动加入薄弱知识
 ↓
继续学习
 ↓
AI模拟面试
 ↓
AI追问
 ↓
面试报告
 ↓
推荐薄弱知识
 ↓
再次刷题
```

这个闭环才是产品真正的核心竞争力。

---

# 四十八、V1 建议实现范围

第一版不要把功能堆得太多。

建议优先完成：

### P0

- 登录
- 首页
- 面试题分类
- 面试题列表
- 面试题详情
- 搜索
- 收藏
- 学习记录
- AI 悬浮助手
- 当前题目上下文 AI 问答
- 文字 AI 模拟面试
- AI 智能追问
- AI 回答评分
- AI 面试报告
- AgentScope2 Java 接入
- 后台题库管理

### P1

- AI 考考我
- 薄弱知识
- 掌握度
- 每日推荐
- 专题
- 学习计划
- 面试冲刺

### P2

- 简历解析
- 简历面试
- 项目深挖
- 语音面试
- RAG 知识库
- 个性化推荐

---

# 四十九、产品名称建议

可以考虑：

### 面试通

简单直接。

### 面霸 AI

更年轻化。

### OfferAI

偏 AI 产品风格。

### InterviewX

偏技术产品。

### HireMind

偏国际化。

### CodeOffer

比较适合程序员。

### AskOffer

突出学习 + AI。

如果主要面向程序员，我更建议：

**CodeOffer**

中文名可以：

**码上 Offer**

App：

**码上 Offer**

工程名：

```text
code-offer
```

鸿蒙：

```text
code-offer-harmony
```

Java 后端：

```text
code-offer-server
```

管理后台：

```text
code-offer-admin
```

AgentScope AI 模块：

```text
code-offer-agent
```

---

# 五十、产品一句话介绍

**码上 Offer —— 面向程序员的 AI 面试学习助手，刷面试题、随时问 AI、模拟真实面试、智能追问并分析薄弱知识，让每一次刷题都真正转化为面试能力。**