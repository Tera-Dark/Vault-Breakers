# 离线检查图，不是 Roblox 截图

这些图片使用实际源码在 Roblox doubles 中构建出的几何与 GUI 坐标，由 Pillow/NumPy 绘制。参考字体不是 Roblox 字体；没有原生光照、阴影、SurfaceGui、ViewportFrame 图像和真机安全区。数字与名字来自固定的自动化测试场景，不是线上玩家数据。

不要将它们标为实机效果图或上传为游戏截图。营销 AI 概念图另放在 `art/marketing`，同样不得与原生实机画面混淆。

可在带 DejaVu Sans 字体的 Linux 环境重生成：

```sh
npm ci --prefix scripts --ignore-scripts
npm run test:contracts --prefix scripts
python3 -m pip install --target .cache/python -r scripts/requirements-review.txt
python3 scripts/render-review.py
```

输出在忽略的 `.cache/review/`。本目录只保留交付说明引用的 5 张检查图，方便快速浏览，不将中间 JSON/依赖包放进版本控制。
