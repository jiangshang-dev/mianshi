---
cursor:
  subagentId: "bc-af0fdcad-2390-5381-937a-82aa3e210376"
---

# 面试助答：只听面试官，告诉候选人怎么回答

只出设计，不改鸿蒙 App、Jeecg 后端、管理后台的代码。

候选人用电脑参加一场真人线上面试，手机放在电脑旁。手机只听扬声器里面试官说的话，切成一道道题，在屏幕上写出候选人可以照着说的回答。候选人自己说的话不收录、不打分、不追问。手机保持前台、屏幕常亮。本方案不设计反检测、隐藏进程、后台静默采集，也不规避监考。

## 1. 和模拟面试是两个功能

| | 模拟面试（已有） | 面试助答（本设计） |
| --- | --- | --- |
| 谁在提问 | App 里的 AI 面试官 | 电脑那头的真人面试官 |
| 手机在听谁 | 听候选人自己的回答（语音模式已注释，当前是文字作答） | 只听面试官 |
| 屏幕上给谁看什么 | 面试官的下一问，结束时给候选人打分报告 | 给候选人一段可以照着说的回答 |
| 页面 | `InterviewPage` → `InterviewSessionPage` | 首页单独入口 → `ListenAssistPage` |
| 接口 | `POST /api/ai/interview`，`action` 为 `start` / `chat` / `finish` | `POST /api/ai/listen/session`、`/match`、`/turn` |
| 提示词 | `mianshi-interview-interviewer.txt`，模型扮演面试官 | `mianshi-listen-candidate.txt`，模型只写候选人的口述稿 |
| 会话标记 | `co_ai_chat_session.questionId = interview` | `questionId = listen` |
| 场次表 | 管理端另有 `co_interview_session` / `co_interview_message` / `co_interview_report` | 不读写这些表 |
| 开关 | `interview_ai_enabled`，控制底部「面试」Tab 和首页 AI 横幅 | `listen_ai_enabled`，单独开关，不跟着模拟面试开或关 |

助答不进入 `InterviewPage`，不调用 `InterviewEngine`、`InterviewRepository`、`AiInterviewService`。首页那块 AI 横幅（`HomePage` 里 `home_ai_hero_*`，点击 `openTab(2)`）仍然只进模拟面试。

两边可以共用的只有账号、会员框架、题库原文和 SSE 传输，见下一节。

## 2. 接到哪些现有模块

| 能力 | 现有落点 | 助答怎么用 |
| --- | --- | --- |
| 入口 | `HomePage` 宫格 `gridItems()`，另有一条已注释的 `action: 'ai'`，点击会打开面试 Tab | 新增宫格项 `action: 'listen'`，`router.pushUrl('pages/listen/ListenAssistPage')`。受 `listenAiEnabled` 控制，与 `interviewAiEnabled` 无关 |
| 登录 | `LoginGate`、`AuthRepository`，`/user/auth`，`HttpClient` 带 `Authorization: Bearer` 和 `X-Login-Device` | 未登录先 `LoginGate.goLogin()`。`userId` 取 `AuthRepository.getCached()` |
| 简历 | `ResumeRepository` → `/api/resume`；服务端 `IResumeContextProvider.findCurrent` | 有简历就附上，让回答能点到项目。没有简历也能听。不要求用户先在模拟面试里选岗位、经验、难度 |
| 语音能力 | `common/speech/SpeechService.ets`：`speechRecognizer`，`zh-CN`、`online: 1`，PCM 16kHz / 16bit / 单声道。`module.json5` 的麦克风权限整段注释 | 只在助答页前台调用 `startListening`。不调用 `speak()`，答案不出声。不恢复 `InterviewSessionPage` 里注释掉的语音作答 |
| 题库 | `co_question.interviewAnswer`（面试回答）、`content`（标准答案）。`GET /api/questions/search`，`IQuestionContextProvider` | 面试官的问题先对题库。命中就显示 `interviewAnswer`，空则用 `content`。这是给候选人看的答法，不是再出一道模拟题。`co_interview_question` 没有答法正文，不参与 |
| 流式输出 | `AiChatChunk`：`think_start` / `think_delta` / `think_end` / `delta` / `done` / `error`。App 已有 `HttpClient.postSse` + `SseParser` | `POST /api/ai/listen/turn` 用同一事件格式。`maxTokens` 约 800，只要一段口述稿 |
| 历史 | `GET /api/ai/sessions`，`CoAiHistoryService` 把非 `interview` 的会话都算 `chat` | 增加 `scene=listen`。`scene=chat` 排除 `questionId=listen`，避免出现在题目讲解历史里 |
| 会员 | `AiQuotaFacade` 现有 `question_ai`、`interview_ai`；`[MEMBER_QUOTA]`；`MemberGate`；`GET /api/member/me` | 新场景 `listen_ai`，每提交一道面试官的问题扣一次。题库原文直出不扣。`MemberAppService.me` 增加 `listenAi` 快照 |
| 开关 | `co_app_setting`，`GET /api/app/features`，管理端 `GET/POST /mianshi/appFeature`，工作台 `CommentFeatureCard.vue`。缺行时 `isOn` 默认 true | 新键 `listen_ai_enabled`。初始化写成 `0` |
| 安全 | `AiUserGuardService`、`AliyunContentModerationService.moderate` | 只审核面试官问题文本。不上传 PCM |
| 鉴权 | `ShiroConfig` 已放行 `/api/ai/**` | 路径放在 `/api/ai/listen/**`。body 的 `userId` 必须是当前登录用户 |

