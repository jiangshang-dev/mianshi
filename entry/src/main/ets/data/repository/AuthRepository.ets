import { common } from '@kit.AbilityKit';
import { authentication } from '@kit.AccountKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DeviceProfile } from '../../common/utils/DeviceProfile';
import { AppConfig } from '../../common/constants/AppConfig';
import { LoginOutcome, UserProfile } from '../../common/models/UserTypes';
import { HttpClient } from '../../common/network/HttpClient';
import { ResumeRepository } from './ResumeRepository';

const DOMAIN = 0xC0DE;
const PREF_NAME = 'user_auth';
const PREF_KEY = 'user_profile';

interface HuaweiAuthPayload {
  authorizationCode?: string;
  idToken?: string;
  openID?: string;
  unionID?: string;
  nickName?: string;
  avatarUri?: string;
}

interface HuaweiAuthAttempt {
  payload: HuaweiAuthPayload | null;
  failCode: number;
}

interface HuaweiLoginBody {
  authorizationCode: string;
  idToken: string;
  openId: string;
  unionId: string;
  nickname: string;
  avatar: string;
  state: string;
  clientSource: string;
  loginDevice: string;
}

interface LoginApiBody {
  success?: boolean;
  message?: string;
  result?: LoginApiResult;
}

interface LoginApiResult {
  token?: string;
  refreshToken?: string;
  isNewUser?: boolean;
  userInfo?: LoginUserInfo;
}

interface LoginUserInfo {
  id?: string | number;
  nickname?: string;
  avatar?: string;
}

interface BizErr {
  code?: number;
}

export class AuthRepository {
  private static instance: AuthRepository | null = null;
  private cached: UserProfile | null = null;

  static getInstance(): AuthRepository {
    if (!AuthRepository.instance) {
      AuthRepository.instance = new AuthRepository();
    }
    return AuthRepository.instance;
  }

  isLoggedIn(): boolean {
    return this.cached !== null && this.cached.token.length > 0;
  }

  getCached(): UserProfile | null {
    return this.cached;
  }

  getToken(): string {
    return this.cached !== null ? this.cached.token : '';
  }

  syncAppStorage(): void {
    if (this.cached && this.cached.token.length > 0) {
      AppStorage.setOrCreate('userId', this.cached.userId);
      AppStorage.setOrCreate('userDisplayName', this.cached.displayName);
      AppStorage.setOrCreate('userAvatarUrl', this.cached.avatarUrl);
      AppStorage.setOrCreate('userToken', this.cached.token);
      AppStorage.setOrCreate('isLoggedIn', true);
    } else {
      AppStorage.setOrCreate('userId', '');
      AppStorage.setOrCreate('userDisplayName', '');
      AppStorage.setOrCreate('userAvatarUrl', '');
      AppStorage.setOrCreate('userToken', '');
      AppStorage.setOrCreate('isLoggedIn', false);
    }
  }

