/** 模拟面试配置 */
export interface InterviewConfig {
  role: string;
  level: string;
  difficulty: string;
  resumeId: string;
  resumePreview: string;
  resumeFileName: string;
  /** 本场考察模块，逗号分隔 */
  focus: string;
  /** 对应面试官人设 */
  interviewerTitle: string;
}

/** 聊天消息 */
export interface InterviewMessage {
  id: string;
  role: 'interviewer' | 'candidate' | 'system';
  content: string;
  time: string;
}

/** 面试报告 */
export interface InterviewReport {
  score: number;
  accuracy: number;
  depth: number;
  expression: number;
  advantages: string[];
  problems: string[];
  suggestions: string[];
}

/** 对话模式 */
export type InterviewChatMode = 'text' | 'voice';
