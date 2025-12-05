import router from '@ohos.router';
import preferences from '@ohos.data.preferences';

@Entry
@Component
struct SettingsPage {
  @State gridSize: number = 20;

  async aboutToAppear() {
    await this.loadSettings();
  }

  async loadSettings() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.gridSize = await prefs.get('gridSize', 20) as number;
    } catch (err) {
      console.error('Failed to load settings:', err);
    }
  }

  async saveSettings() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('gridSize', this.gridSize);
      await prefs.flush();
      console.info('Settings saved successfully');
    } catch (err) {
      console.error('Failed to save settings:', err);
    }
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

      // 设置内容
      Column() {
        // 游戏区域大小设置
        Column() {
          Text('游戏区域大小')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 15 })

          Row() {
            Text('网格数量')
              .fontSize(16)
              .layoutWeight(1)

            Text(`${this.gridSize} x ${this.gridSize}`)
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Slider({
            value: this.gridSize,
            min: 10,
            max: 50,
            step: 1,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .trackColor('#E0E0E0')
            .selectedColor('#2196F3')
            .showSteps(false)
            .showTips(true)
            .onChange((value: number) => {
              this.gridSize = Math.round(value);
            })

          Text('较小的网格会让游戏更简单，较大的网格会增加难度')
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
            Text(`游戏区域将包含 ${this.gridSize * this.gridSize} 个格子`)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .height(100)
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
          .margin({ top: 30 })
          .onClick(async () => {
            await this.saveSettings();
            router.back();
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding(20)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