实现时新增（本次不写代码）：

- 鸿蒙：`entry/src/main/ets/pages/listen/ListenAssistPage.ets`；`entry/src/main/ets/data/listen/QuestionSegmenter.ets`；`entry/src/main/ets/data/repository/ListenRepository.ets`。路由写入 `main_pages.json`。
- 后端：`AiChatController` 增加 listen 映射；`AiListenAnswerService`；提示词 `jeecg-module-ai-biz/src/main/resources/prompts/mianshi-listen-candidate.txt`；`AgentScopeProperties` 增加 `listenAgentName`、`listenSysPrompt`。
- 表 `co_listen_turn`（实体放 `org.jeecg.modules.mianshi.entity.CoListenTurn`）。`co_ai_chat_message` 只有角色和正文，放不下命中题目和耗时。

## 3. 用户流程

1. 首页宫格点「面试助答」（`listenAiEnabled=true` 才显示）。未登录走 `LoginGate`。
2. 进入 `ListenAssistPage`。若「我的」里有简历，顶部写明已带上简历；没有也可以开始。这里不出现模拟面试的岗位、经验、难度、面试官人设。
3. `AiNotice.ensure` 说明一次：手机放在电脑扬声器旁、屏幕朝自己、本页保持前台、麦克风只听面试官、屏幕上的字是给你照着说的。确认后才申请 `ohos.permission.MICROPHONE`。
4. 拒绝权限则停在说明页。可以手动粘贴面试官刚说的那句话，仍走同一套 match / turn。粘贴的也必须是面试官的问题，没有「提交我的回答」按钮。
5. 授权后屏幕常亮，状态为「正在听面试官」。中部是面试官原话（识别中为灰色半句，断句后变黑）。底部是「你可以这样说」，流式写出口述稿。
6. 面试官说完一题，约 0.7 秒没有新字，就定稿这一题。先查题库，命中直接显示 `interviewAnswer`；未命中再 SSE 出 120～180 字。候选人照着念的时候，这段声音不作为下一题提交。
7. 离开页面、切后台、锁屏或点结束：`stopListening`、`speech.release()`、`SseAbort`、关闭常亮。后台不再听。
8. 「我的 → AI 历史」里 `scene=listen` 回看文字。一期不能删，二期给本人删除。

一场助答一条 `co_ai_chat_session`。杀进程再进不自动续麦，重新开始会新建会话。没断完的半句丢弃。

## 4. 端到端时序

