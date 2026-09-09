# VAULT BREAKERS
## Roblox 游戏产品需求文档（PRD）

**版本：v0.3 Final Development Draft**

**状态：准备进入开发**

**游戏类型：**

3D Social Risk Show  
多人社交 / 风险决策 / 舞台真人秀 / 轻策略 / 不完全信息

---

# 1. 项目一句话定义

> Vault Breakers 是一款多人 3D 风险决策真人秀游戏：一名玩家站上金库舞台，在未知奖励与 Curator 报价之间不断做出选择，而其他玩家围观、投票、施压，但最终承担结果的永远只有舞台中央的 Breaker。

---

# 2. 核心体验目标

游戏不追求：

> 玩家获得大量随机奖励。

真正追求：

> 玩家面对一个越来越复杂的局面，明知道继续可能更赚，却不知道什么时候应该停下。

核心情绪：

```text
希望
↓
贪婪
↓
犹豫
↓
群体施压
↓
倒计时
↓
决定
↓
后悔 / 庆幸
↓
再来一局
```

---

# 3. 最终产品定位

# SOCIAL RISK SHOW

不是：

- Casino
- Gambling Game
- Lootbox Simulator
- Idle Simulator

而是：

# Interactive Risk Game Show

核心关键词：

- Breach
- Vault
- Intel
- Curator
- Offer
- Extract
- Push
- Decision
- Pressure

客户端、UI、文案、本地化中避免：

- Bet
- Gamble
- Casino
- Wager
- Odds

---

# 4. 核心设计支柱

## 4.1 不完全信息

玩家永远无法直接知道：

自己的 Claim Vault 中是什么。

只能通过不断排除结果：

缩小可能性。

---

## 4.2 风险决策

每一个 Offer 都必须形成：

```text
确定收益

VS

未知未来
```

---

## 4.3 社交压力

观众：

知道玩家正在面临选择。

可以表达意见。

但：

不承担最终结果。

---

## 4.4 3D Physicality

核心交互必须发生在：

真实 3D 场景。

玩家需要：

- 跑向 Vault
- 操作控制台
- 拉动 Breach Handle
- 观看机械开启
- 走向决策区

不能做成纯 UI 点选游戏。

---

## 4.5 高频重玩

目标单局：

# 2 至 4 分钟

结束后立即产生：

> 再来一次。

---

# 5. 最大架构修改：取消严格轮流舞台排队

## 禁止设计

```text
16 人服务器
↓
1 人玩 3 分钟
↓
其他人等待
↓
轮到第 10 个人
```

这种模式不可接受。

---

# 6. MVP Server Structure

MVP 推荐：

# 6 至 8 名玩家 / Server

服务器中存在：

```text
1 Main Stage
+
1 Quick Arena
```

---

# 7. Main Stage

Main Stage 是：

全服视觉中心。

承担：

- 高 Heat 玩家
- 高连胜玩家
- 高价值局面
- Spectator Social Show

其他玩家可以：

围观。

投票。

互动。

---

# 8. Quick Arena

Quick Arena 是：

第二个并行游戏区域。

用途：

避免玩家长时间等待。

玩家可以：

快速进入自己的 Vault Run。

---

Quick Arena：

- 基础玩法完全相同
- Spectator 功能简化
- 不要求全服围观
- 可以快速开始

---

# 9. MVP 玩家流程

玩家进入服务器。

系统判断：

是否有空闲 Arena。

---

如果有：

立即开始。

---

如果 Main Stage 正在进行：

玩家可以：

```text
WATCH
OR
PLAY QUICK RUN
```

---

核心原则：

# 玩家不能被迫观看超过几分钟才能玩。

---

# 10. 未来服务器结构

未来玩家规模增加后：

服务器可以升级：

```text
              MAIN STAGE
                 │
          全服重点直播
                 │
      ┌──────────┼──────────┐
      │          │          │
   QUICK A     QUICK B    QUICK C
```

---

Main Stage：

负责社交 spectacle。

Quick Arenas：

负责：

即时可玩性。

---

# 11. 单局核心流程

```text
ENTER ARENA
↓
CHOOSE CLAIM VAULT
↓
CLAIM LOCKED
↓
BREACH VAULTS
↓
REWARD ELIMINATION
↓
CURRENT BOARD CHANGES
↓
CURATOR OFFER
↓
PRESSURE CLOCK
↓
SPECTATOR POLL
↓
EXTRACT / PUSH
↓
NEXT ROUND
↓
FINAL PHASE
↓
KEEP / SWAP
↓
FINAL REVEAL
↓
RESULT
```

