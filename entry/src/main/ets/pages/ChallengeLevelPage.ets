import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

interface LevelInfo {
  id: number;
  name: string;
  timeLimit: number; // 秒
  targetScore: number;
  description: string;
  unlocked: boolean;
  bestTime?: number; // 最佳用时（秒）
}

@Entry
@Component
struct ChallengeLevelPage {
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  @State levels: LevelInfo[] = [
    { id: 1, name: '新手挑战', timeLimit: 180, targetScore: 100, description: '3分钟内达到100分', unlocked: true },
    { id: 2, name: '进阶挑战', timeLimit: 180, targetScore: 200, description: '3分钟内达到200分', unlocked: false },
    { id: 3, name: '高手挑战', timeLimit: 240, targetScore: 300, description: '4分钟内达到300分', unlocked: false },
    { id: 4, name: '极限挑战', timeLimit: 300, targetScore: 500, description: '5分钟内达到500分', unlocked: false }
  ];
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    await this.loadLevelData();
    this.updateBackgroundImage();
    
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
  }

  aboutToDisappear() {
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  async loadLevelData() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      
      // 加载解锁关卡
      const unlockedLevel = await prefs.get('unlockedLevel', 1) as number;
      
      // 加载最佳用时记录
      const recordsStr = await prefs.get('challengeRecords', '{}') as string;
      const records = JSON.parse(recordsStr) as Record<number, number>;
      
      // 更新关卡数据
      const updatedLevels: LevelInfo[] = [];
      for (let i = 0; i < this.levels.length; i++) {
        const level = this.levels[i];
        updatedLevels.push({
          id: level.id,
          name: level.name,
          timeLimit: level.timeLimit,
          targetScore: level.targetScore,
          description: level.description,
          unlocked: level.id <= unlockedLevel,
          bestTime: records[level.id]
        });
      }
      this.levels = updatedLevels;
      
      console.info('Loaded level data - Unlocked:', unlockedLevel, 'Records:', records);
    } catch (err) {
      console.error('Failed to load level data:', err);
    }
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'success2.png' : 'blue_qita.png';
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

  startLevel(level: LevelInfo) {
    router.pushUrl({
      url: 'pages/GamePage',
      params: {
        mode: 'challenge',
        levelId: level.id,
        timeLimit: level.timeLimit,
        targetScore: level.targetScore
      }
    });
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

          Text('挑战关卡')
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

        // 关卡列表
        Scroll() {
          Column() {
            ForEach(this.levels, (level: LevelInfo) => {
              Column() {
                Row() {
                  Column() {
                    Text(level.name)
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.currentTheme.primaryText)
                      .margin({ bottom: 8 })

                    Text(level.description)
                      .fontSize(16)
                      .fontColor(this.currentTheme.secondaryText)
                      .margin({ bottom: 8 })

                    Row() {
                      Text(`⏱️ ${Math.floor(level.timeLimit / 60)}分钟`)
                        .fontSize(14)
                        .fontColor(this.currentTheme.hintText)
                        .margin({ right: 15 })

                      Text(`🎯 目标: ${level.targetScore}分`)
                        .fontSize(14)
                        .fontColor(this.currentTheme.hintText)
                    }

                    // 显示最佳用时
                    if (level.bestTime !== undefined) {
                      Text(`⭐ 最佳: ${this.formatTime(level.bestTime)}`)
                        .fontSize(14)
                        .fontColor(this.currentTheme.successColor)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 8 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  if (level.unlocked) {
                    Button('开始')
                      .fontSize(18)
                      .width(80)
                      .height(45)
                      .fontColor('#FFFFFF')
                      .backgroundColor(this.currentTheme.successColor)
                      .onClick(() => {
                        this.startLevel(level);
                      })
                  } else {
                    Column() {
                      Image($rawfile('lock.png'))
                        .width(40)
                        .height(40)
                    }
                    .width(80)
                    .height(45)
                    .justifyContent(FlexAlign.Center)
                  }
                }
                .width('100%')
                .padding(20)
              }
              .width('90%')
              .margin({ top: 15, bottom: 15 })
              .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
              .borderRadius(15)
              .border({ width: 2, color: this.currentTheme.borderColor })
              .shadow({ radius: 6, color: this.currentTheme.shadowColor })
            })
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('rgba(0, 0, 0, 0)')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgImagePath ? 'rgba(0, 0, 0, 0)' : this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
  }
}
