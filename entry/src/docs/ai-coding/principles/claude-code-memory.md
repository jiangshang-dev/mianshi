---
title: Claude Code 记忆系统详解：Markdown、Auto Memory 与向量检索怎么选
description: 从 Claude Code 记忆机制出发，拆解 CLAUDE.md、.claude/rules、Auto Memory、Subagent Memory、Agent Teams 和第三方记忆插件的分工，说明哪些信息值得长期保存，以及 Markdown、claude-mem、memsearch、向量检索各自适合什么场景。
category: AI 编程原理
tag:
  - Claude Code
  - Auto Memory
  - Agent Memory
  - AI 编程
head:
  - - meta
    - name: keywords
      content: Claude Code,Auto Memory,CLAUDE.md,MEMORY.md,Agent Memory,Subagent Memory,Agent Teams,claude-mem,memsearch,向量检索
---

新开一个 Claude Code 会话，它居然知道这个项目怎么跑测试、代码风格是什么、哪些目录不要乱动，甚至还记得你之前纠正过一句：“集成测试别用 H2，要连真实 MySQL”。

难道说模型把上次聊天都记住了？

大概率不是。LLM 每次推理看到的还是本轮输入。Claude Code 能跨会话接上，靠的是模型外面那套文件和加载逻辑：哪些规则常驻，哪些经验先放索引里，哪些内容等任务相关时再读进来。

