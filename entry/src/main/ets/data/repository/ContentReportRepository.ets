import { HttpClient } from '../../common/network/HttpClient';
import { mallStr } from '../../common/models/MallTypes';

interface ContentReportBody {
  targetType: string;
  targetId: string;
  targetTitle: string;
  reportType: string;
  content: string;
}

interface JeecgContentReportResp {
  success?: boolean;
  message?: string;
}

export class ContentReportRepository {
  private static instance: ContentReportRepository | null = null;

  static getInstance(): ContentReportRepository {
    if (ContentReportRepository.instance === null) {
      ContentReportRepository.instance = new ContentReportRepository();
    }
    return ContentReportRepository.instance;
  }

  async submit(targetType: string, targetId: string, targetTitle: string, reportType: string, content: string): Promise<void> {
    const payload: ContentReportBody = {
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
      reportType: reportType,
      content: content
    };
    const resp = await HttpClient.postJson('/api/content-reports', JSON.stringify(payload));
    const parsed: JeecgContentReportResp = JSON.parse(resp.body) as JeecgContentReportResp;
    if (parsed.success === false || !resp.ok) {
      const text = mallStr(parsed.message);
      throw new Error(text.length > 0 ? text : '提交失败');
    }
  }
}
