# 音效系统说明

## 功能概述

游戏中添加了音效系统，当玩家吃到特定类型的食物时会播放音效。

## 音效触发条件

### 正面音效 (coin04.mp3)

当吃到以下有利食物时播放：

**加分食物**
- 🍎 水果 (FRUIT) - +10分
- 🍊 橙子 (ORANGE) - +20分
- 🍉 西瓜 (WATERMELON) - +30分

**减速食物**
- 🍋 柠檬 (LEMON) - 0分，但减速10%（有利效果）

### 负面音效 (button04b.mp3)

当吃到以下不利食物时播放：

**减分食物**
- 🍄 蘑菇 (MUSHROOM) - -20分（不利效果）

**加速食物**
- 🌸 花朵 (FLOWER) - 0分，加速10%（不利效果）

## 技术实现

### MusicManager 新增功能

添加了 `playSoundEffect(soundFile: string)` 方法：
- 创建独立的音效播放器
- 音效音量为背景音乐音量的60%
- 播放完成后自动释放资源
- 只在音乐开启时播放音效

### SnakeGame 集成

在吃食物逻辑中添加了音效触发：
```typescript
// 播放音效：加分食物或减速食物（柠檬）
if (scoreChange > 0 || foodType === FoodType.LEMON) {
  this.musicManager.playSoundEffect('coin04.mp3');
}
```

## 音效控制

- 音效有独立的开关和音量控制
- 可以在设置页面单独控制音效开关
- 音效音量可以独立于背景音乐音量调节（0-100%）
- 即使背景音乐关闭，音效仍可以单独开启

## 音效文件

音效文件位置：
- 正面音效：`entry/src/main/resources/rawfile/coin04.mp3`
- 负面音效：`entry/src/main/resources/rawfile/button04b.mp3`


## 设置页面

在主题设置页面（ThemeSettingsPage）中可以找到：

### 背景音乐设置
- 🎵 背景音乐开关
- 音乐音量滑块（0-100%）

### 游戏音效设置
- 🔊 游戏音效开关
- 音效音量滑块（0-100%）

两者完全独立，可以分别控制。


## 游戏状态音效

### 游戏结束音效 (over.wav)
- 休闲模式游戏结束
- 挑战模式失败（时间到或生命耗尽）

### 挑战成功音效 (win.wav)
- 挑战模式达到目标分数成功通关

## 音效文件列表

所有音效文件位于：`entry/src/main/resources/rawfile/`

1. `coin04.mp3` - 正面音效（吃到加分或减速食物）
2. `button04b.mp3` - 负面音效（吃到减分或加速食物）
3. `over.wav` - 游戏结束音效
4. `win.wav` - 挑战成功音效