---

# 12. Vault 数量

MVP：

# 12 Vaults

其中：

```text
1 Claim Vault
11 Breachable Vaults
```

---

# 13. Reward Pool

MVP：

```text
1
5
10
25
50
100
250
500
1,000
2,500
5,000
10,000
```

全部：

开局公开。

但：

Reward 与 Vault 的对应关系未知。

---

# 14. 回合结构

## Round 1

开启：

4 Vault。

剩余：

8。

Offer #1。

---

## Round 2

开启：

3 Vault。

剩余：

5。

Offer #2。

---

## Round 3

开启：

2 Vault。

剩余：

3。

Offer #3。

---

## Final

剩余：

```text
YOUR CLAIM
+
FINAL VAULT
```

---

# 15. 3D Vault Interaction

玩家不能点击列表。

玩家必须：

走向 Vault。

---

操作流程：

```text
APPROACH
↓
INTERACT
↓
BREACH SYSTEM ACTIVATES
↓
PRESSURE RELEASE
↓
METAL LOCKS RELEASE
↓
DOOR OPENS
↓
REWARD REVEAL
```

---

单次 Opening：

目标：

约 1.5 秒。

不能：

过长。

避免拖慢单局节奏。

---

# 16. Curator

Curator 是：

舞台主持人。

负责：

- Offer
- 倒计时
- 情绪制造
- Final Phase
- Final Reveal

人格：

冷静。

神秘。

略带心理压迫。

---

# 17. Offer 基础算法

基础：

```text
Remaining EV × Offer Factor
```

---

## Round Factors

| Round | Remaining | Factor |
|---|---:|---:|
| Round 1 | 8 | 0.45 |
| Round 2 | 5 | 0.70 |
| Round 3 | 3 | 0.90 |
| Final | 2 | 0.84 - 0.96 |

---

## Variation

最终：

```text
Offer
=
EV
×
Factor
×
Random(0.97 - 1.03)
```

---

# 18. Offer 的核心设计原则

Offer 不一定是：

数学期望最高。

它提供的是：

# 确定性。

玩家拒绝 Offer：

获得更高潜在收益。

但承担：

波动风险。

---

# 19. Pressure Clock

Offer 出现后：

玩家不能无限思考。

---

推荐：

# 18 秒

---

时间：

```text
18 - 6 秒
```

正常紧张。

---

```text
5 - 0 秒
```

进入：

# CRITICAL PRESSURE

---

效果：

- 心跳加快
- 环境音降低
- 警报灯启动
- Spectator Vote 快速刷新
- Curator Screen 闪烁

---

# 20. 超时规则

超时：

不推荐：

强制扣 Credits。

因为：

容易让玩家感觉：

系统在惩罚网络延迟或犹豫。

---

MVP 推荐：

# AUTO PUSH

Curator：

> Hesitation is a decision.

系统：

自动进入下一阶段。

---

后续测试：

可以根据玩家反馈调整。

---

# 21. Audience Poll

Offer 出现时：

观众可以选择：

```text
EXTRACT
```

或：

```text
PUSH
```

---

投票：

免费。

无消耗。

无下注。

---

显示：

```text
EXTRACT

37%

PUSH

63%
```

---

# 22. Audience Lifeline

MVP 正式加入。

---

每局：

Round 3 或 Final 前。

玩家拥有：

# 1 Audience Lifeline

---

玩家可以主动：

走向中央控制台。

拉下：

# EMERGENCY AUDIENCE LEVER

---

触发：

# 10 秒 Emergency Poll

---

现场：

- 警报启动
- 全场 UI 强制弹出投票
- Curator Screen 切换
- Spectator Balcony 灯光变化

---

观众：

选择：

```text
EXTRACT

PUSH
```

---

结束后：

显示：

```text
AUDIENCE CONSENSUS

PUSH

87%
```

---

重要：

Audience Lifeline：

只提供：

社会意见。

不提供：

概率信息。

最终决定：

仍然属于 Breaker。

---

# 23. Decision Quality 系统：正式修正

## 禁止

简单使用：

```text
Offer > EV
```

判断好决策。

因为：

Offer 大多数阶段：

天然小于 EV。

---

# 24. Decision Quality 的真实评价逻辑

Decision Quality 应基于：

# Risk-Adjusted Value

而不是：

单纯 Expected Value。

---

系统考虑：

