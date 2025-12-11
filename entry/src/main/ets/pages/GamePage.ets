import router from '@ohos.router';
import { SnakeGame, Direction, Position, FoodType } from '../models/SnakeGame';
import image from '@ohos.multimedia.image';
import preferences from '@ohos.data.preferences';
import { ThemeManager, LightTheme, Theme } from '../models/ThemeManager';
import { MusicManager } from '../models/MusicManager';
import { AchievementManager } from '../models/AchievementManager';

interface FoodImageConfig {
  type: FoodType;
  file: string;
}

interface GameRecord {
  score: number;
  time: string;
  character: string;
  mode: string;
  timestamp: number;
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
  @State controlMode: string = 'click'; // 'button' 或 'click'，默认为点击控制
  @State showControlDialog: boolean = false;
  @State showMenuDialog: boolean = false;
  @State showCharacterDialog: boolean = false;
  @State showChallengeSuccessDialog: boolean = false;
  @State showRulesDialog: boolean = false;
  @State showUnlockDialog: boolean = false;
  @State unlockedCharacterName: string = '';
  @State showAchievementDialog: boolean = false;
  @State unlockedAchievementName: string = '';
  @State dialogSize: number = 300;
  @State currentCharacter: string = 'cat'; // 当前角色：cat, dog, rabbit, hamster
  @State currentTheme: Theme = LightTheme;
  @State bgImagePath: string = '';
  @State isMusicPlaying: boolean = false;
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private musicManager: MusicManager = MusicManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();
  private hasShownSuccessDialog: boolean = false; // 标记是否已显示成功弹窗
  private totalFoodsCollected: number = 0; // 累计收集的食物数
  private timerId: number = -1;
  private cellSize: number = 30;
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private foodImages: Map<FoodType, image.PixelMap> = new Map();
  private cartImage: image.PixelMap | null = null;
  private catImage: image.PixelMap | null = null;

  async aboutToAppear() {
    await this.themeManager.loadTheme(getContext(this));
    this.currentTheme = this.themeManager.getTheme();
    
    // 设置背景图片
    this.updateBackgroundImage();
    
    // 加载控制方式
    await this.loadControlMode();
    
    // 获取音乐状态
    this.isMusicPlaying = this.musicManager.isPlayingMusic();
    
    // 监听主题变化
    this.themeManager.addListener((theme: Theme) => {
      this.currentTheme = theme;
      this.updateBackgroundImage();
    });
    
    // 监听音乐状态变化
    this.musicManager.addListener((isPlaying: boolean) => {
      this.isMusicPlaying = isPlaying;
    });
    
    // 监听成就解锁
    this.achievementManager.addListener((achievementId: string, name: string) => {
      this.unlockedAchievementName = name;
      this.showAchievementDialog = true;
      
      // 3秒后自动隐藏提示
      setTimeout(() => {
        this.showAchievementDialog = false;
      }, 3000);
    });
    
    await this.loadGameSettings();
  }

