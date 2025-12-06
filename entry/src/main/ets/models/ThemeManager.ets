import preferences from '@ohos.data.preferences';

// 主题接口定义
export interface Theme {
  name: string;
  // 背景色
  primaryBg: string;
  secondaryBg: string;
  cardBg: string;
  // 文字色
  primaryText: string;
  secondaryText: string;
  hintText: string;
  // 强调色
  accentColor: string;
  successColor: string;
  warningColor: string;
  dangerColor: string;
  // 按钮色
  buttonPrimary: string;
  buttonSecondary: string;
  buttonDanger: string;
  // 边框和分割线
  borderColor: string;
  dividerColor: string;
  // 阴影
  shadowColor: string;
}

// 浅色主题 - 明媚温暖柔和
export const LightTheme: Theme = {
  name: 'light',
  // 背景色
  primaryBg: '#FFF9E6',        // 鹅黄背景
  secondaryBg: '#FFFFFF',      // 纯白
  cardBg: '#FFF3E0',           // 浅橙卡片
  
  // 文字色
  primaryText: '#5D4037',      // 深棕文字
  secondaryText: '#8D6E63',    // 中棕文字
  hintText: '#BCAAA4',         // 浅棕提示
  
  // 强调色
  accentColor: '#FFB74D',      // 温暖橙
  successColor: '#81C784',     // 清新绿
  warningColor: '#FFD54F',     // 明亮黄
  dangerColor: '#E57373',      // 柔和红
  
  // 按钮色
  buttonPrimary: '#64B5F6',    // 天蓝
  buttonSecondary: '#FFB74D',  // 温暖橙
  buttonDanger: '#EF9A9A',     // 浅红
  
  // 边框和分割线
  borderColor: '#FFE0B2',      // 浅橙边框
  dividerColor: '#FFECB3',     // 浅黄分割线
  
  // 阴影
  shadowColor: '#00000015',    // 浅阴影
}

// 深色主题 - 天蓝色系（高亮度）
export const DarkTheme: Theme = {
  name: 'dark',
  // 背景色 - 天蓝色调
  primaryBg: '#4A90C8',        // 天蓝主背景
  secondaryBg: '#5BA3D9',      // 亮天蓝
  cardBg: '#6BB5E8',           // 浅天蓝卡片
  
  // 文字色 - 深色文字（在白色半透明卡片上显示）
  primaryText: '#1A1A1A',      // 深灰黑文字
  secondaryText: '#4A4A4A',    // 中灰文字
  hintText: '#757575',         // 浅灰提示
  
  // 强调色 - 明亮色系
  accentColor: '#7EC8F5',      // 明亮天蓝
  successColor: '#6FD9C8',     // 明亮青绿
  warningColor: '#FFB84D',     // 明亮橙黄
  dangerColor: '#FF6B6B',      // 明亮珊瑚红
  
  // 按钮色 - 高亮度
  buttonPrimary: '#5DADE2',    // 亮蓝色
  buttonSecondary: '#7EC8F5',  // 明亮天蓝
  buttonDanger: '#FF6B6B',     // 明亮红
  
  // 边框和分割线 - 浅色
  borderColor: '#7BB8DC',      // 浅蓝边框
  dividerColor: '#8DC5E3',     // 淡蓝分割线
  
  // 阴影
  shadowColor: '#00000030',    // 中等阴影
}

export class ThemeManager {
  private static instance: ThemeManager;
  private currentTheme: Theme = LightTheme;
  private listeners: ((theme: Theme) => void)[] = [];

  private constructor() {}

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  async loadTheme(context: Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      const themeName = await prefs.get('theme', 'light') as string;
      this.currentTheme = themeName === 'dark' ? DarkTheme : LightTheme;
      this.notifyListeners();
    } catch (err) {
      console.error('Failed to load theme:', err);
    }
  }

  async saveTheme(context: Context, themeName: string): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('theme', themeName);
      await prefs.flush();
      this.currentTheme = themeName === 'dark' ? DarkTheme : LightTheme;
      this.notifyListeners();
    } catch (err) {
      console.error('Failed to save theme:', err);
    }
  }

  getTheme(): Theme {
    return this.currentTheme;
  }

  addListener(listener: (theme: Theme) => void): void {
    this.listeners.push(listener);
  }

  removeListener(listener: (theme: Theme) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => listener(this.currentTheme));
  }
}
