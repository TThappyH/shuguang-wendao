# 青曜 Idle V1 资产包

> 分支：`art/qingyao-idle-v1`

本目录用于保存《曙光问道》主角青曜的第一版正式绿幕待机素材。

## 目标资产

| 文件 | 用途 | 原始规格 | SHA256 |
|---|---|---|---|
| `qingyao_idle_v1.mp4` | Idle V1 绿幕视频 | H.264, 1280×720, 24fps, 约 6.04s | `c542926ea469a817561d67c88284fc7056bea90b773013de7da831b5b85dc302` |
| `qingyao_idle_ref_a.png` | 待机参考帧 A | PNG, 1792×1008 | `d5f9aa0fe9d3d71daed782cf32c2f21e94ccfaacb1f3579bfda19b3766b23088` |
| `qingyao_idle_ref_b.png` | 待机参考帧 B | PNG, 1792×1008 | `7c41acdf071db65e9049d1265c0a2b6f92048152a6eb2b04ff896abbcf4d0fb9` |
| `qingyao_idle_ref_c.png` | 待机参考帧 C | PNG, 1792×1008 | `cd3f4336e008ecc9466d08b23cece048ecbc0e1d590f911ea6c7553db72c715d` |

说明：上传的四张 PNG 中有两张内容完全相同（SHA256 相同），因此正式归档只保留 3 张唯一参考帧，避免仓库重复资产。

## 冻结口径

- Character: `青曜 Character V1`
- Camera: 约 55°–60° 向下俯视
- Motion: `Idle V1`
- 核心动作哲学：`静人，烈剑`
- 角色本人动作克制；飞剑承担主要待机生命感
- 三柄飞剑必须保持数量与造型稳定
- 后方飞剑应避免与头顶玉冠/高马尾中轴重叠
- 绿幕素材中的剑光仅作轻量参考，正式剑光、剑痕、尾迹、阵纹与爆发 VFX 后续由游戏运行时实现

## Git 约束

本资产分支独立于主线功能开发，不直接改 `main`，不自动合并。
