> 🌐 语言: 简体中文 | [English](README.md)

# hermes-desktop-ui-tweaks

给 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 桌面端用的本地 UI 补丁包,外加一个在每次 `hermes update` 之后重新应用补丁的脚本。

## 要解决的问题

Hermes Desktop 是打包发布的应用:改源码 → `npm run pack` 重打包 → 改动生效。但 `hermes update` 会把 git 检出重置到 `origin/main`(main 上的本地 commit 会被 `reset --hard` 丢弃)并自动重建 app——每次更新,本地改动全部消失。

## 包含内容

两个针对 `apps/desktop/src/` 的补丁,在 Hermes v2026.7.x(2026 年 9 月)上开发并验证:

| 补丁 | 作用 |
|---|---|
| `0001-collapse-sessions-section-shell.patch` | 左侧栏 Sessions 区块折叠时收起外壳,让下面的 Messaging / Cron 区块向上回流,不再留空白。 |
| `0002-cron-jobs-tab-right-sidebar.patch` | 右侧栏新增 **定时任务 tab**(`FILES \| CRON`)。列出所有定时任务:状态点 + 下次运行倒计时;悬停可立即触发/管理,右键可暂停/恢复/删除,点开行可看最近运行记录并跳转对应会话。复用左侧栏 cron 区块的行组件和共享 `$cronJobs` 数据源,不重复实现逻辑。 |

外加 `scripts/apply-and-repack.sh`:重新应用两个补丁、跑侧边栏测试、重新打包 app。

## 用法

**前提:** 一份能跑起来的 Hermes 源码检出且依赖已装好(默认路径 `~/.hermes/hermes-agent`;不在这个路径时用 `HERMES_REPO=/path/to/hermes-agent` 指定)。

每次 `hermes update` 之后,两种方式任选:

```bash
# 1. 命令行
scripts/apply-and-repack.sh

# 2. 或在访达里双击仓库根目录的 apply-and-repack.command——它会打开终端
#    跑同一个脚本。不会往你的桌面安装任何东西。
```

预期输出:

```
→ applying: desktop: cron jobs tab in the right sidebar (FILES | CRON)   # 或: ✓ already applied, skipping
→ running sidebar tests...   # ✓ 通过(node_modules 缺失时跳过)
→ packing the desktop app (~2 min, the app may stay open)...
✅ Done. Quit Hermes (⌘Q) and relaunch — changes load on restart.
```

**结果:** 重开 Hermes 后,右侧栏出现 `FILES | CRON` 两个 tab;左侧栏 Sessions 折叠后不再挡住下面的 Messaging/Cron 区块。

脚本是幂等的:已在代码里的补丁会被检出(reverse-apply 检查)并跳过。如果上游改了同样的代码行,`git am --3way` 会停下报冲突,不会硬合。

## 开发思路(怎么做的)

桌面的右侧栏不是独立组件,而是一个 pane 系统(`components/pane-shell/tree/`):pane 注册时声明 `placement` 和可选的 `dock: { pane, pos }` 停靠提示;不在布局树里的 pane 会通过 `insertAtGroup` 自动入树,`pos: 'center'` 表示叠成锚点 pane 所在分组的一个 tab。

所以整个功能只有三件事:

1. 注册一个新 pane(`id: 'cron'`,`placement: 'right'`,`dock: { pane: 'files', pos: 'center' }`),渲染一个很薄的列表组件。
2. 一行 `bindPaneVisibility('cron', …)`,绑定与文件栏完全相同的原子状态,且绑定顺序在 files **之前**——打开右侧栏时最后执行的 unhide 决定哪个 tab 在前,这样文件树仍是默认 tab。
3. 全部复用:行组件、状态点、任务标题逻辑、触发控制器、共享 `$cronJobs` 原子都来自已有的左侧栏 cron 区块和 cron 页面。

`controller.tsx` 里约 30 行新胶水代码 + 一个新 pane 组件 + 给已有组件加三个 `export`。零新依赖。

## 注意事项

- 补丁锚定写作时的上游版本(v2026.7.x,2026-09)。更新版本上 `git am --3way` 通常仍能落上;冲突就手工解决——上面的开发思路说明了每个改动的意图。
- 这是个人补丁包,与 Nous Research 无关。更新 Hermes 后不跑脚本只是回到官方原版,不会搞坏 app。

## 🙏 致谢

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) — Nous Research,MIT License。本包的补丁在本地修改其桌面端源码;除补丁上下文行外,没有再分发上游代码。

## License

MIT — 见 [LICENSE](LICENSE)。
