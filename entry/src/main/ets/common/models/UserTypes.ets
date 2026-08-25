/** 登录用户信息 */
export interface UserProfile {
  openId: string;
  unionId: string;
  displayName: string;
  avatarUrl: string;
  loginType: string;
  token: string;
  refreshToken: string;
  userId: string;
}

export interface LoginOutcome {
  ok: boolean;
  profile: UserProfile | null;
  message: string;
}
