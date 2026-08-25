---
title: Kimi K3 实战：全栈项目、Java 项目改造与 3A 游戏 Demo
description: 通过热点追踪系统、Java 项目改造和第三人称动作游戏 Demo 三个真实案例，实测 Kimi K3 在长程 Agent 编程、多模态理解和复杂工程任务中的表现。
category: AI 编程实战
head:
  - - meta
    - name: keywords
      content: Kimi K3,Kimi Code,AI编程,Agent Coding,全栈开发,Java项目改造,多模态,长程任务,游戏开发
---

你好，我是小 G。Kimi K3 上周五正式发布了！

这两天被问得最多的，基本都是同一个问题：K3 能力到底怎么样？写代码体感如何？

国内外已经有很多大佬把 K3 拿去和一线 Coding 模型对比，反馈都很不错。数据也不会骗人，这几天 K3 的订阅和使用量暴增，算力都快顶不住了。

我还是更想看它在真实项目里的表现，我觉得这才是最实际的。

所以，这次我准备了三个非常典型的案例：一个全栈项目、一个现有 Java 项目改造，再加一个从零做游戏 Demo。

K3 这次带来了：**2.8T 参数、1M 上下文、原生多模态，以及面向长程 Agent 编程的架构优化。**

可以看到，它要的核心就是让 Agent 在更长任务里持续读代码、看截图、跑工具、修问题。

![Kimi K3 官方发布信息](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-official-announcement.png)

这篇还是按我的老办法来：先看怎么接入，再看它在几个工程任务里的实际表现，最后回头聊 K3 这次更新的亮点。

## 接入 Kimi K3

K3 支持几乎所有主流的 Coding Agent 和通用 Agent 框架，例如 Claude Code、Roo Code、OpenCode、OMP、OpenClaw、Hermes。

这里先以 Kimi 官方的 Kimi Code CLI 为例介绍最短接入路径。已经在用 Claude Code、Roo Code、OpenCode 或 CC Switch 的话，也可以继续沿用原来的工具链。

### Kimi Code CLI 接入

这是 Kimi 官方的终端 Coding Agent，和 Claude Code 类似。

安装成功之后，你在项目目录里执行 `kimi` 命令，然后就可以让它读代码、改代码、跑命令、解释报错、生成提交说明。

macOS 和 Linux 的安装命令如下：

```bash
curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
```

Windows PowerShell 使用：

```powershell
irm https://code.kimi.com/kimi-code/install.ps1 | iex
```

安装完成后，可以用 `kimi --version` 看一下版本号：

![Kimi Code CLI 安装完成并查看版本号](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-kimi-cli-install.png)

装好后，切到准备测试的项目目录，运行：

```bash
kimi
```

第一次启动会要求登录 Kimi 账号。进入 Kimi Code CLI 后输入 `/model`，选择 `k3` 即可。

![使用 kimi -y 启动后在模型列表中选择 k3](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-kimi-y-model-list.png)

对于我个人来说，我一般在正式用之前会做一个只读小测试：

```text
阅读当前项目的目录结构和核心代码，说明各模块的职责。先不要修改文件，也不要执行有副作用的命令。
```

![Kimi 先读取 Java 项目的目录结构和核心代码](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-read-java-project.png)

### 已有 Coding Agent 也能继续用

Claude Code、Roo Code 或 OpenCode 已经用顺手的话，不用为了 K3 重搭工作流。创建 Kimi Code API Key 后，可以通过兼容接口把 K3 接进去。

OpenClaw、Hermes 等通用 Agent 框架也能调用 Kimi Code。K3 负责模型推理，具体怎么读文件、调用工具和管理权限，仍然由外面的 Agent 框架处理。

以 CC Switch 为例，新增供应商时可以直接选择 Kimi For Coding：

![新增供应商时选择 Kimi For Coding](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-provider-select.png)

然后填入 API Key 和请求地址，API 格式默认即可：

![配置 Kimi For Coding API Key 和请求地址](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-provider-config.png)

点击获取模型列表，把模型角色映射到 `k3`：

![Kimi For Coding 模型映射中选择 k3](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-provider-model-mapping.png)

这里不需要额外开路由：

![CC Switch 中直接选择 Kimi For Coding](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-cc-switch-direct-provider.png)

实际测试一下：

![Claude Code 接入 Kimi ](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-claude-code-read-project.png)

## 案例一：搭建热点追踪系统

第一个案例，我让 K3 搭一个**热点追踪系统**，项目名叫 **HotPulse**。

