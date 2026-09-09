# 🏆 Vault Breakers (金库之夜 / THE VAULT)

> **地下金库 × 真人秀演播舞台 × 高风险极限决断博弈**  
> *"十秒读秒，两个按钮。拿钱走人，还是赌上一切翻倍？一人进，亿万出。"*

---

## 📖 项目简介 (Overview)

**Vault Breakers** 是一款基于 Roblox 平台的沉浸式高奢真人秀博弈游戏（灵感源于经典美式娱乐节目《Deal or No Deal》与高压心战决策）。

游戏采用**双空间宏大架构**：
1. **美式选手备战大厅 (Contestant Holding Lounge / Green Room)**：可容纳数十人的美式演播厅后台，配备全景落地观赛窗、真皮软包沙发组、茶歇吧台 (Craft Service)、特权黑市商城、储物背包与荣耀排行榜。
2. **正式节目演播大厅 (The Vault Stage Arena)**：由 12 座重型精钢防盗门环列而成的聚光灯舞台，配备顶棚演播桁架聚光灯、Curator 巨型导播屏以及实体观众公投紧急操纵杆。

---

## 🎮 核心玩法闭环 (Core Gameplay Loop)

```
[选手大厅备战] ➔ [红毯闸门 / 一键登台] ➔ [挑选锁定 1 座底牌金库]
       │
       ▼
[逐轮破译淘汰其余金库] ➔ [Curator 动态现金报价提议]
       │
       ├─► [拿钱走人 (EXTRACT)] ➔ 锁定落袋 + 结算连胜 Heat
       │
       ├─► [继续博弈 (PUSH)] ➔ 进入下一轮极限攻防
       │
       └─► [犹豫不决？] ➔ 拉下中央操纵杆 ➔ 全服观众 10 秒紧急公投
       │
       ▼
[最终轮：保留底牌 VS 交换最后金库] ➔ [震撼揭晓 + 评级复盘]
```

* **12 档奖池金库**：`¥1`、`¥5`、`¥10`、`¥25`、`¥50`、`¥100`、`¥250`、`¥500`、`¥1,000`、`¥2,500`、`¥5,000`、`¥10,000`。
* **Curator 动态算法**：严格根据剩余奖池数学期望（EV）、极差方差、玩家剩余回合与风险系数动态报价。
* **决断质量评级**：经 10,000 次蒙特卡洛算法调优，给出 `ELITE EXTRACT`、`DARING PUSH` 或 `GREEDY BLUNDER` 终局复盘评级。

---

## 🏗️ 架构与工程目录 (Project Architecture)

项目采用现代标准 **Rojo 7.x** 架构，严格遵循 Luau 强类型（`--!strict`）规范：

```text
Vault Breakers/
├── default.project.json          # Rojo 映射配置文件
├── VaultBreakers.rbxl            # 可直接双击打开运行的 Roblox 工程文件
├── README.md                     # 项目开发与架构文档
├── .gitignore                    # Git 忽略配置
└── src/
    ├── ReplicatedStorage/        # 双端共享配置、协议与算法
    │   ├── Config/
    │   │   ├── GameConfig.luau   # 轮次结构、时钟阈值与核心参数
    │   │   ├── RewardPool.luau   # 12 档奖金定义与千分位格式化
    │   │   └── OfferAlgorithm.luau # Curator 现金报价算法公式
    │   ├── Network/
    │   │   └── Remotes.luau      # 全套 RemoteEvents 网络通信驱动
    │   └── Shared/
    │       ├── MatchState.luau   # 单局严格有限状态机定义
    │       ├── Types.luau        # 全局 Luau 强类型与数据结构
    │       └── DecisionQuality.luau # 风险调整价值评级算法
    │
    ├── ServerScriptService/      # 服务端核心逻辑与数据存储
    │   ├── Main.server.luau      # 服务端初始化入口与流程驱动
    │   ├── Core/
    │   │   ├── MatchManager.luau # 单局状态机核心驱动控制器
    │   │   └── StageBuilder.luau # 3D 演播大厅与美式选手大厅程序化构建
    │   └── Services/
    │       ├── PlayerDataService.luau # 玩家持久化数据、筹码与商城系统
    │       ├── CuratorService.luau    # 主持人动态情绪台词系统
    │       ├── DecisionService.luau   # 连胜加成系数 (🔥 x1.0~x2.0)
    │       ├── AudienceService.luau   # 观众实时公投与 10s 操纵杆求助
    │       └── LeaderboardService.luau# 百万金库提现榜与决断连击榜
    │
    └── StarterPlayerScripts/     # 客户端表现层与交互界面
        ├── ClientMain.client.luau # 客户端入口：金库特刊、侧边栏、背包、商店、决策HUD
        └── Controllers/
            └── AudiovisualController.luau # 聚光灯、警报光影与视听音效控制器
```

---

## 🚀 本地开发与运行 (Getting Started)

### 方式一：直接在 Roblox Studio 运行（无需任何环境）
1. 双击打开根目录下的 [`VaultBreakers.rbxl`](./VaultBreakers.rbxl)；
2. 在 Roblox Studio 工具栏点击 **Play（运行）** 即可立即体验完整大厅与对局玩法！

### 方式二：使用 Rojo 进行代码热同步开发
1. 安装 [Rojo](https://rojo.space/)（推荐 7.x 或以上版本）；
2. 在项目根目录执行本地服务：
   ```bash
   rojo serve
   ```
3. 在 Roblox Studio 中打开空工程或 `VaultBreakers.rbxl`，通过 **Rojo 插件** 连接 `localhost:34872` 进行实时增量热同步。
4. 如需重新打包 `.rbxl` 文件：
   ```bash
   rojo build -o VaultBreakers.rbxl
   ```

---

## 📜 规则与安全红线 (Compliance)
* **纯技术博弈**：所有奖金与筹码均为游戏内虚拟积分数值，严禁任何形式的真钱涉赌。
* **免费观众公投**：观众投票与求助功能完全向全服玩家免费开放，杜绝以付费撬动公投倾斜。

---

## 📄 License
MIT License. 版权所有 © 2026 Vault Breakers Team.
