# claw-pilot

[English](README.md) | 中文

> [OpenClaw](https://github.com/openclaw/openclaw) 的 PM/QA Skill，将 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 作为后台工程师管理。

```
你 (IM)  →  OpenClaw Agent (PM/QA)  →  Claude Code (工程师, 后台执行)
```

你的 OpenClaw agent 变身项目经理：给 Claude Code 派任务、审查方案、监控进度、跑验收、汇报结果 — 全程不阻塞你的对话。

## 特性

- **Plan → 审批 → 执行 → 验收** 完整工作流
- **非阻塞**：CC 后台运行，agent 保持响应
- **Git worktree 隔离**：每个任务独立分支和工作树
- **双轨进度追踪**：git commit（确定性事实）+ progress.json（实时状态）
- **人在回路**：agent 自动上报决策点、错误和 merge 冲突
- **零 JS 代码**：纯 SKILL.md 指令 + shell 脚本

## 快速开始

### 前置条件

- [OpenClaw](https://github.com/openclaw/openclaw) 已安装配置
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 已认证（`claude auth status`）
- 已安装 `jq`（`sudo apt install jq`）
- 已安装 `git`

### 安装

```bash
# 从 ClawdHub 安装
clawdhub install claw-pilot

# 或手动安装
cd ~/.openclaw/workspace/skills/
git clone https://github.com/horacehxw/claw-pilot.git
```

### 配置

```bash
# 创建运行时目录（不在 skill 仓库内）
mkdir -p ~/.openclaw/supervisor/tasks

# 允许 agent 访问 workspace 外的文件
openclaw config set tools.fs.workspaceOnly false
openclaw gateway restart

# 给脚本加执行权限
chmod +x ~/.openclaw/workspace/skills/claw-pilot/scripts/*.sh
```

### 使用

在 IM（飞书/Slack 等）中：

```
/dev 给 auth 模块加 JWT 支持
```

Agent 会：
1. 通过 CC 生成方案 → 呈现给你审批
2. 在 git worktree 中执行 → 监控进度
3. 跑测试 + 生成 diff → 汇报结果
4. 你确认后合并 → 清理

其他命令：

```
/task list              — 列出所有任务
/task status jwt-auth   — 查看任务详情
/task cancel jwt-auth   — 终止并清理
/task approve jwt-auth  — 审批待定方案
```

## 架构

```
claw-pilot/                          # Skill 源码（本仓库）
├── SKILL.md                         # Agent 指令
├── scripts/                         # Shell 脚本
└── templates/CLAUDE.md.tpl          # 注入到工作树

~/.openclaw/supervisor/tasks/        # 运行时数据（临时）
└── jwt-auth/
    ├── task.json, output.json, cc.pid, session_id, status

~/.worktrees/jwt-auth/               # Git 工作树（临时）
├── .supervisor/progress.json        # CC 写进度
├── CLAUDE.md                        # Supervisor Protocol
└── ...项目文件...
```

三层分离：源码 / 运行时数据 / 工作树 — 各有独立生命周期。

## 许可证

[MIT](LICENSE)
