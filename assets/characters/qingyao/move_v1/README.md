# 青曜 Move V1 资产包

> 分支：`art/qingyao-idle-v1` (shared art branch)

本目录保存《曙光问道》主角青曜的基础移动循环 (IN-PLACE MOVE LOOP V1) 绿幕素材。

## 目标资产

| 文件 | 用途 | 规格 | SHA256 |
|---|---|---|---|
| `qingyao_move_v1.mp4` | Move V1 绿幕循环视频 | H.264 1280×720 24fps ~6.04s | `8138a074393ca3933c85935edff0ab09d99296d08eed39628a9d06835d55ea43` |
| `qingyao_move_base.png` | 高分辨率移动姿态基帧 | PNG 1792×1008 | `de3cc1e46ffe4a083a0c570cf32a75fedd9a1e10af15fe7024a1ca2ec5270ac7` |
| `qingyao_move_ref_a.png` | 参考帧 A (start) | PNG 1280×720 | `5d9fdc90196298c2b058c44d9781cc12f0341c497a757bffe1c47177aecdedf8` |
| `qingyao_move_ref_b.png` | 参考帧 B (mid) | PNG 1280×720 | `915cd22f8808c371fb2f4e4d48e1bb7719b5155429a513c0f4617afebe91256d` |
| `qingyao_move_ref_c.png` | 参考帧 C (end) | PNG 1280×720 | `7ed26a0ae4fb78f51bf933de08f6d2f46dead84ceb50120ceaa519307e62fa2b` |

## 冻结口径

- Character: 青曜 Character V1 (严格一致 Idle V1)
- Camera: 55°–60° 向下俯视，完全固定
- Motion: IN-PLACE MOVE LOOP V1（原地移动循环，引擎负责位移）
- 核心：轻、快、稳、御气贴地疾行；静人烈剑 → “人踏清风，剑随身行”
- 三柄飞剑：一前导 + 左右护行
- 无重新编码，原始二进制

## Git 约束

仅在 art/* 分支更新，禁止修改 main，禁止自动合并，不改游戏代码。
