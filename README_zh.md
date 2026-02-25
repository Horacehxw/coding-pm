# coding-pm

[English](README.md) | 中文

> [OpenClaw](https://github.com/openclaw/openclaw) 的 PM/QA Skill，管理编码 agent（Claude Code、Codex、OpenCode、Pi）作为后台工程师。与 [coding-agent](https://github.com/openclaw/openclaw) 互补：agent 执行，PM 管理。

```
你 (IM)  →  OpenClaw Agent (PM/QA)  →  编码 Agent (工程师, 后台执行)
```

你的 OpenClaw agent 变身项目经理：给编码 agent 派任务、审查方案、监控进度、跑验收、汇报结果 — 全程不阻塞你的对话。

## 特性

- **Plan → 审批 → 执行 → 验收 → 合并** 完整工作流
- **非阻塞**：编码 agent 后台运行，agent 保持响应
- **Git worktree 隔离**：每个任务独立分支和工作树
- **多 Agent 支持**：Claude Code、Codex、OpenCode、Pi
- **人在回路**：方案审批门、决策上报、错误重试
- **自动测试验证**：检测并运行项目测试套件
- **纯 SKILL.md**：零脚本，使用 OpenClaw 平台工具

## 快速开始

### 前置条件

- [OpenClaw](https://github.com/openclaw/openclaw) 已安装配置
- 至少一个编码 agent CLI：
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`claude auth status`）
  - [Codex](https://github.com/openai/codex) / [OpenCode](https://github.com/opencode-ai/opencode) / [Pi](https://github.com/anthropics/pi)
- 已安装 `git`

### 安装

```bash
# 从 ClawdHub 安装
clawdhub install coding-pm

# 或手动安装
cd ~/.openclaw/workspace/skills/
git clone https://github.com/horacehxw/coding-pm.git
```

### 配置

```bash
# 允许 agent 访问 workspace 外的文件（用于 worktree）
openclaw config set tools.fs.workspaceOnly false
openclaw gateway restart
```

### 使用

在 IM（飞书/Slack 等）中：

```
/dev 给 auth 模块加 JWT 支持
```

Agent 会：
1. 通过编码 agent 生成方案 → 呈现给你审批
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

## 与 coding-agent 的区别

| | coding-agent | coding-pm |
|--|-------------|-----------|
| 定位 | Cookbook（教你怎么用 agent） | PM/QA（帮你管 agent） |
| 方案审查 | 无 | Agent 审查 + 用户审批门 |
| 测试验证 | 无 | 自动检测并运行测试套件 |
| 报告 | 手动 | 结构化（测试/diff/成本） |
| 错误处理 | 用户手动处理 | 自动重试 + 智能上报 |
| Worktree | 手动管理 | 自动创建/合并/清理 |

## 许可证

[MIT](LICENSE)
