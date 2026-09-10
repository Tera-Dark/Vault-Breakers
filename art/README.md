# 美术与声音资源

## 类型与来源

- `brand/vault-mark.svg`：原创矢量标记。
- `marketing/vault-breakers-key-art.png` / `vault-breakers-icon.png`：AI 生成营销概念，**不是实机截图**，不参与运行时加载。
- `audio/*.wav`：9 个原创程序合成音频，无第三方采样；包含悬疑脉冲和简短节目音型。
- `audio/library-manifest.json`：7 个不同 Creator Store 合作方默认音频的来源/类型/发布者记录。**只有元数据核验，没有目标体验内播放或听测认证。**

## 菜单与场景模型

菜单 3D 卡片由 `VaultPreview.luau` 生成：微缩金库、方块选手、演播摄像机，共 205 个本地零件，首次打开才构建。没有裁切用户参考图作为按钮，也不依赖营销图/上传网格。

实际舞台、电视框、红毯、地标和展台为原生几何。名人堂通过 Roblox Avatar API 获取公开角色模型，失败保留占位；离线截图不会表现真正头像或角色纹理。

菜单字体使用 Roblox 自带 Fredoka One 与平台回退字形。离线 review 可选使用 OFL 参考字体，文件只在 `.cache/fonts`，不打入 place，不能证明原生中文排版。

## 默认音频与授权边界

默认 ID 来自 Creator Store 的 ProSoundEffects / APMOfficial 资源；逐项元数据/商店链接在 [来源清单](audio/library-manifest.json)。**免费提供使用不等于无版权或任意平台无限制使用。**清单中的 `apiIsPublicDomain` 是 API 的分发字段，不是法律上的公共领域声明。

| 使用场合 | 默认资源 / ID | 处理 |
|---|---|---|
| 锁定底牌 | Lock Unlock Door 10 / `9116324156` | 限时播放 |
| 金属门 | Metal Door Creak 2 / `9116604303` | 限时播放 |
| 报价落定/冲击/末段低频脉冲 | Synth Whomps 38 / `9119882039` | 默认合成低频脉冲，不冒充实录心跳 |
| 小额排除欢呼 | Crowd Cheer And Applause 1 / `9112766176` | 原素材 41.5 秒，仅播放短片段，不循环铺满全场 |
| 大额排除吸气 | Male Gasp / `9125572450` | 原素材为单人吸气，非已完成的整场人群录音混音 |
| 悬疑背景 | DRONE-Dark Desire / `1837835644` | 低音量，重要事件时让位 |
| 亮相/结尾 | Winner / `1844584698` | 短片段；剪辑位置与听感需实测 |
| 点击/滚动滴答 | 引擎 `rbxasset://sounds/switch.wav` | 内置后备提示音 |

预载异步进行，不阻塞入场；不可用的一次性声效不会迟到后错播。音乐、观众声可单独关闭。`StudioChecks.run()` 能读出每个声音的配置和加载状态，**不能代替实际试听、混音和权限验证**。

## 上传原创版本

1. 使用体验所属用户/群组上传以下 WAV，等待审核并授予体验使用权限。
2. 填写 `src/ReplicatedStorage/Config/AssetConfig.luau` 中的 **`OriginalUploads`**，格式为 `rbxassetid://数字`；保留 `Sounds` 中的库素材后备表。
3. 重建 place / Rojo 同步，重新 Play。上传版本无法加载时会尝试库后备，并在 Output 报告。
4. 在独立测试体验实测加载、循环、片段结束、音量以及静音/恢复，不要只检查配置里有没有 ID。

| OriginalUploads 键 | 原创文件 | 时长 |
|---|---|---:|
| Claim | `claim-lock.wav` | 0.34 s |
| Breach | `vault-breach.wav` | 1.35 s |
| Offer | `curator-offer.wav` | 0.82 s |
| Heartbeat | `pressure-heartbeat.wav` | 0.96 s |
| Tick | `pressure-tick.wav` | 0.13 s |
| Reveal | `final-reveal.wav` | 1.65 s |
| Showtime | `showtime-sting.wav` | 1.20 s |
| Impact | `vault-impact.wav` | 0.70 s |
| Music | `low-drone-pulse.wav` | 8.00 s |

原创文件为单声道 PCM WAV、44.1 kHz、16 bit，峰值约 −3.9 dBFS；再由分组混音压低。它们只包含程序合成的音色，没有冒充观众录音或真人主持配音。

```sh
python3 scripts/generate-audio.py
python3 scripts/generate-audio.py --check
python3 scripts/check-audio-catalog.py
```

第一个清单核对原始音频哈希/格式；第二个只核对配置与已记录的库资产，不是在线授权检查。原生听感与设备混音仍待 QA。
