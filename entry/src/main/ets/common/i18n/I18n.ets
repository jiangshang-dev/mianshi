export class I18n {
  static readonly KEY: string = 'appLang';
  static readonly HANS: string = 'zh-Hans';
  static readonly HANT: string = 'zh-Hant';
  static readonly EN: string = 'en';

  private static ready: boolean = false;
  private static hans: Map<string, string> = new Map();
  private static hant: Map<string, string> = new Map();
  private static en: Map<string, string> = new Map();

  static t(key: string, lang?: string): string {
    I18n.ensure();
    const code = I18n.code(lang);
    let table = I18n.hans;
    if (code === I18n.HANT) {
      table = I18n.hant;
    } else if (code === I18n.EN) {
      table = I18n.en;
    }
    const val = table.get(key);
    if (val !== undefined && val.length > 0) {
      return val;
    }
    const fb = I18n.hans.get(key);
    return fb !== undefined ? fb : key;
  }

  static tf(key: string, arg: string, lang?: string): string {
    return I18n.t(key, lang).replace('{0}', arg);
  }

  static tf2(key: string, arg0: string, arg1: string, lang?: string): string {
    return I18n.t(key, lang).replace('{0}', arg0).replace('{1}', arg1);
  }

  static langName(lang: string): string {
    if (lang === I18n.HANT) {
      return '正體中文';
    }
    if (lang === I18n.EN) {
      return 'English';
    }
    return '简体中文';
  }

  static groupName(group: string, lang?: string): string {
    if (group === '技能' || group === '技术方向') {
      return I18n.t('group_skill', lang);
    }
    if (group === '公司' || group === '大厂真题') {
      return I18n.t('group_company', lang);
    }
    if (group === '专项' || group === '高频精选') {
      return I18n.t('group_special', lang);
    }
    return group;
  }

  static sectionTitle(name: string, title: string, lang?: string): string {
    const n = name.trim();
    const t = title.trim();
    if (n === '技能' || n === '技术方向' || t === '热门技能' || t === '熱門技能' || t === '技能' || t === '技术方向' ||
      t === 'Popular skills' || t === 'Skills') {
      return I18n.t('hot_skills', lang);
    }
    if (n === '公司' || n === '大厂真题' || t === '公司题库' || t === '公司題庫' || t === '公司' ||
      t === 'Company questions' || t === 'Companies') {
      return I18n.t('company_bank', lang);
    }
    if (n === '专项' || n === '高频精选' || t === '专项' || t === '專項' || t === '高频精选' || t === 'Specials') {
      return I18n.t('special', lang);
    }
    return t.length > 0 ? t : n;
  }

  static weekdays(lang?: string): string[] {
    return [
      I18n.t('week_1', lang),
      I18n.t('week_2', lang),
      I18n.t('week_3', lang),
      I18n.t('week_4', lang),
      I18n.t('week_5', lang),
      I18n.t('week_6', lang),
      I18n.t('week_7', lang)
    ];
  }

  static aiTips(lang?: string): string[] {
    return [
      I18n.t('tip_confused', lang),
      I18n.t('tip_simple', lang),
      I18n.t('tip_example', lang),
      I18n.t('tip_interview', lang),
      I18n.t('tip_followup', lang)
    ];
  }

  static agreement(lang?: string): string[] {
    return [
      I18n.t('ag_0', lang), I18n.t('ag_1', lang), I18n.t('ag_2', lang), I18n.t('ag_3', lang),
      I18n.t('ag_4', lang), I18n.t('ag_5', lang), I18n.t('ag_6', lang), I18n.t('ag_7', lang),
      I18n.t('ag_8', lang), I18n.t('ag_9', lang), I18n.t('ag_10', lang), I18n.t('ag_11', lang),
      I18n.t('ag_12', lang), I18n.t('ag_13', lang)
    ];
  }

  static privacy(lang?: string): string[] {
    return [
      I18n.t('pr_0', lang), I18n.t('pr_1', lang), I18n.t('pr_2', lang), I18n.t('pr_3', lang),
      I18n.t('pr_4', lang), I18n.t('pr_5', lang), I18n.t('pr_6', lang), I18n.t('pr_7', lang),
      I18n.t('pr_8', lang), I18n.t('pr_9', lang), I18n.t('pr_10', lang), I18n.t('pr_11', lang)
    ];
  }

  private static code(lang?: string): string {
    if (lang === I18n.HANT || lang === I18n.EN || lang === I18n.HANS) {
      return lang;
    }
    const stored = AppStorage.get(I18n.KEY) as string;
    if (stored === I18n.HANT || stored === I18n.EN || stored === I18n.HANS) {
      return stored;
    }
    return I18n.HANS;
  }

  private static put(key: string, zh: string, hant: string, en: string): void {
    I18n.hans.set(key, zh);
    I18n.hant.set(key, hant);
    I18n.en.set(key, en);
  }

  private static ensure(): void {
    if (I18n.ready) {
      return;
    }
    I18n.ready = true;
    I18n.put('app_name', '码上 Offer', '碼上 Offer', 'CodeOffer');
    I18n.put('tab_home', '首页', '首頁', 'Home');
    I18n.put('tab_bank', '题库', '題庫', 'Bank');
    I18n.put('tab_interview', 'AI面试', 'AI面試', 'Interview');
    I18n.put('tab_blog', '专栏', '專欄', 'Column');
    I18n.put('tab_forum', '广场', '廣場', 'Square');
    // I18n.put('tab_study', '学习', '學習', 'Study');
    I18n.put('tab_profile', '我的', '我的', 'Me');
    I18n.put('hello_candidate', '你好，面试选手', '你好，面試選手', 'Hi, candidate');
    I18n.put('search_home', '搜面试题 / 技能 / 公司题库', '搜面試題 / 技能 / 公司題庫', 'Search questions / skills / companies');
    I18n.put('loading', '正在加载…', '正在載入…', 'Loading…');
    I18n.put('today_study', '今日学习', '今日學習', 'Today');
    I18n.put('continue_study', '继续学习 ›', '繼續學習 ›', 'Continue ›');
    I18n.put('stat_q', '道题', '道題', 'Qs');
    I18n.put('stat_min', '分钟', '分鐘', 'Min');
    I18n.put('stat_master', '掌握', '掌握', 'Mastered');
    I18n.put('stat_review', '待复习', '待複習', 'Review');
    I18n.put('no_cat_home', '未拉到分类，请检查网络与后端地址', '未拉到分類，請檢查網路與後端位址', 'No categories. Check network and API.');
    I18n.put('hot_skills', '热门技能', '熱門技能', 'Popular skills');
    I18n.put('company_bank', '公司题库', '公司題庫', 'Company questions');
    I18n.put('special', '专项', '專項', 'Specials');
    I18n.put('all_more', '全部 ›', '全部 ›', 'All ›');
    I18n.put('hot_recommend', '热门推荐', '熱門推薦', 'Recommended');
    I18n.put('no_hot', '暂无推荐题目', '暫無推薦題目', 'No recommended questions');
    I18n.put('q_count', '{0} 道题', '{0} 道題', '{0} questions');
    I18n.put('group_skill', '技能', '技能', 'Skills');
    I18n.put('group_company', '公司题库', '公司題庫', 'Companies');
    I18n.put('group_special', '专项', '專項', 'Specials');
    I18n.put('bank_title', '题库', '題庫', 'Question bank');
    I18n.put('all_cats', '全部分类 ›', '全部分類 ›', 'All categories ›');
    I18n.put('no_cat_bank', '未拉到分类，请确认后端已启动且手机与电脑在同一局域网',
      '未拉到分類，請確認後端已啟動且手機與電腦在同一區域網路',
      'No categories. Make sure the backend is running on the same LAN.');
    I18n.put('all_cats_title', '全部分类', '全部分類', 'All categories');
    I18n.put('count_unit', '{0} 个', '{0} 個', '{0}');
    I18n.put('no_cat_short', '未拉到分类', '未拉到分類', 'No categories');
    I18n.put('no_cat_hint', '请确认后端已启动，且 App 能访问局域网地址',
      '請確認後端已啟動，且 App 能存取區域網路位址',
      'Start the backend and confirm the app can reach it.');
    I18n.put('local', '本地', '本地', 'Local');
    I18n.put('remote', '远程', '遠端', 'Remote');
    I18n.put('all', '全部', '全部', 'All');
    I18n.put('empty', '暂无内容', '暫無內容', 'Nothing here');
    I18n.put('empty_remote', '该分类下暂无题目，或接口请求失败', '該分類下暫無題目，或介面請求失敗', 'No questions, or the request failed');
    I18n.put('empty_local', '该分类下没有文章', '該分類下沒有文章', 'No articles in this category');
    I18n.put('hot', '高频', '高頻', 'Hot');
    I18n.put('src_local', '本地 MD', '本地 MD', 'Local MD');
    // I18n.put('src_remote', '远程 API', '遠端 API', 'Remote API');
    I18n.put('detail_title', '题目详情', '題目詳情', 'Question');
    I18n.put('not_found', '未找到题目内容', '未找到題目內容', 'Question not found');
    I18n.put('answer_body', '标准答案 / 正文', '標準答案 / 正文', 'Answer');
    I18n.put('tab_lecture', '文字讲义', '文字講義', 'Notes');
    I18n.put('tab_video', '视频', '視頻', 'Video');
    I18n.put('video_list', '视频列表', '視頻列表', 'Videos');
    I18n.put('video_open', '浏览器打开', '瀏覽器打開', 'Open in browser');
    I18n.put('video_open_bili', '打开B站', '打開B站', 'Open Bilibili');
    I18n.put('video_fullscreen', '全屏', '全屏', 'Fullscreen');
    I18n.put('video_exit_fs', '退出全屏', '退出全屏', 'Exit');
    I18n.put('video_open_fail', '未安装B站时将尝试用浏览器打开', '未安裝B站時將嘗試用瀏覽器打開', 'No Bilibili app, opening in browser');
    I18n.put('video_empty', '暂无可播放视频', '暫無可播放視頻', 'No playable video');
    I18n.put('image_load_fail', '图片加载失败', '圖片加載失敗', 'Image failed to load');
    I18n.put('image_preview_close', '关闭', '關閉', 'Close');
    I18n.put('image_preview_hint', '双击或捏合可放大', '雙擊或捏合可放大', 'Double-tap or pinch to zoom');
    I18n.put('interview_ans', '面试推荐回答', '面試推薦回答', 'Interview answer');
    I18n.put('knowledge', '知识点', '知識點', 'Key points');
    I18n.put('quick_ai', '快捷提问 AI', '快捷提問 AI', 'Ask AI');
    I18n.put('comment_title', '评论', '評論', 'Comments');
    I18n.put('comment_feature', '评论', '評論', 'Comments');
    I18n.put('comment_ph', '说点什么…', '說點什麼…', 'Write a comment…');
    I18n.put('comment_reply_ph', '回复 ', '回覆 ', 'Reply to ');
    I18n.put('comment_send', '发布', '發布', 'Post');
    I18n.put('comment_posting', '发布中', '發布中', 'Posting');
    I18n.put('comment_ok', '评论已发布', '評論已發布', 'Posted');
    I18n.put('comment_fail', '发布失败', '發布失敗', 'Failed to post');
    I18n.put('comment_empty', '还没有评论，来说两句吧', '還沒有評論，來說兩句吧', 'No comments yet');
    I18n.put('comment_reply', '回复', '回覆', 'Reply');
    I18n.put('comment_replying', '回复', '回覆', 'Reply');
    I18n.put('comment_rejected', '审核不通过，仅自己可见', '審核不通過，僅自己可見', 'Rejected, only visible to you');
    I18n.put('comment_replies', '共', '共', '');
    I18n.put('comment_replies_unit', '条回复', '條回覆', ' replies');
    I18n.put('comment_detail', '评论详情', '評論詳情', 'Comment details');
    I18n.put('comment_related', '相关回复共', '相關回覆共', 'Replies ');
    I18n.put('comment_today', '今天', '今天', 'Today');
    I18n.put('comment_month', '月', '月', '/');
    I18n.put('comment_day', '日', '日', '');
    I18n.put('comment_vote_fail', '操作失败', '操作失敗', 'Failed');
    I18n.put('comment_sort_time', '按时间', '按時間', 'Latest');
    I18n.put('comment_sort_hot', '按热度', '按熱度', 'Hot');
    I18n.put('ai_helper', 'AI 面试助手', 'AI 面試助手', 'AI helper');
    I18n.put('stop', '停止', '停止', 'Stop');
    I18n.put('collapse', '收起', '收起', 'Hide');
    I18n.put('expand', '展开', '展開', 'Show');
    I18n.put('ai_empty', '可以问这道题的解法、例子或面试怎么答', '可以問這道題的解法、例子或面試怎麼答', 'Ask for a solution, example, or interview tip');
    I18n.put('me', '我', '我', 'Me');
    I18n.put('thinking', '正在思考…', '正在思考…', 'Thinking…');
    I18n.put('thought_done', '思考完成', '思考完成', 'Thought done');
    I18n.put('no_thought', '暂无思考步骤', '暫無思考步驟', 'No thinking steps');
    I18n.put('thought_start', '思考完成，开始输出正文', '思考完成，開始輸出正文', 'Done thinking, writing answer');
    I18n.put('ai_ph', '针对这道题提问…', '針對這道題提問…', 'Ask about this question…');
    I18n.put('send', '发送', '發送', 'Send');
    I18n.put('cur_q', '当前题目：{0}', '當前題目：{0}', 'Question: {0}');
    I18n.put('tip_confused', '看不懂', '看不懂', 'Explain');
    I18n.put('tip_simple', '简单解释', '簡單解釋', 'Simplify');
    I18n.put('tip_example', '举个例子', '舉個例子', 'Example');
    I18n.put('tip_interview', '面试怎么答', '面試怎麼答', 'Interview tip');
    I18n.put('tip_followup', '可能追问', '可能追問', 'Follow-up');
    I18n.put('fav_on', '已收藏', '已收藏', 'Saved');
    I18n.put('fav_off', '已取消收藏', '已取消收藏', 'Removed');
    I18n.put('fav_feature', '收藏', '收藏', 'Favorites');
    I18n.put('report_feature', '纠错反馈', '糾錯回饋', 'Report error');
    I18n.put('report_title', '纠错反馈', '糾錯回饋', 'Report error');
    I18n.put('report_q', '题目', '題目', 'Question');
    I18n.put('report_type', '问题类型', '問題類型', 'Issue type');
    I18n.put('report_content', '具体说明', '具體說明', 'Details');
    I18n.put('report_hint', '请写明哪一段不对、正确说法是什么', '請寫明哪一段不對、正確說法是什麼', 'Say which part is wrong and what is correct');
    I18n.put('report_ok', '已收到，我们会尽快核对', '已收到，我們會盡快核對', 'Thanks, we will review it');
    I18n.put('report_fail', '提交失败，请稍后重试', '提交失敗，請稍後重試', 'Submit failed, try again later');
    I18n.put('report_ty_wrong', '答案有误', '答案有誤', 'Wrong answer');
    I18n.put('report_ty_unclear', '题干不清', '題幹不清', 'Unclear');
    I18n.put('report_ty_outdated', '内容过时', '內容過時', 'Outdated');
    I18n.put('report_ty_typo', '错别字', '錯別字', 'Typo');
    I18n.put('report_ty_other', '其他', '其他', 'Other');
    I18n.put('ai_feature', 'AI 问答', 'AI 問答', 'AI Q&A');
    I18n.put('search', '搜索', '搜尋', 'Search');
    I18n.put('search_ph', '搜题目 / 知识点 / 分类', '搜題目 / 知識點 / 分類', 'Search questions / topics');
    I18n.put('search_idle', '输入关键词，搜索题目、知识点或分类', '輸入關鍵詞，搜尋題目、知識點或分類', 'Type a keyword to search questions and topics');
    I18n.put('search_empty', '没有找到相关题目', '沒有找到相關題目', 'No matching questions');
    I18n.put('hot_search', '热搜', '熱搜', 'Hot');
    I18n.put('search_history', '搜索历史', '搜尋紀錄', 'History');
    I18n.put('clear_history', '清空', '清空', 'Clear');
    I18n.put('need_login', '需要登录', '需要登入', 'Sign in required');
    I18n.put('need_login_msg', '登录后才可使用{0}', '登入後才可使用{0}', 'Sign in to use {0}');
    I18n.put('cancel', '取消', '取消', 'Cancel');
    I18n.put('go_login', '去登录', '去登入', 'Sign in');
    I18n.put('login', '登录', '登入', 'Sign in');
    I18n.put('login_title', '登录码上 Offer', '登入碼上 Offer', 'Sign in to CodeOffer');
    I18n.put('login_sub', '使用华为账号登录，同步学习记录与简历', '使用華為帳號登入，同步學習記錄與履歷', 'Sign in with HUAWEI ID to sync progress and resume');
    I18n.put('login_huawei', '华为账号登录', '華為帳號登入', 'HUAWEI ID');
    I18n.put('logging', '登录中…', '登入中…', 'Signing in…');
    I18n.put('agree_prefix', '我已阅读并同意', '我已閱讀並同意', 'I agree to the ');
    I18n.put('user_agreement', '用户协议', '使用者協議', 'Terms');
    I18n.put('and', '和', '和', ' and ');
    I18n.put('privacy', '隐私政策', '隱私政策', 'Privacy Policy');
    I18n.put('agree_first', '请先阅读并同意用户协议和隐私政策', '請先閱讀並同意使用者協議和隱私政策', 'Please agree to the terms first');
    I18n.put('no_ctx', '无法获取页面上下文', '無法取得頁面內容', 'Unable to get page context');
    I18n.put('welcome_user', '欢迎，{0}', '歡迎，{0}', 'Welcome, {0}');
    I18n.put('login_fail', '华为账号登录失败', '華為帳號登入失敗', 'HUAWEI ID sign-in failed');
    I18n.put('interview_login_title', '登录后才可使用 AI 模拟面试', '登入後才可使用 AI 模擬面試', 'Sign in to use AI mock interviews');
    I18n.put('interview_login_sub', '登录后会保存本场问答，方便你和管理后台回看历史。',
      '登入後會保存本場問答，方便你和管理後台回看歷史。',
      'Signed-in sessions are saved for you and the admin console.');
    I18n.put('iv_guest_badge', '未登录', '未登入', 'Not signed in');
    I18n.put('iv_guest_cta_sub', '登录后开始面试，本场问答会保存到面试记录。',
      '登入後開始面試，本場問答會保存到面試記錄。',
      'Sign in to start. This session will be saved to interview history.');
    I18n.put('iv_guest_resume', '登录后将使用「我的」简历，面试官会按项目针对性提问。',
      '登入後將使用「我的」履歷，面試官會按專案針對性提問。',
      'After sign-in, the interviewer uses the resume on the Me tab.');
    I18n.put('iv_start_login', '登录后开始面试', '登入後開始面試', 'Sign in to start');
    I18n.put('pick_role', '选择岗位', '選擇崗位', 'Role');
    I18n.put('work_exp', '工作经验', '工作經驗', 'Experience');
    I18n.put('iv_diff', '面试难度', '面試難度', 'Difficulty');
    I18n.put('mock_iv', '模拟面试', '模擬面試', 'Mock interview');
    I18n.put('iv_soon', '即将开始：{0}', '即將開始：{0}', 'Starting: {0}');
    I18n.put('iv_interviewer', '面试官：{0}', '面試官：{0}', 'Interviewer: {0}');
    I18n.put('iv_focus', '考察方向：{0}', '考察方向：{0}', 'Focus: {0}');
    I18n.put('iv_resume_using', '当前使用「我的」简历：{0}', '目前使用「我的」履歷：{0}', 'Using resume: {0}');
    I18n.put('iv_resume_ok', '已根据这份简历推荐岗位、面试官和考察方向',
      '已根據這份履歷推薦崗位、面試官和考察方向',
      'Role, interviewer, and topics were suggested from this resume');
    I18n.put('iv_resume_parse', '云端正在解析这份 PDF/Word。解析完成后面试官就能按项目点名提问。',
      '雲端正在解析這份 PDF/Word。解析完成後面試官就能按專案點名提問。',
      'The resume is being parsed. The interviewer can then ask about your projects.');
    I18n.put('iv_no_resume', '尚未上传全局简历。模拟面试会使用「我的」页那一份，请先去上传。',
      '尚未上傳全域履歷。模擬面試會使用「我的」頁那一份，請先去上傳。',
      'Upload a resume on the Me tab before starting.');
    I18n.put('iv_go_resume', '去「我的」上传简历', '去「我的」上傳履歷', 'Upload resume in Me');
    I18n.put('iv_support', '支持文字聊天与 AI 语音对话，自动追问并生成面试报告。',
      '支援文字聊天與 AI 語音對話，自動追問並生成面試報告。',
      'Text or voice chat, follow-up questions, and an interview report.');
    I18n.put('iv_start', '开始模拟面试', '開始模擬面試', 'Start interview');
    I18n.put('mode_text', '文字聊天', '文字聊天', 'Text');
    I18n.put('mode_voice', '语音对话', '語音對話', 'Voice');
    I18n.put('end_iv', '结束面试', '結束面試', 'End');
    I18n.put('replying', '面试官回复中…', '面試官回覆中…', 'Interviewer is replying…');
    I18n.put('input_ans', '输入你的回答…', '輸入你的回答…', 'Type your answer…');
    I18n.put('muted', '已静音', '已靜音', 'Muted');
    I18n.put('mute', '静音', '靜音', 'Mute');
    I18n.put('end', '结束', '結束', 'Stop');
    I18n.put('tap_end', '点击结束录音', '點擊結束錄音', 'Tap to stop');
    I18n.put('tap_mic', '点击麦克风开始说话，朗读时可静音', '點擊麥克風開始說話，朗讀時可靜音', 'Tap the mic to speak. Mute while TTS plays.');
    I18n.put('back_iv', '返回面试中心', '返回面試中心', 'Back to interview');
    I18n.put('iv_report', '面试报告', '面試報告', 'Report');
    I18n.put('total_score', '综合得分 {0}', '綜合得分 {0}', 'Overall {0}');
    I18n.put('adv_label', '优势：{0}', '優勢：{0}', 'Strengths: {0}');
    I18n.put('prob_label', '待提升：{0}', '待提升：{0}', 'To improve: {0}');
    I18n.put('sugg_label', '建议：{0}', '建議：{0}', 'Suggestions: {0}');
    I18n.put('score_acc', '正确性', '正確性', 'Accuracy');
    I18n.put('score_depth', '深度', '深度', 'Depth');
    I18n.put('score_exp', '表达', '表達', 'Delivery');
    I18n.put('role_iv', '面试官', '面試官', 'Interviewer');
    I18n.put('tts_off', '已关闭语音朗读', '已關閉語音朗讀', 'Voice playback off');
    I18n.put('tts_on', '已开启语音朗读', '已開啟語音朗讀', 'Voice playback on');
    I18n.put('need_answer', '请先输入或说出你的回答', '請先輸入或說出你的回答', 'Enter or speak an answer first');
    I18n.put('voice_unavail', '语音能力不可用，请切换文字模式', '語音能力不可用，請切換文字模式', 'Voice is unavailable. Switch to text.');
    I18n.put('wait_reply', '面试官正在回复，请稍候', '面試官正在回覆，請稍候', 'Please wait for the interviewer');
    I18n.put('asr_fail', '无法启动语音识别', '無法啟動語音辨識', 'Could not start speech recognition');
    I18n.put('today_progress', '今日进度', '今日進度', 'Today');
    I18n.put('done_q', '已刷题', '已刷題', 'Done');
    I18n.put('study_min', '学习分钟', '學習分鐘', 'Minutes');
    I18n.put('done_master', '已掌握', '已掌握', 'Mastered');
    I18n.put('cal_ph', '学习日历（占位）', '學習日曆（佔位）', 'Study calendar (placeholder)');
    I18n.put('cal_hint', '后续可接入连续打卡与 GitHub 风格贡献图。', '後續可接入連續打卡與 GitHub 風格貢獻圖。', 'Streaks and a contribution graph can be added later.');
    I18n.put('weak_ph', '薄弱知识（占位）', '薄弱知識（佔位）', 'Weak topics (placeholder)');
    I18n.put('go_review', '去复习 ›', '去複習 ›', 'Review ›');
    I18n.put('week_1', '一', '一', 'M');
    I18n.put('week_2', '二', '二', 'T');
    I18n.put('week_3', '三', '三', 'W');
    I18n.put('week_4', '四', '四', 'T');
    I18n.put('week_5', '五', '五', 'F');
    I18n.put('week_6', '六', '六', 'S');
    I18n.put('week_7', '日', '日', 'S');
    I18n.put('huawei_user', '华为用户', '華為用戶', 'HUAWEI user');
    I18n.put('huawei_on', '华为账号 · 已登录', '華為帳號 · 已登入', 'HUAWEI ID · signed in');
    I18n.put('tap_login', '点击登录，同步学习数据', '點擊登入，同步學習資料', 'Sign in to sync your data');
    I18n.put('my_resume', '我的简历', '我的履歷', 'My resume');
    I18n.put('resume_cloud', '已上传到云端，模拟面试会用这一份', '已上傳到雲端，模擬面試會用這一份', 'Uploaded. Mock interviews will use this file.');
    I18n.put('resume_local', '已作为全局简历，模拟面试会用这一份', '已作為全域履歷，模擬面試會用這一份', 'Saved as your interview resume.');
    I18n.put('resume_upload_tip', '上传简历，AI 面试更精准', '上傳履歷，AI 面試更精準', 'Upload a resume for better interviews');
    I18n.put('resume_login_sync', '登录后自动同步云端简历', '登入後自動同步雲端履歷', 'Sign in to sync your resume');
    I18n.put('uploading', '上传中…', '上傳中…', 'Uploading…');
    I18n.put('replace_resume', '更换简历', '更換履歷', 'Replace');
    I18n.put('delete', '删除', '刪除', 'Delete');
    I18n.put('picking', '选择文件中…', '選擇檔案中…', 'Choosing file…');
    I18n.put('upload_resume', '上传简历（PDF / Word / TXT）', '上傳履歷（PDF / Word / TXT）', 'Upload resume (PDF / Word / TXT)');
    I18n.put('upload_after_login', '登录后上传简历', '登入後上傳履歷', 'Sign in to upload');
    I18n.put('resume_fmt', '支持 PDF、Word、TXT、Markdown', '支援 PDF、Word、TXT、Markdown', 'PDF, Word, TXT, Markdown');
    I18n.put('resume_account', '简历跟账号走，退出后本机不保留', '履歷跟帳號走，退出後本機不保留', 'Resume follows your account');
    I18n.put('favorites', '收藏夹', '收藏夾', 'Favorites');
    I18n.put('fav_sub', '题目、专栏与广场', '題目、專欄與廣場', 'Questions, columns, posts');
    I18n.put('fav_tab_q', '面试', '面試', 'Questions');
    I18n.put('fav_tab_blog', '专栏', '專欄', 'Columns');
    I18n.put('fav_tab_forum', '广场', '廣場', 'Forum');
    I18n.put('fav_empty_q', '还没有收藏题目', '還沒有收藏題目', 'No saved questions');
    I18n.put('fav_empty_blog', '还没有收藏专栏', '還沒有收藏專欄', 'No saved columns');
    I18n.put('fav_empty_forum', '还没有收藏帖子', '還沒有收藏帖子', 'No saved posts');
    I18n.put('ai_qa', 'AI 问答', 'AI 問答', 'AI Q&A');
    I18n.put('ai_qa_sub', '题目讲解对话历史', '題目講解對話歷史', 'Question chat history');
    I18n.put('ai_qa_title', 'AI 问答记录', 'AI 問答記錄', 'AI Q&A history');
    I18n.put('iv_logs', '面试记录', '面試記錄', 'Interviews');
    I18n.put('iv_logs_sub', '模拟面试历史', '模擬面試歷史', 'Mock interview history');
    I18n.put('study_log', '学习记录', '學習記錄', 'Study log');
    I18n.put('study_log_sub', '刷题天数与进度', '刷題天數與進度', 'Days and progress');
    I18n.put('wrong_book', '错题本', '錯題本', 'Wrong answers');
    I18n.put('wrong_book_sub', '回顾答错的题目', '回顧答錯的題目', 'Review missed questions');
    I18n.put('settings', '设置', '設定', 'Settings');
    I18n.put('settings_sub', '通知、缓存与退出登录', '通知、快取與登出', 'Alerts, cache, and sign-out');
    I18n.put('soon', '{0}即将上线', '{0}即將上線', '{0} is coming soon');
    I18n.put('resume_saved', '简历已保存，正在同步到云端', '履歷已保存，正在同步到雲端', 'Resume saved, syncing…');
    I18n.put('resume_deleted', '简历已删除', '履歷已刪除', 'Resume deleted');
    I18n.put('logged_huawei', '华为账号已登录', '華為帳號已登入', 'Signed in with HUAWEI ID');
    I18n.put('notify', '消息通知', '訊息通知', 'Notifications');
    I18n.put('notify_sub', '学习与面试相关提醒', '學習與面試相關提醒', 'Study and interview alerts');
    I18n.put('daily_remind', '每日学习提醒', '每日學習提醒', 'Daily reminder');
    I18n.put('daily_remind_sub', '提醒你完成当天刷题', '提醒你完成當天刷題', 'Remind you to practice today');
    I18n.put('clear_cache', '清除缓存', '清除快取', 'Clear cache');
    I18n.put('clear_cache_sub', '清理本地临时数据', '清理本地暫存資料', 'Remove local temporary files');
    I18n.put('language', '语言', '語言', 'Language');
    I18n.put('language_sub', '简体中文 / 正体中文 / English', '簡體中文 / 正體中文 / English', 'Simplified / Traditional / English');
    I18n.put('theme', '主题色', '主題色', 'Theme');
    I18n.put('theme_sub', '跟随系统、亮色或暗色', '跟隨系統、亮色或暗色', 'System, light, or dark');
    I18n.put('theme_system', '跟随系统', '跟隨系統', 'Follow system');
    I18n.put('theme_light', '亮色', '亮色', 'Light');
    I18n.put('theme_dark', '暗色', '暗色', 'Dark');
    I18n.put('pick_lang', '选择语言', '選擇語言', 'Choose language');
    I18n.put('version', '当前版本', '目前版本', 'Version');
    I18n.put('logout', '退出登录', '登出', 'Sign out');
    I18n.put('logged_out', '已退出登录', '已登出', 'Signed out');
    I18n.put('cache_cleared', '缓存已清除', '快取已清除', 'Cache cleared');
    I18n.put('feedback', '意见反馈', '意見回饋', 'Feedback');
    I18n.put('feedback_sub', '功能建议、内容纠错', '功能建議、內容糾錯', 'Suggestions and corrections');
    I18n.put('feedback_type', '反馈类型', '回饋類型', 'Type');
    I18n.put('feedback_content', '反馈内容', '回饋內容', 'Details');
    I18n.put('feedback_hint', '请尽量说明复现步骤或期望', '請盡量說明重現步驟或期望', 'Describe steps or what you expected');
    I18n.put('feedback_contact', '联系方式（选填）', '聯絡方式（選填）', 'Contact (optional)');
    I18n.put('feedback_submit', '提交', '提交', 'Submit');
    I18n.put('feedback_ok', '已收到，我们会尽快处理', '已收到，我們會盡快處理', 'Thanks, we will look into it');
    I18n.put('feedback_fail', '提交失败，请稍后重试', '提交失敗，請稍後重試', 'Submit failed, try again later');
    I18n.put('fb_suggest', '功能建议', '功能建議', 'Feature');
    I18n.put('fb_perf', '性能问题', '效能問題', 'Performance');
    I18n.put('fb_content', '内容报错', '內容報錯', 'Content');
    I18n.put('fb_points', '积分/签到', '積分/簽到', 'Points');
    I18n.put('fb_other', '其他问题', '其他問題', 'Other');
    I18n.put('inbox', '站内信', '站內信', 'Inbox');
    I18n.put('inbox_sub', '官方通知与活动消息', '官方通知與活動消息', 'Official notices');
    I18n.put('inbox_empty', '暂无消息', '暫無消息', 'No messages');
    I18n.put('inbox_login', '登录后查看站内信', '登入後查看站內信', 'Sign in to see inbox');
    I18n.put('inbox_unread', '{0} 条未读', '{0} 則未讀', '{0} unread');
    I18n.put('inbox_all_read', '全部已读', '全部已讀', 'Mark all read');
    I18n.put('fav_login', '登录后查看收藏', '登入後查看收藏', 'Sign in to see favorites');
    I18n.put('fav_empty', '还没有收藏内容', '還沒有收藏內容', 'No favorites yet');
    I18n.put('unnamed_q', '未命名题目', '未命名題目', 'Untitled question');
    I18n.put('hist_login', '登录后查看历史记录', '登入後查看歷史記錄', 'Sign in to see history');
    I18n.put('hist_empty_iv', '还没有模拟面试记录', '還沒有模擬面試記錄', 'No mock interviews yet');
    I18n.put('hist_empty_ai', '还没有 AI 问答记录', '還沒有 AI 問答記錄', 'No AI chats yet');
    I18n.put('unnamed_session', '未命名会话', '未命名工作階段', 'Untitled session');
    I18n.put('chat_detail', '对话明细', '對話明細', 'Conversation');
    I18n.put('no_chat', '暂无对话内容', '暫無對話內容', 'No messages');
    I18n.put('ag_0', '欢迎使用码上 Offer（以下简称“本应用”）。在使用华为账号登录或继续使用本应用前，请认真阅读本协议。',
      '歡迎使用碼上 Offer（以下簡稱「本應用」）。在使用華為帳號登入或繼續使用本應用前，請認真閱讀本協議。',
      'Welcome to CodeOffer. Please read these terms before signing in with HUAWEI ID.');
    I18n.put('ag_1', '1. 服务内容', '1. 服務內容', '1. Service');
    I18n.put('ag_2', '本应用向你提供面试题库、学习记录、简历辅助与 AI 模拟面试等功能。我们可能持续优化题目、分类与面试体验。',
      '本應用向你提供面試題庫、學習記錄、履歷輔助與 AI 模擬面試等功能。我們可能持續優化題目、分類與面試體驗。',
      'CodeOffer provides question banks, study records, resume help, and AI mock interviews. We may keep improving content and experience.');
    I18n.put('ag_3', '2. 账号', '2. 帳號', '2. Account');
    I18n.put('ag_4', '你可通过华为账号登录。登录后，刷题进度、简历与学习数据将与该账号关联。请妥善保管你的华为账号，勿将账号借给他人使用。',
      '你可透過華為帳號登入。登入後，刷題進度、履歷與學習資料將與該帳號關聯。請妥善保管你的華為帳號，勿將帳號借給他人使用。',
      'You can sign in with HUAWEI ID. Progress, resume, and study data are tied to that account. Keep it private.');
    I18n.put('ag_5', '3. 使用规范', '3. 使用規範', '3. Acceptable use');
    I18n.put('ag_6', '你应合法使用本应用，不得利用本应用从事侵权、作弊、干扰服务或其它违法活动。题库与 AI 生成内容仅供学习参考，不构成任何录用承诺。',
      '你應合法使用本應用，不得利用本應用從事侵權、作弊、干擾服務或其它違法活動。題庫與 AI 生成內容僅供學習參考，不構成任何錄用承諾。',
      'Use the app lawfully. Question banks and AI output are for learning only and are not a hiring promise.');
    I18n.put('ag_7', '4. 内容与知识产权', '4. 內容與智慧財產權', '4. Intellectual property');
    I18n.put('ag_8', '本应用中的题目、解析、界面与商标等权益归权利人所有。未经许可，不得复制、传播或用于商业用途。',
      '本應用中的題目、解析、介面與商標等權益歸權利人所有。未經許可，不得複製、傳播或用於商業用途。',
      'Questions, explanations, UI, and trademarks belong to their owners. Do not copy or use them commercially without permission.');
    I18n.put('ag_9', '5. 中断与变更', '5. 中斷與變更', '5. Interruptions');
    I18n.put('ag_10', '因维护、升级或不可抗力，服务可能中断或调整。我们将在合理范围内进行说明。',
      '因維護、升級或不可抗力，服務可能中斷或調整。我們將在合理範圍內進行說明。',
      'Service may pause for maintenance, upgrades, or events beyond our control. We will explain when reasonable.');
    I18n.put('ag_11', '6. 协议更新\n我们可能更新本协议。更新后继续使用，即视为你接受修订后的内容。',
      '6. 協議更新\n我們可能更新本協議。更新後繼續使用，即視為你接受修訂後的內容。',
      '6. Updates\nWe may update these terms. Continued use means you accept the revised terms.');
    I18n.put('ag_12', '7. 人工智能生成内容', '7. 人工智慧生成內容', '7. AI-generated content');
    I18n.put('ag_13',
      '本应用的「AI 问答」与「AI 模拟面试」会调用大模型生成文本。生成内容将显著标注「AI生成」，仅供学习参考，可能不准确或过时，不构成录用、法律或专业建议。请自行核实关键信息，不得用于违法违规、侵权或考试作弊。本应用不提供将生成内容导出为独立文件的功能。使用上述功能即表示你已知悉并同意本说明。',
      '本應用的「AI 問答」與「AI 模擬面試」會呼叫大模型生成文本。生成內容將顯著標註「AI生成」，僅供學習參考，可能不準確或過時，不構成錄用、法律或專業建議。請自行核實關鍵資訊，不得用於違法違規、侵權或考試作弊。本應用不提供將生成內容匯出為獨立檔案的功能。使用上述功能即表示你已知悉並同意本說明。',
      'AI Q&A and mock interviews call a large model to generate text. Output is clearly labeled “AI generated”, is for study only, may be inaccurate, and is not hiring, legal, or professional advice. Verify key facts. Do not use it for illegal, infringing, or cheating purposes. This app does not export generated content as standalone files. Using these features means you understand and agree.');
    I18n.put('pr_0', '码上 Offer 重视你的个人信息保护。请结合《用户协议》阅读本政策。',
      '碼上 Offer 重視你的個人資訊保護。請結合《使用者協議》閱讀本政策。',
      'CodeOffer takes privacy seriously. Please read this with the Terms.');
    I18n.put('pr_1', '1. 我们收集的信息', '1. 我們收集的資訊', '1. Information we collect');
    I18n.put('pr_2', '登录时，我们通过华为账号获取用于识别你的 OpenID / UnionID，以及你授权的昵称、头像。你主动上传的简历文本、刷题与面试记录也会保存在你的账号下。',
      '登入時，我們透過華為帳號取得用於識別你的 OpenID / UnionID，以及你授權的暱稱、頭像。你主動上傳的履歷文本、刷題與面試記錄也會保存在你的帳號下。',
      'At sign-in we receive OpenID / UnionID and the nickname and avatar you authorize. Resume text, practice, and interview records you create are stored with your account.');
    I18n.put('pr_3', '2. 使用目的', '2. 使用目的', '2. Purpose');
    I18n.put('pr_4', '上述信息用于账号登录、同步学习进度、结合简历生成面试题，以及改进学习体验。我们不会将简历和刷题记录用于与面试学习无关的用途。',
      '上述資訊用於帳號登入、同步學習進度、結合履歷生成面試題，以及改進學習體驗。我們不會將履歷和刷題記錄用於與面試學習無關的用途。',
      'We use this to sign you in, sync progress, generate interview questions from your resume, and improve learning. We do not use resume or practice data for unrelated purposes.');
    I18n.put('pr_5', '3. 存储与共享', '3. 儲存與共享', '3. Storage and sharing');
    I18n.put('pr_6', '数据存储于本应用服务端。除法律法规要求或获得你的同意外，我们不会向无关第三方出售或共享你的个人信息。',
      '資料儲存於本應用伺服端。除法律法規要求或獲得你的同意外，我們不會向無關第三方出售或共享你的個人資訊。',
      'Data is stored on our servers. We do not sell or share personal data except as required by law or with your consent.');
    I18n.put('pr_7', '4. 你的权利', '4. 你的權利', '4. Your rights');
    I18n.put('pr_8', '你可在设置中退出登录。如需更正或删除账号数据，可通过应用内反馈或开发者联系方式提出请求。',
      '你可在設定中登出。如需更正或刪除帳號資料，可透過應用內回饋或開發者聯絡方式提出請求。',
      'You can sign out in Settings. To correct or delete account data, contact us in-app or via the developer.');
    I18n.put('pr_9', '5. 政策更新\n本政策更新后，我们会在应用内提示。你继续使用即表示知晓相关变更。',
      '5. 政策更新\n本政策更新後，我們會在應用內提示。你繼續使用即表示知曉相關變更。',
      '5. Updates\nWe will notify you in the app when this policy changes. Continued use means you acknowledge the change.');
    I18n.put('pr_10', '6. 人工智能处理', '6. 人工智慧處理', '6. AI processing');
    I18n.put('pr_11',
      '使用 AI 问答或模拟面试时，题目内容、你的提问及简历摘要可能被发送至大模型服务以生成回答。我们仅将相关信息用于提供该功能，并按法律法规要求进行内容安全处理。',
      '使用 AI 問答或模擬面試時，題目內容、你的提問及履歷摘要可能被傳送至大模型服務以生成回答。我們僅將相關資訊用於提供該功能，並按法律法規要求進行內容安全處理。',
      'When you use AI Q&A or mock interviews, the question, your prompts, and a resume summary may be sent to a large-model service. We use this only to provide the feature and apply required content-safety checks.');
    I18n.put('ai_gen_badge', 'AI生成', 'AI生成', 'AI generated');
    I18n.put('ai_disclaimer',
      '以下内容由人工智能生成，仅供学习参考，可能不准确，不构成专业建议或录用承诺。请自行核实，勿用于违法违规用途。',
      '以下內容由人工智慧生成，僅供學習參考，可能不準確，不構成專業建議或錄用承諾。請自行核實，勿用於違法違規用途。',
      'The following is AI generated, for study only, and may be inaccurate. It is not professional or hiring advice. Verify it yourself and do not use it unlawfully.');
    I18n.put('ai_disclaimer_short', '内容由 AI 生成，仅供参考', '內容由 AI 生成，僅供參考', 'AI generated. For reference only.');
    I18n.put('ai_notice_title', '人工智能生成内容说明', '人工智慧生成內容說明', 'AI-generated content');
    I18n.put('ai_notice_msg',
      '「AI 问答」和「AI 模拟面试」将使用人工智能生成文本，并在内容旁标注「AI生成」。生成结果仅供学习参考，可能存在错误，不构成录用或专业建议。请勿用于违法违规、侵权或考试作弊。继续即表示你已阅读并同意《用户协议》中的人工智能条款。',
      '「AI 問答」和「AI 模擬面試」將使用人工智慧生成文本，並在內容旁標註「AI生成」。生成結果僅供學習參考，可能存在錯誤，不構成錄用或專業建議。請勿用於違法違規、侵權或考試作弊。繼續即表示你已閱讀並同意《使用者協議》中的人工智慧條款。',
      'AI Q&A and mock interviews generate text with AI and label it “AI generated”. Results are for study only, may be wrong, and are not hiring or professional advice. Do not use them unlawfully. Continue means you agree to the AI terms in the User Agreement.');
    I18n.put('ai_notice_ok', '同意并继续', '同意並繼續', 'Agree and continue');
    I18n.put('member_title', '会员中心', '會員中心', 'Membership');
    I18n.put('member_sub', '开通后解锁 AI 讲解与模拟面试', '開通後解鎖 AI 講解與模擬面試', 'Unlock AI Q&A and mock interviews');
    I18n.put('member_need_title', '需要会员', '需要會員', 'Membership required');
    I18n.put('member_need_msg', 'AI 功能需开通会员后使用。', 'AI 功能需開通會員後使用。',
      'AI features require membership.');
    I18n.put('member_go', '去开通', '去開通', 'Upgrade');
    I18n.put('member_not_yet', '尚未开通会员', '尚未開通會員', 'Not a member yet');
    I18n.put('member_lifetime_on', '永久会员已开通', '永久會員已開通', 'Lifetime member');
    I18n.put('member_until', '有效期至 {0}', '有效期至 {0}', 'Until {0}');
    I18n.put('member_unlimited', '不限次数', '不限次數', 'Unlimited');
    I18n.put('member_remain', '剩余 {0}', '剩餘 {0}', '{0} left');
    I18n.put('member_buy', '立即开通', '立即開通', 'Subscribe');
    I18n.put('member_renew', '续费 / 升级', '續費 / 升級', 'Renew');
    I18n.put('member_buying', '支付中…', '支付中…', 'Paying…');
    I18n.put('member_restore', '恢复购买', '恢復購買', 'Restore purchases');
    I18n.put('member_load_fail', '会员信息加载失败', '會員資訊載入失敗', 'Failed to load membership');
    I18n.put('member_iap_tip', '支付由华为应用内购买完成，虚拟商品不支持退款到第三方。沙盒测试请使用调试签名与沙盒账号。',
      '支付由華為應用內購買完成，虛擬商品不支援退款到第三方。沙盒測試請使用調試簽名與沙盒帳號。',
      'Paid via Huawei IAP. Use a sandbox account for testing.');
    I18n.put('member_iap_unavail', '当前环境暂无华为 IAP，已展示后台标价。真机调试签名 + 沙盒账号可完成购买。',
      '當前環境暫無華為 IAP，已展示後台標價。真機調試簽名 + 沙盒帳號可完成購買。',
      'Huawei IAP is unavailable here. Catalog prices are shown.');
    I18n.put('member_badge', '会员', '會員', 'VIP');
    I18n.put('member_badge_life', '永久会员', '永久會員', 'Lifetime');
    I18n.put('member_badge_need', '会员专享', '會員專享', 'Members');
    I18n.put('member_ai_need', 'AI 讲解与模拟面试需开通会员', 'AI 講解與模擬面試需開通會員', 'AI features require membership');
    I18n.put('member_hero_sub', '开通后解锁题目 AI 讲解与模拟面试', '開通後解鎖題目 AI 講解與模擬面試', 'Unlock AI Q&A and mock interviews');
    I18n.put('member_hero_life', '全部 AI 功能长期可用', '全部 AI 功能長期可用', 'All AI features stay available');
    I18n.put('member_hero_on', '会员权益生效中', '會員權益生效中', 'Membership is active');
    I18n.put('member_gate_off_title', '会员体系未开启', '會員體系未開啟', 'Membership is off');
    I18n.put('member_gate_off_msg', '运营已关闭会员总开关，AI 功能不再校验会员，付费入口暂不可用。',
      '運營已關閉會員總開關，AI 功能不再校驗會員，付費入口暫不可用。',
      'Membership is disabled by ops. AI is not gated.');
    I18n.put('member_perk_title', '会员权益', '會員權益', 'Benefits');
    I18n.put('member_perk_ai', '· 题目详情 AI 讲解，针对当前题追问', '· 題目詳情 AI 講解，針對當前題追問', '· Question AI explanations');
    I18n.put('member_perk_iv', '· AI 模拟面试，结合简历追问并生成报告', '· AI 模擬面試，結合簡歷追問並生成報告', '· AI mock interviews');
    I18n.put('member_perk_quota', '· 按套餐享对应次数，年卡 / 永久更划算', '· 按套餐享對應次數，年卡 / 永久更划算', '· Quota by plan');
    I18n.put('member_plan_hot', '推荐', '推薦', 'Popular');
    I18n.put('mall_title', '积分商城', '積分商城', 'Mall');
    I18n.put('mall_sub', '积分或现金兑换虚拟 / 实物商品', '積分或現金兌換虛擬 / 實物商品', 'Redeem virtual or physical goods');
    I18n.put('mall_orders', '我的订单', '我的訂單', 'Orders');
    I18n.put('mall_address', '收货地址', '收貨地址', 'Address');
    I18n.put('mall_points', '当前积分 {0}', '目前積分 {0}', 'Points {0}');
    I18n.put('mall_empty', '暂无上架商品', '暫無上架商品', 'No products');
    I18n.put('mall_load_fail', '商城加载失败', '商城載入失敗', 'Failed to load mall');
    I18n.put('mall_detail', '商品详情', '商品詳情', 'Product');
    I18n.put('mall_gone', '商品不存在或已下架', '商品不存在或已下架', 'Product unavailable');
    I18n.put('mall_stock', '库存 {0}', '庫存 {0}', 'Stock {0}');
    I18n.put('mall_stock_unlimited', '库存充足', '庫存充足', 'In stock');
    I18n.put('mall_stock_short', '库存不足', '庫存不足', 'Out of stock');
    I18n.put('mall_sold_out', '已售罄', '已售罄', 'Sold out');
    I18n.put('mall_freight', '运费 {0}', '運費 {0}', 'Freight {0}');
    I18n.put('mall_buy_cash', '立即购买', '立即購買', 'Buy now');
    I18n.put('mall_buy_points', '积分兑换', '積分兌換', 'Redeem');
    I18n.put('mall_buy_now', '去购买', '去購買', 'Buy');
    I18n.put('mall_choose_pay', '支付方式', '支付方式', 'Payment');
    I18n.put('mall_pan_hint', '购买完成后，在订单详情查看网盘链接和提取码。', '購買完成後，在訂單詳情查看網盤連結和提取碼。', 'The cloud disk link appears on the order after payment.');
    I18n.put('mall_pan_link', '网盘链接', '網盤連結', 'Link');
    I18n.put('mall_pan_code', '提取码', '提取碼', 'Code');
    I18n.put('mall_pan_copy', '复制', '複製', 'Copy');
    I18n.put('mall_pan_copied', '已复制', '已複製', 'Copied');
    I18n.put('mall_pan_wait', '支付成功后可查看网盘链接', '支付成功後可查看網盤連結', 'Link unlocks after payment');
    I18n.put('mall_confirm', '确认订单', '確認訂單', 'Checkout');
    I18n.put('mall_need_addr', '实物商品请先填写收货地址', '實物商品請先填寫收貨地址', 'Add a shipping address');
    I18n.put('mall_manage_addr', '管理', '管理', 'Manage');
    I18n.put('mall_remark', '订单备注', '訂單備註', 'Remark');
    I18n.put('mall_remark_ph', '选填，给商家的留言', '選填，給商家的留言', 'Optional note');
    I18n.put('mall_cash_hint', '使用华为支付完成付款，支付成功后自动发货或到账。', '使用華為支付完成付款，支付成功後自動發貨或到賬。', 'Pay with Huawei IAP. Delivery starts after payment.');
    I18n.put('mall_vip_free', '会员免费', '會員免費', 'Free for members');
    I18n.put('mall_vip_tag', '会员价', '會員價', 'Member price');
    I18n.put('mall_vip_hint', '会员积分兑换免费；现金按商品设置免费或折扣。', '會員積分兌換免費；現金按商品設定免費或折扣。', 'Members redeem points for free; cash follows product VIP rules.');
    I18n.put('mall_submit', '提交订单', '提交訂單', 'Place order');
    I18n.put('mall_submitting', '提交中…', '提交中…', 'Submitting…');
    I18n.put('mall_wait_pay', '正在拉起华为支付', '正在拉起華為支付', 'Opening Huawei Pay');
    I18n.put('mall_pay_now', '去支付', '去支付', 'Pay');
    I18n.put('mall_paying', '支付中…', '支付中…', 'Paying…');
    I18n.put('mall_need_iap', '该商品未配置华为支付，请在后台填写 IAP 商品 ID', '該商品未配置華為支付，請在後台填寫 IAP 商品 ID', 'Huawei IAP product ID is missing');
    I18n.put('mall_pay_ok', '支付成功', '支付成功', 'Paid');
    I18n.put('mall_order_ok', '下单成功', '下單成功', 'Order placed');
    I18n.put('mall_order_fail', '操作失败', '操作失敗', 'Failed');
    I18n.put('mall_addr_add', '新增地址', '新增地址', 'Add');
    I18n.put('mall_addr_edit', '编辑地址', '編輯地址', 'Edit address');
    I18n.put('mall_addr_empty', '还没有收货地址', '還沒有收貨地址', 'No address yet');
    I18n.put('mall_addr_required', '请填写收货人、手机号、省市区和详细地址', '請填寫收貨人、手機號、省市區和詳細地址', 'Name, phone, region and address required');
    I18n.put('mall_please_select', '请选择', '請選擇', 'Select');
    I18n.put('mall_addr_saved', '地址已保存', '地址已保存', 'Address saved');
    I18n.put('mall_addr_fail', '地址操作失败', '地址操作失敗', 'Address failed');
    I18n.put('mall_addr_del', '删除地址', '刪除地址', 'Delete address');
    I18n.put('mall_addr_del_msg', '确认删除这条收货地址？', '確認刪除這條收貨地址？', 'Delete this address?');
    I18n.put('mall_recv_name', '收货人', '收貨人', 'Receiver');
    I18n.put('mall_recv_phone', '手机号', '手機號', 'Phone');
    I18n.put('mall_province', '省', '省', 'Province');
    I18n.put('mall_city', '市', '市', 'City');
    I18n.put('mall_district', '区', '區', 'District');
    I18n.put('mall_detail_addr', '详细地址', '詳細地址', 'Street');
    I18n.put('mall_default_addr', '设为默认', '設為預設', 'Default');
    I18n.put('mall_default', '默认', '預設', 'Default');
    I18n.put('mall_yes', '是', '是', 'Yes');
    I18n.put('mall_no', '否', '否', 'No');
    I18n.put('mall_save', '保存', '保存', 'Save');
    I18n.put('mall_edit', '编辑', '編輯', 'Edit');
    I18n.put('mall_use_addr', '使用', '使用', 'Use');
    I18n.put('mall_order_empty', '暂无订单', '暫無訂單', 'No orders');
    I18n.put('mall_order_detail', '订单详情', '訂單詳情', 'Order');
    I18n.put('mall_order_gone', '订单不存在', '訂單不存在', 'Order not found');
    I18n.put('mall_order_no', '订单号', '訂單號', 'Order no.');
    I18n.put('mall_qty', '数量', '數量', 'Qty');
    I18n.put('mall_goods_type', '形态', '形態', 'Type');
    I18n.put('mall_pay_type', '支付', '支付', 'Pay');
    I18n.put('mall_pay_amount', '应付', '應付', 'Amount');
    I18n.put('mall_time', '下单时间', '下單時間', 'Created');
    I18n.put('mall_logistics', '物流公司', '物流公司', 'Courier');
    I18n.put('mall_logistics_no', '物流单号', '物流單號', 'Tracking no.');
    I18n.put('mall_cancel', '取消订单', '取消訂單', 'Cancel order');
    I18n.put('mall_cancel_msg', '未发货订单可取消；积分订单会退回积分。', '未發貨訂單可取消；積分訂單會退回積分。', 'Unshipped orders can be cancelled. Points will be refunded.');
    I18n.put('mall_cancelled', '订单已取消', '訂單已取消', 'Cancelled');
    I18n.put('mall_confirm_recv', '确认收货', '確認收貨', 'Confirm receipt');
    I18n.put('mall_confirm_recv_msg', '确认已收到商品？', '確認已收到商品？', 'Have you received the goods?');
    I18n.put('mall_received', '已确认收货', '已確認收貨', 'Received');
    I18n.put('uc_title', '个人中心', '個人中心', 'Profile');
    I18n.put('uc_load_fail', '个人中心加载失败', '個人中心載入失敗', 'Failed to load profile');
    I18n.put('uc_points', '当前积分', '目前積分', 'Points');
    I18n.put('uc_profile_points', '积分 {0}', '積分 {0}', 'Points {0}');
    I18n.put('uc_checkin', '签到 +{0}', '簽到 +{0}', 'Check in +{0}');
    I18n.put('uc_checking', '签到中…', '簽到中…', 'Checking in…');
    I18n.put('uc_checked', '今日已签', '今日已簽', 'Checked in');
    I18n.put('uc_checkin_ok', '签到成功，+{0} 积分', '簽到成功，+{0} 積分', 'Checked in, +{0} points');
    I18n.put('uc_checkin_fail', '签到失败', '簽到失敗', 'Check-in failed');
    I18n.put('uc_streak', '已连续签到 {0} 天', '已連續簽到 {0} 天', '{0}-day streak');
    I18n.put('uc_checkin_hint', '连续第 1～7 天分别为 10 / 15 / 20 / 30 / 40 / 50 / 80 积分，断签后从第 1 天重新计。',
      '連續第 1～7 天分別為 10 / 15 / 20 / 30 / 40 / 50 / 80 積分，斷簽後從第 1 天重新計。',
      'Days 1–7: 10/15/20/30/40/50/80. A miss resets to day 1.');
    I18n.put('uc_checkin_card', '每日签到', '每日簽到', 'Daily check-in');
    I18n.put('uc_checkin_sub', '连续 {0} 天 · 今日 +{1}', '連續 {0} 天 · 今日 +{1}', '{0}-day streak · today +{1}');
    I18n.put('uc_checkin_first', '今日签到可得 +{0}', '今日簽到可得 +{0}', 'Check in today for +{0}');
    I18n.put('uc_checkin_done_sub', '连续 {0} 天 · 今日已领取', '連續 {0} 天 · 今日已領取', '{0}-day streak · claimed today');
    I18n.put('uc_study', '刷题奖励', '刷題獎勵', 'Study rewards');
    I18n.put('uc_study_line', '今日刷题 {0} 分钟，已得 {1} 积分', '今日刷題 {0} 分鐘，已得 {1} 積分',
      'Studied {0} min today, earned {1} points');
    I18n.put('uc_study_hint', '每满 10 分钟 +5 积分，每天最多 6 次（60 分钟 / 30 积分）。打开题目详情会计入时长。',
      '每滿 10 分鐘 +5 積分，每天最多 6 次（60 分鐘 / 30 積分）。打開題目詳情會計入時長。',
      '+5 per 10 minutes, up to 6 times a day (60 min / 30 pts).');
    I18n.put('uc_study_next', '再刷 {0} 分钟可再得 {1} 积分', '再刷 {0} 分鐘可再得 {1} 積分',
      'Study {0} more min for +{1}');
    I18n.put('uc_study_max', '今日刷题积分已达上限', '今日刷題積分已達上限', 'Daily study points cap reached');
    I18n.put('uc_member_bonus', '开通会员奖励', '開通會員獎勵', 'Membership bonus');
    I18n.put('uc_ledger', '积分明细', '積分明細', 'Points history');
    I18n.put('uc_ledger_empty', '暂无积分流水', '暫無積分流水', 'No points history yet');
    I18n.put('uc_tap_center', '点击进入个人中心', '點擊進入個人中心', 'Open profile');
    I18n.put('blog_recommend', '推荐', '推薦', 'For you');
    I18n.put('blog_load_fail', '专栏加载失败', '專欄加載失敗', 'Failed to load column');
    I18n.put('blog_empty', '暂无文章', '暫無文章', 'No articles yet');
    I18n.put('blog_like', '点赞', '點讚', 'Like');
    I18n.put('blog_fav', '收藏', '收藏', 'Save');
    I18n.put('blog_toc', '目录', '目錄', 'Outline');
    I18n.put('blog_no_toc', '本文暂无目录', '本文暫無目錄', 'No outline');
    I18n.put('blog_vip_lock', '开通会员后查看剩余内容', '開通會員後查看剩餘內容', 'Join membership to read the rest');
    I18n.put('blog_open_vip', '开通会员查看全文', '開通會員查看全文', 'Unlock with membership');
    I18n.put('blog_read_pts', '阅读奖励 +{0} 积分', '閱讀獎勵 +{0} 積分', 'Reading reward +{0}');
    I18n.put('forum_load_fail', '广场加载失败', '廣場加載失敗', 'Failed to load square');
    I18n.put('forum_empty', '还没有帖子，来发第一条吧', '還沒有帖子，來發第一條吧', 'No posts yet');
    I18n.put('forum_compose', '发帖', '發帖', 'Post');
    I18n.put('forum_compose_title', '发交流', '發交流', 'New post');
    I18n.put('forum_content_ph', '请输入内容', '請輸入內容', 'Write something');
    I18n.put('forum_need_content', '请输入内容', '請輸入內容', 'Please enter content');
    I18n.put('forum_ask', '提问', '提問', 'Ask');
    I18n.put('forum_checkin', '打卡', '打卡', 'Check-in');
    I18n.put('forum_emoji', '表情', '表情', 'Emoji');
    I18n.put('forum_topic', '关联话题', '關聯話題', 'Topic');
    I18n.put('forum_mention', '用户', '用戶', '@ User');
    I18n.put('forum_add_image', '添加图片', '添加圖片', 'Add photo');
    I18n.put('forum_pick_fail', '选图失败', '選圖失敗', 'Could not pick photo');
    I18n.put('forum_uploading', '图片上传中', '圖片上傳中', 'Uploading photos');
    I18n.put('forum_title_ph', '标题', '標題', 'Title');
    I18n.put('forum_body_ph', '分享面试经验、求职疑问…', '分享面試經驗、求職疑問…', 'Share interview notes…');
    I18n.put('forum_publish', '发布', '發布', 'Publish');
    I18n.put('forum_publishing', '发布中', '發布中', 'Posting');
    I18n.put('forum_img_max', '最多添加9张图片', '最多添加9張圖片', 'Up to 9 photos');
    I18n.put('forum_reply_ph', '写跟帖…', '寫跟帖…', 'Write a reply…');
    I18n.put('forum_reply_to_ph', '回复 {0}…', '回覆 {0}…', 'Reply to {0}…');
    I18n.put('forum_reply_action', '回复', '回覆', 'Reply');
    I18n.put('forum_reply_empty', '还没有跟帖，来抢沙发', '還沒有跟帖，來搶沙發', 'No replies yet');
    I18n.put('forum_send', '发送', '發送', 'Send');
    I18n.put('forum_cat', '选择分类', '選擇分類', 'Choose a topic');
    I18n.put('forum_all', '全部', '全部', 'All');
    I18n.put('forum_recommend', '推荐', '推薦', 'For you');
    I18n.put('forum_latest', '最新', '最新', 'Latest');
    I18n.put('forum_hot', '热门', '熱門', 'Hot');
    I18n.put('forum_followed', '已关注', '已關注', 'Following');
    I18n.put('forum_fav', '收藏', '收藏', 'Save');
    I18n.put('forum_untitled', '未命名帖子', '未命名帖子', 'Untitled post');
    I18n.put('forum_share', '分享', '分享', 'Share');
    I18n.put('forum_search_ph', '搜索帖子', '搜尋帖子', 'Search posts');
    I18n.put('forum_search_idle', '输入关键词，搜索广场帖子', '輸入關鍵詞，搜尋廣場帖子', 'Type a keyword to search posts');
    I18n.put('forum_search_empty', '没有找到相关帖子', '沒有找到相關帖子', 'No matching posts');
    I18n.put('forum_soon', '即将开放', '即將開放', 'Coming soon');
    I18n.put('forum_copied', '已复制', '已複製', 'Copied');
    I18n.put('forum_just_now', '刚刚', '剛剛', 'Just now');
    I18n.put('forum_min_ago', '{0}分钟前', '{0}分鐘前', '{0}m ago');
    I18n.put('forum_hour_ago', '{0}小时前', '{0}小時前', '{0}h ago');
    I18n.put('forum_day_ago', '{0}天前', '{0}天前', '{0}d ago');
    I18n.put('forum_resolved', '已解决', '已解決', 'Resolved');
    I18n.put('forum_pinned', '置顶', '置頂', 'Pinned');
    I18n.put('forum_rejected', '审核不通过，仅自己可见', '審核不通過，僅自己可見', 'Hidden: review failed');
    I18n.put('forum_pending', '审核中，仅自己可见', '審核中，僅自己可見', 'Under review, only visible to you');
    I18n.put('forum_author', '作者', '作者', 'Author');
    I18n.put('forum_delete_msg', '确定删除这条帖子吗？', '確定刪除這條帖子嗎？', 'Delete this post?');
    I18n.put('forum_delete_fail', '删除失败', '刪除失敗', 'Could not delete');
    I18n.put('forum_deleted', '已删除', '已刪除', 'Deleted');
    I18n.put('forum_reply_delete_msg', '确定删除这条评论吗？其下回复也会一起删除。', '確定刪除這條評論嗎？其下回覆也會一起刪除。', 'Delete this comment and its replies?');
    I18n.put('forum_reply_deleted', '评论已删除', '評論已刪除', 'Comment deleted');
    I18n.put('forum_detail', '帖子详情', '帖子詳情', 'Post');
    I18n.put('forum_not_found', '帖子不存在', '帖子不存在', 'Post not found');
    I18n.put('forum_all_replies', '全部回复', '全部回覆', 'All replies');
    I18n.put('forum_all_comments', '全部评论 ({0})', '全部評論 ({0})', 'Comments ({0})');
    I18n.put('forum_all_n', '全部 {0}', '全部 {0}', 'All {0}');
    I18n.put('forum_sort_default', '默认', '預設', 'Default');
    I18n.put('forum_sort_latest', '最新', '最新', 'Latest');
    I18n.put('forum_sort_default_full', '默认排序', '預設排序', 'Default sort');
    I18n.put('forum_follow', '+ 关注', '+ 關注', '+ Follow');
    I18n.put('forum_edited', '编辑于 {0}', '編輯於 {0}', 'Edited {0}');
    I18n.put('forum_views', '{0} 浏览', '{0} 瀏覽', '{0} views');
    I18n.put('forum_comments', '{0} 评论', '{0} 評論', '{0} comments');
    I18n.put('forum_likes', '{0} 赞', '{0} 讚', '{0} likes');
    I18n.put('forum_floor', '{0}楼', '{0}樓', '#{0}');
    I18n.put('forum_expand', '展开', '展開', 'More');
    I18n.put('forum_more_replies', '查看全部 {0} 条回复', '查看全部 {0} 條回覆', 'See all {0} replies');
    I18n.put('forum_more_replies_expand', '展开更多 {0} 条回复', '展開更多 {0} 條回覆', 'Show {0} more replies');
    I18n.put('forum_only_author', '只看楼主', '只看樓主', 'OP only');
    I18n.put('forum_only_featured', '只看精华', '只看精華', 'Featured');
    I18n.put('forum_featured', '精华', '精華', 'Featured');
    I18n.put('forum_featured_empty', '暂无精华评论', '暫無精華評論', 'No featured replies');
    I18n.put('forum_write_comment', '写下你的评论...', '寫下你的評論...', 'Write a comment...');
    I18n.put('forum_write_reply', '写下你的回复...', '寫下你的回覆...', 'Write a reply...');
    I18n.put('blog_comment', '评论', '評論', 'Comments');
    I18n.put('blog_comment_empty', '还没有评论，来说两句', '還沒有評論，來說兩句', 'No comments yet');
    I18n.put('blog_comment_ph', '写下你的评论...', '寫下你的評論...', 'Write a comment...');
    I18n.put('blog_comment_loading', '评论加载中', '評論加載中', 'Loading comments');
    I18n.put('blog_reply', '回复', '回覆', 'Reply');
    I18n.put('blog_comment_delete_msg', '确定删除这条评论吗？其下回复也会一起删除。', '確定刪除這條評論嗎？其下回覆也會一起刪除。', 'Delete this comment and its replies?');
    I18n.put('blog_comment_deleted', '评论已删除', '評論已刪除', 'Comment deleted');
    I18n.put('blog_search_ph', '搜索专栏', '搜尋專欄', 'Search columns');
    I18n.put('blog_search_idle', '输入关键词，搜索专栏文章', '輸入關鍵詞，搜尋專欄文章', 'Type a keyword to search columns');
    I18n.put('blog_search_empty', '没有找到相关文章', '沒有找到相關文章', 'No matching articles');
    I18n.put('blog_topic', '专题', '專題', 'Topic');
    I18n.put('blog_view_topic', '查看专题', '查看專題', 'Open topic');
    I18n.put('blog_featured', '精选', '精選', 'Featured');
    I18n.put('blog_follow', '+ 关注', '+ 關注', '+ Follow');
    I18n.put('blog_expand', '展开全文', '展開全文', 'Read more');
    I18n.put('blog_hot', '最热', '最熱', 'Hot');
    I18n.put('blog_views', '{0} 阅读', '{0} 閱讀', '{0} reads');
    I18n.put('blog_agree', '{0} 赞同', '{0} 贊同', '{0} likes');
    I18n.put('blog_author', '作者', '作者', 'Author');
    I18n.put('blog_not_found', '文章不存在', '文章不存在', 'Article not found');
  }
}
