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
  MUSHROOM
}

interface FoodItem {
  position: Position;
  createTime: number;
  type: FoodType;
}

export class SnakeGame {
  private gridSize: number = 20;
  private snake: Position[] = [];
  private foods: FoodItem[] = [];
  private direction: Direction = Direction.RIGHT;
  private nextDirection: Direction = Direction.RIGHT;
  private score: number = 0;
  private isGameOver: boolean = false;
  private speed: number = 200;
  private startTime: number = 0;
  private survivalTime: number = 0;
  private lastFoodSpawnTime: number = 0;
  private readonly FOOD_SPAWN_INTERVAL: number = 4000; // 4秒
  private readonly FOOD_LIFETIME: number = 10000; // 10秒

  constructor(speed: number = 200, gridSize: number = 20) {
    this.speed = speed;
    this.gridSize = gridSize;
    this.init();
  }

  init() {
    const centerX = Math.floor(this.gridSize / 2);
    const centerY = Math.floor(this.gridSize / 2);
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

  getGridSize(): number {
    return this.gridSize;
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
    return this.speed;
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
        x: Math.floor(Math.random() * this.gridSize),
        y: Math.floor(Math.random() * this.gridSize)
      };
    } while (this.isPositionOccupied(newFood));
    
    // 随机选择食物类型
    const foodTypes = [FoodType.FRUIT, FoodType.ORANGE, FoodType.WATERMELON, FoodType.MUSHROOM];
    const randomType = foodTypes[Math.floor(Math.random() * foodTypes.length)];
    
    this.foods.push({
      position: newFood,
      createTime: Date.now(),
      type: randomType
    });
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
    if (newHead.x < 0 || newHead.x >= this.gridSize ||
      newHead.y < 0 || newHead.y >= this.gridSize) {
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
        this.score += 10;
        this.foods.splice(i, 1);
        ateFood = true;
        break;
      }
    }

    if (!ateFood) {
      this.snake.pop();
    }

    return true;
  }
}
