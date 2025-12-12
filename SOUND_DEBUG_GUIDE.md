# 音效调试指南

## 问题：听不到音效

### 检查步骤

1. **检查音效开关**
   - 进入设置页面（主页 -> 设置图标）
   - 确认"游戏音效"开关是打开的（绿色）
   - 检查音效音量是否大于0

2. **检查日志输出**
   
   当吃到加分或减速食物时，应该看到以下日志：
   
   ```
   Triggering sound effect for food type: FRUIT scoreChange: 10
   playSoundEffect called: coin04.mp3 context: true enabled: true volume: 0.5
   Preparing sound effect player...
   Setting sound effect volume to: 0.5
   Playing sound effect...
   Sound effect play command sent: coin04.mp3
   ```

3. **可能的问题**

   **音效被禁用**
   - 日志显示：`Sound effect is disabled`
   - 解决：在设置中打开音效开关

   **Context未初始化**
   - 日志显示：`Context is null, cannot play sound effect`
   - 解决：重启应用

   **音量为0**
   - 检查音效音量滑块是否在0位置
   - 解决：调高音效音量

   **音效文件问题**
   - 日志显示：`Failed to play sound effect`
   - 检查：确认 `entry/src/main/resources/rawfile/coin04.mp3` 文件存在

4. **测试方法**
   
   - 开始游戏
   - 吃到以下食物应该播放音效：
     - 🍎 水果 (+10分)
     - 🍊 橙子 (+20分)
     - 🍉 西瓜 (+30分)
     - 🍋 柠檬 (减速)
   
   - 以下食物不播放音效：
     - 🌸 花朵 (加速)
     - 🍄 蘑菇 (减分)

## 代码位置

- 音效触发：`entry/src/main/ets/models/SnakeGame.ets` 第559行
- 音效播放：`entry/src/main/ets/models/MusicManager.ets` playSoundEffect方法
- 音效设置：`entry/src/main/ets/pages/ThemeSettingsPage.ets`

## 已添加的调试日志

所有关键步骤都添加了console.info日志，可以通过DevEco Studio的日志窗口查看。
