# Survivor Inner Voice

[简体中文](#简体中文) | [English](#english)

## 简体中文

Survivor Inner Voice（幸存者心声）是面向 Project Zomboid Build 42.20 的状态反应 Mod。
角色会根据饥饿、口渴、疲劳、疼痛、恐慌、负重和其他当前状态，用简短直白的头顶文字
自言自语；状态改善或完全恢复时也会出现对应反应。

- 当前版本：`0.3.5`
- Mod ID：`SurvivorInnerVoice`
- Workshop ID：`3793128772`
- 支持语言：简体中文、繁体中文、English
- 外部依赖：无
- 目标版本：Project Zomboid Build 42.20

完整状态模型、调度规则、颜色算法和多人边界见
[TECHNICAL_REFERENCE.md](https://github.com/Kinkairy/Project-Zomboid-Survivor-Inner-Voice/blob/main/docs/TECHNICAL_REFERENCE.md)。

### 核心表现

- 覆盖 25 种角色能够直接感受到的负面状态，并包含 `FoodEaten` 吃饱这一正面状态。
- 共 98 个实际可达的“状态 × 严重程度”组；状态出现、加重、减轻和完全恢复分别使用匹配语义。
- 每组每个变化方向最多提供 8 个台词位置，并避开最近 8 条，减少连续重复。
- 可直接使用原版状态标题和说明的位置在运行时读取游戏翻译，并以灰色 `<内容>` 头顶提示
  显示，不带图标或斜体；其余项目原创台词使用不带括号的严重度彩色头顶心声，句末留出间距
  后附对应的原版 Moodle 图标。
- 简中台词以自然的自言自语、自我吐槽、自我提醒和身体感受为主，不使用机械状态播报。
- 严重程度不只靠颜色区分：一级刚察觉，二级明显影响，三级接近极限，四级已经难以承受。
- 隐藏感染、感染倒计时和玩家无法直接感知的信息永远不会被台词泄露。

### 原版提示与心声分开

原版状态标题、说明和特殊状态标签使用游戏自己的头顶提示层，以偏灰色 `<内容>` 标明它是状态
注记，不带图标、斜体或升降箭头。原创角色心声同样复用原版头顶提示对象，不加括号；正式 Moodle
的心声句末通过游戏自己的 `[img=…]` 文本标记显示对应原版图标，不内置第二套图片。着火和尼古丁
戒断不是 Moodle，游戏没有对应 Moodle 图标，因而不配假图标。每次事件仍只显示轮换选中的一条。

### 颜色与原版一致

负面状态从灰色向玩家当前的原版负面高亮色插值，一级较淡、四级最深。正面状态使用同样的
原版正面高亮色；负面状态完全恢复时显示一级浅绿色恢复台词。Mod 不硬编码唯一红绿方案，
会跟随玩家当前的原版颜色设置。

### 频率与随机时间

沙盒设置提供“台词频率”“角色心声字体大小”和默认开启的“显示原版状态提示”。角色心声字体可选
`小 / 中 / 大 / 特大`，默认“中”；原版状态提示固定使用小号灰字。关闭“显示原版状态提示”后，
调度器会跳过原版标题和说明槽位，只显示角色心声。频率可选 `很少 / 较少 / 普通 / 频繁 / 很频繁`，五档内部
平均间隔分别为 60、35、20、12、6 秒，每次实际等待会在平均值的 70%–130% 之间随机变化。

- 进入世界后先等待一段随机时间，不会刚加载完成就立刻刷状态。
- 全局最短安全间隔固定为 3 秒。
- 所有档位都用最新状态变化替换同状态的旧等待项，最多等待 26 条，不补播过时症状。
- 状态升降仍可触发轻微症状提示；同状态提醒保护间隔不会阻挡新的变化。
- 持续处于三级或四级的严重状态会按更长的随机周期再次提醒。

### 架构

| 模块 | 职责 |
| --- | --- |
| `SIV_Catalog.lua` | 状态范围、可达等级、优先级、台词 key、原版文本槽位分类、官方图标路径、颜色与协议校验 |
| `SIV_Scheduler.lua` | 初始静默、升降队列、随机截止时间、严重状态提醒、优先级和最近台词避重 |
| `SIV_Client.lua` | 一秒节流读取本地状态、分流灰色原版提示与彩色角色心声 |
| `SIV_Server.lua` | 校验可选的语义化 spoken 事件、从真实发送者取得身份并执行三秒限流 |
| `Translate/CN・CH・EN` | 三语自定义台词、频率和字体大小沙盒选项 |

默认心声只在本地显示，不调用声音系统，不吸引僵尸，也不把客户端提供的任意文本、颜色、音量
或玩家 ID 交给服务器广播。Mod 不修改 moodle 数值、动作、物品、角色属性、世界状态或存档数据。

### 仓库结构

```text
docs/TECHNICAL_REFERENCE.md                 完整技术参考
workshop/Contents/mods/SurvivorInnerVoice   Mod 运行源码与元数据
workshop/install_local.ps1                  带备份、回滚和 SHA-256 读回验证的安装器
workshop/workshop.txt                       Steam Workshop 公开元数据
CHANGELOG.md                                公开变更记录
CONTRIBUTING.md                             贡献说明
SECURITY.md                                 漏洞报告方式
```

公开仓库不包含内部测试工具、语料平台原始输出、服务器地址、发布凭据、原始日志、私有运维流程
或来源边界未单独确认的发布封面素材。

### 获取与安装

Steam 创意工坊条目：
[幸存者心声 / Survivor Inner Voice](https://steamcommunity.com/sharedfiles/filedetails/?id=3793128772)。

源码安装时，可将 `workshop/Contents/mods/SurvivorInnerVoice` 复制到
`%USERPROFILE%\Zomboid\mods\SurvivorInnerVoice`，或在解压后的仓库根目录运行
`workshop/install_local.ps1`。安装器会先校验暂存副本，保留旧版本备份，并在部署后逐文件执行
SHA-256 读回验证；失败时尝试恢复原目录。

这是非官方社区项目，与 The Indie Stone 无关联。项目采用 [MIT License](LICENSE)。

## English

Survivor Inner Voice is a status-reaction Mod for Project Zomboid Build 42.20. Your character responds
to hunger, thirst, fatigue, pain, panic, heavy load, and other current conditions with short, readable
overhead self-talk. Matching reactions can also appear when a condition improves or fully clears.

- Current version: `0.3.5`
- Mod ID: `SurvivorInnerVoice`
- Workshop ID: `3793128772`
- Languages: Simplified Chinese, Traditional Chinese, and English
- External dependencies: none
- Target: Project Zomboid Build 42.20

See
[TECHNICAL_REFERENCE.md](https://github.com/Kinkairy/Project-Zomboid-Survivor-Inner-Voice/blob/main/docs/TECHNICAL_REFERENCE.md)
for the complete state model, scheduler rules, color algorithm, and multiplayer boundaries.

### Core Behavior

- Covers 25 directly perceptible negative conditions plus the positive `FoodEaten` state.
- Defines 98 reachable state-and-severity groups, with matching semantics for appearing, worsening,
  improving, and fully clearing.
- Provides up to eight phrase slots per group and direction while avoiding the eight most recent lines.
- Phrase slots backed by vanilla titles or descriptions resolve the game's own translation at runtime and
  use a neutral-gray `<text>` overhead prompt without an icon or attempted italics. Original character
  thoughts remain unwrapped, use severity colors, and leave a gap before the matching vanilla Moodle icon.
- Simplified Chinese is written as natural self-talk, complaints, self-reminders, and physical reactions
  instead of mechanical status announcements.
- Severity remains understandable without color: level one is newly noticeable, level two clearly
  interferes, level three approaches the limit, and level four is difficult to endure.
- Hidden infection data, infection timers, and information the character cannot directly perceive are
  never exposed.

### Vanilla-Aligned Colors

Vanilla titles, descriptions, and special-state labels use the game's overhead halo as neutral-gray `<text>`,
without an icon, italics, or arrows. Original character thoughts reuse the same vanilla halo object while
remaining unwrapped and colored by severity. For formal Moodles, the matching vanilla icon is appended through the
game's own `[img=…]` markup; no icon assets are bundled. On-fire and nicotine withdrawal are not Moodles and
therefore receive no fabricated Moodle icon. One scheduler event still produces only one selected line.

Negative reactions interpolate from gray toward the player's current vanilla negative highlight color,
from pale at level one to strongest at level four. Positive states use the vanilla positive highlight;
fully clearing a negative state uses the level-one positive color. The Mod follows the player's current
color settings instead of hardcoding one red-and-green palette.

### Frequency and Random Timing

Sandbox settings control frequency, inner-voice font size, and whether vanilla state prompts are shown.
Inner-voice font size offers `Small / Medium / Large / Massive` and defaults to `Medium`; vanilla prompts
always use small gray text. `Show vanilla state prompts` is enabled by default; disabling it skips vanilla
title and description slots while keeping character thoughts. Frequency offers
`Very Rare / Rare / Normal / Frequent / Very Frequent`.
Internal average intervals are 60, 35, 20, 12, and 6 seconds. Every actual delay is randomized to
70%–130% of the selected average.

- A randomized startup quiet period prevents immediate messages after entering the world.
- The global minimum safety interval is three seconds.
- All modes keep only the newest pending change per state: at most 26 pending entries, without replaying outdated symptoms.
- New changes can still trigger mild-symptom reactions; same-state reminder protection does not suppress transitions.
- Severe level-three and level-four conditions can produce a later reminder on a longer randomized timer.

### Architecture

| Module | Responsibility |
| --- | --- |
| `SIV_Catalog.lua` | State scope, reachable levels, priorities, phrase keys, vanilla-slot classification, official icon paths, colors, and protocol validation |
| `SIV_Scheduler.lua` | Startup silence, transition queues, randomized deadlines, reminders, priority, and recent-line avoidance |
| `SIV_Client.lua` | One-second state sampling and separate rendering for gray vanilla prompts and colored thoughts |
| `SIV_Server.lua` | Validation and rate limiting for optional semantic `spoken` events using the real sender identity |
| `Translate/CN・CH・EN` | Three-language custom lines plus frequency, thought-font, and vanilla-prompt options |

Inner thoughts are local by default. The Mod does not call the sound system, attract zombies, or allow a
client to broadcast arbitrary text, color, volume, or player IDs. It does not modify moodle values,
actions, items, character stats, world state, or save data.

### Repository Layout

```text
docs/TECHNICAL_REFERENCE.md                 Complete technical reference
workshop/Contents/mods/SurvivorInnerVoice   Runtime source and Mod metadata
workshop/install_local.ps1                  Installer with backup, rollback, and SHA-256 readback
workshop/workshop.txt                       Public Steam Workshop metadata
CHANGELOG.md                                Public change history
CONTRIBUTING.md                             Contribution guide
SECURITY.md                                 Vulnerability reporting
```

The public repository excludes internal test harnesses, raw writing-platform output, server addresses,
publishing credentials, raw logs, private operational procedures, and release artwork whose public
provenance has not been separately established.

### Distribution and Installation

Steam Workshop entry:
[Survivor Inner Voice](https://steamcommunity.com/sharedfiles/filedetails/?id=3793128772).

For a source installation, copy `workshop/Contents/mods/SurvivorInnerVoice` to
`%USERPROFILE%\Zomboid\mods\SurvivorInnerVoice`, or run `workshop/install_local.ps1` from an extracted
repository. The installer verifies a staging copy, preserves the previous version as a backup, performs
a file-by-file SHA-256 readback after deployment, and attempts to restore the old directory on failure.

This is an unofficial community project and is not affiliated with The Indie Stone.
Licensed under the [MIT License](LICENSE).
