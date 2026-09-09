# 离线检查图，不是 Roblox 截图

这些图片使用实际源码在 Roblox doubles 中构建出的几何与 GUI 坐标，由 Pillow/NumPy 绘制。图中金额与名字来自固定测试，不是线上玩家数据。

新菜单图包含生产 ViewportFrame 内微缩模型的近似绘制、GUI 层级/描边/渐变；背景是实际场景的一组代表性角度。**不是原生光照、材质、SurfaceGui、文字排版、安全区、玩家角色或 PlayerModule 相机的验证。** 字体是离线参考版本，不能取代 Roblox 的中英排版检查。

- `menu-states.png`：收起/展开对照。
- `lobby-desktop.png`：新版可收起菜单，不再是旧常驻大厅。
- `menu-mobile.png` / `menu-landscape.png`：竖屏、矮横屏菜单。
- `offer-*.png` / `*-geometry.png`：局内布局与场景几何检查。

不要把这些图上传为实机游戏截图。营销 AI 概念图在 `art/marketing`，也不得与实机画面混淆。

## 重生成

带 DejaVu Sans 的 Linux 环境：

```sh
npm ci --prefix scripts --ignore-scripts
npm run test:contracts --prefix scripts
python3 -m pip install --target .cache/python -r scripts/requirements-review.txt
# 可选：GitHub CLI 读取固定公共 blob，下载并核对离线参考字体
python3 scripts/fetch-review-fonts.py
python3 scripts/render-review.py
# 只更新菜单/收起 HUD 图：
python3 scripts/render-review.py --only-menu
```

不下载可选字体时使用 DejaVu 替代，并跳过中文检查图。参考字体只保存在 `.cache/fonts`，不进入 Git 或 Roblox 工程：

- Fredoka One：Google Fonts，固定 blob `304e608cb0717db90ac2c54ead2d0a86324aaa68`，[OFL 许可](https://github.com/google/fonts/blob/be2838a23fd2918408e22b25c54135da76525ff6/ofl/fredokaone/OFL.txt)。
- Noto Sans CJK SC Bold：Noto CJK，固定 blob `ff4c0450e8a5bf0290fbb6013a72dc61a10e8e56`，[OFL 许可](https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE)。

输出位于忽略的 `.cache/review`；本目录只保留交付说明引用的图片。JSON、字体和依赖包不进入版本控制。
