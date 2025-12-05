import router from '@ohos.router';
import preferences from '@ohos.data.preferences';

interface CharacterInfo {
  name: string;
  image: string;
  description: string;
}

@Entry
@Component
struct CharacterSelectPage {
  @State selectedCharacter: string = 'cat.png';
  private characters: CharacterInfo[] = [
    { name: '小猫', image: 'cat.png', description: '免疫3次蘑菇扣分' } as CharacterInfo,
    { name: '小狗', image: 'dog.png', description: '速度+10%，分数效果×2' } as CharacterInfo,
    { name: '兔子', image: 'rabbit.png', description: '速度变化×2，分数效果+50%' } as CharacterInfo,
    { name: '仓鼠', image: 'cangshu.png', description: '初始100分，速度-10%，减分+200%' } as CharacterInfo
  ];

  async aboutToAppear() {
    await this.loadSelectedCharacter();
  }

  async loadSelectedCharacter() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.selectedCharacter = await prefs.get('character', 'cat.png') as string;
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
          .backgroundColor('#666666')
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

        Text('')
          .width(60)
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')

      // 角色列表
      Scroll() {
        Column() {
          Text('选择你的角色')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
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
                  .margin({ bottom: 8 })

                Text(character.description)
                  .fontSize(15)
                  .fontColor('#666666')
                  .margin({ bottom: 10 })

                if (this.selectedCharacter === character.image) {
                  Row() {
                    Text('✓ 已选择')
                      .fontSize(14)
                      .fontColor('#4CAF50')
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
            .backgroundColor(this.selectedCharacter === character.image ? '#E8F5E9' : '#FFFFFF')
            .borderRadius(12)
            .margin({ bottom: 15 })
            .border({
              width: 3,
              color: this.selectedCharacter === character.image ? '#4CAF50' : '#E0E0E0'
            })
            .shadow({
              radius: this.selectedCharacter === character.image ? 8 : 4,
              color: this.selectedCharacter === character.image ? '#4CAF5040' : '#00000020'
            })
            .onClick(() => {
              this.saveCharacter(character.image);
            })
          })

          Text('选择你喜欢的角色作为蛇头吧！')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 20, bottom: 30 })
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
