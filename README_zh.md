# coding-pm

[English](README.md) | [中文](README_zh.md)

[![GitHub release](https://img.shields.io/github/v/release/horacehxw/coding-pm?include_prereleases&style=for-the-badge)](https://github.com/horacehxw/coding-pm/releases)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8A2BE2?style=for-the-badge)](https://github.com/openclaw/openclaw)

> [OpenClaw](https://github.com/openclaw/openclaw) 的 PM/QA Skill，管理编码 agent 作为后台工程师。与 [coding-agent](https://github.com/openclaw/openclaw) 互补：agent 执行，PM 管理。

**PM**（Project Manager，项目经理）确保需求被覆盖、流程被遵循、结果达到质量标准。**QA**（Quality Assurance，质量保证）通过自动化测试、功能检查和视觉检查验收交付物。coding-pm 同时扮演这两个角色 — 从方案到合并，全程管理 coding-agent 的工作，你无需亲自操心。

```
你 (IM)  →  coding-pm (PM/QA)  →  coding-agent (工程师, 后台执行)
```

## 特性

- **5 阶段工作流**：预处理 → 方案审查 → 执行监控 → 验收测试 → 合并清理
- **非阻塞**：coding-agent 后台运行，你的对话保持响应
- **PM 管人不管技术**：审查需求覆盖、流程合规、结果质量 — coding-agent 负责所有技术决策
- **主动监控**：每 30-60 秒轮询，解析结构化标记，向你推送进度
- **三层验收测试**：自动化测试 + 功能集成测试 + 截图分析
- **Git worktree 隔离**：每个任务独立分支和工作树
- **并发支持**：多个任务同时运行，互相独立隔离
- **多 Agent 支持**：Claude Code、Codex、OpenCode、Pi
- **人在回路**：方案审批门、决策上报、错误重试（最多 3 轮）
- **任务生命周期**：暂停、恢复、取消 — 完全掌控后台任务
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
1. 探索项目上下文，为 coding-agent 组装结构化 prompt
2. coding-agent 调研并产出方案 → PM 审查 → 呈现给你审批
3. 在 git worktree 中执行 → 主动监控并推送进度
4. 运行验收测试（自动化 + 功能 + 视觉）→ 汇报结果
5. 你确认后合并 → 清理

任务命令：

```
/task list              — 列出所有任务的阶段和状态
/task status jwt-auth   — 查看任务详情和最近的检查点
/task cancel jwt-auth   — 终止并清理
/task approve jwt-auth  — 审批待定方案
/task pause jwt-auth    — 暂停任务，保留状态
/task resume jwt-auth   — 恢复已暂停的任务
/task progress jwt-auth — 查看最近的检查点
/task plan jwt-auth     — 查看已审批的方案
```

## 与 coding-agent 的区别

| | coding-agent | coding-pm |
|--|-------------|-----------|
| 定位 | Cookbook（教你怎么用 agent） | PM/QA（帮你管 agent） |
| 方案审查 | 无 | PM 审查需求覆盖 + 用户审批门 |
| 监控 | 无 | 主动循环：标记、提交、异常检测 |
| 测试验证 | 无 | 三层：自动化 + 功能 + 视觉 |
| 报告 | 手动 | 按检查点结构化推送进度 |
| 错误处理 | 用户手动处理 | 自动重试（3 轮）+ 智能上报 |
| 并发 | 单任务 | 多任务独立运行 |
| Worktree | 手动管理 | 自动创建/合并/清理 |

## 架构

```
coding-pm/
  SKILL.md                          # PM 大脑 — 5 阶段工作流逻辑
  references/
    supervisor-prompt.md            # 注入 worktree 作为 CLAUDE.md
  CLAUDE.md                         # 开发指南
```

无自定义脚本。使用 OpenClaw 内置的 `bash`（pty/background/workdir）和 `process`（poll/log/kill/list/write）工具。

## 系统要求

| 组件 | 版本 |
|------|------|
| OpenClaw | 2026.2.19+ |
| git | 2.20+（worktree 支持） |
| 编码 agent | Claude Code 2.1.0+ / Codex / OpenCode / Pi |

## 许可证

[MIT](LICENSE)
