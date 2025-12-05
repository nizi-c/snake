import router from '@ohos.router';
import { SnakeGame, Direction, Position, FoodType } from '../models/SnakeGame';
import image from '@ohos.multimedia.image';
import preferences from '@ohos.data.preferences';

interface FoodImageConfig {
  type: FoodType;
  file: string;
}

@Entry
@Component
struct GamePage {
  @State game: SnakeGame = new SnakeGame(200);
  @State isPlaying: boolean = false;
  @State isPaused: boolean = false;
  @State gameMode: string = 'casual';
  @State updateFlag: number = 0;
  @State currentTime: string = '00:00';
  @State controlMode: string = 'button'; // 'button' 或 'click'
  @State showControlDialog: boolean = false;
  @State showMenuDialog: boolean = false;
  @State dialogSize: number = 300;
  private timerId: number = -1;
  private cellSize: number = 20;
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private foodImages: Map<FoodType, image.PixelMap> = new Map();

  async aboutToAppear() {
    await this.loadGameSettings();
  }

  async loadGameSettings() {
    const params = router.getParams() as Record<string, Object>;
    this.gameMode = (params?.mode as string) || 'casual';
    
    let baseSpeed = this.gameMode === 'challenge' ? 100 : 200;
    let gridSize = 20;
    
    // 检查是否从设置页面返回
    if (params?.reload) {
      if (params?.gridSize) {
        gridSize = params.gridSize as number;
      }
      if (params?.baseSpeed) {
        baseSpeed = params.baseSpeed as number;
      }
      console.info('Reloading game with new settings - gridSize:', gridSize, 'baseSpeed:', baseSpeed);
      this.game = new SnakeGame(baseSpeed, gridSize);
      this.stopGame();
      this.drawGame();
      return;
    }
    
    // 加载设置
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      gridSize = await prefs.get('gridSize', 20) as number;
      
      // 只在休闲模式使用自定义速度，挑战模式固定为100ms
      if (this.gameMode === 'casual') {
        baseSpeed = await prefs.get('baseSpeed', 200) as number;
      }
      
      this.game = new SnakeGame(baseSpeed, gridSize);
    } catch (err) {
      console.error('Failed to load settings:', err);
      this.game = new SnakeGame(baseSpeed, gridSize);
    }
  }

  onPageShow() {
    // 页面显示时检查是否需要重新加载
    const params = router.getParams() as Record<string, Object>;
    if (params?.reload && params?.gridSize) {
      this.loadGameSettings();
    }
  }

  async loadFruitImage() {
    try {
      const context = getContext(this);
      const resourceMgr = context.resourceManager;
      
      // 加载所有食物图片
      const foodFiles: FoodImageConfig[] = [
        { type: FoodType.FRUIT, file: 'fruit.png' } as FoodImageConfig,
        { type: FoodType.ORANGE, file: 'orange.png' } as FoodImageConfig,
        { type: FoodType.WATERMELON, file: 'watermelon.png' } as FoodImageConfig,
        { type: FoodType.MUSHROOM, file: 'mushroom.png' } as FoodImageConfig,
        { type: FoodType.LEMON, file: 'lemon.png' } as FoodImageConfig,
        { type: FoodType.FLOWER, file: 'flower.png' } as FoodImageConfig
      ];
      
      for (const food of foodFiles) {
        try {
          const fileData = await resourceMgr.getRawFileContent(food.file);
          const imageSource = image.createImageSource(fileData.buffer);
          const pixelMap = await imageSource.createPixelMap();
          this.foodImages.set(food.type, pixelMap);
          console.info(`${food.file} loaded successfully`);
        } catch (err) {
          console.error(`Failed to load ${food.file}:`, JSON.stringify(err));
        }
      }
      
      this.drawGame();
    } catch (err) {
      console.error('Failed to load food images:', JSON.stringify(err));
    }
  }

  aboutToDisappear() {
    this.stopGame();
  }

  startGame() {
    if (this.game.isOver()) {
      this.game.init();
    }
    this.game.startTimer();
    this.isPlaying = true;
    this.isPaused = false;
    this.gameLoop();
  }

  stopGame() {
    this.isPlaying = false;
    this.isPaused = false;
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  pauseGame() {
    this.isPaused = true;
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  resumeGame() {
    this.isPaused = false;
    this.gameLoop();
  }

  restartGame() {
    this.stopGame();
    this.game.init();
    this.startGame();
  }

  gameLoop() {
    if (!this.isPlaying || this.isPaused) return;

    const success = this.game.update();
    this.updateFlag++;
    this.currentTime = this.game.getFormattedTime();
    this.drawGame();

    if (!success) {
      this.stopGame();
      return;
    }

    this.timerId = setTimeout(() => {
      this.gameLoop();
    }, this.game.getSpeed());
  }

  handleDirection(dir: Direction) {
    this.game.setDirection(dir);
    if (!this.isPlaying && !this.game.isOver()) {
      this.startGame();
    } else if (this.isPaused) {
      this.resumeGame();
    }
  }

  handleCanvasClick(x: number, y: number) {
    if (this.controlMode !== 'click') return;

    const head = this.game.getSnake()[0];
    const headX = head.x * this.cellSize + this.cellSize / 2;
    const headY = head.y * this.cellSize + this.cellSize / 2;

    const direction = this.game.getDirection();

    // 根据当前方向判断左右
    let isRight = false;
    if (direction === Direction.UP) {
      isRight = x > headX;
    } else if (direction === Direction.DOWN) {
      isRight = x < headX;
    } else if (direction === Direction.LEFT) {
      isRight = y < headY;
    } else if (direction === Direction.RIGHT) {
      isRight = y > headY;
    }

    if (isRight) {
      this.game.turnRight();
    } else {
      this.game.turnLeft();
    }

    if (!this.isPlaying && !this.game.isOver()) {
      this.startGame();
    } else if (this.isPaused) {
      this.resumeGame();
    }
  }

  getSpeedColor(): string {
    const ratio = this.game.getCurrentSpeedRatio();
    if (ratio >= 1.5) return '#FF5722'; // 很快 - 红色
    if (ratio >= 1.2) return '#FF9800'; // 快 - 橙色
    if (ratio >= 0.8) return '#4CAF50'; // 正常 - 绿色
    return '#2196F3'; // 慢 - 蓝色
  }

  @Builder
  MenuDialog() {
    Column() {
      Text('菜单')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 控制方式按钮
      Button('控制方式')
        .width('100%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#9C27B0')
        .margin({ bottom: 15 })
        .onClick(() => {
          this.showMenuDialog = false;
          this.showControlDialog = true;
        })

      // 设置按钮
      if (this.gameMode === 'casual') {
        Button('设置')
          .width('100%')
          .height(50)
          .fontSize(18)
          .backgroundColor('#2196F3')
          .margin({ bottom: 15 })
          .onClick(() => {
            this.showMenuDialog = false;
            this.stopGame();
            router.pushUrl({
              url: 'pages/SettingsPage'
            });
          })
      }

      // 取消按钮
      Button('取消')
        .width('100%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#666666')
        .onClick(() => {
          this.showMenuDialog = false;
        })
    }
    .width(this.dialogSize)
    .height(this.dialogSize)
    .padding(25)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 当区域改变时，确保保持正方形
      const width = newValue.width as number;
      this.dialogSize = Math.min(width, 400);
    })
  }

  @Builder
  ControlDialog() {
    Column() {
      Text('选择控制方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 30 })

      // 按键控制
      Column() {
        Row() {
          Radio({ value: 'button', group: 'controlGroup' })
            .checked(this.controlMode === 'button')
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.controlMode = 'button';
              }
            })

          Column() {
            Text('按键控制')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 5 })

            Text('使用屏幕下方的方向按钮控制蛇的移动方向')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(15)
        .backgroundColor(this.controlMode === 'button' ? '#E3F2FD' : '#F5F5F5')
        .borderRadius(8)
        .onClick(() => this.controlMode = 'button')
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 点击控制
      Column() {
        Row() {
          Radio({ value: 'click', group: 'controlGroup' })
            .checked(this.controlMode === 'click')
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.controlMode = 'click';
              }
            })

          Column() {
            Text('点击控制')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 5 })

            Text('点击游戏区域：蛇右侧右转，蛇左侧左转')
              .fontSize(14)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(15)
        .backgroundColor(this.controlMode === 'click' ? '#E3F2FD' : '#F5F5F5')
        .borderRadius(8)
        .onClick(() => this.controlMode = 'click')
      }
      .width('100%')
      .margin({ bottom: 30 })

      Button('确定')
        .width('100%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#2196F3')
        .onClick(() => {
          this.showControlDialog = false;
        })
    }
    .width(this.dialogSize)
    .height(this.dialogSize)
    .padding(25)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 当区域改变时，确保保持正方形
      const width = newValue.width as number;
      this.dialogSize = Math.min(width, 400);
    })
  }

  build() {
    Stack() {
      Column() {
        // 顶部信息栏
        Column() {
          Row() {
            Button('返回')
              .fontSize(16)
              .backgroundColor('#666666')
              .onClick(() => {
                this.stopGame();
                router.back();
              })

            Row() {
              Text(`${this.gameMode === 'casual' ? '休闲模式' : '挑战模式'}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)

            Row() {
              Column() {
                Text(`得分: ${this.game.getScore()}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                
                Text(`速度: ${this.game.getCurrentSpeedRatio().toFixed(1)}x`)
                  .fontSize(14)
                  .fontColor(this.getSpeedColor())
              }
              .alignItems(HorizontalAlign.End)
              .margin({ right: 10 })

              Button('⋮')
                .fontSize(24)
                .width(40)
                .height(40)
                .backgroundColor('#E0E0E0')
                .onClick(() => {
                  this.showMenuDialog = true;
                })
            }
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 20, right: 20 })

          // 第二行：时间、速度和控制按钮
          Row() {
            Column() {
              Text(`时间: ${this.currentTime}`)
                .fontSize(16)
                .fontColor('#666666')
              
              Text(`速度: ${this.game.getSpeed()}ms`)
                .fontSize(14)
                .fontColor('#999999')
            }
            .alignItems(HorizontalAlign.Start)

            if (this.gameMode === 'casual') {
              Row() {
                if (!this.isPlaying || this.game.isOver()) {
                  Button('开始')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor('#4CAF50')
                    .onClick(() => this.startGame())
                } else if (this.isPaused) {
                  Button('继续')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor('#4CAF50')
                    .onClick(() => this.resumeGame())
                } else {
                  Button('暂停')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor('#FF9800')
                    .onClick(() => this.pauseGame())
                }

                Button('重开')
                  .fontSize(14)
                  .height(32)
                  .backgroundColor('#2196F3')
                  .margin({ left: 10 })
                  .onClick(() => this.restartGame())
              }
            }
          }
          .width('100%')
          .height(40)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')

        // 游戏区域
        Column() {
          Canvas(this.canvasContext)
            .width(this.game.getGridSize() * this.cellSize)
            .height(this.game.getGridSize() * this.cellSize)
            .backgroundColor('#000000')
            .onReady(() => {
              this.loadFruitImage();
              this.drawGame();
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.handleCanvasClick(event.touches[0].x, event.touches[0].y);
              }
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#222222')

        // 游戏结束提示
        if (this.game.isOver()) {
          Column() {
            Text('游戏结束!')
              .fontSize(36)
              .fontColor('#FF0000')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Text(`得分: ${this.game.getScore()}`)
              .fontSize(24)
              .fontColor('#333333')
              .margin({ bottom: 10 })

            Text(`存活时间: ${this.currentTime}`)
              .fontSize(20)
              .fontColor('#666666')
              .margin({ bottom: 30 })

            Button('重新开始')
              .fontSize(20)
              .width(160)
              .height(50)
              .backgroundColor('#4CAF50')
              .onClick(() => {
                this.restartGame();
              })
          }
          .width(300)
          .padding(30)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 20, color: '#00000030' })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%', y: '-50%' })
        }

        // 暂停提示
        if (this.isPaused && !this.game.isOver()) {
          Column() {
            Text('游戏已暂停')
              .fontSize(32)
              .fontColor('#FF9800')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })

            Text('点击"继续"或方向键恢复游戏')
              .fontSize(16)
              .fontColor('#666666')
          }
          .width(280)
          .padding(30)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 20, color: '#00000030' })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%', y: '-50%' })
        }

        // 控制按钮（仅在按键模式显示）
        if (this.controlMode === 'button') {
          Column() {
            Row() {
              Button('↑')
                .width(80)
                .height(80)
                .fontSize(32)
                .backgroundColor('#2196F3')
                .opacity(0.4)
                .onClick(() => this.handleDirection(Direction.UP))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: 10 })

            Row() {
              Button('←')
                .width(80)
                .height(80)
                .fontSize(32)
                .backgroundColor('#2196F3')
                .opacity(0.4)
                .margin({ right: 10 })
                .onClick(() => this.handleDirection(Direction.LEFT))

              Button('↓')
                .width(80)
                .height(80)
                .fontSize(32)
                .backgroundColor('#2196F3')
                .opacity(0.4)
                .margin({ right: 10 })
                .onClick(() => this.handleDirection(Direction.DOWN))

              Button('→')
                .width(80)
                .height(80)
                .fontSize(32)
                .backgroundColor('#2196F3')
                .opacity(0.4)
                .onClick(() => this.handleDirection(Direction.RIGHT))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({ top: 20, bottom: 40 })
          .backgroundColor(Color.Transparent)
        }
      }
      .width('100%')
      .height('100%')

      // 菜单弹窗
      if (this.showMenuDialog) {
        Column() {
          this.MenuDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showMenuDialog = false;
        })
        .onAreaChange((oldValue: Area, newValue: Area) => {
          // 根据屏幕宽度调整弹窗大小
          const screenWidth = newValue.width as number;
          this.dialogSize = Math.min(screenWidth * 0.8, 400);
        })
      }

      // 控制方式选择弹窗
      if (this.showControlDialog) {
        Column() {
          this.ControlDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showControlDialog = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private drawGame() {
    const ctx = this.canvasContext;
    const gridSize = this.game.getGridSize();

    // 清空画布
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, gridSize * this.cellSize, gridSize * this.cellSize);

    // 绘制网格线
    ctx.strokeStyle = '#333333';
    ctx.lineWidth = 1;
    for (let i = 0; i <= gridSize; i++) {
      ctx.beginPath();
      ctx.moveTo(i * this.cellSize, 0);
      ctx.lineTo(i * this.cellSize, gridSize * this.cellSize);
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(0, i * this.cellSize);
      ctx.lineTo(gridSize * this.cellSize, i * this.cellSize);
      ctx.stroke();
    }

    // 绘制蛇
    const snake = this.game.getSnake();
    snake.forEach((segment, index) => {
      ctx.fillStyle = index === 0 ? '#00FF00' : '#00CC00';
      ctx.fillRect(
        segment.x * this.cellSize + 1,
        segment.y * this.cellSize + 1,
        this.cellSize - 2,
        this.cellSize - 2
      );
    });

    // 绘制食物
    const foods = this.game.getFoods();
    
    foods.forEach(food => {
      const foodImage = this.foodImages.get(food.type);
      
      if (foodImage) {
        try {
          ctx.drawImage(
            foodImage,
            food.position.x * this.cellSize,
            food.position.y * this.cellSize,
            this.cellSize,
            this.cellSize
          );
        } catch (err) {
          console.error('Failed to draw food image:', err);
          // 绘制失败时使用红色方块
          ctx.fillStyle = '#FF0000';
          ctx.fillRect(
            food.position.x * this.cellSize + 1,
            food.position.y * this.cellSize + 1,
            this.cellSize - 2,
            this.cellSize - 2
          );
        }
      } else {
        // 图片未加载时使用红色方块
        ctx.fillStyle = '#FF0000';
        ctx.fillRect(
          food.position.x * this.cellSize + 1,
          food.position.y * this.cellSize + 1,
          this.cellSize - 2,
          this.cellSize - 2
        );
      }
    });
  }
}