  async load(context: common.UIAbilityContext): Promise<UserProfile | null> {
    if (this.cached) {
      this.syncAppStorage();
      await this.ensureActiveSession(context);
      return this.cached;
    }
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      const raw = await pref.get(PREF_KEY, '') as string;
      if (raw.length === 0) {
        this.cached = null;
        this.syncAppStorage();
        return null;
      }
      this.cached = JSON.parse(raw) as UserProfile;
      if (!this.cached.token) {
        this.cached.token = '';
      }
      if (!this.cached.refreshToken) {
        this.cached.refreshToken = '';
      }
      if (!this.cached.userId) {
        this.cached.userId = '';
      }
      this.syncAppStorage();
      await this.ensureActiveSession(context);
      return this.cached;
    } catch (err) {
      hilog.warn(DOMAIN, 'AuthRepository', 'load failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  async loginWithHuawei(context: common.Context): Promise<LoginOutcome> {
    try {
      const attempt = await this.requestHuaweiAccount(context);
      if (!attempt.payload) {
        const reason = this.describeHuaweiCode(attempt.failCode);
        return {
          ok: false,
          profile: null,
          message: attempt.failCode !== 0 ? `${reason}（${attempt.failCode}）` : reason
        };
      }
      const payload = attempt.payload;
      const hasCredential = (payload.authorizationCode ?? '').length > 0
        || (payload.idToken ?? '').length > 0
        || (payload.openID ?? '').length > 0
        || (payload.unionID ?? '').length > 0;
      if (!hasCredential) {
        return { ok: false, profile: null, message: '华为账号未返回有效凭证，请重试' };
      }
      const loginBody: HuaweiLoginBody = {
        authorizationCode: payload.authorizationCode ?? '',
        idToken: payload.idToken ?? '',
        openId: payload.openID ?? '',
        unionId: payload.unionID ?? '',
        nickname: payload.nickName ?? '华为用户',
        avatar: payload.avatarUri ?? '',
        state: `${Date.now()}`,
        clientSource: 'harmony',
        loginDevice: DeviceProfile.loginDevice()
      };
      const body = JSON.stringify(loginBody);
      const resp = await HttpClient.postJson('/user/auth/huaweiLogin', body, AppConfig.LOGIN_TIMEOUT_MS);
      if (resp.code === -1) {
        return { ok: false, profile: null, message: '无法连接服务器，请确认后台已启动' };
      }
      const parsed = this.parseLoginBody(resp.body);
      if (!resp.ok || !parsed.success || !parsed.result || !parsed.result.token) {
        const msg = parsed.message && parsed.message.length > 0 ? parsed.message : '华为账号登录失败';
        return { ok: false, profile: null, message: msg };
      }
      const info = parsed.result.userInfo;
      let displayName = payload.nickName ?? '华为用户';
      if (info !== undefined && info.nickname !== undefined && info.nickname.length > 0) {
        displayName = info.nickname;
      }
      let avatarUrl = payload.avatarUri ?? '';
      if (info !== undefined && info.avatar !== undefined && info.avatar.length > 0) {
        avatarUrl = info.avatar;
      }
      const profile: UserProfile = {
        openId: payload.openID ?? '',
        unionId: payload.unionID ?? '',
        displayName: displayName,
        avatarUrl: avatarUrl,
        loginType: 'huawei',
        token: parsed.result.token ?? '',
        refreshToken: parsed.result.refreshToken ?? '',
        userId: this.readUserId(info, resp.body)
      };
      await this.persist(context, profile);
      this.cached = profile;
      this.syncAppStorage();
      await ResumeRepository.getInstance().load(context as common.UIAbilityContext);
      return { ok: true, profile, message: '' };
    } catch (err) {
      hilog.warn(DOMAIN, 'AuthRepository', 'loginWithHuawei failed %{public}s', JSON.stringify(err));
      return { ok: false, profile: null, message: this.describeHuaweiCode(this.errorCodeFromRaw(JSON.stringify(err))) };
    }
  }

  async logout(context: common.UIAbilityContext): Promise<void> {
    await this.clearLocal(context);
    await ResumeRepository.getInstance().clearLocalSession(context);
  }

  async clearLocal(context: common.UIAbilityContext): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.delete(PREF_KEY);
    await pref.flush();
    this.cached = null;
    this.syncAppStorage();
  }

  private async ensureActiveSession(context: common.UIAbilityContext): Promise<void> {
    if (this.cached === null || this.cached.token.length === 0) {
      return;
    }
    const resp = await HttpClient.get('/user/auth/info');
    if (resp.code === -1) {
      return;
    }
    const parsed = this.parseLoginBody(resp.body);
    const message = parsed.message ?? '';
    if (parsed.success === false && message.indexOf('禁用') >= 0) {
      hilog.warn(DOMAIN, 'AuthRepository', 'account disabled, clear local session');
      await this.logout(context);
    }
  }

