import router from '@ohos.router';
import preferences from '@ohos.data.preferences';

@Entry
@Component
struct SettingsPage {
  @State gridWidth: number = 22;
  @State gridHeight: number = 15;
  @State baseSpeed: number = 200;

  async aboutToAppear() {
    await this.loadSettings();
  }

  async loadSettings() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.gridWidth = await prefs.get('gridWidth', 22) as number;
      this.gridHeight = await prefs.get('gridHeight', 15) as number;
      this.baseSpeed = await prefs.get('baseSpeed', 200) as number;
    } catch (err) {
      console.error('Failed to load settings:', err);
    }
  }

  async saveSettings() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('gridWidth', this.gridWidth);
      await prefs.put('gridHeight', this.gridHeight);
      await prefs.put('baseSpeed', this.baseSpeed);
      await prefs.flush();
      console.info('Settings saved successfully');
    } catch (err) {
      console.error('Failed to save settings:', err);
    }
  }

  getSpeedLabel(): string {
    if (this.baseSpeed >= 300) return '慢速';
    if (this.baseSpeed >= 200) return '正常';
    if (this.baseSpeed >= 150) return '快速';
    return '极速';
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor('#666666')
          .onClick(() => {
            router.back();
          })

        Text('休闲模式设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text('')
          .width(60)
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')

      // 设置内容（可滚动）
      Scroll() {
        Column() {
          // 游戏区域大小设置
        Column() {
          Text('游戏区域大小')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 15 })

          // 宽度设置
          Row() {
            Text('宽度（横向格子数）')
              .fontSize(16)
              .layoutWeight(1)

            Text(`${this.gridWidth}`)
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Slider({
            value: this.gridWidth,
            min: 10,
            max: 30,
            step: 1,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#2196F3')
            .showSteps(false)
            .showTips(true)
            .onChange((value: number) => {
              this.gridWidth = Math.round(value);
            })
            .margin({ bottom: 20 })

          // 高度设置
          Row() {
            Text('高度（纵向格子数）')
              .fontSize(16)
              .layoutWeight(1)

            Text(`${this.gridHeight}`)
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Slider({
            value: this.gridHeight,
            min: 10,
            max: 20,
            step: 1,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#2196F3')
            .showSteps(false)
            .showTips(true)
            .onChange((value: number) => {
              this.gridHeight = Math.round(value);
            })

          Text('可以设置不同的宽度和高度，充分利用屏幕空间')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 10 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 20 })

        // 游戏速度设置
        Column() {
          Text('游戏速度')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 15 })

          Row() {
            Text('基础速度')
              .fontSize(16)
              .layoutWeight(1)

            Text(this.getSpeedLabel())
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Slider({
            value: this.baseSpeed,
            min: 100,
            max: 400,
            step: 50,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#FF9800')
            .showSteps(false)
            .showTips(false)
            .onChange((value: number) => {
              this.baseSpeed = Math.round(value / 50) * 50;
            })

          Text('速度会随着分数增加自动加快（每50分加快10%）')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 10 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 20 })

        // 预览区域
        Column() {
          Text('预览')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 15 })

          Column() {
            Text(`游戏区域: ${this.gridWidth} x ${this.gridHeight} (${this.gridWidth * this.gridHeight} 个格子)`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            Text(`基础速度: ${this.baseSpeed}ms (${this.getSpeedLabel()})`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            Text(`50分时: ${Math.floor(this.baseSpeed * 0.9)}ms`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 4 })
            
            Text(`100分时: ${Math.floor(this.baseSpeed * 0.81)}ms`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(15)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)

          // 保存按钮
          Button('保存设置')
            .width('100%')
            .height(50)
            .fontSize(18)
            .backgroundColor('#4CAF50')
            .margin({ top: 30, bottom: 20 })
            .onClick(async () => {
              await this.saveSettings();
              // 返回并传递新的设置
              router.back({
                url: 'pages/GamePage',
                params: {
                  gridWidth: this.gridWidth,
                  gridHeight: this.gridHeight,
                  baseSpeed: this.baseSpeed,
                  reload: true
                }
              });
            })
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
