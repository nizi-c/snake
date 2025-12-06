import router from '@ohos.router';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

@Entry
@Component
struct HomePage {
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 设置背景图片路径
    this.updateBackgroundImage();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      // 主题变化时更新背景图片
      this.updateBackgroundImage();
    });
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'light_index.png' : 'dark_index.png';
    console.info(`Background image path set to: ${this.bgImagePath}`);
  }

  aboutToDisappear() {
    // 清理监听器
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  build() {
    Stack() {
      // 背景图片
      if (this.bgImagePath) {
        Image($rawfile(this.bgImagePath))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Column() {
        // 顶部设置按钮
        Row() {
        Text('')
          .layoutWeight(1)
        
        Button('⚙️ 设置')
          .fontSize(16)
          .backgroundColor(this.currentTheme.buttonSecondary)
          .fontColor('#FFFFFF')
          .borderRadius(20)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ThemeSettingsPage'
            })
          })
      }
      .width('100%')
      .padding({ top: 20, right: 20 })

      Text('贪吃蛇游戏')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.primaryText)
        .margin({ top: 60, bottom: 80 })

      Button('休闲模式')
        .width(280)
        .height(70)
        .fontSize(28)
        .backgroundColor(this.currentTheme.successColor)
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 30 })
        .shadow({ radius: 6, color: this.currentTheme.shadowColor })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/GamePage',
            params: { mode: 'casual' }
          })
        })

      Button('挑战模式')
        .width(280)
        .height(70)
        .fontSize(28)
        .backgroundColor(this.currentTheme.accentColor)
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 6, color: this.currentTheme.shadowColor })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/GamePage',
            params: { mode: 'challenge' }
          })
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgImagePath ? 'rgba(0, 0, 0, 0)' : this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
  }
}
