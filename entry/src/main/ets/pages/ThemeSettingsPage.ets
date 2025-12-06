import router from '@ohos.router';
import { ThemeManager, LightTheme, DarkTheme, Theme } from '../models/ThemeManager';

@Entry
@Component
struct ThemeSettingsPage {
  @State currentTheme: Theme = LightTheme;
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  aboutToDisappear() {
    // 清理监听器
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  async switchTheme(themeName: string) {
    await this.themeManager.saveTheme(getContext(this), themeName);
    this.currentTheme = this.themeManager.getTheme();
  }

  build() {
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

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.primaryText)

        // 占位保持居中
        Text('')
          .width(60)
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.currentTheme.secondaryBg)

      // 设置列表
      Scroll() {
        Column() {
          // 主题设置分组
          Column() {
            Text('主题设置')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentTheme.secondaryText)
              .width('100%')
              .padding({ left: 20, top: 20, bottom: 10 })

            // 浅色主题选项
            Row() {
              Text('☀️')
                .fontSize(32)
                .margin({ right: 15 })

              Column() {
                Text('浅色主题')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                  .margin({ bottom: 4 })

                Text('明媚温暖柔和')
                  .fontSize(14)
                  .fontColor(this.currentTheme.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.currentTheme.name === 'light') {
                Text('✓')
                  .fontSize(24)
                  .fontColor(this.currentTheme.successColor)
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.currentTheme.cardBg)
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 10 })
            .onClick(() => {
              if (this.currentTheme.name !== 'light') {
                this.switchTheme('light');
              }
            })

            // 深色主题选项
            Row() {
              Text('🌙')
                .fontSize(32)
                .margin({ right: 15 })

              Column() {
                Text('深色主题')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                  .margin({ bottom: 4 })

                Text('天蓝色系')
                  .fontSize(14)
                  .fontColor(this.currentTheme.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.currentTheme.name === 'dark') {
                Text('✓')
                  .fontSize(24)
                  .fontColor(this.currentTheme.successColor)
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.currentTheme.cardBg)
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 10 })
            .onClick(() => {
              if (this.currentTheme.name !== 'dark') {
                this.switchTheme('dark');
              }
            })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 预留其他设置分组的位置
          // 可以在这里添加更多设置项
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentTheme.primaryBg)
  }
}