```
首页宫格 listen
  │  LoginGate + AiNotice + 麦克风授权 + setWindowKeepScreenOn(true)
  │  POST /api/ai/listen/session     → co_ai_chat_session(questionId=listen)
  ▼
SpeechService.startListening         （只采面试官方向的扬声器声）
  │  partial                         → 草稿，不出答案
  │  QuestionSegmenter 认定是一道面试官的题
  │  与屏幕上「你可以这样说」大段重合的文本直接丢掉
  ▼
POST /api/ai/listen/match            → co_question
  │  hit  → 展示 interviewAnswer，co_listen_turn.source=bank，不扣 listen_ai
  │  miss → POST /api/ai/listen/turn （SSE）
  ▼
AiListenAnswerService
  │  守卫 → 审核问题文本 → quota.consume(listen_ai)
  │  简历 + 弱相关题库作参考
  │  提示词只产出候选人怎么说
  ▼
SseParser 写入「你可以这样说」
  │  答案展示期间不提交新题，直到用户点「听下一题」或静音超过 2.5 秒且文本不像在复读答案
  ▼
离开页面 → 停麦、取消常亮
```

时延（前台、网络正常）：断句稳定窗口 700ms；`match` 目标 400ms，查询串截到 40 字；未命中时首个 `delta` 目标 1.5～3 秒。`isLast` 到下一次 `startListening` 有空隙，页面显示「听写重启中」。

每道题带客户端 `turnId`。Redis 键 `{agentscope.demo.redis.key-prefix}listen:turn:{turnId}`，重复请求不二次扣次。

## 5. 鸿蒙：采集、断句、识别、展示

### 5.1 页面

- 路由 `pages/listen/ListenAssistPage`，不放在 `pages/interview/` 下，不接收 `InterviewSessionPage` 的 `role/level/difficulty`。
- `HomePage.gridItems()` 增加一项，`onGrid('listen')` 直接 `pushUrl`。不要复用现在的 `action === 'ai'`，那段是去面试 Tab。
- `AppFeatureRepository` 解析 `listenAiEnabled`，缺字段时 App 视为关。
- `Index.ets` 不新增 Tab，也不把助答塞进 `InterviewPage`。

### 5.2 只听面试官

`SpeechService` 增加连续听写方法，模拟面试那条注释掉的语音路径保持原样。

- `createEngine({ language: 'zh-CN', online: 1 })`。设备没有 `SystemCapability.AI.SpeechRecognizer` 时只能手动粘贴面试官原话。
- `audioInfo` 仍是 `pcm / 16000 / 1 / 16`。每一轮新的 `sessionId`，不用现有常量 `interview-session`。
- `isLast=false` 只更新草稿；`isLast=true` 把终稿交给断句器，并立刻再 `startListening`。
- `module.json5` 恢复 `ohos.permission.MICROPHONE`，`usedScene.when = inuse`，只挂 `EntryAbility`。不加 `backgroundModes`，不加 ExtensionAbility。
- 本页 `setWindowKeepScreenOn(true)`，`onPageHide` / `aboutToDisappear` 关掉并 `release()`。
- 全程不 `speak()`。手机外放调低，避免喇叭声盖过电脑里的面试官。

候选人就在手机旁边说话。麦会同时收到两边的声音。产品规则是：只把像面试官提问的句子送去出答案；候选人的复述、口头禅、和屏幕答案重合的句子丢掉。不做声纹分离，也不做让对方听不见的处理。用户把手机麦对准电脑扬声器。

### 5.3 断句（`QuestionSegmenter`）

`isLast` 只表示一小段话结束。断句在端上完成，服务端只收已经认定的一道面试官问题。

可以提交，需同时满足：

- 去掉「嗯、啊、那个、就是」后不少于 8 个字。
- 满足其一：以 `？` 或 `?` 结尾；以「吗 / 呢 / 吧」结尾且 700ms 无新字；出现「请你 / 介绍一下 / 说一下 / 怎么理解 / 手写 / 对比」且 700ms 无新字；连续两段 `isLast` 中间停顿超过 1.2 秒。
- 和上一道已提交问题的归一化相似度低于 0.85。只是变长则更新草稿，不新开一题。

直接丢掉：

- 纯语气词、短于 8 字。
- 和当前「你可以这样说」文本重合超过 0.6（候选人正在照着念）。
- 答案卡片出现后的 2.5 秒内的新句子，除非用户点了「听下一题」。

