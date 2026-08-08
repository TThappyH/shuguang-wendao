# V8.3 白模地图框架

## 本轮目标

先验证空间，不做表面美术。运行入口只构建白模地图，不再构建旧草原、透明区域圆片、程序化树池或装饰性水面。

## 玩家与地图指标

| 指标 | 当前值 |
| --- | ---: |
| 玩家半径 | 0.42 m |
| 敌人导航半径 | 0.72 m |
| 主连接通道宽度 | 8 m |
| 战斗区边缘净空 | 2.2 m |
| 世界边界 | ±43 m |
| 白模网格单位 | 1 m |

## 地图图结构

五个战斗房间：

- `ruins`：中央教学场，四角体块，观察基础绕柱走位。
- `bamboo`：柱阵走位场，纵向体块切分视线。
- `marsh`：桥岛控制场，低矮大体块制造绕行。
- `sword`：碑阵决斗场，窄高体块制造视线开合。
- `ember`：峡谷压迫场，横向墙体形成折线路径。

四条 8 米宽连接通道组成星形关键路径，所有房间从中央区域可达。地图数据分为：

1. `MAP_ROOMS`：战斗空间尺寸与位置。
2. `MAP_LINKS`：区域图连接。
3. `MAP_BLOCKERS`：掩体和碰撞占地。
4. `LEVEL_METRICS`：角色半径、通道宽度和世界尺度。

视觉 Mesh 与可行走/碰撞数据分离。当前俯视移动只需要矩形 footprint；以后加入坡道、跳跃或复杂凹面时，再升级成合并静态碰撞体与 BVH，不提前引入无用复杂度。

## 角色锁定

- 运行资产：`assets/characters/qingyao/model_v1/qingyao_v1.glb`
- 与源资产 `D:\1\fantasy swordsman 3d model.glb` 的 SHA-256 一致。
- 实际解析：225,303 vertices / 411,054 triangles / 1 mesh。
- 旧程序化角色默认隐藏；GLB 加载失败时保持隐藏并显示错误，不再回退。

## GitHub 调研

- [mrdoob/three.js Editor](https://github.com/mrdoob/three.js/tree/dev/editor)：参考 Scene Graph、独立对象注册和地图根节点组织。
- [gkjohnson/three-mesh-bvh character movement](https://github.com/gkjohnson/three-mesh-bvh/blob/master/example/characterMovement.js)：参考视觉几何与静态 collider 分离、角色 capsule 指标和空间查询结构。
- [gkjohnson/three-bvh-csg](https://github.com/gkjohnson/three-bvh-csg)：调研后暂不引入；当前白模用数据化 Box 体块即可更快迭代。

## 当前 Gate

只判断：

- 五区尺寸是否合理。
- 通道是否过宽或过窄。
- 掩体是否真的改变走位和飞剑线路。
- 敌人跨区是否能通过中央连接导航。
- HUD 是否遮挡战场。

本 Gate 通过前不恢复场景贴图和装饰堆叠。
