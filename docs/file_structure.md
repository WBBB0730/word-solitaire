# 文件结构

本文档记录项目的逻辑文件结构。`.godot/`、`.git/`、`.idea/`、`screenshots/`、`builds/`、`.DS_Store` 等本地缓存、构建产物和调试截图不作为源码结构维护；需要时可以重新生成。

```text
.
├── .github/
│   └── workflows/
│       └── deploy_web.yml            # push main 后自动导出 Web 并部署到 Vercel
├── AGENTS.md                         # Codex / 项目协作规则
├── MEMORY.md                         # 项目长期记忆、重要实现决策
├── PLAN.md                           # 早期实现计划与验证记录
├── STRUCTURE.md                      # 架构说明与模块职责
├── docs/
│   ├── file_structure.md             # 当前文件
│   └── game_rules.md                 # 游戏规则说明
├── project.godot                     # Godot 项目配置
├── export_presets.cfg                # Godot 导出预设
├── icon.svg                          # 项目图标
├── icon.svg.import                   # Godot 图标导入配置
├── assets/
│   └── audio/
│       ├── background_music.mp3      # 全局背景音乐
│       ├── background_music.mp3.import
│       ├── button_click.mp3          # 普通按钮点击音效
│       ├── button_click.mp3.import
│       ├── card_flip.wav             # 翻牌/洗牌音效
│       └── card_flip.wav.import
├── scenes/
│   └── main.tscn                     # 主游戏场景，根节点挂载 scripts/main.gd
├── scripts/
│   ├── main.gd                       # 主场景状态、渲染、输入、动画和胜负流程
│   ├── main.gd.uid                   # Godot 脚本 UID
│   ├── category_library.gd           # 总类别/词语牌库
│   ├── category_selector.gd          # 每局类别抽样、长度限制、混淆 token 过滤
│   ├── deal_solver.gd                # 随机 DFS 求解器和步数估算
│   └── game_audio.gd                 # BGM/SFX 播放器与音量模型
├── test/
│   ├── *_smoke.gd                    # 自动化冒烟测试
│   ├── *_smoke.gd.uid                # Godot 为测试脚本生成的 UID
│   ├── *_preview.gd                  # 用于截图/动画调试的预览脚本
│   ├── *_preview.gd.uid              # Godot 为预览脚本生成的 UID
│   ├── tmp_complete_group_demo.gd    # 临时可复现局面脚本，保留用于后续验证
│   ├── tmp_complete_group_demo.gd.uid
│   └── tmp_complete_group_demo.tscn
```

## 重要源码文件

- `scripts/main.gd`：仍然是唯一直接挂在场景上的脚本。它负责 Godot 节点树、控件创建、拖拽、动画交接、回合幕布、胜负结算等强 UI 耦合逻辑。
- `scripts/category_library.gd`：总牌库内容和手写冲突组。后续扩充类别和词语时优先修改这里。
- `scripts/category_selector.gd`：纯规则 helper。它不接触节点树，负责生成本局 3-8 词数槽位、选择类别、抽样词语并过滤冲突。
- `scripts/deal_solver.gd`：纯求解 helper。它读取当前牌局状态，转换成紧凑 id 状态后进行 DFS。
- `scripts/game_audio.gd`：音频 helper。它创建 `AudioStreamPlayer` 节点并挂回主场景。

## 测试文件分组

- 规则和牌局：`rule_smoke.gd`、`category_conflict_token_smoke.gd`、`initial_visible_category_smoke.gd`、`available_step_end_state_smoke.gd`
- 求解器：`solver_smoke.gd`、`solver_randomized_dfs_smoke.gd`
- 牌堆/洗牌动画：`deck_*_smoke.gd`、`draw_*_smoke.gd`、`wash_*_smoke.gd`、`repeated_draw_smoke.gd`
- 拖拽/移动：`drag_*_smoke.gd`、`drop_no_replay_smoke.gd`、`board_drop_extended_hitbox_smoke.gd`
- 3 区吸收/完成：`category_*_smoke.gd`、`complete_group_category_pulse_smoke.gd`、`board_absorb_reveal_sync_smoke.gd`
- UI/音频/菜单：`audio_smoke.gd`、`button_click_sfx_scope_smoke.gd`、`board_empty_slot_smoke.gd`、`start_menu_smoke.gd`、`settings_menu_smoke.gd`、`top_controls_smoke.gd`、`no_hover_smoke.gd`

## 生成和本地文件

- `.godot/`：Godot 导入缓存和编辑器缓存，不手写维护。
- `screenshots/`：视觉验证截图和录制帧，目录下有 `.gdignore`，不参与 Godot 资源导入。
- `builds/`：本地导出的 APK、DMG 等产物。
- `.import` 和 `.uid` 文件：Godot 生成的资源元数据。源码资源对应的 `.import` 需要保留；测试脚本对应的 `.uid` 可随脚本一起保留。
