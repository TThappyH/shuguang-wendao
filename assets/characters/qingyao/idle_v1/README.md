# 青曜 Idle V1 资产包

> 分支：`art/qingyao-idle-v1`

本目录用于保存《曙光问道》主角青曜的第一版正式绿幕待机素材。

## 目标资产

| 文件 | 用途 | 原始规格 | SHA256 |
|---|---|---|---|
| `qingyao_idle_v1.mp4` | Idle V1 绿幕视频 | H.264, 1280×720, 24fps, 约 6.04s | `1707b3cf0fa35d939dcb32c3fd8b401d0c9a9b1ec25af5b82dd156c9aa8ef0fa` |
| `qingyao_idle_ref_a.png` | 待机参考帧 A (final base) | PNG, 1792×1008 | `2a4e9017ea213ed2b24070ae938b383e887bfa819cb29a5e9db59d3f68463df1` |
| `qingyao_idle_ref_b.png` | 待机参考帧 B | PNG, 1792×1008 | `2243621a578313470f76566d561a242c0f4fb72014fc6f029459812644036fbe` |
| `qingyao_idle_ref_c.png` | 待机参考帧 C | PNG, 1792×1008 | `d2ba18691a0889f6c826c8761d31bb484384440a798b51b08892cb97a46d7205` |

说明：最新 Grok Imagine 生成的 Idle V1 绿幕素材，3 张唯一高分辨率参考帧 + 1 个 6s 循环视频。无重复。

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

- 仅在 `art/qingyao-idle-v1` 分支更新
- 禁止修改 `main`
- 禁止自动合并
- 不改游戏代码

## 视频元数据

- 1280×720
- H.264
- 24 fps
- duration ≈ 6.041667 s
- 无重新编码，原始二进制归档