这次我没有只让它做一个好看的前端页面。前端当然要看，但我更想看它能不能把后端链路、数据库、队列、测试、错误恢复这些东西串起来。

这次的验收目标是一套能跑起来的 MVP：用户创建关键词 Monitor，系统定时或手动抓取 Hacker News / RSS，把原始内容落成 Observation，再经过 analyze 阶段生成 Entry，最后走 Notify 投递。前端要能看 Feed、Monitor Run、Delivery 状态，还要支持阅读、收藏和归档。

我在给 K3 的系统设计方案中重点做了这些约束：后端用 Hono、SQLite、Drizzle，前端用 React 19、React Router、TanStack Query，再加 Socket.IO。测试不能依赖真实公网，通知用 fake webhook server，数据库用临时 SQLite。

为了跳过文件写入和命令执行的人工审批，我们可以使用 `kimi -y` 命令。

任务推进用到了 `/goal` 命令。为了看模型本身在长任务里的能力，我没有启用任何 Skills，也没有给它额外的项目专用外挂。

![Kimi Code CLI 中使用 goal 推进 HotPulse 任务](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-goal-active.png)

这里有个小细节：图里出现了 8 小时多，不代表模型实际连续工作了这么久。我是昨晚 12 点左右开始跑的，中途卡住后就放着了，早上继续推进。实际有效完成时间大概在 1 小时左右。

### 它先把后端链路跑通

K3 的推进顺序还挺稳：先做 shared 契约、Zod schema 和单测，再补服务端配置、数据库、队列、领域服务，最后把抓取、分析、通知、定时调度、后台 Worker 和维护任务串起来。

中间也不是一路绿灯。K3 会自己跑 TypeScript 检查和测试，看到报错后再回去修 helper、handler 和测试。

![Kimi 修复服务端测试和 TypeScript 报错](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-server-tests.png)

### 后端全绿后再做前端

服务端这边中途先跑到了 `94/94` 全绿，然后 K3 才开始处理 client 侧。

![服务端测试通过后切到前端 SPA](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-client-stage.png)

前端部分补了 Monitor、Feed、Targets、Deliveries、System 这些页面。

下面是 HotPulse MVP 最终交付报告：

![HotPulse MVP 最终交付报告](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-goal-complete.png)

最终交付的功能范围，基本覆盖了我给它的 MVP 验收条件。

不过，第一版能跑，但确实比较粗，只能算 MVP 版本。

Monitor 编辑页能配置名称、关键词、运行间隔、启用状态和来源：

![HotPulse Monitor 编辑页](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-monitor-edit.png)

Feed 页能展示抓取和分析后的 Entry，也支持按状态、Monitor、排序和收藏过滤：

![HotPulse Feed 页面](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-feed.png)

### 继续优化

后面，我又让 Kimi 继续优化了几轮。

![HotPulse MVP 进一步优化后的最终报告](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-optimization-report.png)

这轮主要是把第一版「能用」的地方继续往产品形态上推了一步。比如默认首页、新手引导、手动运行反馈、按钮 pending、防重复提交、toast、删除确认弹窗，还有更统一的中文文案。

再进一步，我还让它做了 **多源扩展** 。

这次就不是单纯修界面了。HotPulse 不再只看 Hacker News / RSS，而是把 RSS、Webpage、GitHub、Twitter 都接进同一条 scrape → analyze → notify 管线里。

![HotPulse V1.1 多源扩展完成并通过验证](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-hotpulse-v11-multisource-complete.png)

这块最有意思的不是多写了几个抓取器，而是 K3 把这些来源统一到了 `source_items` 中间层，用 `(monitorId, externalId)` 做唯一键，再用 `contentFingerprint` 做内容变化检测。

真正的监控系统，难点在于某个来源挂了、页面结构变了、接口变慢了之后，整条链路还能不能稳住，能不能自动降级，能不能继续跑，并且把问题位置暴露出来。

这是现在跑出来的效果，已经接近一个产品形态了。

演示视频地址：<https://www.zhihu.com/pin/2062834508802569097>

这个案例最有价值的地方在于， **K3 在一个比较长的任务里能持续抓住目标：读需求、拆模块、改代码、跑测试、修报错，最后交出可验证的结果。**

## 案例二：现有项目改造

第二个案例，我准备放两个在现有项目上修问题或加功能的小任务。

这类任务和第一个全栈 MVP 不太一样。重点是先读懂已有代码，再沿着现象去找调用链、数据源和实现细节。对 Coding Agent 来说，这种任务更贴近日常开发：线上或本地发现一个问题，把它定位清楚，改最小范围，然后跑验证。

