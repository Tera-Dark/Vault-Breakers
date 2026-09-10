# Lyria 精剪版高保真音频资产 (Mastered Audio Cues)

本项目音频源自 Google DeepMind Lyria 生成的长篇母带，经专业音频处理脚本（`scripts/process-lyria-cues.py`）进行切片、等功率无缝跨淡入淡出（Equal-Power Crossfade）和 -1.5dB 峰值安全归一化处理。
输出格式严格符合 Roblox 官方最高标准：**44,100 Hz、16-bit PCM WAV**。

## 剪辑成品清单与游戏场景映射表

| 文件名 | 时长 | 声道 | 循环模式 | 来源母带 | 对应游戏场景与触发机制 | 建议上传映射 |
|---|---:|:---:|:---:|---|---|---|
| `bgm_stage_sterile_hour_loop.wav` | 53.80 s | 立体声 | **无缝大循环** | 《The Sterile Hour》 | **主舞台决策思考 BGM**：选手在主舞台选门、看奖池概率、庄家出价（Round 1~3）的核心悬疑思考回路。留白充足，不遮盖游戏提示音。 | 填入 `AssetConfig.OriginalUploads.Music` |
| `bgm_final_two_lock_loop.wav` | 46.00 s | 立体声 | **无缝大循环** | 《Before The Lock》 | **生死对决·最后两门决战 BGM**：第 4 轮只剩最后两扇门（KEEP or SWAP）与报价倒计时最后 5 秒的高压加速心跳推进回路。 | 可作为决战独立音乐 |
| `bgm_green_room_lounge_loop.wav` | 170.50 s (2m50s) | 立体声 | **无缝大循环** | 《Green Room》 | **贵宾休息室 BGM**：等候大厅（Lobby / Green Room）自由走动、沙发闲逛、看 32x14 电视大屏幕直播赛况时的冷调奢华 Downtempo 休闲长曲。 | 休息室专属音乐 |
| `showtime_fanfare_sting.wav` | 2.20 s | 单声道 | 单次播放 | 《The Midnight Verdict》 | **选手登台特写号角**：选手成功排上主舞台时，全场聚光灯打开、2 秒 SHOWTIME 登台亮相特写音效。 | 填入 `AssetConfig.OriginalUploads.Showtime` |
| `final_reveal_resolution.wav` | 3.00 s | 单声道 | 单次播放 | 《The Midnight Verdict》 | **最终底牌揭晓华彩**：最终二选一揭晓与大奖开箱瞬间的辉煌高光音。 | 填入 `AssetConfig.OriginalUploads.Reveal` |
| `pressure_heartbeat.wav` | 0.96 s | 单声道 | **双击脉冲循环** | 《Before The Lock》 | **最后 5 秒紧迫心跳**：提取自真实母带的超低频双击心跳（Lub-dub），无爆音首尾平滑衰减。 | 填入 `AssetConfig.OriginalUploads.Heartbeat` |
| `grand_victory_theme.wav` | 14.50 s | 立体声 | 单次播放 | 《The Midnight Verdict》 | **大满贯通关结算盛典曲**：带走巨额奖金或全服通报广播时播放的华丽电视庆典大片长曲。 | 结算胜利主题 |

---

## 如何在 Roblox Studio 中应用

1. 打开 Roblox Studio，进入游戏工程；
2. 打开 **View -> Asset Manager**（资产管理器），点击 **Audio** 下的批量上传按钮（Bulk Import），将 `art/audio/lyria_processed/` 下的 WAV 文件上传至你的 Roblox 体验所有者账户；
3. 上传完成后，右键复制生成的 `rbxassetid://...`；
4. 打开 `src/ReplicatedStorage/Config/AssetConfig.luau`，将对应的 ID 粘贴到 `OriginalUploads` 表中即可生效！
