# V9 Godot Art Foundation

分支：`dev/v9-godot-art-foundation`

## 这轮完成的内容

- V9.1 使用 `cd5cef59-84a0-4bd2-a373-7ab78901bbc5.zip` 内的完整 PBR 浮岛场景替换程序化五域视觉地图。
- 新地图保留角色、三飞剑、敌人、HUD 和区域运行数据；移动边界改为适配浮岛外轮廓的圆形边界。
- 将 V8.3 五域白模的房间、连接通道、阻挡体和区域坐标迁移到 Godot 4.7.1。
- 使用已通过视觉 Gate 的青曜 GLB，不再生成积木人替代角色。
- 以真实 `MeshInstance3D`、`StaticBody3D`、`CharacterBody3D`、`WorldEnvironment` 建立场景。
- 五域分别有玉庭、碧篁、灵泽、古冢、丹霞的材质、植被、灯笼、水面、剑碑和火晶视觉语言。
- 迁入青曜移动、55°~60°俯视相机、三柄飞剑 FSM、追踪敌人、接触伤害、1/3/8 敌群调试和 HUD 数据面板。
- 水面和区域法阵使用 Godot shader；不是 UI 贴图替代 3D 地图。

## 本轮参考的 GitHub 方法

| 仓库 | 实际采用 | 许可证/处理 |
|---|---|---|
| [htdt/godogen](https://github.com/htdt/godogen) | 分阶段工程拆分、先跑验证再扩展 | MIT；未复制其提示词/运行时 |
| [FunplayAI/funplay-godot-mcp](https://github.com/FunplayAI/funplay-godot-mcp) | 运行时可观测性、项目地图与 smoke 检查思路 | MIT；未把 MCP 插件装进游戏运行时 |
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Godot 场景、相机、关卡、AI、性能的拆分方式 | Apache-2.0；只按方法实现 |
| [RandallLiuXin/GodotMaker](https://github.com/RandallLiuXin/GodotMaker) | agent/worker/reviewer 分工思路 | LICENSE 需单独审阅；未复制代码 |
| [Tencent-Hunyuan/Hunyuan3D-2.1](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1) | 作为未来道具/妖兽资产生成参考 | 生成器体量大，本轮不安装、不进入运行时 |
| [KhronosGroup/glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO) | GLB 资产链路参考 | Apache-2.0；当前使用 Blender/Godot 原生链路 |
| [sparklecatta-lang/XSXB-Frame-Tuner](https://github.com/sparklecatta-lang/XSXB-Frame-Tuner) | 记录为未来 2D 帧特效工具 | MIT；本轮不引入 2D 帧动画 |

## 打开方式

双击：`E:\shuguang-wendao-v68\godot\run_game.bat`

或在 PowerShell：

```powershell
& 'E:\shuguang-wendao-v68\godot\run_game.ps1'
```

操作：`WASD` 移动，`SPACE` 闪身，`R` 重启，`1/3/8` 调试敌群，`F3` 数据面板。

## 验证

```powershell
& 'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'E:\shuguang-wendao-v68\godot' --editor --quit
& 'E:\tools\Godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'E:\shuguang-wendao-v68\godot' --quit-after 6
```

本机已核验：Godot 4.7.1 官方便携版 SHA-256 为 `c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1`；当前青曜 GLB SHA-256 为 `CAD02281087C3C4AE3210A7CF42E3D83F7D04CCB6A7702A6A8C12BE6F3932D2C`。

外部地图包 SHA-256：`958AF1F348596ECEE11ED04337BD97DFD84803A0EC4A41408F12AB287C16931D`。Godot 地图 GLB 为 1 个 PBR 网格、896,791 个导入顶点、999,992 个三角面。

## 暂留项

- 当前是 Godot 美术基础垂直切片，不是完整 V6.8 功能等价迁移。
- 青曜 GLB 目前沿用外部资产自身的材质/贴图；下一轮再做专门的材质统一、灯光分层和动画/骨骼 Gate。
- 用户负责实际手动游玩验收；本轮只执行短时启动与解析检查。
