/** 简历同步状态（预留服务端对接） */
export type ResumeSyncStatus = 'local' | 'pending' | 'uploaded';

/** 本地简历档案 */
export interface ResumeProfile {
  fileName: string;
  filePath: string;
  fileUrl: string;
  fileSize: number;
  mimeType: string;
  uploadedAt: string;
  textPreview: string;
  textContent: string;
  resumeId: string;
  parseStatus: string;
  syncStatus: ResumeSyncStatus;
}