本文和 [《AI Agent 记忆系统》](https://javaguide.cn/ai/agent/agent-memory.html) 这篇互为补充。那篇讲通用 Agent 记忆：短期记忆、长期记忆和记忆演化机制。放到 Claude Code 里，问题就更具体了：`CLAUDE.md` 到底放什么？Auto Memory 记下来的又是什么？`.claude/rules/` 和第三方的 `claude-mem`、`memsearch` 该怎么分工？

![AI Agent 记忆系统架构](https://oss.javaguide.cn/github/javaguide/ai/agent/agent-memory-arch.png)

## LLM 自己不保存跨会话状态

先把这个点说清楚：模型本身不会在两次请求之间偷偷保存状态。

一次调用里，客户端把系统提示词、历史对话、工具返回、用户新问题拼到一起，模型根据这些内容生成下一段输出。下一轮还能想起来，只是应用层又把相关内容带回来了。

普通聊天不太容易暴露这个问题。你连续聊几十轮，客户端把前文带上，模型自然能接话。Agent 场景就麻烦多了：它会读文件、跑命令、调用工具、拿日志，每一步返回都在吃上下文。几轮下来，窗口里塞满临时材料，长期规则反而混在里面。

![LLM 自己不保存跨会话状态](https://oss.javaguide.cn/github/javaguide/ai/skills/llm-no-cross-session-state.webp)

如果打个工程类比，Context Engineering 有点像给 LLM 做“内存管理”：上下文窗口容量有限，真正要管的是哪些信息常驻、哪些按需读取、哪些过期后淘汰。Token 紧张时，摘要、压缩、检索、优先级取舍，本质上都在处理同一个问题：**别让低价值内容挤掉当前任务真正需要的上下文。**

上下文该怎么组织、什么时候按需加载、什么时候压缩，我在 [《上下文工程(Context Engineering) 是什么？和 Prompt Engineering 有什么区别？》](https://javaguide.cn/ai/agent/context-engineering.html) 里单独讲过，篇幅问题这里就不重复介绍了。

回到 Claude Code，长期记忆要先回答这几个问题：

1. 哪些信息值得长期保存？
2. 保存到哪里，谁能看见？
3. 启动时加载多少，任务中再怎么补？
4. 记忆过期、冲突或者被代码库推翻时，怎么发现和清理？

很多问题都卡在第一项：**到底什么值得写入**。

![Claude Code 记忆分层](https://oss.javaguide.cn/github/javaguide/ai/skills/claude-code-memory-layers.webp)

## 规则和经验别搞混了

Claude Code 的长期上下文可以先分成两类：**人写给 Claude 的规则，以及 Claude 工作时自己攒下来的经验。**

`CLAUDE.md` 是第一类。它更像会话开始前的工作说明书：编码规范、常用命令、目录约束、团队流程、不要碰的区域，都应该写在这里。官方文档把它归到 instructions and rules。

![CLAUDE.md 和 AGENTS.md](https://oss.javaguide.cn/github/javaguide/ai/coding/claude-agents-md.png)

Auto Memory 是第二类。它记录的是 Claude 在项目里遇到的模式，比如 build 命令、调试经验、用户偏好、一些反复出现的坑。官方文档把它归到 learnings and patterns。

两者都会进入会话，但职责不一样：

| 机制        | 谁写   | 适合存什么                   | 默认加载方式                              |
| ----------- | ------ | ---------------------------- | ----------------------------------------- |
| `CLAUDE.md` | 人     | 稳定规则、项目约定、协作流程 | 每次会话加载                              |
| Auto Memory | Claude | 工作中发现的经验、偏好、模式 | 每次会话加载 `MEMORY.md` 前 200 行或 25KB |

这两类最好分清楚。规则尽量由人维护，因为它更接近团队约定；经验可以让 Claude 记，但使用前最好回到当前代码里核对一下。

### `CLAUDE.md`：放每次都要看的规则

`CLAUDE.md` 的具体写法，我之前在 [《CLAUDE.md 最佳实践：该写什么、不该写什么、项目变大后怎么拆》](https://javaguide.cn/ai-coding/practices/claude-md-best-practices.html) 里已经单独讲过。这篇不重复模板和示例，只看它在 memory 体系里的位置。

官方文档里这些位置分散在不同段落里看，我更建议直接按五层来记：

![CLAUDE.md 层级与优先级](https://oss.javaguide.cn/github/javaguide/ai/coding/claudecode/claude-md-best-practices-file-hierarchy.png)

| 位置     | 路径                                                                                                                                                  | 适合内容                                                    |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| 组织级   | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`；Linux/WSL: `/etc/claude-code/CLAUDE.md`；Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | IT/DevOps 统一下发的编码规范、安全策略、合规要求            |
| 用户级   | `~/.claude/CLAUDE.md`                                                                                                                                 | 个人所有项目通用的偏好和工具习惯                            |
| 项目级   | `./CLAUDE.md` 或 `./.claude/CLAUDE.md`                                                                                                                | 团队共享的项目架构、命令、代码标准                          |
| 本地级   | `./CLAUDE.local.md`                                                                                                                                   | 当前项目里的个人配置，例如沙箱 URL、测试数据偏好            |
| 子目录级 | `./subdir/CLAUDE.md`，以及同目录下的 `CLAUDE.local.md`                                                                                                | 某个模块或子目录的规则，Claude 读取该目录文件时才会按需加载 |

这些文件不是谁覆盖谁。Claude 会把启动路径上能看到的 `CLAUDE.md` 和 `CLAUDE.local.md` 拼进上下文，范围越大越先加载，越靠近当前目录越后加载；子目录里的文件不在启动时加载，要等 Claude 读到那个目录下的文件才会补进来。组织级 managed policy 不能被个人配置排除。

每份 `CLAUDE.md` 最好控制在 200 行以内。文件一长，模型就容易只记住一部分。

![Claude Code 官方文档对 CLAUDE.md 的建议](https://oss.javaguide.cn/github/javaguide/ai/coding/claudecode/claudemd-claude-docs.png)

这就是我们常说的上下文腐化（Context Rot）问题。**上下文越长，信息越杂，模型利用上下文的稳定性就越可能变差。**

![上下文腐化](https://oss.javaguide.cn/github/javaguide/ai/harness/context-rot-diagram.png)

`CLAUDE.md` 很容易被误用，尤其是下面这几种情况。

1. `CLAUDE.md` 不是强制配置。

`CLAUDE.md` 会作为 user message 注入到系统提示词之后。它很有用，但规则写得模糊、过期，或者不同文件之间互相冲突，模型照样可能选错。

1. 块级 HTML 注释只是在注入上下文前被剥离。

你可以在 `CLAUDE.md` 里写维护说明：

```markdown
<!-- 这段给维护者看，注入上下文时会被剥离 -->
```

但如果 Claude 用文件读取工具直接打开它，注释仍然可见。

1. `@path/to/file` 能引入外部文件，但不会省 token。

被引用文件会在启动时展开进上下文，递归最多四跳，首次引用外部文件还可能需要审批。大段规则不要指望靠 `@` 拆文件来“省窗口”。

真正适合按需加载规则的，是 `.claude/rules/`。

![CLAUDE.md 与其他规则文件怎么分工](https://oss.javaguide.cn/github/javaguide/ai/coding/claudecode/claude-md-best-practices-rule-files-relationship.png)

### `.claude/rules/`：放按文件触发的规则

假设你有一份前端规则，只在处理 `src/**/*.tsx` 时才需要。后端任务每次都把它加载进来，就是在浪费上下文。

`.claude/rules/` 适合放这类条件规则。每条规则是一个 Markdown 文件，可以在 frontmatter 里写 `paths`：

```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "tests/**/*.test.ts"
---

# TypeScript Rules

- API 入参必须做校验。
- 测试文件优先复用已有 fixture。
```

带 `paths` 的规则不会在启动时全量塞进去。Claude 读取匹配 glob 的文件时，才会触发对应规则。这样一来，那些长期有效、但只在某类任务里有用的内容，就不用全塞进 `CLAUDE.md`。

放到项目里时，我一般按用途拆开：

- 每次会话都要看到的规则，放 `CLAUDE.md`；
- 只在某类文件或目录下才有用的规则，放 `.claude/rules/`；
- 多步骤、可复用的操作流程，做成 skill，按需触发；
- 必须硬拦的行为，用 hook 或权限配置，不要只写在 Markdown 里。

“禁止执行 `rm -rf`”“提交前必须跑某个脚本”这类要求，写在 `CLAUDE.md` 里只能算提醒。真要拦住工具调用，还是得靠 hook、permissions 或外层 CI。

### Auto Memory：放 Claude 工作中记下的经验

Auto Memory 是 Claude Code 官方提供的自动记忆机制。它的自动，主要体现在 Claude 会在工作中自己写 notes：比如构建命令、调试经验、架构信息、代码风格偏好和工作习惯。

不过，它不是每轮会话都写，而是由 Claude 判断哪些内容以后还会用到。你可以用 `/memory` 直接打开对应的文件夹。

![Claude Code  /memory](https://oss.javaguide.cn/github/javaguide/ai/skills/claudecode-memory-command.png)

按官方文档，Auto Memory 从 Claude Code v2.1.59 开始可用，并且默认开启。它会把项目记忆放到 `~/.claude/projects/<project>/memory/`，启动时先读 `MEMORY.md` 的前 200 行或 25KB。更细的内容不会一次性全塞进来，而是放在 topic files 里，需要时再打开；`/memory` 可以查看和编辑。

![Claude Code Auto Memory](https://oss.javaguide.cn/github/javaguide/ai/skills/claude-code-auto-memory.png)

也可以直接关掉它：

```json
{
  "autoMemoryEnabled": false
}
```

或者用环境变量：

```bash
CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
```

默认存储目录是：

```text
~/.claude/projects/<project>/memory/
```

官方文档给出的典型结构是：

```text
~/.claude/projects/<project>/memory/
├── MEMORY.md
├── debugging.md
├── api-conventions.md
└── ...
```

`MEMORY.md` 只做入口索引，启动时自动加载前 200 行或 25KB，哪个先到就停。更细的说明放在 topic files 里，Claude 需要时再读。

这个设计很像我前面写过的 Skill 渐进式披露：先让模型知道“有什么”，别一上来就把“全部内容”塞满上下文。

![Skill 渐进式披露](https://oss.javaguide.cn/github/javaguide/ai/skills/agent-skills-progressive-disclosure.webp)

官方文档没有要求 topic file 一定使用某个 schema，也没有公开承诺“记忆类型必须是 user / feedback / project / reference”。

下面这四类是根据之前的源码泄露分析得出的：

| 类型        | 适合保存                         | 不适合保存                           |
| ----------- | -------------------------------- | ------------------------------------ |
| `user`      | 用户长期偏好、技术背景、沟通习惯 | 用户刚才说的一次性临时想法           |
| `feedback`  | 用户明确纠正过的做法             | Agent 自己猜出来的偏好               |
| `project`   | 项目阶段、决策原因、短期冻结规则 | 当前代码结构、文件行号这类会变的事实 |
| `reference` | 信息去哪查、哪个文档是权威来源   | 大段复制的文档正文                   |

Auto Memory 会自动写 notes，但不等于可以完全不管。你让 Claude “记住某件事”、事后用 `/memory` 审核自动写入的内容，或者自己做类似系统时，都要有一套筛选标准。我的原则是宁可少记几条，也不要堆无用的内容。

重点关注这三点：

1. 下次做决定会不会用到？
2. 是不是用户明确确认过？
3. 过期了有没有人能发现？

答不上来，就让它留在当前会话里，没必要写进长期记忆。

真要保留下来，也不要只在 topic file 里塞一句结论。至少把事实、当时这么定的原因、记录时间/失效时间、用之前是否要核对都写上。以后 Agent 再读到这条记忆，看到的就不是一条死规则，而是一条有边界的记录。

![记忆写入治理](https://oss.javaguide.cn/github/javaguide/ai/skills/claude-code-memory-write-governance.webp)

例如：

```markdown
---
type: feedback
created_at: 2026-06-17
updated_at: 2026-06-17
---

# 集成测试连接真实 MySQL

集成测试只要验证数据库行为，就连接真实 MySQL，不使用 H2 内存库替代。

原因：之前有用例在 H2 上通过，但上线后因为 MySQL 的事务和 SQL 方言差异暴露问题。

适用范围：参数校验、纯分支逻辑测试可以继续使用更轻的替代方案；涉及事务、索引、SQL 方言和并发行为时，必须回到 MySQL。
```

只写“集成测试不用 H2”当然也能起作用，但 Agent 很容易机械执行。补上原因和适用范围，后面遇到参数校验、纯分支逻辑这类场景，它才有机会做出正确取舍。

## 哪些东西别放进长期记忆

前面说的是哪些值得记。反过来，还有一些内容最好只留在本轮会话里。

下面这些我一般不会建议放进 Auto Memory：

- 某个文件现在有多少行、某个函数现在在哪；
- 本轮命令输出、临时日志、一次性报错和排查中间状态；
- Git 里能查到的修改历史，README、接口文档里已有的稳定内容；
- Agent 自己推出来、但用户没有确认过的偏好或判断。

它们放在当前上下文里很有用，放进 memory 里就没任何意义了，反而会影响 Agent 的判断。

时间最好也落到具体日期。用户说“月底前别动订单模块”，如果这句话要进 memory，就写成“2026-06-30 前不要修改订单模块”。“月底”“下周”“昨天”这种说法只在当场成立，隔几天再读，Claude 很难知道它指的是哪一天。

一条 memory 写进去以后，成本就不只是几十个 token。它还要被复查、改掉或删除；没人管时，Agent 可能会拿着这条旧前提继续做决定。

## Auto Memory 怎么读回来，不要写死

官方文档中只提到了 `MEMORY.md` 和 topic files 这一层：启动时先加载索引，更细的内容按需读取。

再往里，Auto Memory 到底用 grep、LLM picker、向量检索，还是别的策略，官方并没有展开。

![Auto Memory 召回流程](https://oss.javaguide.cn/github/javaguide/ai/skills/claude-code-memory-recall-flow.webp)

根据网上流出的源码片段和反编译分析来看：Claude 可能会先读 `MEMORY.md` 和各文件摘要，再按当前任务挑相关文件；也有人认为它更偏关键词匹配。

实际落地时，先抓住几条就够了：索引短一点，正文拆出去，同一轮已经注入过的记忆不要重复塞。读回来也不是越多越好，错塞一条过期记忆，比少塞一条更容易把 Agent 带偏。

## 读到 memory 后，先判断它是哪类信息

Auto Memory 被读回上下文后，先按带时间戳的线索处理：它能告诉你以前为什么这么做、可以从哪里开始查，但不能证明现在仍然如此。

比如 memory 里写“订单超时任务在 `order-job` 模块”。这条记录在写入当天可能是对的；后来代码拆了模块，任务可能已经搬家，也可能改了名字。如果 Agent 直接按旧记忆去改文件，大概率会偏。更稳的顺序是：先用 memory 找方向，再回到当前仓库、当前文档或命令输出里确认。

读到不同类型的 memory，信任方式也不一样。

用户长期偏好可以优先采用，但本轮明确指令永远更近。历史决策原因可以参考，不过它解释的是当时为什么这么选，不代表现在还必须这么做。文件路径、模块位置、命令参数这类内容，只能当线索，用之前一定要回到当前仓库核对。项目冻结、上线窗口、排期要看绝对日期，过期了就更新或删除。第三方文档结论也一样，最后还是要回到当前官方文档或实际版本确认。

Auto Memory 的价值是减少重复解释，让 Agent 少从零开始摸索。真正动手前，当前代码、当前文档和当前命令输出的优先级仍然最高。

## Subagent Memory 和 Agent Teams 分别解决什么问题

多 Agent 相关文档里，Subagent Memory 和 Agent Teams 很容易被放到一起看。前者管某个 subagent 自己的长期经验，后者管多个 Claude Code session 在一次任务里怎么配合。

Subagent Memory 仍然是文件式长期记忆，只是记忆主体从主会话换成了某个 subagent。官方 subagent 文档里的 `memory` 字段支持 `user`、`project`、`local` 三种 scope。

按 scope 不同，Claude Code 会使用下面这些目录：

```text
~/.claude/agent-memory/<agent-name>/
.claude/agent-memory/<agent-name>/
.claude/agent-memory-local/<agent-name>/
```

这些目录按需创建或使用。没有给 subagent 配 `memory` 时，在 `~/.claude/` 里看不到 `agent-memory/` 很正常。

启用后，subagent 启动时会读取对应目录里 `MEMORY.md` 的前 200 行或 25KB，哪个先到就停。它也会拿到读写 memory 目录所需的文件工具，用来维护自己的经验。

这类 memory 适合放专用 worker 的经验。比如一个只负责数据库迁移的 subagent，可以沉淀迁移脚本规范、常见失败原因、项目里的历史取舍。下次处理同类任务，它至少知道先查哪里、哪些坑别重复踩。

Agent Teams 走的是协作调度路线。官方文档里提到的 team lead、teammates、shared task list、mailbox，解决的是多个独立 Claude Code session 如何分工、通信、同步任务状态，和共享长期记忆不是一回事。

Agent Teams 可以引用某个 subagent definition 来生成 teammate，但这只说明 teammate 会复用 definition 里的部分配置。官方明确写到的是 `tools`、`model` 会被使用，正文会追加到 teammate 的 system prompt；`skills`、`mcpServers` 不会沿这条路径生效。`memory` 在 teammate 场景下怎么处理，最好按当前版本单独验证，别顺手外推成团队共享长期记忆。

所以我会把两者分开用：Subagent Memory 用来沉淀专用 worker 的长期经验；Agent Teams 用来做一次任务里的并行协作。真要让团队角色带上长期经验，先验证它启动时加载什么、写到哪里、能不能跨 session 保留，再放进正式流程。

## 第三方记忆插件解决了什么问题

内置 Auto Memory 让 Claude Code 在本地文件里记住以后还可能用到的偏好、命令和项目经验。它省心，但没有打算把每次会话过程完整存下来，也没有把多台机器、多名开发者、多种 Agent 的历史统一到一个搜索入口。

第三方插件主要解决的就是这两个问题。

**[`claude-mem`](https://github.com/thedotmack/claude-mem) 关心的是会话过程。** 它通过 Lifecycle Hooks 记录会话和工具观察，再交给本地 Worker 处理。

它有几个关键组件：默认端口 `37777` 的 Worker Service、SQLite 里的 sessions / observations / summaries、Chroma 向量库、`mem-search` skill 和 MCP Tools。

这种方案适合回看历史过程，比如：上次为什么暂停支付模块合入？、之前哪个命令查过慢查询？。

代价也跟着上来：worker、数据库、索引、权限都要维护。

**[`memsearch`](https://github.com/zilliztech/memsearch) 更像外置 Memory Store。** 它用每日 Markdown 保存原始内容，Milvus 做向量索引缓存，检索时结合语义向量、BM25 和 RRF。

它适合多工具、多成员、长周期项目，比如 Claude Code、OpenClaw、OpenCode、Codex CLI 共用一套记忆。

这类方案比本地 Markdown 重得多。索引、嵌入模型、Milvus Lite 或云端 Zilliz、同步策略、数据权限，都要有人负责。记忆还只有几十条时，通常没必要上到这一层。

**如何选择呢？**

单人项目想让 Claude 记住测试命令、提交习惯和项目偏好，先用 `CLAUDE.md` 加 Auto Memory。团队共享稳定规则，就放进仓库里的 `CLAUDE.md`、`.claude/rules/` 或正式文档，让改动走 review。

需要自动保存会话过程，再看 `claude-mem` 这类 Hooks 加本地数据库的方案。

多个 Agent、多台机器、多名开发者共享长期记忆，才考虑 `memsearch`、Mem0 或自建数据库。

至于 BM25、向量检索和 reranker，更适合几万条文档、工单、Wiki 混在一起查的场景。

## 如何做一套轻量级记忆系统

如果你想给团队做一套轻量记忆系统，可以先定文件结构和写入规则。

`CLAUDE.md` 只放每次会话都必须知道的内容，比如测试命令、提交规范、禁改目录。目录或文件类型相关的规则，不要继续往这个文件里塞，放进 `.claude/rules/`，再用 `paths` 控制加载范围。

长期记忆单独放到 `memory/` 目录。刚开始别分太细，四类够用：`user` 放用户长期偏好，`feedback` 放用户明确纠正过的做法，`project` 放阶段性决策和短期冻结规则，`reference` 放资料入口。每个 topic file 里写 `created_at`、`updated_at`、记录原因和适用范围；依赖当前代码状态的内容，打开以后先核对再用。

![轻量记忆系统落地](https://oss.javaguide.cn/github/javaguide/ai/skills/claude-code-lightweight-memory-system.webp)

这个版本可以先手工维护。它不酷，但脏数据少，团队能审阅，删错了也能从 Git 里找回来。等人工索引真的开始拖慢使用，再加自动摘要、全文检索或向量检索也不迟。

目录不用一开始就设计得很复杂。先让索引、用户偏好、明确反馈、项目决策和资料入口各有位置就够了：

```text
memory/
├── MEMORY.md
├── feedback/
│   └── integration-test-real-mysql.md
├── project/
│   └── payment-freeze-before-2026-06-30.md
├── reference/
│   └── slow-query-wiki.md
└── user/
    └── backend-preferences.md
```

`MEMORY.md` 不负责解释来龙去脉，只做入口。它告诉 Claude 现在有哪些记忆，以及需要细看时该打开哪个文件：

```markdown
# Memory Index

- [Integration tests use real MySQL](feedback/integration-test-real-mysql.md): 数据库行为相关集成测试必须连接真实 MySQL。
- [Payment freeze before 2026-06-30](project/payment-freeze-before-2026-06-30.md): 2026-06-30 前支付模块暂停合入新需求。
- [Slow query wiki](reference/slow-query-wiki.md): 线上慢查询排查入口在内部 Wiki 的 db-slow-log 页面。
```

解释、背景和适用范围放到 topic file 里。这样 `MEMORY.md` 可以一直很短，适合常驻；后面要改、要删、要 review，也能直接看对应文件的 diff。

## 总结

Claude Code 的记忆靠外部文件、索引和加载规则起作用，不是模型自己把历史存在脑子里。

`CLAUDE.md` 适合写稳定规则，`.claude/rules/` 适合写按路径触发的规则，Auto Memory 适合留下 Claude 工作中发现的偏好和经验。`MEMORY.md` 别写成小作文，做索引就够了；原因、适用范围、过期时间这些细节，放到 topic file 里。

比起怎么搜得更准，我更在意什么东西别写进去。临时日志、当前文件行数、一次性报错、Agent 自己猜出来的偏好，留在本轮上下文里就行。长期记忆一旦写进去，后面就要有人核对、更新和删除。

第三方工具按需求再加，千万别为了用而用，能保持简单就是最好的。想保存会话过程，`claude-mem` 更贴近；想让多工具、多成员共用一套记忆，再看 `memsearch`、Mem0 或自建库。记忆只有几十条时，先别急着上向量库，文件索引通常已经够用。

我的建议很简单：先把 `CLAUDE.md` 和 `.claude/rules/` 写清楚，再让 Auto Memory 或手工 `memory/` 只留下少量高价值经验。等记忆真的多到人工索引拖不动、协作角色也变复杂了，再考虑数据库、BM25、向量检索和 reranker。

让 Agent 记住一切没什么意义。更可靠的做法，是让它知道下一步该去哪里核对。

## 参考资料

- Claude Code 官方文档：[How Claude remembers your project](https://code.claude.com/docs/en/memory)
- Claude Code 官方文档：[Subagents](https://code.claude.com/docs/en/sub-agents)
- Claude Code 官方文档：[Agent Teams](https://code.claude.com/docs/en/agent-teams)
- Claude Code 官方文档：[Hooks guide](https://code.claude.com/docs/en/hooks-guide)
- GitHub：[thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)
- MindStudio：[Claude Code Memory Systems Explained](https://www.mindstudio.ai/blog/claude-code-memory-systems-compared)
- Milvus：[Claude Code Memory System Explained: 4 Layers, 5 Limits, and a Fix](https://milvus.io/zh/blog/claude-code-memory-memsearch.md)
