---
title: Claude Code Skills 技术实现细节与运行方式
description: 从 Claude Code Skills 的文件结构、发现加载、Front Matter、动态上下文、安全限制和 Subagent 配合方式入手，讲清 Skills 如何把可复用工作流变成按需加载的 Agent 能力。
category: AI 编程原理
tag:
  - Claude Code
  - Skills
  - AI Agent
  - AI 编程
head:
  - - meta
    - name: keywords
      content: Claude Code,Skills,Agent Skills,SKILL.md,Front Matter,动态上下文,Subagent,Plugin,AI编程
---

不少读者反馈 Skills 在现在的面试中经常会碰到，于是在前面已经写过两篇的基础上，我又肝了一篇。

下面是正文。

还记得刚用 Claude Code 那会，我很容易把各种规则都往 `CLAUDE.md` 里塞。

代码风格，目录约定，测试命令，这些放进去没问题。可后来一些代码审查 checklist、PR 总结流程、UI 验收步骤，也开始往里面堆。

这时候问题就来了。

这些流程确实有用，但它们不是每一轮任务都要用。每次带上的话，会增加很多无用的信息，反而会干扰模型的判断。

这类内容就别继续塞进 `CLAUDE.md` 了。如果你总是在对话里复制同一段 instructions、checklist 或多步骤流程，或者 `CLAUDE.md` 的某一节已经像操作手册，就可以把它拆出来。

差别主要在加载方式上。`CLAUDE.md` 通常会在会话开始时作为持久上下文加载；Skill 平时只暴露名称和描述，真正命中时才加载完整内容。长参考材料、检查清单、脚本说明，不用一开始就挤进上下文。

这篇文章主要讲 Claude Code Skills 的技术实现和运行方式。我会参考社区源码分析材料看实现细节，但当前用法以官方文档和 changelog 为准。

