import router from '@ohos.router';
import { ThemeManager, LightTheme, DarkTheme, Theme } from '../models/ThemeManager';
import { MusicManager } from '../models/MusicManager';

@Entry
@Component
struct ThemeSettingsPage {
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  @State isMusicEnabled: boolean = true;
  @State musicVolume: number = 0.5;
  @State isSoundEffectEnabled: boolean = true;
  @State soundEffectVolume: number = 0.5;
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private musicManager: MusicManager = MusicManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 设置背景图片
    this.updateBackgroundImage();
    
    // 加载音乐和音效状态
    this.isMusicEnabled = this.musicManager.isPlayingMusic();
    this.musicVolume = this.musicManager.getVolume();
    this.isSoundEffectEnabled = this.musicManager.isSoundEffectEnabled();
    this.soundEffectVolume = this.musicManager.getSoundEffectVolume();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
    
    // 监听音乐状态变化
    this.musicManager.addListener((isPlaying: boolean, volume: number) => {
      this.isMusicEnabled = isPlaying;
      this.musicVolume = volume;
    });
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'startIcon.png' : 'blue_qita.png';
  }

  getTransparentBg(color: string, opacity: number): string {
    // 深色主题使用白色背景，浅色主题使用主题颜色
    if (this.currentTheme.name === 'dark') {
      return `rgba(255, 255, 255, ${opacity})`;
    }
    // 将十六进制颜色转换为rgba格式
    const hex = color.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
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
    Stack() {
      // 背景图片
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
      .backgroundColor(this.getTransparentBg(this.currentTheme.secondaryBg, 0.6))

      // 设置列表
      Scroll() {
        Column() {
          // 音乐设置分组
          Column() {
            Text('音乐设置')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentTheme.secondaryText)
              .width('100%')
              .padding({ left: 20, top: 20, bottom: 10 })

            // 背景音乐开关
            Row() {
              Text('🎵')
                .fontSize(32)
                .margin({ right: 15 })

              Column() {
                Text('背景音乐')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                  .margin({ bottom: 4 })

                Text(this.isMusicEnabled ? '正在播放' : '已暂停')
                  .fontSize(14)
                  .fontColor(this.currentTheme.secondaryText)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.isMusicEnabled })
                .selectedColor(this.currentTheme.successColor)
                .onChange((isOn: boolean) => {
                  console.info('Music toggle changed to:', isOn);
                  if (isOn) {
                    this.musicManager.play();
                  } else {
                    this.musicManager.pause();
                  }
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 10 })
            .onClick(() => {
              console.info('Music card clicked, current state - isPlaying:', this.isMusicEnabled, 'volume:', this.musicVolume);
            })

            // 音量调节
            Column() {
              Row() {
                Text('音量')
                  .fontSize(16)
                  .fontColor(this.currentTheme.primaryText)
                  .layoutWeight(1)

                Text(`${Math.round(this.musicVolume * 100)}%`)
                  .fontSize(16)
                  .fontColor(this.currentTheme.accentColor)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .margin({ bottom: 10 })

              Slider({
                value: this.musicVolume * 100,
                min: 0,
                max: 100,
                step: 5,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .trackColor(this.currentTheme.borderColor)
                .selectedColor(this.currentTheme.accentColor)
                .showSteps(false)
                .showTips(true)
                .onChange((value: number) => {
                  this.musicManager.setVolume(value / 100);
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 10 })

            // 音效开关
            Row() {
              Text('🔊')
                .fontSize(24)
                .margin({ right: 15 })

              Column() {
                Text('游戏音效')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                
                Text('吃到食物时的音效')
                  .fontSize(14)
                  .fontColor(this.currentTheme.secondaryText)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.isSoundEffectEnabled })
                .selectedColor(this.currentTheme.accentColor)
                .onChange((isOn: boolean) => {
                  this.isSoundEffectEnabled = isOn;
                  this.musicManager.toggleSoundEffect();
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 10 })

            // 音效音量
            Column() {
              Row() {
                Text('音效音量')
                  .fontSize(16)
                  .fontColor(this.currentTheme.primaryText)
                  .layoutWeight(1)

                Text(`${Math.round(this.soundEffectVolume * 100)}%`)
                  .fontSize(16)
                  .fontColor(this.currentTheme.accentColor)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .margin({ bottom: 10 })

              Slider({
                value: this.soundEffectVolume * 100,
                min: 0,
                max: 100,
                step: 5,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .trackColor(this.currentTheme.borderColor)
                .selectedColor(this.currentTheme.accentColor)
                .showSteps(false)
                .showTips(true)
                .onChange((value: number) => {
                  this.soundEffectVolume = value / 100;
                  this.musicManager.setSoundEffectVolume(value / 100);
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 15, bottom: 15 })
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
            .borderRadius(12)
            .margin({ left: 15, right: 15, bottom: 20 })
          }

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
                Text('蜜糖日光')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                  .margin({ bottom: 4 })

                Text('阳光正好，不急不躁')
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
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.4))
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
                Text('溪畔微风')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentTheme.primaryText)
                  .margin({ bottom: 4 })

                Text('甜梦初醒，漫步收集')
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
            .backgroundColor(this.getTransparentBg(this.currentTheme.cardBg, 0.6))
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
