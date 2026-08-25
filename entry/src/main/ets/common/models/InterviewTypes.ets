/** 模拟面试配置 */
export interface InterviewConfig {
  role: string;
  level: string;
  difficulty: string;
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
