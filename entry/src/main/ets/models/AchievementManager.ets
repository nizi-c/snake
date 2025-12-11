import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

export class AchievementManager {
  private static instance: AchievementManager;
  private context: Context | null = null;
  private achievements: Record<string, boolean> = {};
  private listeners: Array<(achievementId: string, name: string) => void> = [];

  private constructor() {}

  static getInstance(): AchievementManager {
    if (!AchievementManager.instance) {
      AchievementManager.instance = new AchievementManager();
    }
    return AchievementManager.instance;
  }

  async init(context: Context) {
    this.context = context;
    await this.loadAchievements();
  }

  private async loadAchievements() {
    try {
      if (!this.context) return;
      const prefs = await preferences.getPreferences(this.context, 'snake_settings');
      const achievementsStr = await prefs.get('achievements', '{}') as string;
      this.achievements = JSON.parse(achievementsStr) as Record<string, boolean>;
      console.info('Achievements loaded:', this.achievements);
    } catch (err) {
      console.error('Failed to load achievements:', err);
    }
  }

  async unlockAchievement(achievementId: string, achievementName: string) {
    if (this.achievements[achievementId]) {
      return; // 已解锁
    }

    this.achievements[achievementId] = true;
    await this.saveAchievements();
    
    // 通知监听器
    this.notifyListeners(achievementId, achievementName);
    console.info('Achievement unlocked:', achievementId, achievementName);
  }

  private async saveAchievements() {
    try {
      if (!this.context) return;
      const prefs = await preferences.getPreferences(this.context, 'snake_settings');
      await prefs.put('achievements', JSON.stringify(this.achievements));
      await prefs.flush();
    } catch (err) {
      console.error('Failed to save achievements:', err);
    }
  }

  isUnlocked(achievementId: string): boolean {
    return this.achievements[achievementId] || false;
  }

  addListener(callback: (achievementId: string, name: string) => void) {
    this.listeners.push(callback);
  }

  removeListener(callback: (achievementId: string, name: string) => void) {
    const index = this.listeners.indexOf(callback);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(achievementId: string, name: string) {
    this.listeners.forEach(callback => {
      callback(achievementId, name);
    });
  }
}
