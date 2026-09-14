export interface CsSession {
  id: string;
  userId?: number;
  status?: number;
  agentName?: string;
  lastMsg?: string;
  unreadUser?: number;
}

export interface CsMessage {
  id: string;
  sessionId?: string;
  senderType?: string;
  senderName?: string;
  content?: string;
  createTime?: string;
}

export interface JeecgCsSessionResp {
  success?: boolean;
  message?: string;
  result?: CsSession;
}

export interface JeecgCsMessagesResp {
  success?: boolean;
  message?: string;
  result?: CsMessage[];
}

export interface JeecgCsMessageResp {
  success?: boolean;
  message?: string;
  result?: CsMessage;
}
