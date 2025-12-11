import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  unlocked: boolean;
}

@Entry
@Component
struct AchievementPage {
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  @State achievements: Achievement[] = [];
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    this.updateBackgroundImage();
    
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
    
    await this.loadAchievements();
  }

  aboutToDisappear() {
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  async loadAchievements() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      const achievementsStr = await prefs.get('achievements', '{}') as string;
      const unlockedAchievements = JSON.parse(achievementsStr) as Record<string, boolean>;
      
      // 定义所有成就
      const allAchievements: Achievement[] = [
        { id: 'first_game', name: '初次邂逅', description: '完成第一局游戏', icon: '🎮', unlocked: false } as Achievement,
        { id: 'food_collector', name: '美食启程', description: '累计收集6个食物', icon: '🍎', unlocked: false } as Achievement,
        { id: 'survival_master', name: '生存大师', description: '休闲模式存活超过5分钟', icon: '⏱️', unlocked: false } as Achievement,
        { id: 'score_maniac', name: '分数狂人', description: '休闲模式单局得分突破5000分', icon: '🏆', unlocked: false } as Achievement,
        { id: 'time_master', name: '时间管理大师', description: '挑战模式剩余超过1分钟完成目标', icon: '⚡', unlocked: false } as Achievement,
        { id: 'quick_eater', name: '贪吃鬼', description: '食物出现后3秒内收集到它', icon: '🍕', unlocked: false } as Achievement,
        { id: 'no_damage', name: '无伤挑战者', description: '挑战模式不消耗生命通关', icon: '🛡️', unlocked: false } as Achievement,
        { id: 'last_second', name: '最后一秒', description: '倒计时最后1秒内达成目标通关', icon: '⏰', unlocked: false } as Achievement,
        { id: 'best_collector', name: '最佳收集者', description: '连续3次挑战通关且每次剩余生命≥2', icon: '⭐', unlocked: false } as Achievement
      ];
      
      // 更新解锁状态
      const updatedAchievements: Achievement[] = [];
      for (let i = 0; i < allAchievements.length; i++) {
        const achievement = allAchievements[i];
        updatedAchievements.push({
          id: achievement.id,
          name: achievement.name,
          description: achievement.description,
          icon: achievement.icon,
          unlocked: unlockedAchievements[achievement.id] || false
        } as Achievement);
      }
      this.achievements = updatedAchievements;
      
      console.info('Achievements loaded:', this.achievements);
    } catch (err) {
      console.error('Failed to load achievements:', err);
    }
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'startIcon.png' : 'blue_qita.png';
  }

  getTransparentBg(color: string, opacity: number): string {
    if (this.currentTheme.name === 'dark') {
      return `rgba(255, 255, 255, ${opacity})`;
    }
    const hex = color.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }

  getUnlockedCount(): number {
    return this.achievements.filter(a => a.unlocked).length;
  }

  build() {
    Stack() {
      if (this.bgImagePath) {
        Image($rawfile(this.bgImagePath))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Column() {
        // 顶部导航栏
        Row() {
          Button('返回')
            .fontSize(16)
            .backgroundColor(this.currentTheme.buttonSecondary)
            .fontColor(this.currentTheme.primaryText)
            .onClick(() => {
              router.back();
            })

          Text('成就')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)

          Text('')
            .width(60)
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 20, right: 20 })
        .backgroundColor(this.getTransparentBg(this.currentTheme.secondaryBg, 0.6))

        // 成就统计
        Row() {
          Text(`已解锁: ${this.getUnlockedCount()} / ${this.achievements.length}`)
            .fontSize(16)
            .fontColor(this.currentTheme.primaryText)
            .fontWeight(FontWeight.Medium)
        }
        .width('90%')
        .padding(15)
        .margin({ top: 15 })
        .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
        .borderRadius(12)

        // 成就列表
        Scroll() {
          Column() {
            ForEach(this.achievements, (achievement: Achievement) => {
              Row() {
                Image($rawfile(achievement.unlocked ? 'award.png' : 'award_n.png'))
                  .width(50)
                  .height(50)
                  .margin({ right: 15 })

                Column() {
                  Text(achievement.name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.currentTheme.primaryText)
                    .margin({ bottom: 5 })

                  Text(achievement.description)
                    .fontSize(14)
                    .fontColor(this.currentTheme.secondaryText)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (achievement.unlocked) {
                  Text('✓')
                    .fontSize(24)
                    .fontColor(this.currentTheme.successColor)
                    .fontWeight(FontWeight.Bold)
                } else {
                  Image($rawfile('lock.png'))
                    .width(24)
                    .height(24)
                    .opacity(0.5)
                }
              }
              .width('90%')
              .padding(15)
              .margin({ top: 10, bottom: 10 })
              .backgroundColor(this.getTransparentBg(
                achievement.unlocked ? this.currentTheme.cardBg : this.currentTheme.secondaryBg,
                0.6
              ))
              .borderRadius(12)
              .border({
                width: 2,
                color: achievement.unlocked ? this.currentTheme.successColor : this.currentTheme.borderColor
              })
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgImagePath ? 'rgba(0, 0, 0, 0)' : this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
  }
}