卡片上可以「这不是一题」丢掉，或「就按这句出答案」强制提交。强制提交的文本仍然当作面试官的问题。

### 5.4 答案展示

- 上半屏：面试官原话。下半屏：固定标题「你可以这样说」。
- 历史题收起，点开用 `MdContentView`。
- 流式用 `SseParser` 的 `delta`。额度错误走 `MemberGate.isQuotaError`。
- 来源标「题库答法」或「AI 生成」。AI 生成带 `AiGenMark` 和 `AiDisclaimerBar`。
- 题库命中整段显示 `interviewAnswer`。点「换一种说法」才 `forceLlm=true`，这时扣 `listen_ai`。
- 页面上没有作答输入框，没有评分，没有「面试官追问」。

## 6. 后端

### 6.1 单独的服务和提示词

`AiInterviewService.buildUserPrompt` 在 `chat` 时让模型点评并追问。助答不调用它。

`AiListenAnswerService` 的系统提示词 `mianshi-listen-candidate.txt`：

- 输入只有面试官刚刚问的那句话，外加可选简历摘要和弱相关题库。
- 输出是候选人第一人称、能直接说出口的 120～180 字：先给结论，再举一个例子。
- 不扮演面试官，不评价候选人答得好不好，不追问，不输出 `<<<REPORT>>>`。

`AgentScopeProperties`：`listenAgentName` 默认 `mianshi-listen-candidate`，`listenSysPrompt` 默认 `classpath:prompts/mianshi-listen-candidate.txt`。模型仍用 `agentscope.demo.llm`（未配置 `LLM_API_KEY` 时返回「AI 服务未配置」）。`HarnessAgent` 关掉文件、shell、子代理，`maxIters=1`，与现有面试官 Agent 的工具开关同一级别，但是另一个 Agent 名和另一份提示词。

### 6.2 会话

`POST /api/ai/listen/session` 写入 `co_ai_chat_session`：`questionId="listen"`，`questionTitle` 固定「面试助答」。`userId`、`ipAddress`、`userDevice` 用现有 `ClientDeviceUtil`。这张表是现成的 AI 会话存储，`questionId` 用来和模拟面试、题目讲解分开，不表示助答是模拟面试的一种模式。

每道题写 `co_listen_turn`，并写两条 `co_ai_chat_message`（`user` = 面试官原话，`assistant` = 给候选人的答法），这样 `GET /mianshi/aiSession/messages` 和 `GET /api/ai/sessions/{id}/messages` 不用改协议。`CoAiHistoryService` 增加 `SCENE_LISTEN = "listen"`。`scene=chat` 时 `questionId not in (interview, listen)`。

### 6.3 题库匹配

一期没有服务端语音识别，不接收音频。手机 CoreSpeechKit 出文本。

`POST /api/ai/listen/match`：

1. `AiUserGuardService.isEnabled`。
2. `moderate(text)`，拒绝则不查题。
3. `CoQuestionService` 查 `status=1`，标题 `LIKE` 截断后的关键词（去掉「请你说一下」一类前缀，最多 40 字），按 `hot` 排序。
4. ES 可用时合并 `GET /api/search` 的题目命中；不可用则只走 MySQL。
5. 分数 ≥ 0.72 且 `interviewAnswer` 或 `content` 非空视为命中。不扣 `listen_ai`。
6. 0.45～0.72 不直接当答案，把 `IQuestionContextProvider.find` 的摘要放进提示词「可参考」，并要求不要整页照抄 `content`。

### 6.4 生成与额度

`POST /api/ai/listen/turn` 返回 `Flux<AiChatChunk>`，响应头复用 `AiChatController.prepareSse`。

1. `sessionId` 属于该 `userId`，且 `questionId=listen`。
2. 守卫、审核。
3. `turnId` 已有结果则重放，不扣次。
4. 题库命中且 `forceLlm=false`：把 `interviewAnswer`（空则 `content`）分成小段 `delta` 推送，`source=bank`，不调用 `AiQuotaFacade`。
5. 否则 `quotaFacade.consume(userId, "listen_ai")`。失败时 `error` 文案带 `[MEMBER_QUOTA]`。会员总开关关闭时现有 `consume` 直接放行。
6. 用户提示词只含：面试官原话、简历摘要（最多 4000 字）、最近 3 道面试官问题、可选的弱命中题库。没有「候选人刚才的回答」这一段。
7. 成功写 `co_listen_turn` 和 assistant 消息。