```text
Potential Reward

+

Remaining EV

+

Variance

+

Downside Risk

+

Offer Certainty
```

---

# 25. 核心概念：Risk Premium

玩家拒绝 Offer：

不是简单：

> 想获得更多。

而是：

> 是否愿意为了额外潜在收益承担额外波动。

---

系统需要衡量：

当前局面：

继续 Push 的风险。

---

# 26. 示例

剩余：

```text
1
10,000
```

EV：

```text
5,000.5
```

Offer：

```text
4,500
```

虽然：

Offer < EV。

但：

玩家 EXTRACT。

应该判定：

# ELITE EXTRACT

因为玩家：

放弃约 500 EV。

获得：

100% 确定收益。

避免：

50% 获得 1。

---

# 27. Greedy Blunder

剩余：

```text
1
5
10,000
```

Offer：

```text
3,000
```

玩家：

拒绝。

随后：

开掉 10,000。

局面崩坏。

系统可以判定：

# GREEDY BLUNDER

---

注意：

这个标签应该：

主要用于玩家赛后回顾。

不能频繁羞辱玩家。

---

# 28. MVP Decision Score 简化方案

第一版不需要复杂金融模型。

可以使用：

# Risk Score

---

系统计算：

```text
Worst Case
Best Case
Range
Spread
Offer Guarantee
```

---

例如：

```text
Risk Range

=

Highest Remaining Reward

-

Lowest Remaining Reward
```

---

Range 越大：

接受确定 Offer 的价值越高。

---

# 29. MVP Extract Score

系统内部：

计算：

```text
Offer / EV
```

同时结合：

```text
Reward Spread
```

---

如果：

Offer 接近 EV。

且：

Reward Spread 极大。

那么：

EXTRACT：

高质量决策。

---

如果：

Offer 极低。

Reward Spread 较低。

EXTRACT：

保守决策。

---

# 30. MVP Push Score

Push 不应该因为：

结果不好。

直接被判错误。

---

例如：

```text
Offer = 500

EV = 5,000
```

即使玩家 Push 后：

最后结果不好。

原决策：

依然可能合理。

---

因此：

# Decision Quality 必须评价决策发生时的信息。

不是根据最终 Reveal 倒推。

---

# 31. Heat 系统

Heat：

代表：

Breaker 的当前状态。

---

例如：

```text
🔥 x1.0

🔥 x1.2

🔥 x1.5

🔥 x2.0
```

---

Heat：

来自：

长期优秀决策。

不是：

单纯高 Reward。

---

# 32. Heat 风险

连续：

高质量决策：

Heat 上升。

---

连续：

低质量决策：

Heat 下降。

---

禁止：

一次 RNG 翻车。

直接清零。

---

核心心理：

> 玩家保护的是自己的决策纪录。

不是：

随机运气。

---

# 33. Spectator 深度参与

Spectator 不能只是：

坐着等待。

---

MVP Spectator 可以：

- EXTRACT / PUSH Poll
- KEEP / SWAP Poll
- Audience Lifeline
- Emote Reaction
- Celebration Effect

---

Future：

可以加入：

- Cheer
- Light Stick
- Confetti
- Audience Emotes
- Prediction Streak

---

# 34. Spectator Prediction

允许：

无成本预测。

例如：

```text
I THINK THEY WILL PUSH
```

---

正确：

获得：

少量：

Reputation。

---

禁止：

```text
Spend Credits

to predict

and win more Credits
```

---

任何 Prediction：

不得构成：

价值下注。

---

# 35. Final Phase

最后剩：

```text
CLAIM VAULT
+
FINAL VAULT
```

Curator：

给出 Final Offer。

---

玩家：

```text
EXTRACT
```

结束。

---

或：

```text
PUSH TO FINAL
```

进入：

Keep / Swap。

---

# 36. Final Swap

玩家：

选择：

```text
KEEP
```

保留 Claim。

---

或：

```text
SWAP
```

交换到 Final Vault。

---

观众：

免费表达意见。

```text
KEEP

SWAP
```

---

最终：

玩家承担结果。

---

# 37. Final Reveal

Final Reveal：

必须是：

单局最高情绪点。

---

流程：

```text
LIGHTS DOWN
↓
MUSIC CUT
↓
CURATOR SPEAKS
↓
VAULT LOCK RELEASE
↓
DOOR SLOWLY OPENS
↓
REWARD PAUSE
↓
FINAL REVEAL
```

---

