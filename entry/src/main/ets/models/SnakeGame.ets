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
  private speedMultiplier: number = 1.0; // 速度倍数（由食物效果累积）
  private startTime: number = 0;
  private survivalTime: number = 0;
  private lastFoodSpawnTime: number = 0;
  private readonly FOOD_SPAWN_INTERVAL: number = 4000; // 4秒
  private readonly FOOD_LIFETIME: number = 10000; // 10秒

  constructor(speed: number = 200, gridWidth: number = 22, gridHeight: number = 15) {
    this.speed = speed;
    this.baseSpeed = speed;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
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
    this.spawnFood();
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
    // 返回当前速度相对于初始速度的比率
    // 速度越快，比率越大（因为时间间隔越小）
    const speedLevel = Math.floor(this.score / 50);
    const scoreSpeedMultiplier = Math.pow(0.9, speedLevel);
    // 实际速度比率 = 1 / (scoreSpeedMultiplier * speedMultiplier)
    return 1.0 / (scoreSpeedMultiplier * this.speedMultiplier);
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
    if (random < 40) {
      return FoodType.FRUIT; // 40%
    } else if (random < 55) {
      return FoodType.LEMON; // 15%
    } else if (random < 70) {
      return FoodType.FLOWER; // 15%
    } else if (random < 85) {
      return FoodType.ORANGE; // 15%
    } else if (random < 90) {
      return FoodType.WATERMELON; // 5%
    } else {
      return FoodType.MUSHROOM; // 10%
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
        return -10;
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
    switch (type) {
      case FoodType.LEMON:
        return 1.1; // 减速10%（时间增加10%）
      case FoodType.FLOWER:
        return 0.9; // 加速10%（时间减少10%）
      default:
        return 1.0; // 无影响
    }
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
      this.isGameOver = true;
      return false;
    }

    // 检查撞到自己
    if (this.isPositionOnSnake(newHead)) {
      this.isGameOver = true;
      return false;
    }

    this.snake.unshift(newHead);

    // 检查是否吃到任何食物
    let ateFood = false;
    for (let i = this.foods.length - 1; i >= 0; i--) {
      if (newHead.x === this.foods[i].position.x && newHead.y === this.foods[i].position.y) {
        const foodType = this.foods[i].type;
        const scoreChange = this.getFoodScore(foodType);
        const speedEffect = this.getFoodSpeedEffect(foodType);
        
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
