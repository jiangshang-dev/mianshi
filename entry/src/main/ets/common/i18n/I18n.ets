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
      I18n.t('ag_8', lang), I18n.t('ag_9', lang), I18n.t('ag_10', lang), I18n.t('ag_11', lang)
    ];
  }

  static privacy(lang?: string): string[] {
    return [
      I18n.t('pr_0', lang), I18n.t('pr_1', lang), I18n.t('pr_2', lang), I18n.t('pr_3', lang),
      I18n.t('pr_4', lang), I18n.t('pr_5', lang), I18n.t('pr_6', lang), I18n.t('pr_7', lang),
      I18n.t('pr_8', lang), I18n.t('pr_9', lang)
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
    I18n.put('tab_study', '学习', '學習', 'Study');
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
    I18n.put('src_remote', '远程 API', '遠端 API', 'Remote API');
    I18n.put('detail_title', '题目详情', '題目詳情', 'Question');
    I18n.put('not_found', '未找到题目内容', '未找到題目內容', 'Question not found');
    I18n.put('answer_body', '标准答案 / 正文', '標準答案 / 正文', 'Answer');
    I18n.put('interview_ans', '面试推荐回答', '面試推薦回答', 'Interview answer');
    I18n.put('knowledge', '知识点', '知識點', 'Key points');
    I18n.put('quick_ai', '快捷提问 AI', '快捷提問 AI', 'Ask AI');
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
    I18n.put('ai_feature', 'AI 问答', 'AI 問答', 'AI Q&A');
    I18n.put('search', '搜索', '搜尋', 'Search');
    I18n.put('search_ph', '搜题目 / 知识点 / 分类', '搜題目 / 知識點 / 分類', 'Search questions / topics');
    I18n.put('need_login', '需要登录', '需要登入', 'Sign in required');
    I18n.put('need_login_msg', '{0}登录后才可使用', '{0}登入後才可使用', 'Sign in to use {0}');
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
    I18n.put('fav_sub', '收藏的题目', '收藏的題目', 'Saved questions');
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
    I18n.put('pick_lang', '选择语言', '選擇語言', 'Choose language');
    I18n.put('version', '当前版本', '目前版本', 'Version');
    I18n.put('logout', '退出登录', '登出', 'Sign out');
    I18n.put('logged_out', '已退出登录', '已登出', 'Signed out');
    I18n.put('cache_cleared', '缓存已清除', '快取已清除', 'Cache cleared');
    I18n.put('fav_login', '登录后查看收藏的题目', '登入後查看收藏的題目', 'Sign in to see favorites');
    I18n.put('fav_empty', '还没有收藏题目', '還沒有收藏題目', 'No favorites yet');
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
  }
}
