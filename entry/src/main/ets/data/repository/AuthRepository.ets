import { common } from '@kit.AbilityKit';
import { authentication } from '@kit.AccountKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UserProfile } from '../../common/models/UserTypes';

const DOMAIN = 0xC0DE;
const PREF_NAME = 'user_auth';
const PREF_KEY = 'user_profile';

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
    return this.cached !== null;
  }

  getCached(): UserProfile | null {
    return this.cached;
  }

  syncAppStorage(): void {
    if (this.cached) {
      AppStorage.setOrCreate('isLoggedIn', true);
      AppStorage.setOrCreate('userDisplayName', this.cached.displayName);
      AppStorage.setOrCreate('userAvatarUrl', this.cached.avatarUrl);
    } else {
      AppStorage.setOrCreate('isLoggedIn', false);
      AppStorage.setOrCreate('userDisplayName', '');
      AppStorage.setOrCreate('userAvatarUrl', '');
    }
  }

  async load(context: common.UIAbilityContext): Promise<UserProfile | null> {
    if (this.cached) {
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
      this.syncAppStorage();
      return this.cached;
    } catch (err) {
      hilog.warn(DOMAIN, 'AuthRepository', 'load failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  async loginWithHuawei(context: common.UIAbilityContext): Promise<UserProfile | null> {
    try {
      const provider = new authentication.HuaweiIDProvider();
      const controller = new authentication.AuthenticationController(context);
      const loginRequest = provider.createLoginWithHuaweiIDRequest();
      loginRequest.forceLogin = false;
      loginRequest.state = `${Date.now()}`;

      const loginResp = await controller.executeRequest(loginRequest);
      const loginResponse = loginResp as authentication.LoginWithHuaweiIDResponse;
      const loginData = loginResponse.data;
      if (!loginData) {
        return null;
      }

      let displayName = '华为用户';
      let avatarUrl = '';
      try {
        const authRequest = provider.createAuthorizationWithHuaweiIDRequest();
        authRequest.scopes = ['profile'];
        authRequest.state = `${Date.now()}`;
        const authResp = await controller.executeRequest(authRequest);
        const authResponse = authResp as authentication.AuthorizationWithHuaweiIDResponse;
        const authData = authResponse.data;
        if (authData) {
          if (authData.nickName && authData.nickName.length > 0) {
            displayName = authData.nickName;
          }
          if (authData.avatarUri && authData.avatarUri.length > 0) {
            avatarUrl = authData.avatarUri;
          }
        }
      } catch (profileErr) {
        hilog.warn(DOMAIN, 'AuthRepository', 'fetch profile failed %{public}s', JSON.stringify(profileErr));
      }

      const profile: UserProfile = {
        openId: loginData.openID ?? '',
        unionId: loginData.unionID ?? '',
        displayName,
        avatarUrl,
        loginType: 'huawei'
      };
      await this.persist(context, profile);
      this.cached = profile;
      this.syncAppStorage();
      return profile;
    } catch (err) {
      hilog.warn(DOMAIN, 'AuthRepository', 'loginWithHuawei failed %{public}s', JSON.stringify(err));
      return null;
    }
  }

  async logout(context: common.UIAbilityContext): Promise<void> {
    await this.clearLocal(context);
  }

  async clearLocal(context: common.UIAbilityContext): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.delete(PREF_KEY);
    await pref.flush();
    this.cached = null;
    this.syncAppStorage();
  }

  private async persist(context: common.UIAbilityContext, profile: UserProfile): Promise<void> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    await pref.put(PREF_KEY, JSON.stringify(profile));
    await pref.flush();
  }
}
