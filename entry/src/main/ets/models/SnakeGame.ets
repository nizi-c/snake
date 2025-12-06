export enum Direction {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

export interface Position {
  x: number;
  y: number;
}

export enum FoodType {
  FRUIT,
  ORANGE,
  WATERMELON,
  MUSHROOM,
  LEMON,
  FLOWER
}

interface FoodItem {
  position: Position;
  createTime: number;
  type: FoodType;
}

export class SnakeGame {
  private gridWidth: number = 22;
  private gridHeight: number = 15;
  private snake: Position[] = [];
  private foods: FoodItem[] = [];
  private direction: Direction = Direction.RIGHT;
  private nextDirection: Direction = Direction.RIGHT;
  private score: number = 0;
  private isGameOver: boolean = false;
  private speed: number = 200;
  private baseSpeed: number = 200;
  private originalSpeed: number = 200; // 保存原始设定速度（用于计算速度比率）
  private speedMultiplier: number = 1.0; // 速度倍数（由食物效果累积）
  // 挑战模式相关
  private isChallengeMode: boolean = false;
  private lives: number = 3; // 生命数
  private timeLimit: number = 180; // 时间限制（秒）
  private remainingTime: number = 180; // 剩余时间
  private targetScore: number = 0; // 目标分数
  private challengeStartTime: number = 0; // 挑战开始时间
  private startTime: number = 0;
  private survivalTime: number = 0;
  private lastFoodSpawnTime: number = 0;
  private readonly FOOD_SPAWN_INTERVAL: number = 2000; // 2秒
  private readonly FOOD_LIFETIME: number = 10000; // 10秒
  private character: string = 'xiaomao.jpg'; // 当前角色
  private mushroomImmunity: number = 0; // 蘑菇免疫次数

  constructor(speed: number = 200, gridWidth: number = 28, gridHeight: number = 18, character: string = 'xiaomao.jpg', 
              isChallengeMode: boolean = false, timeLimit: number = 180, targetScore: number = 0) {
    this.speed = speed;
    this.baseSpeed = speed;
    this.originalSpeed = speed; // 保存原始速度
    this.gridWidth = gridWidth;
    this.isChallengeMode = isChallengeMode;
    this.timeLimit = timeLimit;
    this.remainingTime = timeLimit;
    this.targetScore = targetScore;
    this.gridHeight = gridHeight;
    this.character = character;
    this.init();
  }

  init() {
    const centerX = Math.floor(this.gridWidth / 2);
    const centerY = Math.floor(this.gridHeight / 2);
    this.snake = [
      { x: centerX, y: centerY },
      { x: centerX - 1, y: centerY },
      { x: centerX - 2, y: centerY }
    ];
    this.direction = Direction.RIGHT;
    this.nextDirection = Direction.RIGHT;
    this.score = 0;
    this.isGameOver = false;
    this.startTime = Date.now();
    this.survivalTime = 0;
    this.foods = [];
    this.lastFoodSpawnTime = Date.now();
    this.speedMultiplier = 1.0; // 重置速度倍数
    
    // 挑战模式初始化
    if (this.isChallengeMode) {
      this.lives = 3;
      this.remainingTime = this.timeLimit;
      this.challengeStartTime = Date.now();
    }
    
    this.initCharacterAbility(); // 初始化角色能力
    this.spawnFood();
  }

  // 处理死亡
  private handleDeath(): boolean {
    if (this.isChallengeMode && this.lives > 1) {
      // 挑战模式且还有生命：扣除生命并复活
      this.lives--;
      this.revive();
      return true; // 继续游戏
    } else {
      // 休闲模式或生命耗尽：游戏结束
      this.isGameOver = true;
      return false;
    }
  }

  // 挑战模式：死亡后复活
  private revive() {
    const centerX = Math.floor(this.gridWidth / 2);
    const centerY = Math.floor(this.gridHeight / 2);
    this.snake = [
      { x: centerX, y: centerY },
      { x: centerX - 1, y: centerY },
      { x: centerX - 2, y: centerY }
    ];
    this.direction = Direction.RIGHT;
    this.nextDirection = Direction.RIGHT;
    this.foods = [];
    this.lastFoodSpawnTime = Date.now();
    this.spawnFood();
  }

  private initCharacterAbility() {
    // 根据角色初始化特殊能力
    switch (this.character) {
      case 'xiaomao.jpg':
      case 'xiaom.jpg': // 兼容拼写错误
      case 'cat.png': // 兼容旧数据
        this.mushroomImmunity = 3; // 小猫：免疫3次蘑菇扣分
        break;
      case 'xiaogou.jpg':
      case 'dog.png': // 兼容旧数据
        // 小狗：基础速度加快10%（时间减少10%）
        this.baseSpeed = Math.floor(this.baseSpeed * 0.9);
        this.speed = this.baseSpeed;
        break;
      case 'tuzi.jpg':
      case 'rabbit.png': // 兼容旧数据
        // 兔子：速度变化效果翻倍，分数效果+50%
        // 特性在吃食物时应用
        break;
      case 'cangshu.png':
        // 仓鼠：初始100分，速度减慢10%
        this.score = 100;
        this.baseSpeed = Math.floor(this.baseSpeed * 1.1);
        this.speed = this.baseSpeed;
        break;
      default:
        this.mushroomImmunity = 0;
    }
  }

  getMushroomImmunity(): number {
    return this.mushroomImmunity;
  }

  getCharacter(): string {
    return this.character;
  }

  // 挑战模式相关方法
  isChallengeGameMode(): boolean {
    return this.isChallengeMode;
  }

  getLives(): number {
    return this.lives;
  }

  getRemainingTime(): number {
    return this.remainingTime;
  }

  getTimeLimit(): number {
    return this.timeLimit;
  }

  getTargetScore(): number {
    return this.targetScore;
  }

  getFormattedRemainingTime(): string {
    const minutes = Math.floor(this.remainingTime / 60);
    const seconds = this.remainingTime % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  startTimer() {
    this.startTime = Date.now();
  }

  updateSurvivalTime() {
    if (!this.isGameOver && this.startTime > 0) {
      this.survivalTime = Math.floor((Date.now() - this.startTime) / 1000);
    }
  }

  getSurvivalTime(): number {
    return this.survivalTime;
  }

  getFormattedTime(): string {
    const minutes = Math.floor(this.survivalTime / 60);
    const seconds = this.survivalTime % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  getGridWidth(): number {
    return this.gridWidth;
  }

  getGridHeight(): number {
    return this.gridHeight;
  }

  getSnake(): Position[] {
    return this.snake;
  }

  getFoods(): FoodItem[] {
    return this.foods;
  }

  getScore(): number {
    return this.score;
  }

  getSpeed(): number {
    // 根据分数计算当前速度
    // 每50分速度加快10%（时间间隔减少10%）
    const speedLevel = Math.floor(this.score / 50);
    const scoreSpeedMultiplier = Math.pow(0.9, speedLevel); // 每级速度提升10%
    
    // 综合分数加速和食物效果
    const currentSpeed = Math.max(this.baseSpeed * scoreSpeedMultiplier * this.speedMultiplier, 50); // 最快不超过50ms
    return Math.floor(currentSpeed);
  }

  getBaseSpeed(): number {
    return this.baseSpeed;
  }

  setBaseSpeed(speed: number) {
    this.baseSpeed = speed;
  }

  getSpeedMultiplier(): number {
    return this.speedMultiplier;
  }

  getCurrentSpeedRatio(): number {
    // 返回当前速度相对于原始设定速度的比率
    // 速度越快，比率越大（因为时间间隔越小）
    const currentSpeed = this.getSpeed();
    // 速度比率 = 原始速度 / 当前速度
    // 注意：速度值越小表示越快（时间间隔短），所以比率计算是原始/当前
    return this.originalSpeed / currentSpeed;
  }

  isOver(): boolean {
    return this.isGameOver;
  }

  setDirection(dir: Direction) {
    // 防止180度反向
    if (this.direction === Direction.UP && dir === Direction.DOWN) return;
    if (this.direction === Direction.DOWN && dir === Direction.UP) return;
    if (this.direction === Direction.LEFT && dir === Direction.RIGHT) return;
    if (this.direction === Direction.RIGHT && dir === Direction.LEFT) return;
    this.nextDirection = dir;
  }

  turnLeft() {
    switch (this.direction) {
      case Direction.UP:
        this.nextDirection = Direction.LEFT;
        break;
      case Direction.LEFT:
        this.nextDirection = Direction.DOWN;
        break;
      case Direction.DOWN:
        this.nextDirection = Direction.RIGHT;
        break;
      case Direction.RIGHT:
        this.nextDirection = Direction.UP;
        break;
    }
  }

  turnRight() {
    switch (this.direction) {
      case Direction.UP:
        this.nextDirection = Direction.RIGHT;
        break;
      case Direction.RIGHT:
        this.nextDirection = Direction.DOWN;
        break;
      case Direction.DOWN:
        this.nextDirection = Direction.LEFT;
        break;
      case Direction.LEFT:
        this.nextDirection = Direction.UP;
        break;
    }
  }

  getDirection(): Direction {
    return this.direction;
  }

  private spawnFood() {
    let newFood: Position;
    do {
      newFood = {
        x: Math.floor(Math.random() * this.gridWidth),
        y: Math.floor(Math.random() * this.gridHeight)
      };
    } while (this.isPositionOccupied(newFood));
    
    // 根据概率选择食物类型
    // FRUIT: 70%, ORANGE: 15%, WATERMELON: 5%, MUSHROOM: 10%
    const randomType = this.getRandomFoodType();
    
    this.foods.push({
      position: newFood,
      createTime: Date.now(),
      type: randomType
    });
  }

  private getRandomFoodType(): FoodType {
    const random = Math.random() * 100;
    if (random < 30) {
      return FoodType.FRUIT; // 30%
    } else if (random < 45) {
      return FoodType.LEMON; // 15%
    } else if (random < 60) {
      return FoodType.FLOWER; // 15%
    } else if (random < 70) {
      return FoodType.ORANGE; // 10%
    } else if (random < 75) {
      return FoodType.WATERMELON; // 5%
    } else {
      return FoodType.MUSHROOM; // 25%
    }
  }

  private getFoodScore(type: FoodType): number {
    switch (type) {
      case FoodType.FRUIT:
        return 10;
      case FoodType.ORANGE:
        return 20;
      case FoodType.WATERMELON:
        return 30;
      case FoodType.MUSHROOM:
        return -20;
      case FoodType.LEMON:
        return 0;
      case FoodType.FLOWER:
        return 0;
      default:
        return 10;
    }
  }

  private getFoodSpeedEffect(type: FoodType): number {
    // 返回速度倍数变化
    let speedEffect = 1.0;
    switch (type) {
      case FoodType.LEMON:
        speedEffect = 1.1; // 减速10%（时间增加10%）
        break;
      case FoodType.FLOWER:
        speedEffect = 0.9; // 加速10%（时间减少10%）
        break;
      default:
        speedEffect = 1.0; // 无影响
    }
    
    // 兔子特性：速度变化效果翻倍
    if ((this.character === 'tuzi.jpg' || this.character === 'rabbit.png') && speedEffect !== 1.0) {
      if (speedEffect > 1.0) {
        // 减速效果翻倍：1.1 → 1.2
        speedEffect = 1.0 + (speedEffect - 1.0) * 2;
      } else {
        // 加速效果翻倍：0.9 → 0.8
        speedEffect = 1.0 - (1.0 - speedEffect) * 2;
      }
      console.info(`Rabbit speed effect doubled to ${speedEffect}`);
    }
    
    return speedEffect;
  }

  private isPositionOnSnake(pos: Position): boolean {
    return this.snake.some(segment => segment.x === pos.x && segment.y === pos.y);
  }

  private isPositionOccupied(pos: Position): boolean {
    // 检查是否在蛇身上或已有食物位置
    if (this.isPositionOnSnake(pos)) return true;
    return this.foods.some(f => f.position.x === pos.x && f.position.y === pos.y);
  }

  private updateFoods() {
    const currentTime = Date.now();
    
    // 移除超过10秒的食物
    this.foods = this.foods.filter(f => currentTime - f.createTime < this.FOOD_LIFETIME);
    
    // 确保至少有一个食物
    if (this.foods.length === 0) {
      this.spawnFood();
      this.lastFoodSpawnTime = currentTime;
      return;
    }
    
    // 每4秒生成新食物
    if (currentTime - this.lastFoodSpawnTime >= this.FOOD_SPAWN_INTERVAL) {
      this.spawnFood();
      this.lastFoodSpawnTime = currentTime;
    }
  }

  update(): boolean {
    if (this.isGameOver) return false;

    this.updateSurvivalTime();
    
    // 挑战模式：更新倒计时
    if (this.isChallengeMode) {
      const elapsed = Math.floor((Date.now() - this.challengeStartTime) / 1000);
      this.remainingTime = Math.max(0, this.timeLimit - elapsed);
      
      // 时间耗尽，游戏结束
      if (this.remainingTime <= 0) {
        this.isGameOver = true;
        return false;
      }
    }
    
    this.updateFoods();
    this.direction = this.nextDirection;

    const head = this.snake[0];
    let newHead: Position = { x: head.x, y: head.y };

    switch (this.direction) {
      case Direction.UP:
        newHead.y -= 1;
        break;
      case Direction.DOWN:
        newHead.y += 1;
        break;
      case Direction.LEFT:
        newHead.x -= 1;
        break;
      case Direction.RIGHT:
        newHead.x += 1;
        break;
    }

    // 检查撞墙
    if (newHead.x < 0 || newHead.x >= this.gridWidth ||
      newHead.y < 0 || newHead.y >= this.gridHeight) {
      return this.handleDeath();
    }

    // 检查撞到自己
    if (this.isPositionOnSnake(newHead)) {
      return this.handleDeath();
    }

    this.snake.unshift(newHead);

    // 检查是否吃到任何食物
    let ateFood = false;
    for (let i = this.foods.length - 1; i >= 0; i--) {
      if (newHead.x === this.foods[i].position.x && newHead.y === this.foods[i].position.y) {
        const foodType = this.foods[i].type;
        let scoreChange = this.getFoodScore(foodType);
        const speedEffect = this.getFoodSpeedEffect(foodType);
        
        // 小猫特性：免疫蘑菇扣分
        if (foodType === FoodType.MUSHROOM && scoreChange < 0 && this.mushroomImmunity > 0) {
          this.mushroomImmunity--;
          scoreChange = 0; // 免疫扣分
          console.info(`Cat immunity activated! Remaining: ${this.mushroomImmunity}`);
        }
        
        // 小狗特性：食物加分减分效果翻倍
        if ((this.character === 'xiaogou.jpg' || this.character === 'dog.png') && scoreChange !== 0) {
          scoreChange *= 2;
          console.info(`Dog bonus: score doubled to ${scoreChange}`);
        }
        
        // 仓鼠特性：减分+200%
        if (this.character === 'cangshu.png' && scoreChange < 0) {
          scoreChange = Math.floor(scoreChange * 3); // 减分增加200%（变为3倍）
          console.info(`Hamster penalty: negative score increased to ${scoreChange}`);
        }
        
        // 兔子特性：分数效果+50%
        if ((this.character === 'tuzi.jpg' || this.character === 'rabbit.png') && scoreChange !== 0) {
          scoreChange = Math.floor(scoreChange * 1.5);
          console.info(`Rabbit bonus: score effect increased to ${scoreChange}`);
        }
        
        this.score += scoreChange;
        // 确保分数不为负
        if (this.score < 0) {
          this.score = 0;
        }
        
        // 应用速度效果
        this.speedMultiplier *= speedEffect;
        // 限制速度倍数范围（0.5到2.0之间）
        this.speedMultiplier = Math.max(0.5, Math.min(2.0, this.speedMultiplier));
        
        this.foods.splice(i, 1);
        ateFood = true;
        console.info(`Ate ${FoodType[foodType]}, score: ${scoreChange}, speed effect: ${speedEffect}, multiplier: ${this.speedMultiplier.toFixed(2)}`);
        break;
      }
    }

    if (!ateFood) {
      this.snake.pop();
    }

    return true;
  }
}