`AiQuotaFacade.SCENE_LISTEN_AI = "listen_ai"`。`/api/member/me` 增加 `listenAi`，形态与 `questionAi` 相同。

### 6.5 明确不接的模拟面试对象

- 不调用 `/api/ai/interview`，不传 `action=start|chat|finish`。
- 不读写 `co_interview_session`、`co_interview_message`、`co_interview_report`、`co_interview_question`。
- 不生成 `<<<REPORT>>>`，不打分。
- 不走 `/api/ai/polish`（那是管理端润色题库）。
- 不新增音频 WebSocket，不存 PCM。

## 7. 管理后台

1. **开关**  
   `CommentFeatureCard.vue` 增加「面试助答」，文案写明：听真人面试官，给候选人答法。与「底部 Tab AI 模拟面试」分两行。`POST /mianshi/appFeature`，字段 `listenAiEnabled` ↔ `listen_ai_enabled`，种子值 `0`。

2. **额度**  
   `views/mianshi/aiQuota/aiQuota.data.ts` 增加 `{ label: '面试助答', value: 'listen_ai' }`。建议 `periodType=day`，`freeQuota=0`，`memberQuota=40`。接口仍是 `/mianshi/aiQuota`。

3. **会话**  
   `views/mianshi/aiSession` 筛选增加「面试助答」，条件 `questionId=listen`。消息里 user 是面试官原话，assistant 是答法。不在 `views/mianshi/interviewSession` 里展示。

4. **题库**  
   仍用 `views/mianshi/question` 的「面试回答」。这个字段就是助答命中后念给候选人的正文。

5. **提示词**  
   `mianshi-listen-candidate.txt` 随 `jeecg-module-ai-biz` 发版，不和 `mianshi-interview-interviewer.txt` 混文件。

6. **二期**  
   需要看命中率时再做只读页 `views/mianshi/listenTurn`，对 `co_listen_turn`，不要挂到模拟面试场次菜单下。

## 8. 数据模型

### 8.1 `co_ai_chat_session` / `co_ai_chat_message`

不改列。约定：

- `question_id = 'listen'`
- `question_title = 面试助答`
- 消息 `user` 只存面试官原话，`assistant` 只存给候选人的答法

### 8.2 新表 `co_listen_turn`

| 列 | 说明 |
| --- | --- |
| `id` | 雪花，`ASSIGN_ID` |
| `session_id` | `co_ai_chat_session.id` |
| `user_id` | 与会话一致 |
| `turn_id` | 客户端 UUID，唯一索引 |
| `seq` | 从 1 |
| `question_text` | 面试官原话 |
| `answer_text` | 「你可以这样说」的全文 |
| `source` | `bank` 或 `llm` |
| `question_id` | 命中的 `co_question.id`，未命中为空 |
| `match_score` | 0～1 |
| `latency_ms` | 收到 turn 到 done |
| `status` | `ok` / `rejected` / `quota` / `error` |
| `create_time` | 与其他 `co_*` 表相同 |

不存音频。

### 8.3 配置与额度

- `co_app_setting.setting_key = listen_ai_enabled`，值为 `0` 或 `1`
- `co_ai_quota_rule.scene = listen_ai`

## 9. 接口草案

基址：`AppConfig.REMOTE_API_BASE`（`https://www.mianshi-offer.cn/jeecgboot`）。JSON 用 Jeecg `Result`。SSE 与现有 AI 接口一样不包 `Result`。

### 9.1 `POST /api/ai/listen/session`

```json
{
  "userId": "登录用户 id",
  "resumeId": "",
  "resumeFileName": "",
  "resumePreview": "",
  "userDevice": "DeviceProfile.loginDevice()"
}
```

没有 `role`、`level`、`difficulty`、`focus`、`interviewerTitle`、`action`。响应：`{ "sessionId": "...", "questionTitle": "面试助答" }`。

