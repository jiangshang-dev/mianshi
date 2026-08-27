import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF = 'app_settings';
const PREF_THEME = 'app_theme';

export class ThemeManager {
  static readonly KEY: string = 'appTheme';
  static readonly SYSTEM: string = 'system';
  static readonly LIGHT: string = 'light';
  static readonly DARK: string = 'dark';

  static async load(ctx: common.UIAbilityContext): Promise<void> {
    let mode = ThemeManager.SYSTEM;
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      const saved = await pref.get(PREF_THEME, '') as string;
      if (saved === ThemeManager.LIGHT || saved === ThemeManager.DARK || saved === ThemeManager.SYSTEM) {
        mode = saved;
      }
    } catch (_e) {
    }
    ThemeManager.apply(ctx, mode);
  }

  static async setMode(ctx: common.UIAbilityContext, mode: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(ctx, PREF);
      await pref.put(PREF_THEME, mode);
      await pref.flush();
    } catch (_e) {
    }
    ThemeManager.apply(ctx, mode);
  }

  static apply(ctx: common.UIAbilityContext, mode: string): void {
    AppStorage.setOrCreate(ThemeManager.KEY, mode);
    let colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === ThemeManager.LIGHT) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === ThemeManager.DARK) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      ctx.getApplicationContext().setColorMode(colorMode);
    } catch (_e) {
    }
    if (colorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      AppStorage.setOrCreate('colorMode', colorMode);
    }
  }

  static labelKey(mode: string): string {
    if (mode === ThemeManager.DARK) {
      return 'theme_dark';
    }
    if (mode === ThemeManager.LIGHT) {
      return 'theme_light';
    }
    return 'theme_system';
  }
}

export class ThemePalette {
  static isDark(theme: string, colorMode: number): boolean {
    if (theme === ThemeManager.DARK) {
      return true;
    }
    if (theme === ThemeManager.LIGHT) {
      return false;
    }
    return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  static pageBg(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#0F172A' : '#F3F4F6';
  }

  static cardBg(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#1E2937' : '#FFFFFF';
  }

  static textPrimary(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#F8FAFC' : '#111827';
  }

  static textSecondary(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#94A3B8' : '#9CA3AF';
  }

  static divider(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#334155' : '#F3F4F6';
  }

  static tabBarBg(theme: string, colorMode: number): string {
    return ThemePalette.isDark(theme, colorMode) ? '#1E2937' : '#FFFFFF';
  }
}
