import media from '@ohos.multimedia.media';
import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

export class MusicManager {
  private static instance: MusicManager;
  private audioPlayer: media.AVPlayer | null = null;
  private isPlaying: boolean = false;
  private isEnabled: boolean = true;
  private volume: number = 0.5; // 音量 0.0 - 1.0
  private listeners: Array<(isPlaying: boolean, volume: number) => void> = [];
  private context: Context | null = null;

  private constructor() {}

  static getInstance(): MusicManager {
    if (!MusicManager.instance) {
      MusicManager.instance = new MusicManager();
    }
    return MusicManager.instance;
  }

  async init(context: Context) {
    if (this.audioPlayer) {
      return; // 已经初始化
    }

    this.context = context;
    await this.loadSettings();
    await this.initPlayer();
  }

  private async loadSettings() {
    try {
      if (!this.context) return;
      const prefs = await preferences.getPreferences(this.context, 'snake_settings');
      
      // 检查是否是首次运行或需要重置
      const settingsVersion = await prefs.get('musicSettingsVersion', 0) as number;
      if (settingsVersion < 1) {
        // 首次运行或旧版本，设置默认值
        this.isEnabled = true;
        this.volume = 0.5;
        await prefs.put('musicEnabled', true);
        await prefs.put('musicVolume', 0.5);
        await prefs.put('musicSettingsVersion', 1);
        await prefs.flush();
        console.info('Music settings initialized with defaults');
      } else {
        // 加载已保存的设置
        this.isEnabled = await prefs.get('musicEnabled', true) as boolean;
        this.volume = await prefs.get('musicVolume', 0.5) as number;
        console.info('Music settings loaded:', this.isEnabled, this.volume);
      }
    } catch (err) {
      console.error('Failed to load music settings:', err);
    }
  }

  private async initPlayer() {
    try {
      if (!this.context) {
        console.error('Context is null, cannot initialize player');
        return;
      }

      console.info('Creating AVPlayer...');
      this.audioPlayer = await media.createAVPlayer();
      console.info('AVPlayer created');
      
      // 注册状态变化监听
      this.audioPlayer.on('stateChange', (state) => {
        console.info(`Music player state changed: ${state}`);
        this.isPlaying = (state === 'playing');
        this.notifyListeners();
      });
      
      // 注册错误监听
      this.audioPlayer.on('error', (err) => {
        console.error('Audio player error:', JSON.stringify(err));
      });
      
      console.info('Getting audio file descriptor...');
      const fileDescriptor = await this.context.resourceManager.getRawFd('new_day.aac');
      console.info('File descriptor obtained');
      
      // 设置音频源
      this.audioPlayer.fdSrc = {
        fd: fileDescriptor.fd,
        offset: fileDescriptor.offset,
        length: fileDescriptor.length
      };
      
      // 等待一小段时间让状态变化
      await new Promise<void>((resolve) => setTimeout(resolve, 100));
      
      // 调用 prepare
      console.info('Preparing audio player...');
      await this.audioPlayer.prepare();
      console.info('Prepare called');
      
      // 等待一小段时间
      await new Promise<void>((resolve) => setTimeout(resolve, 100));
      
      // prepare 之后才能设置 loop
      this.audioPlayer.loop = true;
      console.info('Loop mode enabled');
      
      // 设置音量
      console.info('Setting volume to:', this.volume);
      await this.audioPlayer.setVolume(this.volume);
      
      if (this.isEnabled) {
        console.info('Auto-playing music (isEnabled=true)');
        await this.audioPlayer.play();
        console.info('Play command sent');
      } else {
        console.info('Music not auto-playing (isEnabled=false)');
      }
      
      console.info('Music player initialized successfully');
    } catch (err) {
      console.error('Failed to initialize music player:', JSON.stringify(err));
    }
  }

  async play() {
    try {
      console.info('Play music called, audioPlayer:', !!this.audioPlayer, 'isPlaying:', this.isPlaying);
      
      if (!this.audioPlayer) {
        console.error('Audio player not initialized');
        return;
      }
      
      if (!this.isPlaying) {
        console.info('Starting music playback...');
        await this.audioPlayer.play();
        this.isEnabled = true;
        await this.saveSettings();
        console.info('Music playback started');
      } else {
        console.info('Music is already playing');
      }
    } catch (err) {
      console.error('Failed to play music:', JSON.stringify(err));
    }
  }

  async pause() {
    try {
      if (this.audioPlayer && this.isPlaying) {
        await this.audioPlayer.pause();
        this.isEnabled = false;
        await this.saveSettings();
      }
    } catch (err) {
      console.error('Failed to pause music:', err);
    }
  }

  async toggle() {
    if (this.isPlaying) {
      await this.pause();
    } else {
      await this.play();
    }
  }

  async setVolume(volume: number) {
    try {
      this.volume = Math.max(0, Math.min(1, volume));
      if (this.audioPlayer) {
        await this.audioPlayer.setVolume(this.volume);
      }
      await this.saveSettings();
      this.notifyListeners();
    } catch (err) {
      console.error('Failed to set volume:', err);
    }
  }

  getVolume(): number {
    return this.volume;
  }

  isPlayingMusic(): boolean {
    return this.isPlaying;
  }

  isMusicEnabled(): boolean {
    return this.isEnabled;
  }

  private async saveSettings() {
    try {
      if (!this.context) return;
      const prefs = await preferences.getPreferences(this.context, 'snake_settings');
      await prefs.put('musicEnabled', this.isEnabled);
      await prefs.put('musicVolume', this.volume);
      await prefs.flush();
    } catch (err) {
      console.error('Failed to save music settings:', err);
    }
  }

  addListener(callback: (isPlaying: boolean, volume: number) => void) {
    this.listeners.push(callback);
  }

  removeListener(callback: (isPlaying: boolean, volume: number) => void) {
    const index = this.listeners.indexOf(callback);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners() {
    this.listeners.forEach(callback => {
      callback(this.isPlaying, this.volume);
    });
  }

  async release() {
    try {
      if (this.audioPlayer) {
        await this.audioPlayer.stop();
        await this.audioPlayer.release();
        this.audioPlayer = null;
        this.isPlaying = false;
        console.info('Music player released');
      }
    } catch (err) {
      console.error('Failed to release music player:', err);
    }
  }
}