  async loadControlMode() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      this.controlMode = await prefs.get('controlMode', 'click') as string;
      console.info('Loaded control mode:', this.controlMode);
    } catch (err) {
      console.error('Failed to load control mode:', err);
    }
  }

  async saveControlMode() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      await prefs.put('controlMode', this.controlMode);
      await prefs.flush();
      console.info('Control mode saved:', this.controlMode);
    } catch (err) {
      console.error('Failed to save control mode:', err);
    }
  }

  toggleMusic() {
    this.musicManager.toggle();
  }

  updateBackgroundImage() {
    // 休闲模式和挑战模式都显示背景图片
    this.bgImagePath = this.currentTheme.name === 'light' ? 'light.png' : 'dark.png';
    console.info(`Game background image path set to: ${this.bgImagePath}`);
  }

  aboutToDisappear() {
    // 清理监听器
    this.themeManager.removeListener((theme: Theme) => {
      this.currentTheme = theme;
    });
    // 停止游戏
    this.stopGame();
  }

  onPageShow() {
    // 页面显示时检查是否需要重新加载
    const params = router.getParams() as Record<string, Object>;
    if (params?.reload) {
      this.loadGameSettings();
    }
  }

  async loadGameSettings() {
    const params = router.getParams() as Record<string, Object>;
    this.gameMode = (params?.mode as string) || 'casual';
    
    // 更新背景图片
    this.updateBackgroundImage();
    
    let baseSpeed = this.gameMode === 'challenge' ? 100 : 200;
    let gridWidth = 22;
    let gridHeight = 15;
    let characterImage = 'xiaomao.jpg';
    
    // 挑战模式参数
    const isChallengeMode = this.gameMode === 'challenge';
    const timeLimit = (params?.timeLimit as number) || 180;
    const targetScore = (params?.targetScore as number) || 0;
    
    // 检查是否从设置页面或角色选择页面返回
    if (params?.reload) {
      if (params?.gridWidth) {
        gridWidth = params.gridWidth as number;
      }
      if (params?.gridHeight) {
        gridHeight = params.gridHeight as number;
      }
      if (params?.baseSpeed) {
        baseSpeed = params.baseSpeed as number;
      }
      if (params?.character) {
        characterImage = params.character as string;
      }
      console.info('Reloading game with new settings - gridWidth:', gridWidth, 'gridHeight:', gridHeight, 'baseSpeed:', baseSpeed, 'character:', characterImage);
      
      // 先加载角色图片，再创建游戏和绘制
      await this.loadCharacterImage(characterImage);
      this.game = new SnakeGame(baseSpeed, gridWidth, gridHeight, characterImage, isChallengeMode, timeLimit, targetScore);
      this.stopGame();
      this.drawGame();
      return;
    }
    
    // 加载设置
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      gridWidth = await prefs.get('gridWidth', 22) as number;
      gridHeight = await prefs.get('gridHeight', 15) as number;
      characterImage = await prefs.get('character', 'xiaomao.jpg') as string;
      
      console.info('Loaded character from preferences:', characterImage);
      
      // 只在休闲模式使用自定义速度，挑战模式固定为100ms
      if (this.gameMode === 'casual') {
        baseSpeed = await prefs.get('baseSpeed', 200) as number;
      }
      
      // 加载角色图片
      await this.loadCharacterImage(characterImage);
      this.game = new SnakeGame(baseSpeed, gridWidth, gridHeight, characterImage, isChallengeMode, timeLimit, targetScore);
      console.info('Game created with character:', characterImage);
    } catch (err) {
      console.error('Failed to load settings:', err);
      await this.loadCharacterImage(characterImage);
      this.game = new SnakeGame(baseSpeed, gridWidth, gridHeight, characterImage, isChallengeMode, timeLimit, targetScore);
    }
  }

  async loadCharacterImage(characterFile: string) {
    try {
      const context = getContext(this);
      const resourceMgr = context.resourceManager;
      const catData = await resourceMgr.getRawFileContent(characterFile);
      const catSource = image.createImageSource(catData.buffer);
      this.catImage = await catSource.createPixelMap();
      console.info(`${characterFile} loaded successfully`);
    } catch (err) {
      console.error(`Failed to load ${characterFile}:`, JSON.stringify(err));
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
      
      // 加载蛇身图片
      try {
        const cartData = await resourceMgr.getRawFileContent('cart.png');
        const cartSource = image.createImageSource(cartData.buffer);
        this.cartImage = await cartSource.createPixelMap();
        console.info('cart.png loaded successfully');
      } catch (err) {
        console.error('Failed to load cart.png:', JSON.stringify(err));
      }
      
      // 加载蛇头图片（根据当前游戏角色）
      const characterFile = this.game.getCharacter();
      try {
        const catData = await resourceMgr.getRawFileContent(characterFile);
        const catSource = image.createImageSource(catData.buffer);
        this.catImage = await catSource.createPixelMap();
        console.info(`${characterFile} loaded successfully in loadFruitImage`);
      } catch (err) {
        console.error(`Failed to load ${characterFile}:`, JSON.stringify(err));
      }
      
      this.drawGame();
    } catch (err) {
      console.error('Failed to load images:', JSON.stringify(err));
    }
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

  async saveGameRecord() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      const historyStr = await prefs.get('gameHistory', '[]') as string;
      const history: GameRecord[] = JSON.parse(historyStr) as GameRecord[];

      const record: GameRecord = {
        score: this.game.getScore(),
        time: this.game.getFormattedTime(),
        character: this.game.getCharacter(),
        mode: this.gameMode,
        timestamp: Date.now()
      };

      history.push(record);
      // 只保留最近50条记录
      if (history.length > 50) {
        history.shift();
      }

      await prefs.put('gameHistory', JSON.stringify(history));
      
      // 增加总游戏次数并检查角色解锁
      const totalGames = await prefs.get('totalGames', 0) as number;
      const newTotalGames = totalGames + 1;
      await prefs.put('totalGames', newTotalGames);
      
      // 检查是否解锁新角色
      this.checkCharacterUnlock(totalGames, newTotalGames);
      
      // 检查成就
      await this.checkAchievements(record);
      
      await prefs.flush();
      console.info('Game record saved:', record, 'Total games:', newTotalGames);
    } catch (err) {
      console.error('Failed to save game record:', err);
    }
  }

  async checkAchievements(record: GameRecord) {
    // 初次邂逅：完成第一局游戏
    await this.achievementManager.unlockAchievement('first_game', '初次邂逅');
    
    // 分数狂人：休闲模式单局得分突破5000分
    if (record.mode === 'casual' && record.score >= 5000) {
      await this.achievementManager.unlockAchievement('score_maniac', '分数狂人');
    }
    
    // 生存大师：休闲模式存活超过5分钟
    if (record.mode === 'casual') {
      const survivalSeconds = this.game.getSurvivalTime();
      if (survivalSeconds >= 300) {
        await this.achievementManager.unlockAchievement('survival_master', '生存大师');
      }
    }
    
    // 美食启程：累计收集6个食物
    await this.checkFoodCollectorAchievement();
  }

  async checkFoodCollectorAchievement() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      
      // 获取累计食物数
      const totalFoods = await prefs.get('totalFoodsCollected', 0) as number;
      const currentGameFoods = this.game.getTotalFoodsEaten();
      const newTotal = totalFoods + currentGameFoods;
      
      await prefs.put('totalFoodsCollected', newTotal);
      await prefs.flush();
      
      console.info('Total foods collected:', newTotal);
      
      if (newTotal >= 6) {
        await this.achievementManager.unlockAchievement('food_collector', '美食启程');
      }
    } catch (err) {
      console.error('Failed to check food collector achievement:', err);
    }
  }

  async checkQuickEaterAchievement() {
    // 检查最后吃掉的食物是否在3秒内
    if (this.game.wasLastFoodEatenQuickly()) {
      await this.achievementManager.unlockAchievement('quick_eater', '贪吃鬼');
      console.info('Quick eater achievement unlocked!');
    }
  }

  checkCharacterUnlock(oldGames: number, newGames: number) {
    const unlockMap: Record<number, string> = {
      2: '小狗',
      5: '兔子',
      8: '仓鼠'
    };

    // 检查是否刚好达到解锁条件
    if (unlockMap[newGames]) {
      this.unlockedCharacterName = unlockMap[newGames];
      this.showUnlockDialog = true;
      console.info('Character unlocked:', this.unlockedCharacterName);
      
      // 3秒后自动隐藏提示
      setTimeout(() => {
        this.showUnlockDialog = false;
      }, 3000);
    }
  }

  async saveChallengeRecord() {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      const params = router.getParams() as Record<string, Object>;
      const levelId = (params?.levelId as number) || 1;
      
      // 获取当前关卡的最佳用时
      const recordsStr = await prefs.get('challengeRecords', '{}') as string;
      const records = JSON.parse(recordsStr) as Record<number, number>;
      
      // 计算用时（秒）
      const usedTime = this.game.getTargetScore() > 0 ? 
        (this.game.getTimeLimit() - this.game.getRemainingTime()) : 0;
      
      // 更新最佳用时（如果更快或首次完成）
      if (!records[levelId] || usedTime < records[levelId]) {
        records[levelId] = usedTime;
      }
      
      await prefs.put('challengeRecords', JSON.stringify(records));
      
      // 解锁下一关
      const unlockedLevel = await prefs.get('unlockedLevel', 1) as number;
      if (levelId >= unlockedLevel) {
        await prefs.put('unlockedLevel', levelId + 1);
      }
      
      // 检查挑战模式成就
      await this.checkChallengeAchievements();
      
      await prefs.flush();
      console.info('Challenge record saved - Level:', levelId, 'Time:', usedTime);
    } catch (err) {
      console.error('Failed to save challenge record:', err);
    }
  }

  async checkChallengeAchievements() {
    const remainingTime = this.game.getRemainingTime();
    const lives = this.game.getLives();
    
    // 时间管理大师：剩余超过1分钟完成目标
    if (remainingTime > 60) {
      await this.achievementManager.unlockAchievement('time_master', '时间管理大师');
    }
    
    // 无伤挑战者：不消耗生命通关
    if (lives === 3) {
      await this.achievementManager.unlockAchievement('no_damage', '无伤挑战者');
    }
    
    // 最后一秒：倒计时最后1秒内达成目标通关
    if (remainingTime <= 1) {
      await this.achievementManager.unlockAchievement('last_second', '最后一秒');
    }
    
    // 最佳收集者：连续3次挑战通关且每次剩余生命≥2
    await this.checkBestCollectorAchievement(lives);
  }

  async checkBestCollectorAchievement(lives: number) {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'snake_settings');
      
      if (lives >= 2) {
        const streak = await prefs.get('challengeStreak', 0) as number;
        const newStreak = streak + 1;
        await prefs.put('challengeStreak', newStreak);
        
        if (newStreak >= 3) {
          await this.achievementManager.unlockAchievement('best_collector', '最佳收集者');
        }
      } else {
        await prefs.put('challengeStreak', 0);
      }
      
      await prefs.flush();
    } catch (err) {
      console.error('Failed to check best collector achievement:', err);
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
    this.hasShownSuccessDialog = false;
    this.showChallengeSuccessDialog = false;
    this.game.init();
    this.startGame();
  }

  gameLoop() {
    if (!this.isPlaying || this.isPaused) return;

    const oldFoodCount = this.game.getTotalFoodsEaten();
    const success = this.game.update();
    const newFoodCount = this.game.getTotalFoodsEaten();
    
    // 检查是否吃到了食物（贪吃鬼成就）
    if (newFoodCount > oldFoodCount) {
      this.checkQuickEaterAchievement();
    }
    
    this.updateFlag++;
    this.currentTime = this.game.getFormattedTime();
    this.drawGame();

    // 挑战模式：检查是否达到目标分数
    if (this.game.isChallengeGameMode() && !this.hasShownSuccessDialog && 
        this.game.getScore() >= this.game.getTargetScore()) {
      this.hasShownSuccessDialog = true;
      this.showChallengeSuccessDialog = true;
      this.stopGame();
      
      // 保存挑战记录
      this.saveChallengeRecord();
      return;
    }

    if (!success) {
      this.stopGame();
      // 游戏结束时保存记录
      this.saveGameRecord();
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

  getTransparentBg(color: string, opacity: number): string {
    // 将十六进制颜色转换为rgba格式
    const hex = color.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }

  @Builder
  MenuDialog() {
    Column() {
      Text('菜单')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.primaryText)
        .margin({ bottom: 20 })

      // 角色选择按钮
      Button('角色选择')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.accentColor)
        .margin({ bottom: 15 })
        .onClick(() => {
          this.showMenuDialog = false;
          this.stopGame();
          router.pushUrl({
            url: 'pages/CharacterSelectPage'
          });
        })

      // 控制方式按钮
      Button('控制方式')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.name === 'dark' ? '#D4AF37' : this.currentTheme.buttonPrimary)
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
          .fontColor('#FFFFFF')
          .backgroundColor(this.currentTheme.successColor)
          .margin({ bottom: 15 })
          .onClick(() => {
            this.showMenuDialog = false;
            this.stopGame();
            router.pushUrl({
              url: 'pages/SettingsPage'
            });
          })
      }

      // 规则介绍按钮
      Button('规则介绍')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.buttonPrimary)
        .margin({ bottom: 15 })
        .onClick(() => {
          this.showMenuDialog = false;
          this.showRulesDialog = true;
        })

      // 历史记录按钮
      Button('历史记录')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.warningColor)
        .margin({ bottom: 15 })
        .onClick(() => {
          this.showMenuDialog = false;
          this.stopGame();
          router.pushUrl({
            url: 'pages/HistoryPage'
          });
        })

      // 取消按钮
      Button('取消')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.buttonSecondary)
        .onClick(() => {
          this.showMenuDialog = false;
        })
    }
    .width('60%')
    .padding(25)
    .backgroundColor(this.currentTheme.secondaryBg)
    .borderRadius(16)
    .shadow({ radius: 10, color: this.currentTheme.shadowColor })
  }

  @Builder
  ControlDialog() {
    Column() {
      Text('选择控制方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.primaryText)
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

            Text('使用屏幕下方的方向按钮控制小动物的移动方向')
              .fontSize(14)
              .fontColor(this.currentTheme.secondaryText)
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(15)
        .backgroundColor(this.controlMode === 'button' ? this.currentTheme.cardBg : this.currentTheme.borderColor)
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

            Text('点击游戏区域：小动物右侧右转，左侧左转')
              .fontSize(14)
              .fontColor(this.currentTheme.secondaryText)
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10 })
          .layoutWeight(1)
        }
        .width('100%')
        .padding(15)
        .backgroundColor(this.controlMode === 'click' ? this.currentTheme.cardBg : this.currentTheme.borderColor)
        .borderRadius(8)
        .onClick(() => this.controlMode = 'click')
      }
      .width('100%')
      .margin({ bottom: 30 })

      Button('确定')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.buttonPrimary)
        .onClick(() => {
          this.showControlDialog = false;
          this.saveControlMode();
        })
    }
    .width(this.dialogSize)
    .height(this.dialogSize)
    .padding(25)
    .backgroundColor(this.currentTheme.secondaryBg)
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 10, color: this.currentTheme.shadowColor })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 当区域改变时，确保保持正方形
      const width = newValue.width as number;
      this.dialogSize = Math.min(width, 400);
    })
  }

  @Builder
  RulesDialog() {
    Column() {
      Text('休闲模式规则')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.primaryText)
        .margin({ bottom: 20 })

      Scroll() {
        Column() {
          Text('🎮 游戏目标')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)
            .margin({ bottom: 10 })
            .width('100%')

          Text('控制小动物收集食物，获得尽可能高的分数和存活时间。')
            .fontSize(14)
            .fontColor(this.currentTheme.secondaryText)
            .lineHeight(22)
            .margin({ bottom: 15 })

          Text('🍎 食物系统')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)
            .margin({ bottom: 10 })
            .width('100%')

          Text('• 苹果：+10分\n• 橙子：+20分\n• 西瓜：+30分\n• 柠檬：速度-10%\n• 花朵：速度+10%\n• 蘑菇：-20分')
            .fontSize(14)
            .fontColor(this.currentTheme.secondaryText)
            .lineHeight(22)
            .margin({ bottom: 15 })

          Text('🐱 角色特性')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)
            .margin({ bottom: 10 })
            .width('100%')

          Text('• 小猫：免疫3次蘑菇扣分\n• 小狗：速度+10%，分数效果×2\n• 兔子：速度变化×2，分数效果+50%\n• 仓鼠：初始100分，速度-10%，减分+200%')
            .fontSize(14)
            .fontColor(this.currentTheme.secondaryText)
            .lineHeight(22)
            .margin({ bottom: 15 })

          Text('⚡ 速度机制')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentTheme.primaryText)
            .margin({ bottom: 10 })
            .width('100%')

          Text('每获得50分，速度自动提升10%，增加挑战难度。')
            .fontSize(14)
            .fontColor(this.currentTheme.secondaryText)
            .lineHeight(22)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Button('知道了')
        .width('100%')
        .height(50)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.currentTheme.buttonPrimary)
        .margin({ top: 15 })
        .onClick(() => {
          this.showRulesDialog = false;
        })
    }
    .width('85%')
    .height('70%')
    .padding(25)
    .backgroundColor(this.currentTheme.secondaryBg)
    .borderRadius(16)
    .shadow({ radius: 10, color: this.currentTheme.shadowColor })
  }

  build() {
    Stack() {
      // 背景图片（仅休闲模式）- 放在最外层占满整个页面
      if (this.bgImagePath) {
        Image($rawfile(this.bgImagePath))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      Column() {
        // 顶部信息栏
        Column() {
          Row() {
            Button('返回')
              .fontSize(16)
              .backgroundColor(this.currentTheme.buttonSecondary)
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.stopGame();
                router.back();
              })

            Row() {
              Text(`${this.gameMode === 'casual' ? '休闲模式' : '挑战模式'}`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentTheme.primaryText)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)

            Row() {
              Column() {
                if (this.game.isChallengeGameMode()) {
                  // 挑战模式：显示生命和目标分数
                  Row() {
                    Image($rawfile('heart.png'))
                      .width(20)
                      .height(20)
                      .margin({ right: 5 })
                    
                    Text(`× ${this.game.getLives()}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.currentTheme.dangerColor)
                      .margin({ right: 10 })
                    
                    Text(`${this.game.getScore()}/${this.game.getTargetScore()}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.currentTheme.name === 'dark' ? this.currentTheme.accentColor : this.currentTheme.primaryText)
                  }
                  
                  Text(`速度: ${this.game.getCurrentSpeedRatio().toFixed(1)}x`)
                    .fontSize(14)
                    .fontColor(this.getSpeedColor())
                } else {
                  // 休闲模式：显示得分和速度
                  Text(`得分: ${this.game.getScore()}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.currentTheme.name === 'dark' ? this.currentTheme.accentColor : this.currentTheme.primaryText)
                  
                  Text(`速度: ${this.game.getCurrentSpeedRatio().toFixed(1)}x`)
                    .fontSize(14)
                    .fontColor(this.getSpeedColor())
                }
              }
              .alignItems(HorizontalAlign.End)
              .margin({ right: 10 })

              Button('⋮')
                .fontSize(24)
                .width(40)
                .height(40)
                .backgroundColor(this.currentTheme.borderColor)
                .fontColor(this.currentTheme.primaryText)
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
            Row() {
              if (this.game.isChallengeGameMode()) {
                // 挑战模式：显示倒计时
                Text(`⏱️ ${this.game.getFormattedRemainingTime()}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.game.getRemainingTime() <= 30 ? this.currentTheme.dangerColor : 
                            (this.currentTheme.name === 'dark' ? this.currentTheme.accentColor : this.currentTheme.secondaryText))
                
                // 小猫角色显示免疫次数
                if ((this.game.getCharacter() === 'xiaomao.jpg' || this.game.getCharacter() === 'xiaom.jpg' || this.game.getCharacter() === 'cat.png') && this.game.getMushroomImmunity() > 0) {
                  Row() {
                    Text(' | ')
                      .fontSize(16)
                      .fontColor(this.currentTheme.accentColor)
                    
                    Image($rawfile('dunpai.png'))
                      .width(30)
                      .height(30)
                      .margin({ right: 3 })
                    
                    Text(`×${this.game.getMushroomImmunity()}`)
                      .fontSize(16)
                      .fontColor(this.currentTheme.accentColor)
                  }
                }
              } else {
                // 休闲模式：显示存活时间
                Text(`时间: ${this.currentTime}`)
                  .fontSize(16)
                  .fontColor(this.currentTheme.name === 'dark' ? this.currentTheme.accentColor : this.currentTheme.secondaryText)
                
                if ((this.game.getCharacter() === 'xiaomao.jpg' || this.game.getCharacter() === 'xiaom.jpg' || this.game.getCharacter() === 'cat.png') && this.game.getMushroomImmunity() > 0) {
                  Row() {
                    Text(' | ')
                      .fontSize(16)
                      .fontColor(this.currentTheme.accentColor)
                    
                    Image($rawfile('dunpai.png'))
                      .width(30)
                      .height(30)
                      .margin({ right: 3 })
                    
                    Text(`×${this.game.getMushroomImmunity()}`)
                      .fontSize(16)
                      .fontColor(this.currentTheme.accentColor)
                  }
                }
              }
            }

            // 休闲模式和挑战模式都显示控制按钮
            Row() {
              Row() {
                if (!this.isPlaying || this.game.isOver()) {
                  Button('开始')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor(this.currentTheme.successColor)
                    .fontColor('#FFFFFF')
                    .onClick(() => this.startGame())
                } else if (this.isPaused) {
                  Button('继续')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor(this.currentTheme.successColor)
                    .fontColor('#FFFFFF')
                    .onClick(() => this.resumeGame())
                } else {
                  Button('暂停')
                    .fontSize(14)
                    .height(32)
                    .backgroundColor(this.currentTheme.accentColor)
                    .fontColor('#FFFFFF')
                    .onClick(() => this.pauseGame())
                }

                Button('重开')
                  .fontSize(14)
                  .height(32)
                  .backgroundColor(this.currentTheme.buttonPrimary)
                  .fontColor('#FFFFFF')
                  .margin({ left: 10 })
                  .onClick(() => this.restartGame())
              }

              Image($rawfile(this.isMusicPlaying ? 'bofang.png' : 'bofang_n.png'))
                .width(32)
                .height(32)
                .onClick(() => this.toggleMusic())
            }
          }
          .width('100%')
          .height(40)
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .backgroundColor(this.getTransparentBg(this.currentTheme.secondaryBg, 0.6))

        // 游戏区域
        Column() {
          Canvas(this.canvasContext)
            .width(this.game.getGridWidth() * this.cellSize)
            .height(this.game.getGridHeight() * this.cellSize)
            .backgroundColor('rgba(255, 255, 255, 0.3)')
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
        .backgroundColor('rgba(0, 0, 0, 0)')

        // 游戏结束提示
        if (this.game.isOver()) {
          Column() {
            Image($rawfile('success.jpg'))
              .width(200)
              .height(200)
              .margin({ bottom: 20 })

            Text('游戏结束!')
              .fontSize(32)
              .fontColor(this.currentTheme.name === 'dark' ? '#FFFFFF' : this.currentTheme.accentColor)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Text(`得分: ${this.game.getScore()}`)
              .fontSize(20)
              .fontColor(this.currentTheme.primaryText)
              .margin({ bottom: 10 })

            Text(`存活时间: ${this.currentTime}`)
              .fontSize(16)
              .fontColor(this.currentTheme.secondaryText)
              .margin({ bottom: 25 })

            Button('重新开始')
              .fontSize(18)
              .width(160)
              .height(50)
              .fontColor('#FFFFFF')
              .backgroundColor(this.currentTheme.successColor)
              .onClick(() => {
                this.restartGame();
              })
          }
          .width(320)
          .padding(20)
          .backgroundColor(this.currentTheme.secondaryBg)
          .borderRadius(16)
          .shadow({ radius: 20, color: this.currentTheme.shadowColor })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%', y: '-50%' })
        }

        // 暂停提示
        if (this.isPaused && !this.game.isOver()) {
          Column() {
            Image($rawfile('stop.png'))
              .width(200)
              .height(200)
              .margin({ bottom: 20 })

            Text('游戏已暂停')
              .fontSize(32)
              .fontColor(this.currentTheme.name === 'dark' ? '#FFFFFF' : this.currentTheme.accentColor)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Text('点击"继续"或方向键恢复游戏')
              .fontSize(16)
              .fontColor(this.currentTheme.secondaryText)
          }
          .width(320)
          .padding(20)
          .backgroundColor(this.currentTheme.secondaryBg)
          .borderRadius(16)
          .shadow({ radius: 20, color: this.currentTheme.shadowColor })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%', y: '-50%' })
        }

        // 挑战成功提示
        if (this.showChallengeSuccessDialog) {
          Column() {
            Image($rawfile('success3.png'))
              .width(200)
              .height(200)
              .margin({ bottom: 20 })

            Text('挑战成功')
              .fontSize(32)
              .fontColor(this.currentTheme.name === 'dark' ? '#FFFFFF' : this.currentTheme.accentColor)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 15 })

            Text('成功帮助小动物收集食物')
              .fontSize(16)
              .fontColor(this.currentTheme.secondaryText)
              .margin({ bottom: 10 })

            Text('点击返回关卡页面')
              .fontSize(14)
              .fontColor(this.currentTheme.hintText)
          }
          .width(320)
          .padding(20)
          .backgroundColor(this.currentTheme.secondaryBg)
          .borderRadius(16)
          .shadow({ radius: 20, color: this.currentTheme.shadowColor })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%', y: '-50%' })
          .onClick(() => {
            router.back();
          })
        }

        // 角色解锁提示（顶部消息通知）
        if (this.showUnlockDialog) {
          Row() {
            Image($rawfile('star.png'))
              .width(40)
              .height(40)
              .margin({ right: 12 })

            Column() {
              Text('🎉 恭喜解锁新角色')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 4 })

              Text(`${this.unlockedCharacterName}已解锁，快去试试吧！`)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .opacity(0.9)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('90%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FF9800')
          .borderRadius(12)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.3)' })
          .position({ x: '50%', y: 60 })
          .translate({ x: '-50%', y: 0 })
          .animation({
            duration: 300,
            curve: Curve.EaseOut
          })
        }

        // 成就解锁提示（顶部消息通知）
        if (this.showAchievementDialog) {
          Row() {
            Image($rawfile('award.png'))
              .width(40)
              .height(40)
              .margin({ right: 12 })

            Column() {
              Text('🎉 成就解锁')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 4 })

              Text(`恭喜获得「${this.unlockedAchievementName}」成就！`)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .opacity(0.9)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('90%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#4CAF50')
          .borderRadius(12)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.3)' })
          .position({ x: '50%', y: this.showUnlockDialog ? 120 : 60 })
          .translate({ x: '-50%', y: 0 })
          .animation({
            duration: 300,
            curve: Curve.EaseOut
          })
        }

        // 控制按钮（仅在按键模式显示）
        if (this.controlMode === 'button') {
          Column() {
            Row() {
              Button('↑')
                .width(80)
                .height(80)
                .fontSize(32)
                .fontColor(this.currentTheme.primaryText)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .border({ width: 2, color: this.currentTheme.buttonPrimary })
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
                .fontColor(this.currentTheme.primaryText)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .border({ width: 2, color: this.currentTheme.buttonPrimary })
                .margin({ right: 10 })
                .onClick(() => this.handleDirection(Direction.LEFT))

              Button('↓')
                .width(80)
                .height(80)
                .fontSize(32)
                .fontColor(this.currentTheme.primaryText)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .border({ width: 2, color: this.currentTheme.buttonPrimary })
                .margin({ right: 10 })
                .onClick(() => this.handleDirection(Direction.DOWN))

              Button('→')
                .width(80)
                .height(80)
                .fontSize(32)
                .fontColor(this.currentTheme.primaryText)
                .backgroundColor('rgba(0, 0, 0, 0)')
                .border({ width: 2, color: this.currentTheme.buttonPrimary })
                .onClick(() => this.handleDirection(Direction.RIGHT))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({ top: 20, bottom: 40 })
          .backgroundColor('rgba(255, 255, 255, 0.1)')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.bgImagePath ? 'rgba(0, 0, 0, 0)' : this.currentTheme.primaryBg)

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

      // 规则介绍弹窗
      if (this.showRulesDialog) {
        Column() {
          this.RulesDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showRulesDialog = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private drawGame() {
    const ctx = this.canvasContext;
    const gridWidth = this.game.getGridWidth();
    const gridHeight = this.game.getGridHeight();

    // 清空画布 - 使用透明背景
    ctx.clearRect(0, 0, gridWidth * this.cellSize, gridHeight * this.cellSize);

    // 绘制网格线 - 根据主题设置网格线颜色
    ctx.strokeStyle = this.currentTheme.name === 'light' ? '#E0E0E0' : '#333333';
    ctx.lineWidth = 1;
    for (let i = 0; i <= gridWidth; i++) {
      ctx.beginPath();
      ctx.moveTo(i * this.cellSize, 0);
      ctx.lineTo(i * this.cellSize, gridHeight * this.cellSize);
      ctx.stroke();
    }
    for (let i = 0; i <= gridHeight; i++) {
      ctx.beginPath();
      ctx.moveTo(0, i * this.cellSize);
      ctx.lineTo(gridWidth * this.cellSize, i * this.cellSize);
      ctx.stroke();
    }

    // 绘制蛇
    const snake = this.game.getSnake();
    snake.forEach((segment, index) => {
      if (index === 0) {
        // 蛇头使用cat2图片
        if (this.catImage) {
          try {
            ctx.drawImage(
              this.catImage,
              segment.x * this.cellSize,
              segment.y * this.cellSize,
              this.cellSize,
              this.cellSize
            );
          } catch (err) {
            console.error('Failed to draw cat image:', err);
            // 绘制失败时使用绿色方块
            ctx.fillStyle = '#00FF00';
            ctx.fillRect(
              segment.x * this.cellSize + 1,
              segment.y * this.cellSize + 1,
              this.cellSize - 2,
              this.cellSize - 2
            );
          }
        } else {
          // 图片未加载时使用绿色方块
          ctx.fillStyle = '#00FF00';
          ctx.fillRect(
            segment.x * this.cellSize + 1,
            segment.y * this.cellSize + 1,
            this.cellSize - 2,
            this.cellSize - 2
          );
        }
      } else if (this.cartImage) {
        // 蛇身和蛇尾使用cart图片
        try {
          ctx.drawImage(
            this.cartImage,
            segment.x * this.cellSize,
            segment.y * this.cellSize,
            this.cellSize,
            this.cellSize
          );
        } catch (err) {
          console.error('Failed to draw cart image:', err);
          // 绘制失败时使用绿色方块
          ctx.fillStyle = '#00CC00';
          ctx.fillRect(
            segment.x * this.cellSize + 1,
            segment.y * this.cellSize + 1,
            this.cellSize - 2,
            this.cellSize - 2
          );
        }
      } else {
        // 图片未加载时使用绿色方块
        ctx.fillStyle = '#00CC00';
        ctx.fillRect(
          segment.x * this.cellSize + 1,
          segment.y * this.cellSize + 1,
          this.cellSize - 2,
          this.cellSize - 2
        );
      }
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
