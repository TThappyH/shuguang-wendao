# 青曜 Move V1 R2 资产包

> 分支：`art/qingyao-idle-v1`

本目录保存《曙光问道》主角青曜的基础移动循环 (IN-PLACE MOVE LOOP V1 R2 修正版) 绿幕素材。

## 目标资产

| 文件 | 用途 | 规格 | SHA256 |
|---|---|---|---|
| `qingyao_move_v1.mp4` | Move V1 R2 绿幕循环视频 | H.264 1280×720 24fps ~6.04s | `247842da6e6fb95ab1e70ca2fb61a3aa8726e50082668a5c8dfec93616295d36` |
| `qingyao_move_base.png` | 高分辨率移动基帧 | PNG 1792×1008 | `1b88b4c5222777b0f14044cb7d8c8be2eba598c4b599bff187d98f6a620ea321` |
| `qingyao_move_ref_a.png` | 参考帧 A (start) | PNG 1280×720 | `530bbddc7c2237d99909ccb272762078583859771a74d02f16bab59a531581ad` |
| `qingyao_move_ref_b.png` | 参考帧 B (mid) | PNG 1280×720 | `b210210300165fb74427ab187af184fce1ee449a4ba36d2630906161ef2debc8` |
| `qingyao_move_ref_c.png` | 参考帧 C (end) | PNG 1280×720 | `94457d33f033176e39528de4b4e7a1a0ae4015d65a435cbdf21a0a3aec8447d0` |

## 冻结口径
- Character: 青曜 Character V1（严格一致 Idle）
- Camera: 55°–60° 向下俯视，完全固定
- Motion: IN-PLACE MOVE LOOP V1 R2（御气贴地疾行，短步低抬，头部稳定，三剑离中轴实体护阵）
- 核心：人踏清风，三剑护行
- 无重新编码，原始二进制

## Git 约束
仅在 art/* 分支更新，禁止修改 main，禁止自动合并，不改游戏代码。
