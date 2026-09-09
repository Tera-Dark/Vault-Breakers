# 美术与声音资源

## 分类与用途

| 文件 | 类型 | 状态 |
|---|---|---|
| `brand/vault-mark.svg` | 原创矢量标记，四角框与秘密核心 | 对应游戏内 `UI.mark` 的几何图形；可继续编辑 |
| `marketing/vault-breakers-key-art.png` | AI 生成的演播室营销概念图 | **非游戏实机截图**；原尺寸 1376×768 |
| `marketing/vault-breakers-icon.png` | AI 生成的金库概念图标 | **非运行时模型渲染**；1024×1024 |
| `audio/*.wav` | 原创程序合成的 6 个机械/广播提示音 | 待体验所有者上传；无第三方采样 |

营销图只作美术方向/封面候选，不参与运行时加载，不应声称是游戏截图。原型中的文字、状态标识、金库预览和舞台全部使用原生 GUI/几何，不要求先上传图片。

## 上传声音

1. 在 Roblox Creator Dashboard / Studio 的资源导入入口，用**体验所属用户或群组**上传音频，等待审核。
2. 确认每个音频资产授权给该体验。能在个人库存试听，不代表目标群组体验能播放。
3. 将对应 ID 填入 `src/ReplicatedStorage/Config/AssetConfig.luau`，格式 `rbxassetid://1234567890`。
4. 同步源码并重新 Play；若使用根目录 place，执行 `python3 scripts/build-place.py` 后重新打开。检查 Output 中的音频加载/权限错误。

| AssetConfig 键 | WAV | 时长 | 设计意图 |
|---|---|---:|---|
| Claim | `claim-lock.wav` | 0.34 s | 两次锁定触点 |
| Breach | `vault-breach.wav` | 1.35 s | 锁栓、低声转动、阻尼停止 |
| Offer | `curator-offer.wav` | 0.82 s | 克制的广播信号，而不是中奖音 |
| Heartbeat | `pressure-heartbeat.wav` | 0.96 s | 最后五秒的低频双脉冲；循环边界留静音 |
| Tick | `pressure-tick.wav` | 0.13 s | 柔化的秒针接点 |
| Reveal | `final-reveal.wav` | 1.65 s | 中性收束，既适合庆幸也适合后悔 |

Click 默认保留引擎自带 `rbxasset://sounds/switch.wav`。未上传时 Claim、Offer、Breach、Tick 降级使用这一简短提示；Heartbeat 与 Reveal 留空静音。**默认工程没有冒用未验证的公共音频 ID，也没有假装完整音效已上线。**

音频均为单声道 PCM WAV、44.1 kHz、16 bit，峰值约 -3.9 dBFS，另由客户端音量控制压低。可以修改合成脚本和重新导出：

```sh
python3 scripts/generate-audio.py
python3 scripts/generate-audio.py --check
```

`audio/manifest.json` 记录参数与 SHA-256。已验证文件格式、长度、峰值余量和哈希；尚未在 Roblox 内听测、混音或验证资源权限。没有生成主持人语音、背景音乐或真人配音。