这里我们以星球的下一个多智能体股票分析实战项目为例，这段时间依然在持续完善和补充教程中。

先放第一个：修复股票搜索乱码。

### 修复股票搜索乱码

问题现象一眼就能看出来：股票搜索结果里的中文名称全变成了乱码，只剩股票代码还能看。

![股票搜索结果出现乱码](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-stock-garbled-before.png)

我把截图和现象丢给 K3 后，它先顺着搜索入口找到 `marketDataService.searchStock`，再继续追到数据源回退逻辑。

最后问题落在 `HttpBodyFetcher` / `HttpUtils` 这条链路上：新浪的 `suggest3.sinajs.cn` 搜索接口和 `hq.sinajs.cn` 行情接口返回 GBK 编码，而项目里的 `SinaDataSource` 默认走 `HttpUtils.get`，固定按 UTF-8 解码，中文名就在这里被解坏了。

修复核心就是让新浪数据源按 GBK 解码，并补上支持 `Referer` 请求头的请求方法。

![Kimi 定位并修复股票搜索乱码](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-stock-garbled-fixed.png)

修完后，K3 跑了 `mvn -pl stock-crawler -am install`，重启后端，并实测 `GET /api/market/search?keyword=开`，确认返回“神开股份、开立医疗、经纬辉开、开开 B 股、开发科技”等正常中文名。

这个小任务看起来不大，但比“给我写个工具类”更能看出模型的工程习惯：它从入口、数据源、HTTP 解码工具一路追到外部接口编码，最后也没有扩大到无关模块。

### 开发持仓收益看板

第二个任务是在这个股票项目里加一个 **持仓收益看板** 。

它要做的是基于已有自选股的成本价、持仓量和实时行情，算出总市值、浮动盈亏、今日盈亏、最大仓位等信息。并且，样式需要和现有的保持一致。

![K3 接到持仓收益看板的开发任务](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-task.png)

这个需求看着像一张页面，实际要同时把后端计算、接口分层、前端展示和测试补齐。

K3 先读了项目的自选股字段、行情接口和现有分层，再开始实现。金额计算统一用 `BigDecimal`，行情缺失时让单只股票降级，避免一条异常把整页带崩。

![K3 完成持仓收益看板并给出验证结果](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-complete.png)

最后交付的是一个能直接访问的看板：上面是总市值、总成本、浮动盈亏等汇总卡片，下面能看到每只股票的成本、现价、仓位和收益。后端接口、前端路由和测试也一起补上了。

![持仓收益看板最终页面](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-dashboard.png)

到这一步，其实已经能用了。

但我后来想了一下，真实项目里很多问题不是「页面有没有」这么简单，而是口径能不能对齐，异常能不能兜住，指标能不能继续往下钻。

所以我又让 K3 在这个看板基础上做了一版 V2。

这一版会继续补业务口径和风险指标。比如修复部分行情不可用时汇总口径不一致的问题，增加收益贡献排行、前三大持仓占比、HHI 集中度、年化波动率、最大回撤。

![K3 继续优化持仓收益看板 V2](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-v2-task.png)

这里我觉得比较有意思的是，它没有直接在前端堆字段，而是先回到后端确认 K 线服务字段、交易日期对齐、停牌和数据不足时怎么降级，再把计算逻辑放进独立的 `PortfolioRiskCalculator` 里。

这就很像一个正常工程师干活的节奏。

![K3 完成持仓收益看板 V2 并通过验证](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-v2-complete.png)

最后 V2 页面里，原来的持仓明细还在，下面多了收益贡献和风险概览。

收益贡献能看到哪只股票真正贡献了组合盈亏，风险概览里也能看到年化波动率、最大回撤、VaR、HHI 集中度和前三大持仓占比。

![持仓收益看板 V2 页面](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-case2-portfolio-v2-dashboard.png)

这个案例中，它能在已有项目的约束里把完整链路接起来：先复用数据，再补计算和接口，最后跑测试、验页面。更关键的是，第二轮继续优化时，它还能顺着业务口径往下追，把「能展示」推进到「数据口径更靠谱」。

另外，完成之后，我还用 GPT 5.6 Sol 审核了一下代码，整体实现逻辑和代码质量都是没问题的，可以直接提交。

## 案例三：从零做一个 3A 质感游戏 Demo

第三个案例，我一开始其实纠结过。

前面已经有一个全栈项目，也有一个现有 Java 项目改造。如果再放一个普通 Bug 修复，信息量会有点重复。

