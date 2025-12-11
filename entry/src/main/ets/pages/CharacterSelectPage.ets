import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

interface CharacterInfo {
  name: string;
  image: string;
  description: string;
  unlockGames: number; // 解锁所需游戏次数
}

@Entry
@Component
struct CharacterSelectPage {
  @State selectedCharacter: string = 'cat.png';
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  @State totalGames: number = 0; // 总游戏次数
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private characters: CharacterInfo[] = [
    { name: '小猫', image: 'xiaomao.jpg', description: '免疫3次蘑菇扣分', unlockGames: 0 } as CharacterInfo,
    { name: '小狗', image: 'xiaogou.jpg', description: '速度+10%，分数效果×2', unlockGames: 2 } as CharacterInfo,
    { name: '兔子', image: 'tuzi.jpg', description: '速度变化×2，分数效果+50%', unlockGames: 5 } as CharacterInfo,
    { name: '仓鼠', image: 'cangshu.jpg', description: '初始100分，移动变慢10%，减分+200%', unlockGames: 8 } as CharacterInfo
  ];

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    this.updateBackgroundImage();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
    
    await this.loadTotalGames();
    await this.loadSelectedCharacter();
  }

  async loadTotalGames() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.totalGames = await prefs.get('totalGames', 0) as number;
      console.info('Total games played:', this.totalGames);
    } catch (err) {
      console.error('Failed to load total games:', err);
    }
  }

  aboutToDisappear() {
    // 清理监听器
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  async loadSelectedCharacter() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.selectedCharacter = await prefs.get('character', 'xiaomao.jpg') as string;
    } catch (err) {
      console.error('Failed to load character:', err);
    }
  }

  async saveCharacter(character: string) {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('character', character);
      await prefs.flush();
      this.selectedCharacter = character;
      console.info('Character saved:', character);
    } catch (err) {
      console.error('Failed to save character:', err);
    }
  }

  isCharacterUnlocked(character: CharacterInfo): boolean {
    return this.totalGames >= character.unlockGames;
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'startIcon.png' : 'blue_qita.png';
  }

  getTransparentBg(color: string, opacity: number): string {
    // 深色主题使用白色背景，浅色主题使用主题颜色
    if (this.currentTheme.name === 'dark') {
      return `rgba(255, 255, 255, ${opacity})`;
    }
    const hex = color.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
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
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back({
              url: 'pages/GamePage',
              params: {
                character: this.selectedCharacter,
                reload: true
              }
            });
          })

        Text('角色选择')
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

      // 角色列表
      Scroll() {
        Column() {
          Text('选择你的角色')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)
            .margin({ top: 30, bottom: 20 })

          // 角色卡片
          ForEach(this.characters, (character: CharacterInfo) => {
            Stack() {
              Row() {
                // 左侧图片
                Column() {
                  Image($rawfile(character.image))
                    .width(100)
                    .height(100)
                    .objectFit(ImageFit.Contain)
                    .borderRadius(8)
                    .opacity(this.isCharacterUnlocked(character) ? 1.0 : 0.3)
                }
                .width(120)
                .height(120)
                .justifyContent(FlexAlign.Center)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)

                // 右侧文字信息
                Column() {
                  Text(character.name)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.currentTheme.primaryText)
                    .margin({ bottom: 8 })

                  Text(character.description)
                    .fontSize(15)
                    .fontColor(this.currentTheme.secondaryText)
                    .margin({ bottom: 10 })

                  if (this.isCharacterUnlocked(character)) {
                    if (this.selectedCharacter === character.image) {
                      Row() {
                        Text('✓ 已选择')
                          .fontSize(14)
                          .fontColor(this.currentTheme.successColor)
                          .fontWeight(FontWeight.Medium)
                      }
                    }
                  } else {
                    Text(`🔒 需要${character.unlockGames}局游戏解锁`)
                      .fontSize(14)
                      .fontColor(this.currentTheme.hintText)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .padding({ left: 20 })
              }
              .width('100%')
              .height(140)
              .padding(10)
            }
            .width('100%')
            .height(140)
            .backgroundColor(this.selectedCharacter === character.image ? this.getTransparentBg(this.currentTheme.cardBg, 0.6) : this.getTransparentBg(this.currentTheme.secondaryBg, 0.6))
            .borderRadius(12)
            .margin({ bottom: 15 })
            .border({
              width: 3,
              color: this.selectedCharacter === character.image ? this.currentTheme.successColor : this.currentTheme.borderColor
            })
            .shadow({
              radius: this.selectedCharacter === character.image ? 8 : 4,
              color: this.currentTheme.shadowColor
            })
            .onClick(() => {
              if (this.isCharacterUnlocked(character)) {
                this.saveCharacter(character.image);
              }
            })
          })

          Text('选择你喜欢的角色作为蛇头吧！')
            .fontSize(14)
            .fontColor(this.currentTheme.hintText)
            .margin({ top: 20, bottom: 30 })
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
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