  private async requestHuaweiAccount(context: common.Context): Promise<HuaweiAuthAttempt> {
    return await this.executeHuaweiAuth(context);
  }

  private async executeHuaweiAuth(context: common.Context): Promise<HuaweiAuthAttempt> {
    try {
      const provider = new authentication.HuaweiIDProvider();
      const controller = new authentication.AuthenticationController(context);
      const authRequest = provider.createAuthorizationWithHuaweiIDRequest();
      // 个人开发者只申请头像昵称；serviceauthcode/idtoken 会报 1001502003
      authRequest.scopes = ['profile'];
      authRequest.forceAuthorization = true;
      authRequest.state = `mianshi${Date.now()}`;
      const authResp = await controller.executeRequest(authRequest);
      const authResponse = authResp as authentication.AuthorizationWithHuaweiIDResponse;
      if (authResponse.data) {
        return { payload: authResponse.data as HuaweiAuthPayload, failCode: 0 };
      }
      return { payload: null, failCode: 0 };
    } catch (authErr) {
      const raw = JSON.stringify(authErr);
      hilog.warn(DOMAIN, 'AuthRepository', 'authorization failed %{public}s', raw);
      return { payload: null, failCode: this.errorCodeFromRaw(raw) };
    }
  }

  private errorCodeFromRaw(raw: string): number {
    try {
      const parsed = JSON.parse(raw) as BizErr;
      if (parsed.code !== undefined) {
        return parsed.code;
      }
      return 0;
    } catch (_e) {
      return 0;
    }
  }

  private describeHuaweiCode(code: number): string {
    if (code === 1001502012) {
      return '已取消登录';
    }
    if (code === 1001502001) {
      return '请先在系统设置中登录华为账号';
    }
    if (code === 1001500001) {
      return '应用签名校验失败，请使用与 AGC 一致的签名证书';
    }
    if (code === 1001502003) {
      return '华为账号授权参数无效，请确认已开通华为账号服务且 client_id 为应用 OAuth ID';
    }
    if (code === 1001502014 || code === 1001500003) {
      return '华为账号授权范围未开通，请在 AGC 开通华为账号服务';
    }
    if (code === 1001502005) {
      return '网络异常，请稍后重试';
    }
    if (code === 0) {
      return '未获取到华为账号授权，请确认已登录华为账号';
    }
    return '华为账号登录失败，请稍后重试';
  }

  private parseLoginBody(body: string): LoginApiBody {
    if (!body || body.length === 0) {
      return { success: false, message: '服务器无响应' };
    }
    try {
      return JSON.parse(body) as LoginApiBody;
    } catch (_e) {
      return { success: false, message: '服务器返回异常' };
    }
  }

  private readUserId(info: LoginUserInfo | undefined, rawBody: string): string {
    const fromRaw = this.extractJsonNumericField(rawBody, 'id');
    if (fromRaw.length > 0) {
      return fromRaw;
    }
    if (info !== undefined && info.id !== undefined) {
      return `${info.id}`;
    }
    return '';
  }

  private extractJsonNumericField(body: string, key: string): string {
    const token = `"${key}"`;
    const at = body.indexOf(token);
    if (at < 0) {
      return '';
    }
    let i = at + token.length;
    while (i < body.length) {
      const ch = body.charAt(i);
      if (ch === ' ' || ch === ':') {
        i++;
        continue;
      }
      break;
    }
    if (i < body.length && body.charAt(i) === '"') {
      i++;
      let out = '';
      while (i < body.length && body.charAt(i) !== '"') {
        out += body.charAt(i);
        i++;
      }
      return out;
    }
    let digits = '';
    while (i < body.length) {
      const ch = body.charAt(i);
      if (ch < '0' || ch > '9') {
        break;
      }
      digits += ch;
      i++;
    }
    return digits;
  }

  private async persist(context: common.Context, profile: UserProfile): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.put(PREF_KEY, JSON.stringify(profile));
    await pref.flush();
  }
}