# 38. Quick Arena 与 Main Stage 区别

## Main Stage

特点：

- 全服围观
- 完整 Spectator Poll
- Audience Lifeline
- 高视觉效果
- Highlight 记录

---

## Quick Arena

特点：

- 即时进入
- 快速 Match
- 简化观众
- 重点保证可玩性

---

# 39. Main Stage 触发方式

MVP 推荐：

不要：

付费进入。

---

可以：

根据：

- Heat
- Match Performance
- Queue
- Server Rotation

获得 Main Stage。

---

禁止：

Robux 购买：

高价值舞台机会。

---

# 40. 长期成长

主要：

# Reputation

用于：

- Title
- Cosmetic
- Vault Skin
- UI Theme
- Profile Frame
- Emote
- Entrance Effect

---

# 41. 玩家 Profile

记录：

```text
Total Runs

Best Extract

Best Final Reward

Highest Heat

Decision Accuracy

Longest Decision Streak

Main Stage Appearances
```

---

# 42. 商业化原则

优先：

Cosmetic。

---

可考虑：

- Vault Skin
- Breach Animation
- Entrance Animation
- Extraction Animation
- Profile Decoration
- Emote
- Title
- UI Theme
- Private Arena

---

禁止：

付费提高：

- Reward Probability
- High Reward Chance
- Claim Vault Value
- Offer Value

---

# 43. Roblox 合规底线

Credits：

必须：

纯游戏内资源。

---

禁止：

Credits：

兑换：

- Robux
- 现实货币
- 可提现资产

---

禁止：

观众：

支付 Credits。

预测。

获得更高价值 Credits。

---

Poll：

必须是：

免费意见表达。

---

Prediction：

只能：

提供非交易性：

Reputation。

---

# 44. MVP Vertical Slice

第一阶段目标：

不是赚钱。

不是商业化。

而是：

验证：

# 玩家是否真的产生犹豫。

---

必须实现：

## Gameplay

- 12 Vault
- Reward Randomization
- Claim Vault
- Breach Interaction
- Reward Elimination
- 3 Rounds
- Offer
- Pressure Clock
- EXTRACT
- PUSH
- Final Offer
- KEEP / SWAP
- Final Reveal

---

## Social

- Main Stage
- Spectator Poll
- Audience Lifeline
- Final Poll

---

## Meta

- Credits
- Reputation
- Heat
- Basic Decision Score

---

## Presentation

- 3D Vault Arena
- Curator Screen
- Lighting
- Alarm
- Heartbeat
- Vault Opening Sound
- Final Reveal

---

# 45. MVP 明确不做

暂时禁止扩展：

- Tool Inventory
- Scanner
- Intel
- Random Events
- Multiple Curators
- Battle Pass
- Season
- Shop
- GamePass
- Complex Cosmetics
- Multiple Reward Pools

---

# 46. 开发优先级

## Priority 1

完整单局逻辑。

---

## Priority 2

Offer。

Decision。

Final Swap。

---

## Priority 3

3D Interaction。

Vault Animation。

---

## Priority 4

Spectator。

Audience Pressure。

---

## Priority 5

Heat。

Reputation。

---

# 47. 第一阶段验收标准

Prototype 必须回答：

---

## 玩家会犹豫吗？

Offer 出现后：

是否存在：

明显 Decision Pause。

---

## 玩家会后悔吗？

Extract 后 Reveal 高价值：

是否产生：

> 我是不是走早了？

---

## 玩家会庆幸吗？

Extract 后 Reveal 低价值：

是否产生：

> 幸好我撤了。

---

## Push 是否有诱惑？

玩家是否：

愿意拒绝 Offer。

---

## Spectator 是否活跃？

是否：

投票。

起哄。

表达意见。

---

## 玩家是否立即再来？

这是：

最重要指标。

---

# 48. 最终核心循环

```text
UNKNOWN
↓
DISCOVER
↓
ELIMINATE
↓
HOPE
↓
OFFER
↓
PRESSURE
↓
TIME RUNNING OUT
↓
EXTRACT
OR
PUSH
↓
CONSEQUENCE
↓
REPLAY
```

---

# 49. 项目最终定义

Vault Breakers 最终不是：

> 一个随机开箱游戏。

而是：

> 一个玩家必须在不确定性中决定什么时候离开，而整个服务器都在看着他的真人秀。

---

# VAULT BREAKERS

## BREAK THE VAULT.

## FACE THE PRESSURE.

## KNOW WHEN TO LEAVE.