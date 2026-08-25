---
title: JavaGuide 专属 draw.io 绘图 Skill 开源：用 Agent 自动生成可编辑的 draw.io 技术图
description: 分享 drawio-chart Skill 的设计思路、安装方式和使用流程，说明为什么技术文章配图更适合保留 draw.io 源文件，以及如何让 Agent 生成可维护的流程图、架构图和模块关系图。
category: AI 编程实战
tag:
  - AI 编程
  - Skills
  - draw.io
  - Codex
  - 技术写作
head:
  - - meta
    - name: keywords
      content: draw.io,drawio-chart,Agent Skills,AI编程,技术文章配图,Codex,diagrams.net
---

你好，我是小 G。很多时候我感叹 AI 时代给我带来的冲击，是从一些小事引起的。

在过去，我写一篇技术文章最少需要花费一周，长一点的甚至要一个月。其中，有 1/3 的时间都花费在了枯燥的配图上。

熟悉我的读者朋友应该知道，[JavaGuide](https://mp.weixin.qq.com/s/MP8_Td9h72jAhTntVV4DxQ) 上的很多配图都是用 draw.io 手动绘制的。每一篇文章都有大量的图解，帮助理解。

![Java 基础常见面试题](https://oss.javaguide.cn/github/javaguide/intro/java-basic-questions-01-overview.png)

![MySQL 常见面试题总结](https://oss.javaguide.cn/github/javaguide/intro/mysql-questions-01.png)

但是到了 AI 时代就彻底变了，尤其是对于 draw.io 配图来说。

在去年 Skill 还没火的时候，我是用 AI 直接生成对应的 XML，然后导入到 draw.io 中。

到了今天，得益于 Skill 的诞生，生成 draw.io 配图变得更加自动化了。

这篇文章会分享我平时用的自定义 draw.io 绘图 Skill：[`drawio-chart`](https://github.com/Snailclimb/AIGuide/tree/main/skills/drawio-chart)，也会顺带聊聊为什么我没有完全转向图片生成模型，而是继续保留 `.drawio` 这种可编辑源文件。

## 为什么选择 draw.io？

图不能只看生成时漂不漂亮，后面能不能改也很重要。

技术文章发出去以后，标题、节点、箭头、术语经常会调整。如果手里只剩一张 PNG，要么重新生成，要么硬改图片，最后风格还不一定能对上。

所以我现在更愿意保留一份可编辑源文件。

比如我本地会把这些 `.drawio` 源文件单独留在素材目录里，后面要改某张图，直接打开对应文件就行。

![本地留存的 draw.io 配图源文件](https://oss.javaguide.cn/github/javaguide/ai/coding/local-drawio-source-files.png)

`draw.io` 的好处就在这里：`.drawio` 可以继续在 diagrams.net 或 draw.io 桌面版里改，导出 PNG、SVG、PDF 也方便。流程图、架构图、状态图这些技术图，源文件通常不大，放进仓库或素材目录也没什么压力。

导出时也不用额外折腾，菜单里可以直接选 PNG、JPEG、WebP、SVG、PDF 等常见格式。

![draw.io 导出格式选择](https://oss.javaguide.cn/github/javaguide/ai/coding/drawio-export-format-options.png)

Skill 刚诞生那会，我就把这套流程整理成了一个 Skill：[`drawio-chart`](https://github.com/Snailclimb/AIGuide/tree/main/skills/drawio-chart)。

现在你在 [javaguide.cn](https://javaguide.cn/) 上看到的不少 AI 编程、Spec Coding、Claude Code 相关文章配图，基本都是这套思路做出来的：

- 先让 Agent 抽结构、排节点、生成 `.drawio`，再按文章需要导出图片；
- 需要更强视觉表现时，再搭配 GPT-IMG2 做进一步处理。

## 为什么不只用图片生成？

我之前也试过几个方向。

[`tt-a1i/archify`](https://github.com/tt-a1i/archify) 更像是用自然语言生成自包含的 HTML 技术图，支持主题切换和多格式导出，也有校验、渲染流程。

[`coleam00/excalidraw-diagram-skill`](https://github.com/coleam00/excalidraw-diagram-skill) 走 Excalidraw 风格，适合白板感和观点表达，还会用 Playwright 检查文字重叠、箭头错位、间距失衡这些问题。

[`DayuanJiang/next-ai-draw-io`](https://github.com/DayuanJiang/next-ai-draw-io) 更像一套 AI 绘图产品，把 AI 接进 draw.io，支持在线 Demo、桌面应用、Docker、本地安装、MCP Server 和多模型配置。我当时用起来体感有点卡，画图效率也不高。不过这个项目现在还在更新，我没有重新压测，就不评价当前性能了。

这几个项目各有侧重。Archify 成品感更强，Excalidraw 更适合白板表达，next-ai-draw-io 更像独立产品。

但放到 JavaGuide 的技术文章里，我更常遇到的是这些需求：

- 图里有很多中文术语，后续经常要微调。
- 同一批文章里的配色、字体、节点风格要尽量统一。
- 图要能插进 Markdown、公众号、网页和仓库文档。
- 文章更新后，最好只改几个节点，而不是整张重来。

这时候 `.drawio` 源文件更顺手。

单独打开一个绘图系统，对文章配图来说有点重。Coding Agent 本来就在读文章、改文件、跑命令、整理素材，让它顺手调用 Skill 生成 `.drawio`，再批量导出，链路会短很多。

图片生成模型适合增强视觉表现，但不太适合长期维护。今天改一个词，明天加一个分支，你很难只让它精准动那一小块，还保持整张图不变形。

draw.io 没有那么“生成即大片”，但节点、连线、容器、文字都能继续改。对技术图来说，这点很值钱。

## 我现在的绘图流程

我现在更常用的流程大概是这样：

1. 先写文章，或者至少把文章的主线、流程、概念关系整理出来。
2. 让 Agent 判断这篇文章里哪些地方值得画图。
3. 用 `$drawio-chart` 生成 `.drawio` 源文件。
4. 需要发布时导出 PNG / SVG / PDF。
5. 如果某张图需要更强的视觉表现，再搭配 GPT-IMG2 做进一步处理。

我更在意的是把结构和表现拆开。

`drawio-chart` 负责结构化图表：流程怎么走，模块怎么连，状态怎么迁移，哪些节点属于一组。GPT-IMG2 更适合处理位图层面的表达，比如让一张图更像文章配图、更有视觉完整度。

结构还留在 `.drawio` 里，后面要改就能改。

下面这张就是一次实际生成 `.drawio` 的过程。Agent 读完需求后直接写出源文件，最后返回文件路径和结构说明。

![Codex 使用 drawio-chart 生成 draw.io 源文件](https://oss.javaguide.cn/github/javaguide/ai/coding/codex-generate-drawio-source.png)

打开以后，它仍然是标准 draw.io 文件。节点、连线、文字都能继续手动调，不会被锁死在一张图片里。

![draw.io 中打开生成的 SKILL.md 结构图](https://oss.javaguide.cn/github/javaguide/ai/coding/drawio-open-generated-source.png)

这就是绘图之后没有改动的原图，可以看到线条还是有一些小细节需要手动调整优化。这也是比较正常的。

下面来看看用这个 Skill 画的一些图片。

这张 `CLAUDE.md` 维护决策流程图，就是典型的流程判断类配图：

![CLAUDE.md 维护决策流程](https://oss.javaguide.cn/github/javaguide/ai/coding/claudecode/claude-md-best-practices-maintenance-flow.png)

Multi-Agent 协作这种内容，如果只用文字写，读者很容易看成一堆角色名。画成流水线后，每个 Agent 负责什么、信息怎么流转，会直观很多。

![Multi-Agent 三代理协作流水线](https://oss.javaguide.cn/github/javaguide/ai/coding/spec-coding-multi-agent-pipeline.png)

Spec Coding 这类文章也类似。它讲的是一套工作流，不是一个孤立概念。图里把需求、Spec、实现、验证串起来，读者就能先抓住整体，再回到正文看细节。

![Spec Coding 规范驱动编程流水线](https://oss.javaguide.cn/github/javaguide/ai/coding/spec-coding-pipeline-flow.png)

还有 Spec 管理策略这种图，文字解释会比较绕。分层过滤、精准召回、上下文控制这些词放到一张图里，反而更容易理解。

![Spec 管理策略：分层过滤 + 精准召回](https://oss.javaguide.cn/github/javaguide/ai/coding/spec-coding-spec-management-strategy.png)

这些图不一定每张都要靠 AI 一次性做完。省时间的地方主要在前半段：Agent 先帮你搭出结构，后续人再按文章语境修。

技术文章配图一旦和文章脱节，就会很麻烦。图里的节点、标题、箭头如果不能和正文对上，再漂亮也没用。

## `drawio-chart` 这个 Skill 做了什么？

我之前在 [《Agent Skills 是什么？和 Prompt、MCP 到底差在哪？》](https://javaguide.cn/ai/agent/skills.html) 里讲过，Skill 更像一份按需加载的任务说明。

它不负责发明一个新工具，也不等同于 Function Calling 或 MCP。它解决的是：某类任务怎么做、什么时候做、哪些步骤不能漏、需要哪些参考资料。

`drawio-chart` 就是把“给技术文章画 draw.io 图”这件事沉淀成了 Skill。

它的主文件是 [`SKILL.md`](https://github.com/Snailclimb/AIGuide/blob/main/skills/drawio-chart/SKILL.md)，里面只放几类信息：

- 什么时候应该用它，比如 draw.io、diagrams.net、流程图、架构图、时序图、ER 图、状态机图、思维导图。
- 什么时候不该用它，比如用户只想要 Mermaid 代码，或者要的是位图插画、海报、白板风配图。
- 绘图前要收集什么信息，比如主题、图表类型、关键节点、节点关系、是否导出。
- 生成 `.drawio` 时按什么顺序走，比如标题、容器、核心节点、连线、标签。
- 交付前检查什么，比如节点是否齐全、关系是否画对、连线标签是否过长、文件名是否规范。

更细的东西没有全塞进 `SKILL.md`。

它拆了几个 `references/` 文件：

| 文件                  | 放什么                                         |
| --------------------- | ---------------------------------------------- |
| `style-spec.md`       | 配色、字体、节点语义、连线风格                 |
| `xml-and-layout.md`   | draw.io XML 结构、节点模板、连线模板、布局建议 |
| `export-and-files.md` | PNG / SVG / PDF 导出命令、文件命名、交付规则   |
| `use-cases.md`        | 常见 prompt、多图文章配图模式、页面命名建议    |

这个拆法和 Skills 的设计思路是一致的。

主文件不要写成超长 README。Agent 先知道这个 Skill 能干什么；命中任务以后，再根据当前需求读取对应参考文件。

比如只是生成一张流程图，不一定要读完整导出规范。如果用户明确要求导出 PNG，再去看 `export-and-files.md` 就够了。需要控制样式时，再读 `style-spec.md`。

这样上下文不会被无关细节挤满，执行也更稳定。

## 我给它加了哪些约束？

画图这件事很容易失控。

Agent 生成图时，常见问题有几个：节点文字太长，连线标签压在箭头上；一张图里颜色乱用，看起来像随机上色；流程图里每条线都带很长的解释；XML 里混进 HTML 标签，后面渲染或编辑时容易出问题。

所以 `drawio-chart` 里写了不少很具体的约束。

比如样式上，Agent 不需要现场随便选颜色。规则会按语义分配：入口、业务服务、基础设施、客户端、外部依赖、数据库、缓存、消息队列、异常状态分别有对应色值。这样同一批图放在一起时，读者不会每张都重新理解颜色。

文字上，它要求 `mxCell.value` 默认使用纯文本，需要换行时用 XML 换行实体，不在节点值里塞 `<br>`、`<b>` 这类 HTML 标签。

连线标签也要短。短连接线不要放长说明，能写进节点就写进节点，能放旁注就放旁注。技术图里很多凌乱感，都是从“每条线都想解释一句”开始的。

导出上，它默认先保留 `.drawio`，再按需要导出。即使导出失败，也不能删源文件。

## 怎么安装和使用？

我已经把这个 Skill 放到了 [AIGuide：AI 应用开发、AI 编程实战与面试指南](https://github.com/Snailclimb/AIGuide) 仓库里：

- 仓库入口：**<https://github.com/Snailclimb/AIGuide/tree/main/skills>**
- Skill 目录：**<https://github.com/Snailclimb/AIGuide/tree/main/skills/drawio-chart>**

如果你在用 `npx skills` 生态，可以这样安装：

```bash
npx skills add Snailclimb/AIGuide/skills/drawio-chart
```

如果只想安装给 Codex，也可以直接指定 agent：

```bash
npx -y skills add Snailclimb/AIGuide/skills/drawio-chart --agent codex --yes
```

如果你主要在 Codex 里用，也可以从 GitHub 安装：

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo Snailclimb/AIGuide \
  --path skills/drawio-chart
```

这里要注意一下，`skills@1.5.15` 这类版本里，`npx skills add Snailclimb/AIGuide --path skills/drawio-chart` 可能仍会先扫描到仓库里的全部 Skill。更稳的写法是把 `skills/drawio-chart` 直接写进 source，也就是上面的 `Snailclimb/AIGuide/skills/drawio-chart`。

安装时会看到它识别仓库来源、找到 `drawio-chart`，再让你选择安装到哪个 agent 和作用范围。

![使用 Skills CLI 安装 drawio-chart](https://oss.javaguide.cn/github/javaguide/ai/coding/skills-cli-install-drawio-chart.png)

Codex 有时不会立刻重新扫描新装的 Skill，我一般会重启一下再用。

刚开始别让 Agent 猜。直接点名 `$drawio-chart`，它更容易进到正确的工作流里。比如画一个登录流程图，我会这么写：

```text
使用 $drawio-chart 画一个用户登录流程图，包含：
输入账号密码 -> 验证账号密码 -> 成功跳转首页 -> 失败提示错误并允许重试。
要求导出 PNG。
```

给整篇文章配图时，我通常不会先规定“必须画几张”。更顺的做法是把文章路径交给它，让它先从文章里挑真正值得画的结构，再把格式要求补上：

```text
使用 $drawio-chart 读取这篇文章，为文章生成几张合适的技术配图。
所有配图放到同一个 draw.io 文件里，每张子图作为一个 diagram page。
主文件名和文章文件名保持一致，页面名用英文小写中横线。
配图风格遵循 drawio-chart 的统一规范。
```

这里不要只丢一句“帮我画个架构图”。微服务架构图至少要说清楚有哪些服务、哪些存储、哪些外部依赖，请求从哪里进来，哪些调用是同步的，哪些链路走异步消息。

你给它的是一段明确的图表需求，它产出的才更接近可用稿。只给一个很虚的标题，后面大概率还是要人手动返工。

## 哪些图适合 draw.io？

我现在主要把三类图交给 `drawio-chart`。

一类是文章里的流程图。比如 Spec Coding、CLAUDE.md 维护策略、Agent 协作流水线，这些图都有清晰的步骤和分支，draw.io 很适合后续微调。

一类是架构图和模块关系图。这里最烦的是风格不统一：同一篇文章里，服务节点一个颜色，存储节点一个颜色，外部依赖再单独区分，读者看起来会轻松很多。

还有一类是会反复改的图。文章上线后，标题、节点名、箭头方向、导出尺寸都可能调整。只要 `.drawio` 还在，改起来就不算麻烦。

我不太会拿它做封面图、海报、产品氛围图，这些交给 GPT-IMG2 更合适。想要白板手绘风，Excalidraw 那套更贴近；想要带主题切换、自包含 HTML 和网页交互，Archify 也值得看看。
