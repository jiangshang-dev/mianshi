import { HttpClient } from '../../common/network/HttpClient';
import { CommentUi } from '../../common/utils/CommentUi';

export interface AppFeatureFlags {
  memberEnabled?: boolean;
  commentEnabled: boolean;
  questionAiEnabled: boolean;
  interviewAiEnabled: boolean;
  blogEnabled?: boolean;
  forumEnabled?: boolean;
}

interface AppFeatureResponse {
  code: number;
  result?: AppFeatureFlags;
  data?: AppFeatureFlags;
}

export class AppFeatureRepository {
  static readonly COMMENT = 'commentFeatureEnabled';
  static readonly QUESTION_AI = 'questionAiEnabled';
  static readonly INTERVIEW_AI = 'interviewAiEnabled';
  static readonly MEMBER = 'memberEnabled';
  static readonly BLOG = 'blogEnabled';
  static readonly FORUM = 'forumEnabled';

  private static instance: AppFeatureRepository | null = null;

  static getInstance(): AppFeatureRepository {
    if (!AppFeatureRepository.instance) {
      AppFeatureRepository.instance = new AppFeatureRepository();
    }
    return AppFeatureRepository.instance;
  }

  async refresh(): Promise<void> {
    let commentOn = true;
    let questionAiOn = true;
    let interviewAiOn = true;
    let memberOn = true;
    let blogOn = true;
    let forumOn = true;
    try {
      const resp = await HttpClient.get('/api/app/features');
      if (resp.ok) {
        const parsed = JSON.parse(resp.body) as AppFeatureResponse;
        const flags = parsed.result ?? parsed.data;
        if (flags !== undefined) {
          commentOn = flags.commentEnabled !== false;
          questionAiOn = flags.questionAiEnabled !== false;
          interviewAiOn = flags.interviewAiEnabled !== false;
          memberOn = flags.memberEnabled !== false;
          blogOn = flags.blogEnabled !== false;
          forumOn = flags.forumEnabled !== false;
        }
      }
    } catch (_e) {
    }
    CommentUi.setBool(AppFeatureRepository.COMMENT, commentOn);
    CommentUi.setBool(AppFeatureRepository.QUESTION_AI, questionAiOn);
    CommentUi.setBool(AppFeatureRepository.INTERVIEW_AI, interviewAiOn);
    CommentUi.setBool(AppFeatureRepository.MEMBER, memberOn);
    CommentUi.setBool(AppFeatureRepository.BLOG, blogOn);
    CommentUi.setBool(AppFeatureRepository.FORUM, forumOn);
    if (!commentOn) {
      CommentUi.closeDetail();
    }
  }
}