后来我决定换一个更直观的。

做游戏。

这个方向有点不一样。业务系统看的是分层、接口、测试和数据口径，游戏看的是另一套能力：画面、物理、输入手感、镜头、战斗反馈、音效、UI、性能，还有最重要的，能不能真的玩起来。

而且 K3 做游戏这块，真的挺离谱的。

我在海外社区也刷到不少类似反馈，有人直接说 K3 一句话 prompt 做小游戏很猛，甚至拿它去复刻《我的世界》风格的 3D Demo。

![海外社区对 K3 做游戏能力的反馈](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-game-community-feedback.png)

那我就想，行，别只看别人玩。

我自己也来试一下。

我的提示词很简单，要求它在当前空目录里，从零开发一款有 3A 质感的第三人称科幻动作游戏 Demo。背景是一座废弃的未来工业基地，玩家要进入基地，击败沿途敌人，取得能源核心，最后打机械 Boss 并撤离。

技术上，我要求它用 Vite、TypeScript、Three.js 和 Rapier。不要手写物理引擎，角色移动、碰撞、重力都交给 Rapier。游戏里必须有移动、奔跑、闪避、瞄准、射击、受击、死亡重开、普通敌人、精英敌人、多阶段 Boss、完整任务循环、PBR 材质、动态光影、阴影、雾效、粒子、Bloom、命中反馈和镜头震动。

![让 K3 从零开发 3A 质感第三人称动作游戏 Demo](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-game-steel-haven-prompt.jpg)

说实话，我写这个 prompt 的时候，心里预期也没那么高。

因为游戏不是普通网页。

一个网页按钮歪一点还能看，一个游戏的镜头、碰撞、射击、敌人 AI、Boss 阶段、特效和音效只要有一个环节不对，玩家马上就能感觉到。

K3 先给了游戏设计和技术方案。项目叫《STEEL HAVEN · 钢铁庇护所》，完整流程是降落平台、突破基地大门、中央庭院精英守卫、夺取能源核心、唤醒 WARDEN-9 Boss、三阶段 Boss 战、撤离点坚守，死亡后从检查点重开。

![K3 给出的游戏设计和目录结构](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-game-steel-haven-design.jpg)

然后它开始直接写项目。

第一步交付出来之后，已经不是那种「贴几块方块然后说这是游戏」的程度了。

它真的把游戏循环做出来了：第三人称角色控制、WASD 移动、Shift 奔跑、空格闪避、右键瞄准、左键射击、R 换弹、E 交互、普通敌人、精英敌人、三阶段 Boss、任务目标、Boss 血条、死亡重开、胜利结算，甚至还有 PBR 材质、环境反射、阴影、雾效、Bloom、枪口火光、爆炸粒子、命中标记和屏幕震动。

![STEEL HAVEN 第一版交付报告](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-game-steel-haven-report-v1.jpg)

当然，第一版不是没有问题。

它自己在交付报告里也写了几个已知问题，比如无跳跃、Boss 正对玩家时会被自身模型短暂遮挡、构建产物偏大。更关键的是，我实际玩下来能明显感觉到，射击手感还可以继续打磨。

这就进入第二步。

我让它重点优化射击动作和战斗体验，不要重新做一套游戏，而是基于现有项目继续修。它先看截图和代码，列出了 7 个影响手感的问题：左手不参与持枪、枪口和准星对不齐、瞄准时角色挡画面、枪口火光被身体挡住、连射扩散和真实 spread 没有对应、命中反馈层次不够、换弹音效和动作脱节。

然后它开始改 Player、PlayerController、CameraRig、Weapon、Game、Physics、AudioManager、HUD 和敌人模块。

![K3 第二轮优化射击动作和战斗手感](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-game-steel-haven-report-v2.jpg)

这轮改完之后，变化就更像游戏了。

瞄准时角色从画面中心移到右下，准星前方更干净；开火有枪体后顿和镜头上抬；连射会积累扩散；换弹有下沉内倾、弹匣弹出、插入和拉机柄的分段动作；命中、暴击、击杀有不同标记和音效；墙面火花也沿着法线喷出来，不再像贴在墙上的硬编码贴花。

演示视频地址：<https://www.zhihu.com/pin/2062833196090275836>

这个案例为什么我觉得必须放进来？

因为它特别能体现 K3 的多模态和长程 Agent 能力。

第一轮，它要从一句需求里拆出玩法、关卡、敌人、Boss、物理、视觉、音频、UI 和测试。第二轮，它又要根据截图和实际体验回头修手感，把「能玩」推进到「更像一个游戏」。