未登录：「请先登录后再使用面试助答」。开关关闭：「面试助答未开放」。

### 9.2 `POST /api/ai/listen/match`

请求：`{ "userId", "sessionId", "text" }`，`text` 是面试官原话。

```json
{
  "hit": true,
  "questionId": "co_question.id",
  "title": "HashMap 怎么扩容",
  "interviewAnswer": "给候选人照着说的答法",
  "content": "标准答案",
  "score": 0.81
}
```

未命中 `hit=false`。审核拒绝不返回题干。

### 9.3 `POST /api/ai/listen/turn`（SSE）

```json
{
  "sessionId": "",
  "userId": "",
  "turnId": "uuid",
  "seq": 3,
  "questionText": "面试官的整题",
  "forceLlm": false,
  "resumePreview": "",
  "userDevice": ""
}
```

`done.markdown` 是「你可以这样说」的全文。额度不足时 `type=error`，内容含 `[MEMBER_QUOTA]`。`ListenRepository` 用 `HttpClient.postSse`，不解析 `<<<REPORT>>>`。

### 9.4 已有接口增量

- `GET /api/app/features` 增加 `listenAiEnabled`。
- `GET /api/member/me` 增加 `listenAi`。
- `GET /api/ai/sessions?scene=listen` 只返回助答；`scene=chat` 排除助答；`scene=interview` 仍只返回模拟面试。
- `POST /mianshi/appFeature` 接受 `listenAiEnabled`。

## 10. 分期

**一期**

- 首页独立入口、`ListenAssistPage`、连续听写、只提交面试官问题、常亮、离开停麦。
- `session` / `match` / `turn`，题库命中直出答法，未命中走候选人提示词。
- `questionId=listen`，`listen_ai_enabled` 种子为 0，麦克风权限 `inuse`。
- 历史按 `scene=listen` 分开。额度调用点留好；规则未配置时与现有 `quotaFacade == null` 一样放行。

**二期**

- `listen_ai` 规则、`/api/member/me` 快照、工作台开关、AI 会话筛选。
- 弱命中题库注入；简历走 `IResumeContextProvider`。
- 本人删除助答会话。

**三期**

- 统计听写重启空隙丢字。若漏掉面试官的题，再在本页前台用 `AudioCapturer` 连续采集，仍显示「正在听面试官」。云端识别要单独同意后才上传音频。
- 不做后台持续任务。

## 11. 风险

**后台麦克风**  
不申请 `backgroundModes: audioRecording`，不在 `onPageHide` 之后继续听。锁屏或切走就停，回来要点「继续听面试官」。商店说明写：仅面试助答页、前台、听面试官提问。与模拟面试的麦克风注释分开写，避免合成「全局听写」。

**延迟**  
听写收尾 + 700ms 断句 + 题库或模型。题库命中目标一秒内出「你可以这样说」。模型题先把面试官原话显示出来，答案区写「正在组织说法」。20 秒没有 `delta` 就 abort，允许重试这一题。

**扬声器与候选人同时出声**  
要收的是电脑扬声器里的面试官。候选人就在旁边照着念，麦一定会听到。用「对准扬声器、答案不出声、复读文本丢弃、出答案后短暂停提交」处理。不做声纹隐藏，也不做让监考端听不见手机的处理。

**断句**  
长问题可能拆成两张卡，短追问可能粘在上一题。提供「这不是一题」和「并入上一题」。并入后若需要重新生成答法，用新的 `turnId` 把合并后的面试官原话再请求一次。断句不放到服务端模型上，避免半句也扣 `listen_ai`。

**电量**  
前台麦 + 常亮 + 在线听写 + 间歇 SSE。页面写明耗电，满 60 分钟提示暂停。离开必须 `release()` 并关掉常亮。

**隐私**  
只上传面试官问题文本和可选简历摘要。不上传、不落库原始音频。文本进 `co_ai_chat_message` 和 `co_listen_turn`，管理端可审计。告知写在 `AiNotice`：只在本人这场面试里听面试官，不要拿去录别人的谈话。日志里的问题文本截断后再打。
