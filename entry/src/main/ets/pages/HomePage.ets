import router from '@ohos.router';

@Entry
@Component
struct HomePage {
  build() {
    Column() {
      Text('贪吃蛇游戏')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 100, bottom: 80 })

      Button('休闲模式')
        .width(280)
        .height(70)
        .fontSize(28)
        .backgroundColor('#4CAF50')
        .borderRadius(12)
        .margin({ bottom: 30 })
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
        .backgroundColor('#FF9800')
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/GamePage',
            params: { mode: 'challenge' }
          })
        })

      Text('游戏说明')
        .fontSize(20)
        .fontColor('#666666')
        .margin({ top: 60, bottom: 20 })

      Text('• 控制蛇的方向吃食物\n• 吃到食物后蛇会变长\n• 撞墙或撞到自己游戏结束\n• 挑战模式速度更快')
        .fontSize(16)
        .fontColor('#999999')
        .lineHeight(28)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