这不是简单生成一个前端页面。

这是把很多主观体验翻译成代码细节。

射击手感这种东西很难用一个单元测试定义。准星有没有被身体挡住，开火有没有顿挫，命中有没有反馈，换弹有没有节奏，Boss 战有没有压迫感，这些都要靠视觉和体验来判断。

它说明 K3 不只是能写业务代码，也能处理更综合的创意工程任务。只要目标足够清楚，验收条件写得足够具体，它可以从玩法设计一路跑到可玩的浏览器游戏 Demo，再继续根据体验反馈做第二轮优化。

这块真的有点超出我的预期。

## K3 这次更新有什么亮点

几个 Coding 榜单里，K3 基本都站到了第一梯队，有些项目甚至直接排到第一。尤其是 Terminal Bench、Program Bench、SWE Marathon 这类更接近日常开发和长任务的测试，表现都挺亮眼。

![Kimi K3 Coding benchmark 对比](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-coding-benchmarks.png)

当然了，benchmark 只能当参考。

实际项目中，Agent 接触到的场景会更复杂：任务越跑越长，需求、代码、日志、测试输出全挤在一起。

所以，1M 上下文就很关键。它至少能让更多需求、代码和终端输出留在现场，不至于跑几轮之后前面发生过什么都被压没了。

不过，1M 只解决能放多少，不能自动解决会不会用。所以 K3 这次还提了 Kimi Delta Attention 和 Attention Residuals。百万级 token 上下文里最高 6.3 倍更快解码，小于 2% 的额外成本下带来大约 25% 的训练效率提升。

你不用记这些名词，简单来说就是：**K3 的长任务场景得到了质的提升，更稳了！**

Agent 和多模态这块也挺有意思。通用 Agent、表格、浏览器任务里，K3 基本都在第一梯队，部分项目直接排第一。视觉任务也没有掉队，整体看下来很均衡。

![Kimi K3 General Agents 和 Visual Agents benchmark 对比](https://oss.javaguide.cn/github/javaguide/ai/coding/k3/k3-agent-visual-benchmarks.png)

不过普通开发者最后看的还是三件事：**效果够不够，成本扛不扛得住，速度快不快。**

K3 这块给我的感觉是，速度很快，价格放到同类模型里也比较低，可以说是接近 Sonnet 的价格，同时在复杂任务里达到 Opus 级的体验，性价比确实非常高。

**⭐️推荐阅读：**

- [后端开发学习 + 面试指南](https://javaguide.cn/home.html)：覆盖 Java、计算机基础、数据库、框架、系统设计等后端开发核心知识与面试内容。
- [AI 应用开发学习 + 面试指南](https://javaguide.cn/ai/)：覆盖 LLM、RAG、Agent、MCP、Prompt、评测、系统设计等 AI 应用开发知识与面试内容。
- [AI 编程实战指南](https://javaguide.cn/ai-coding/)：覆盖 Claude Code、Cursor、Codex、Trae 等工具的使用技巧与面试内容。

## 小结

这几个案例跑完后，相信大家和我一样对 K3 的能力有了更直观的认识，而不仅仅是依赖参数和榜单。

Kimi 在前端能力上一直是最顶的那一档。这次的 K3 发布，能力更加全面了。

全栈 MVP 里，`/goal` 能把长任务往前推；现有项目修问题时，它能沿着入口、服务层、数据源、工具类一路追下去；到了游戏案例里，它又能把玩法、物理、镜头、射击手感和反馈系统串起来。

我会更愿意把它放在目标清楚、验收条件明确、允许它持续执行命令和修复的任务里。比如搭一个 MVP、修一个跨模块 Bug，或者做一个可玩的交互 Demo，这类任务比单纯生成页面更能看出 Coding Agent 的水平。

这次比较打动我的地方在于，K3 确实能在长任务里稳得住，而且完成任务的效果很赞，这几个案例完成之后几乎都没有 bug。

如果后续价格、速度和可用性都能稳住，K3 会是性价比和能力都很能打的第一梯队模型。

我这里就不写「超越谁」「吊打谁」了。

开发者最后看的其实很简单：任务能不能跑完，报错能不能修掉，代码能不能过 review，价格能不能让自己日常用得起。

K3 最近在国内讨论得很热，也有不少人给了差评。我的建议还是，别急着跟风吹，也别急着跟风踩，最好自己拿真实项目跑一跑，用实践和体感去评价一个模型。
