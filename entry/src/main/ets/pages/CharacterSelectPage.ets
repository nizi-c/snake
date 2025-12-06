import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

interface CharacterInfo {
  name: string;
  image: string;
  description: string;
}

@Entry
@Component
struct CharacterSelectPage {
  @State selectedCharacter: string = 'cat.png';
  @State currentTheme: Theme = LightTheme;
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private characters: CharacterInfo[] = [
    { name: '小猫', image: 'xiaomao.jpg', description: '免疫3次蘑菇扣分' } as CharacterInfo,
    { name: '小狗', image: 'xiaogou.jpg', description: '速度+10%，分数效果×2' } as CharacterInfo,
    { name: '兔子', image: 'tuzi.jpg', description: '速度变化×2，分数效果+50%' } as CharacterInfo,
    { name: '仓鼠', image: 'cangshu.png', description: '初始100分，速度-10%，减分+200%' } as CharacterInfo
  ];

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
    });
    
    await this.loadSelectedCharacter();
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

  build() {
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
      .backgroundColor(this.currentTheme.secondaryBg)

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
            Row() {
              // 左侧图片
              Column() {
                Image($rawfile(character.image))
                  .width(100)
                  .height(100)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(8)
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

                if (this.selectedCharacter === character.image) {
                  Row() {
                    Text('✓ 已选择')
                      .fontSize(14)
                      .fontColor(this.currentTheme.successColor)
                      .fontWeight(FontWeight.Medium)
                  }
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding({ left: 20 })
            }
            .width('100%')
            .height(140)
            .padding(10)
            .backgroundColor(this.selectedCharacter === character.image ? this.currentTheme.cardBg : this.currentTheme.secondaryBg)
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
              this.saveCharacter(character.image);
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
      .backgroundColor(this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentTheme.primaryBg)
  }
}
