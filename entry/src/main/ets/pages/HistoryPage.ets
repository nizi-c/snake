import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';

interface GameRecord {
  score: number;
  time: string;
  character: string;
  mode: string;
  timestamp: number;
}

@Entry
@Component
struct HistoryPage {
  @State records: GameRecord[] = [];
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 设置背景图片
    this.updateBackgroundImage();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
    
    await this.loadHistory();
  }

  updateBackgroundImage() {
    this.bgImagePath = this.currentTheme.name === 'light' ? 'light_qita.jpg' : 'blue_qita.png';
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

  aboutToDisappear() {
    // 清理监听器
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
  }

  async loadHistory() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      const historyStr = await prefs.get('gameHistory', '[]') as string;
      this.records = JSON.parse(historyStr);
      // 按时间戳降序排序
      this.records.sort((a, b) => b.timestamp - a.timestamp);
      console.info('Loaded history:', this.records.length, 'records');
    } catch (err) {
      console.error('Failed to load history:', err);
      this.records = [];
    }
  }

  getBestRecord(): GameRecord | null {
    if (this.records.length === 0) return null;
    // 找到得分最高的记录
    let best = this.records[0];
    for (let i = 1; i < this.records.length; i++) {
      if (this.records[i].score > best.score) {
        best = this.records[i];
      }
    }
    return best;
  }

  isBestRecord(record: GameRecord): boolean {
    const best = this.getBestRecord();
    return best !== null && record.timestamp === best.timestamp;
  }

  async clearHistory() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('gameHistory', '[]');
      await prefs.flush();
      this.records = [];
      console.info('History cleared');
    } catch (err) {
      console.error('Failed to clear history:', err);
    }
  }

  getCharacterName(character: string): string {
    switch (character) {
      case 'xiaomao.jpg':
      case 'xiaom.jpg': // 兼容拼写错误
      case 'cat.png': // 兼容旧数据
        return '🐱 小猫';
      case 'xiaogou.jpg':
      case 'dog.png': // 兼容旧数据
        return '🐶 小狗';
      case 'tuzi.jpg':
      case 'rabbit.png': // 兼容旧数据
        return '🐰 兔子';
      case 'cangshu.png':
        return '🐹 仓鼠';
      default:
        return '未知';
    }
  }

  getModeName(mode: string): string {
    return mode === 'casual' ? '休闲模式' : '挑战模式';
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
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back();
          })

        Text('历史记录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.primaryText)

        Button('清空')
          .fontSize(16)
          .backgroundColor(this.currentTheme.buttonDanger)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.clearHistory();
          })
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.getTransparentBg(this.currentTheme.secondaryBg, 0.4))

      // 最佳记录卡片
      if (this.records.length > 0) {
        Column() {
          Text('🏆 最佳记录')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6F00')
            .margin({ bottom: 15 })

          Row() {
            Column() {
              Text(`${this.getBestRecord()?.score || 0}`)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9800')
              
              Text('最高分')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 5 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Divider()
              .vertical(true)
              .height(60)
              .color('#FFB74D')
              .strokeWidth(2)

            Column() {
              Text(this.getCharacterName(this.getBestRecord()?.character || ''))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 8 })
              
              Text(`⏱️ ${this.getBestRecord()?.time || '00:00'}`)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ bottom: 5 })
              
              Text(this.getModeName(this.getBestRecord()?.mode || 'casual'))
                .fontSize(14)
                .fontColor('#999999')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
        }
        .width('90%')
        .padding(20)
        .margin({ top: 15, bottom: 10 })
        .backgroundColor('rgba(255, 243, 224, 0.4)')
        .borderRadius(15)
        .border({ width: 3, color: '#FF9800' })
        .shadow({ radius: 8, color: '#FF980040' })
      }

      // 历史记录列表
      if (this.records.length === 0) {
        Column() {
          Text('暂无游戏记录')
            .fontSize(18)
            .fontColor(this.currentTheme.hintText)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.currentTheme.primaryBg)
      } else {
        Scroll() {
          Column() {
            ForEach(this.records, (record: GameRecord, index: number) => {
              Column() {
                Row() {
                  // 排名标识
                  Text(`#${index + 1}`)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.isBestRecord(record) ? this.currentTheme.accentColor : this.currentTheme.buttonPrimary)
                    .width(50)

                  Column() {
                    Row() {
                      // 最佳记录标识
                      if (this.isBestRecord(record)) {
                        Text('🏆 ')
                          .fontSize(18)
                      }
                      
                      Text(`得分: ${record.score}`)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.isBestRecord(record) ? this.currentTheme.accentColor : this.currentTheme.primaryText)
                        .margin({ right: 15 })

                      Text(this.getCharacterName(record.character))
                        .fontSize(16)
                        .fontColor(this.currentTheme.secondaryText)
                    }
                    .margin({ bottom: 5 })

                    Row() {
                      Text(this.getModeName(record.mode))
                        .fontSize(14)
                        .fontColor(this.currentTheme.hintText)
                        .margin({ right: 15 })

                      Text(`⏱️ ${record.time}`)
                        .fontSize(14)
                        .fontColor(this.currentTheme.hintText)
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(15)
              }
              .width('100%')
              .backgroundColor(this.isBestRecord(record) ? this.getTransparentBg(this.currentTheme.cardBg, 0.4) : this.getTransparentBg(this.currentTheme.secondaryBg, 0.4))
              .borderRadius(12)
              .margin({ bottom: 10 })
              .border(this.isBestRecord(record) ? { width: 2, color: this.currentTheme.accentColor } : undefined)
              .shadow({ radius: this.isBestRecord(record) ? 6 : 4, color: this.currentTheme.shadowColor })
            })
          }
          .width('100%')
          .padding(15)
        }
        .layoutWeight(1)
        .backgroundColor('rgba(0, 0, 0, 0)')
      }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgImagePath ? 'rgba(0, 0, 0, 0)' : this.currentTheme.primaryBg)
    }
    .width('100%')
    .height('100%')
  }
}