如果你想先系统了解 Agent Skills 和 Prompt、MCP、Function Calling 的区别，可以看我之前写的 [Agent Skills 是什么？和 Prompt、MCP 到底差在哪？](https://javaguide.cn/ai/agent/skills.html)。如果更关心有哪些现成 Skill 值得装，可以直接看 [AI 编程必备 Skills 推荐：TDD、代码审查、网页自动化与 MCP 实战](https://javaguide.cn/ai-coding/programmer-essential-skills.html)。

## Skills 解决了什么问题

先看 `CLAUDE.md` 和 Skill 的分工。

`CLAUDE.md` 适合放每轮都要用到的项目事实和长期规则，比如代码风格、目录约定、常用命令、架构说明。

Skill 适合放有明确触发场景的流程。它们需要被复用，但不需要每次都跟着会话启动。

最典型的是这些：

- 一套代码审查 checklist；
- 一套排查线上问题的步骤；
- 一个生成 PR 总结的流程；
- 一个只在改 UI 时才需要的设计规范；
- 一个只在写测试时才用到的 TDD 工作流。

它们的共同点是：步骤固定、篇幅不短，但只在特定任务里出现。如果全部写进 `CLAUDE.md`，启动时就会变成额外的上下文成本，越堆越重。

你可以把 Skill 理解成一份按需打开的操作手册：平时只让 Claude 知道有这项能力，真用到的时候，再把完整说明拿出来。

![Skill 和 Prompt、MCP、Function Calling 对比](https://oss.javaguide.cn/github/javaguide/ai/skills/skill-prompt-function-calling-mcp-comparison.webp)

`CLAUDE.md` 则反过来。官方建议把它留给每轮都要知道的内容，比如构建命令、项目约定、目录结构，以及必须一直遵守的规则。

如果一段内容已经是多步骤流程，或者只影响代码库里的某个局部，就更适合移到 Skill 或 path-scoped rule。

真到项目里拆的时候，我一般不会先纠结名字，而是先看这段内容到底卡在哪。

- 如果卡在“规则每轮都要生效”，那更像 `CLAUDE.md` 的问题。如果卡在“一段流程反复复制”，那更像 Skill 的问题。
- 如果卡在“任务太长，完整过程会挤占主会话上下文”，才考虑 Subagent。如果卡在“团队里每个人都要装一套”，再考虑 Plugin。

我用了一张表格总结了一下上面提到的概念：

| 机制        | 主要解决的问题                             |
| ----------- | ------------------------------------------ |
| `CLAUDE.md` | 常驻项目规则和长期约定                     |
| Skill       | 只有特定任务才会用到的流程和清单           |
| Subagent    | 把长任务或支线任务委派给另一个 Agent       |
| Plugin      | 分发 Skills、Agents、Hooks、MCP 等扩展能力 |

Claude Code 里的 Skill 可以理解成“prompt-based command”。

自定义命令这块也已经并到 Skills 体系里了。现在 `.claude/commands/deploy.md` 和 `.claude/skills/deploy/SKILL.md` 都能创建 `/deploy`；旧的 `.claude/commands/` 不用马上迁移，仍然兼容。

Subagent 解决的是“谁来做”；Skill 解决的是“怎么做”。

Plugin 负责分发。一个 Plugin 可以带 Skills、Agents、Hooks 和 MCP Servers。企业或团队如果要统一发放能力，Plugin 会比单独复制 Skill 文件更适合。

如果项目里同时有 `CLAUDE.md`、`AGENTS.md`、局部规则、SPEC 和 Skills，也可以按这个思路拆：常驻规则放在规则文件里，可复用流程交给 Skill，本次任务的验收标准放到 SPEC。

![CLAUDE.md 与其他规则文件怎么分工](https://oss.javaguide.cn/github/javaguide/ai/coding/claudecode/claude-md-best-practices-rule-files-relationship.png)

适合变成 Skill 的内容，通常有几个特点：经常复用，有明确触发场景，步骤比较固定，内容比较长，不适合常驻上下文，最好还能配 supporting files 或脚本（例如 `scripts/`、`references/`、`templates/`）。

代码审查、TDD、PR 总结、数据库变更检查、UI 验收、日志排查，都属于这类任务。

不适合做成 Skill 的，是项目里永远要遵守的硬规则。比如“所有 Java 代码使用 Google Java Style”，这种更适合放 `CLAUDE.md` 或项目规则里。

关于 `CLAUDE.md` 的详细介绍和最佳实践，可以参考我写的这篇 [CLAUDE.md 最佳实践：该写什么、不该写什么、项目变大后怎么拆](https://javaguide.cn/ai-coding/practices/claude-md-best-practices.html)。

## `SKILL.md` 怎么写

一个文件系统 Skill 通常是这样的目录结构：

```text
.claude/skills/
  pr-summary/
    SKILL.md
    scripts/
      collect-pr-info.sh
    references/
      review-checklist.md
```

`SKILL.md` 由两部分组成：

1. YAML frontmatter：描述名字、触发条件、工具权限、模型、执行上下文等元数据。
2. Markdown body：真正发给 Claude 的操作说明。

一个最小例子：

```md
---
name: pr-summary
description: Summarize a pull request and list key risks
allowed-tools: Bash(gh *)
---

Read the pull request diff and comments, then summarize:

1. Main changes
2. Risky files
3. Missing tests
4. Suggested follow-up
```

当你执行 `/pr-summary`，Claude Code 会把这个 Skill 渲染成 prompt，再交给模型。

源码里的 `parseSkillFrontmatterFields()` 支持的字段比较多，常见字段可以先看下面这些：

| 字段                       | 作用                                       |
| -------------------------- | ------------------------------------------ |
| `name`                     | 展示名；目录名通常决定命令名               |
| `description`              | 给模型判断何时使用                         |
| `when_to_use`              | 更细的触发说明                             |
| `allowed-tools`            | 预批准该 Skill 可用的工具                  |
| `model`                    | 指定模型别名                               |
| `effort`                   | 指定推理/努力等级                          |
| `user-invocable`           | 是否允许用户通过 `/skill-name` 直接调用    |
| `disable-model-invocation` | 禁止模型自动调用，只允许用户手动调用       |
| `paths`                    | 条件触发路径                               |
| `context`                  | 支持 `fork`，让 Skill 在子代理上下文中运行 |
| `agent`                    | 绑定指定 Agent                             |
| `shell`                    | 指定动态上下文命令使用 bash 或 powershell  |

这里别一上来就把字段全堆上。大多数 Skill 只需要 `description`、`allowed-tools` 和正文说明。字段越多，维护成本越高。

这里有几个字段容易混：

| 字段            | 更适合解决什么问题                             |
| --------------- | ---------------------------------------------- |
| `allowed-tools` | 收窄当前 Skill 可以直接使用的工具范围          |
| `context: fork` | 让长流程、调研类、审查类任务在 fork 上下文里跑 |
| `agent`         | 指定由哪个 Agent 执行这个 Skill                |

例如：

```yaml
context: fork
agent: Explore
allowed-tools: Bash(gh *)
```

这类配置适合 PR 总结、模块审查、文档汇总这类任务。主会话不一定要背完整过程，只拿结果就够。

Skills 还支持参数替换。最简单的是 `$ARGUMENTS`：

```md
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.
```

执行：

```bash
/fix-issue 123
```

Claude 收到的内容里，`$ARGUMENTS` 会被替换成 `123`。

如果要按位置取参数，可以用 `$ARGUMENTS[0]`，也可以用短写 `$0`：

```md
Migrate the $0 component from $1 to $2.
```

执行：

```bash
/migrate-component SearchBar React Vue
```

`$0`、`$1`、`$2` 会分别替换成 `SearchBar`、`React`、`Vue`。

## Claude Code 怎么发现 Skills

Claude Code 会从多个来源加载 Skills。常见位置包括：

```text
~/.claude/skills/
.claude/skills/
```

用户级 Skills 放在 `~/.claude/skills/`，所有项目都能用。项目级 Skills 放在项目的 `.claude/skills/`，适合和团队共享。

![项目里的 .claude/skills 目录示例](https://oss.javaguide.cn/github/javaguide/ai/coding/claude-code-project-skills-folder.png)

从源码看，Skills 目录采用的是：

```text
skill-name/SKILL.md
```

也就是说，`/skills/` 目录下单独一个 `.md` 文件不是标准 Skill 格式，目录里要有 `SKILL.md`。

Claude Code 的 Skill 来源大致可以分几类：

| 类型           | 来源                | 说明                                      |
| -------------- | ------------------- | ----------------------------------------- |
| 用户级 Skills  | `~/.claude/skills/` | 个人长期复用                              |
| 项目级 Skills  | `.claude/skills/`   | 项目或团队共享                            |
| Managed Skills | 管理策略目录        | 组织统一下发                              |
| Bundled Skills | Claude Code 内置    | 例如 `/code-review`、`/debug`、`/loop` 等 |
| Plugin Skills  | 插件提供            | 跟随 plugin 安装和启用                    |
| MCP Skills     | MCP Server 映射能力 | 来自 MCP Server                           |

Claude Code 包含一些 bundled skills，比如 `/code-review`、`/batch`、`/debug`、`/loop` 和 `/claude-api`。它们和普通内置命令不一样，属于 prompt-based skill。

![Claude Code 官方文档中的 Bundled skills 说明](https://oss.javaguide.cn/github/javaguide/ai/coding/claude-code-bundled-skills-docs.png)

嵌套 `.claude/skills` 目录也要留意。

v2.1.178 后，嵌套 `.claude/skills` 目录在处理对应文件时也会加载。发生名称冲突时，嵌套 Skill 会以 `<dir>:<name>` 的形式出现，避免覆盖外层同名 Skill。

这和项目规则的思路接近：**越靠近当前工作目录的配置，越能表达局部上下文。**

不过，不建议滥用嵌套 Skills。只有当子目录确实有独立工作流时才拆，比如：

- `frontend/.claude/skills/ui-review/SKILL.md`
- `backend/.claude/skills/api-contract-check/SKILL.md`
- `docs/.claude/skills/article-review/SKILL.md`

如果只是为了分类，普通目录和文件名就够了。

旧版 `.claude/commands/` 仍然兼容。源码里也能看到 legacy commands loader：如果旧命令目录里存在 `SKILL.md`，会按 Skill 方式处理；否则继续按 Markdown command 加载。

官方文档里已经写明：custom commands 已经合并进 Skills，但已有 `.claude/commands/` 文件会继续工作。新写能力时，建议直接用 `.claude/skills/<name>/SKILL.md`。

## Skill 被调用后发生什么

Skill 平时不会把完整正文塞进上下文。

Claude Code 主要通过 Skill 的名称、描述、`when_to_use` 等 frontmatter 信息，让模型知道有哪些能力可用。

源码里还有一个 `estimateSkillFrontmatterTokens()`，只估算 name、description、whenToUse 的 token，因为完整内容只在调用时加载。

当用户执行 `/skill-name`，或者模型判断某个 Skill 适合当前任务时，Claude Code 才会调用 `getPromptForCommand()`，把 Skill body 渲染出来。

这也是 Skills 比长 `CLAUDE.md` 更省上下文的主要原因。

![Agent 执行链路](https://oss.javaguide.cn/github/javaguide/ai/skills/skill-agent-execution-link.webp)

Skill 被调用后，Claude Code 会先拿到 Markdown body，然后依次做几件事：

1. 展开参数，比如 `$ARGUMENTS`、`$0`。
2. 替换 `${CLAUDE_SKILL_DIR}`。
3. 替换 `${CLAUDE_SESSION_ID}`。
4. 如果不是 MCP 来源，再执行内嵌 shell 命令。
5. 返回最终 prompt 给模型。

`createSkillCommand()` 里对应的实现就是 `getPromptForCommand()`。它会等到真正调用时才处理，不会在启动阶段把所有 Skill 都渲染好。

Skill 可以带 supporting files，比如脚本、参考文档、模板。目录结构可以是：

```text
my-skill/
  SKILL.md
  scripts/
  references/
  templates/
```

如果正文里需要引用脚本路径，可以用 `${CLAUDE_SKILL_DIR}`：

```md
Run this helper:

!`${CLAUDE_SKILL_DIR}/scripts/collect-context.sh`
```

这样 Skill 移动目录后也不容易坏。

不过，支持文件不应该全量塞进正文。更好的写法是：在 `SKILL.md` 里告诉 Claude 什么时候读取哪个文件。用得到再读，用不到就别进上下文。

这就是渐进式披露：先让模型知道“有这个能力”，命中后再读正文，正文里只放流程骨架，真正长的材料继续放到 supporting files。

![渐进式披露（三层模型）](https://oss.javaguide.cn/github/javaguide/ai/skills/skills-progressive-disclosure-three-layer-model.png)

所以 `SKILL.md` 不适合写成超长 README。正文里优先写什么时候用、按什么顺序做、哪些情况别做、失败怎么兜底；长清单、模板和脚本说明放到 `references/`、`templates/`、`scripts/` 里。

![SKILL.md 正文最好控制在 500 行以内](https://oss.javaguide.cn/github/javaguide/ai/skills/keep-skill-md-content-under-500-lines-for-best-performance.png)

`CLAUDE.md` 和 Skill 的区别，也可以回到加载策略上理解：

| 内容              | 更适合放哪里             |
| ----------------- | ------------------------ |
| 项目编码规范      | `CLAUDE.md`              |
| 目录结构说明      | `CLAUDE.md`              |
| 代码审查流程      | Skill                    |
| PR 总结流程       | Skill                    |
| UI 验收 checklist | Skill                    |
| 线上故障排查脚本  | Skill + supporting files |

不要把 Skill 当成另一个更长的 `CLAUDE.md`。Skill 的价值在于按需加载，而不是换个目录继续堆规则。

## 动态上下文和安全限制

Skills 支持动态上下文注入，语法是：

```md
当前 Git 状态：
!`git status --short`
```

也支持代码块形式：

````md
```!
git log --oneline -5
```
````

这些命令会在 Skill 内容发送给 Claude 之前执行。命令输出会替换原来的占位符，模型看到的是最终结果，不是命令本身。

官方文档里也强调：这是 preprocessing。Claude 只看到渲染后的 prompt。

它和 Claude 调用 Bash 的区别很大。

Claude 调用 Bash，是模型在 agent loop 里决定使用工具。它会产生一次工具调用，工具结果进入对话历史。

Skill 里的动态命令是 prompt 预处理。命令先执行，输出被塞进 Skill prompt。模型不会看到“我要执行这条命令”的过程。

适合放在动态上下文里的内容，通常是稳定、只读、低风险的上下文采集，比如：

- `git status --short`
- `git diff --name-only`
- `gh pr view --comments`
- 项目自带的只读脚本

不要把会修改文件、提交代码、删除资源的命令写进动态上下文。动态上下文应该负责“收集材料”，不负责“执行改动”。

MCP 来源的 Skill 更特殊。源码里的判断条件是：`loadedFrom !== 'mcp'` 时才执行内嵌 shell。

MCP Skill 来自远程 MCP Server，不一定可信。如果允许远程服务器返回一个带动态命令的 Skill，再在本机执行，就会变成远程代码执行风险。

所以 MCP 来源的 Skill 会跳过内嵌 shell。文件系统、本地项目、受信任来源的 Skill 才能走这条预处理链路。

同时，即使是本地 Skill，命令执行前也会走同一套工具权限检查。`allowed-tools` 可以给当前 Skill 放行一部分命令，但不是无条件执行。

第三方 Skill 也要按这个思路检查。安装前至少看一遍 `SKILL.md`、`scripts/`、`references/`，确认里面没有危险命令、异常脚本或过宽权限。安装 Skill，等于把一套流程交给 Agent 执行，来源不清楚时，别急着让它进项目。

企业环境里，官方 settings 文档有一个和治理相关的配置：`strictPluginOnlyCustomization`。

它可以限制 skills、agents、hooks、MCP servers 的来源。比如设置：

```json
{
  "strictPluginOnlyCustomization": ["skills", "hooks"]
}
```

被锁定后，用户级和项目级来源会被跳过，只加载 plugin 提供的、managed settings 提供的，或者内置的能力。

这类配置适合团队或企业环境。个人项目一般用不上，但如果公司要统一管理 AI 编程工具的扩展来源，就不能只靠口头约定。

## Skills 怎么和 Agent 配合

Skill 可以跑在 Subagent 里。

官方文档里有“Run skills in a subagent”相关说明，Skill frontmatter 也支持 `context: fork` 和 `agent`。

例如一个 PR 总结 Skill，可以让 Explore agent 在 fork 上下文里跑：

```yaml
context: fork
agent: Explore
allowed-tools: Bash(gh *)
```

这样主会话不用自己背完整 PR diff、评论和文件列表，只拿总结结果。

`context: fork` 适合三类场景：

1. Skill 过程很长；
2. Skill 需要读很多文件或外部信息；
3. 主会话只关心结果，不关心完整过程。

比如生成 PR 风险摘要、对一个模块做只读审查、汇总文档和 issue、生成迁移计划，都可以考虑 fork。

不适合放到 fork 里的，是那些必须和主会话持续互动的任务。比如你正在手动调整某个核心设计，Skill 每一步都要你确认，那就不要 fork 出去。

Agent Teams 也会带来额外上下文开销。官方成本文档提醒过：teammates 会自动加载 `CLAUDE.md`、MCP servers 和 Skills。也就是说，Agent Teams 不是只多了几个 prompt，每个 teammate 都有自己的启动开销。

这并不代表不要用 Skills，而是要控制 Skill 描述和触发范围：

- `description` 写清楚，不要让模型误触发；
- 长内容放 supporting files，不要全塞 `SKILL.md`；
- 用 `disable-model-invocation` 限制只允许手动调用的 Skill；
- 大型团队项目用 `strictPluginOnlyCustomization` 控制来源。

Skill 的设计目标是按需加载。如果描述太泛、触发太频繁，它就会从“节省上下文”变成“额外开销”。

实际项目里，我一般按下面这个规则拆：

| 内容                   | 放哪里                                 |
| ---------------------- | -------------------------------------- |
| 每轮都要遵守的规则     | `CLAUDE.md`                            |
| 特定路径下才生效的规则 | `.claude/rules/` 或带 `paths` 的 Skill |
| 可复用操作流程         | Skill                                  |
| 长参考材料             | Skill supporting files                 |
| 搜索、审查、验证支线   | Subagent                               |
| 多角色协作任务         | Agent Teams                            |

举个例子：你要做一次后端接口重构。

`CLAUDE.md` 里放项目编码规范和测试命令；`api-contract-check` Skill 里放接口兼容性检查流程；`code-review` Skill 里放审查 checklist；搜索旧调用方交给 Subagent；如果前端、后端、测试要并行推进，再考虑 Agent Teams。

这样拆的好处是，规则、流程、执行者各自清楚。别把所有东西都塞进主会话，也别为了显得高级到处开 Agent。

## 总结

我更愿意把 Skill 当成一种 **按需加载的操作手册**。

每轮都要遵守的，继续放规则文件；只有特定任务才会用到的流程，拆成 Skill；流程里很长的 checklist、模板和脚本说明，再继续拆到 supporting files。

判断标准也很简单：如果你已经开始反复复制同一段提示词，或者 `CLAUDE.md` 里某一节长到读起来像手册，那它大概率该变成 Skill 了。

反过来，如果只是代码风格、测试命令、目录约定这类每轮都要遵守的硬规则，就别为了用 Skill 而写 Skill。放在 `CLAUDE.md` 里，反而更直接。
