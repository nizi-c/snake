import router from '@ohos.router';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';
import { MusicManager } from '../models/MusicManager';

@Entry
@Component
struct HomePage {
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private musicManager: MusicManager = MusicManager.getInstance();

  async aboutToAppear() {
    console.info('HomePage aboutToAppear started');
    
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
    
    console.info('HomePage aboutToAppear completed');
    
    // 在后台初始化背景音乐，不阻塞页面渲染
    this.musicManager.init(getContext(this)).then(() => {
      console.info('Music manager initialized in background');
    }).catch((err: Error) => {
      console.error('Failed to initialize music manager:', err);
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
          .onComplete(() => {
            console.info('Background image loaded:', this.bgImagePath);
          })
          .onError(() => {
            console.error('Failed to load background image:', this.bgImagePath);
          })
      }

      Column() {
        // 顶部设置按钮
        Row() {
        Text('')
          .layoutWeight(1)
        
        Row() {
          Image($rawfile('setting.png'))
            .width(20)
            .height(20)
            .margin({ right: 8 })
          
          Text('设置')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .backgroundColor(this.currentTheme.buttonSecondary)
        .borderRadius(20)
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ThemeSettingsPage'
          })
        })
      }
      .width('100%')
      .padding({ top: 20, right: 20 })

      Text('一起野餐吧')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.primaryText)
        .margin({ top: 60, bottom: 50 })

      Button('休闲模式')
        .width(280)
        .height(70)
        .fontSize(28)
        .backgroundColor(this.currentTheme.successColor)
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 30 })
        .shadow({ radius: 6, color: this.currentTheme.shadowColor })
        .opacity(0.7)
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
        .margin({ bottom: 30 })
        .shadow({ radius: 6, color: this.currentTheme.shadowColor })
        .opacity(0.7)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ChallengeLevelPage'
          })
        })

      Button('成就')
        .width(280)
        .height(70)
        .fontSize(28)
        .backgroundColor(this.currentTheme.name === 'dark' ? '#B0B0B0' : '#FF9800')
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 6, color: this.currentTheme.shadowColor })
        .opacity(0.7)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/AchievementPage'
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
