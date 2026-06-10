# Rijan Window Manager Fork Guide

Rijan 是一个运行在 River Wayland compositor 之上的 Janet 窗口管理器。River 负责 Wayland、输入、输出、协议和底层 compositor 工作；Rijan 负责窗口如何排列、聚焦、移动、切换、热重载和响应按键。

这个 fork 在原版 Rijan 的基础上加入了更完整的日用功能：多布局、libinput 配置、rules DSL、子窗口处理、waybar 焦点修复、热重载回滚、键盘控制浮动窗口，以及更稳的错误隔离。

## 当前文件

- `rijan.janet.patched`：主窗口管理器源码。
- `init.janet`：用户配置、按键绑定、自启动、输入设备配置。
- `scripts/ensure-zig-0.15.sh`：Arch 下自动安装/降级 Zig 0.15 的辅助脚本。
- `PKGBUILD`：打包构建文件，当前要求 Zig `>=0.15,<0.16`。

## 构建要求

当前 Rijan 依赖的 Zig/Wayland Janet 包还没有适配 Zig 0.16，所以必须使用 Zig 0.15.x。

```bash
zig version
```

如果显示 `0.16.x`，先执行：

```bash
./scripts/ensure-zig-0.15.sh
```

然后构建：

```bash
makepkg -Csf --holdver
```

说明：

- `-C`：清理旧 build 目录。
- `-s`：自动安装缺失依赖。
- `-f`：已有包时强制重新构建。
- `--holdver`：不更新 git source 到最新 commit，使用当前固定版本。

## 启动流程

River 启动后加载 Rijan。Rijan 启动时会读取：

```text
~/.config/rijan/init.janet
```

也可以通过启动参数传入自定义 init 路径。源码会把当前路径写进 `config :init-path`，所以之后按热重载快捷键仍然会重载同一个文件。

## init.janet 的结构

当前 `init.janet` 分为四段：

1. 路径和常量
2. 工具函数、输入设备、rules
3. 按键绑定
4. 首次启动序列

路径统一从 `$HOME` 推导，不再硬编码 `/home/xxx`：

```janet
(def- home (os/getenv "HOME"))

(def paths {
  :waybar-conf   (string home "/.config/river/statusbar/waybar/config.json")
  :waybar-css    (string home "/.config/river/statusbar/waybar/river_style.css")
  :wallpaper     (string home "/.config/river/wallpapers/blackhole.gif")
  :dunst-conf    (string home "/.config/dunst/dunstrc")
  :mihomo-script (string home "/.config/river/scripts/mihomo_status.sh")
  :volume-script (string home "/.config/river/scripts/volume-notify.sh")
})
```

这样换机器、换用户名时不需要改绝对路径。

## 热重载

当前快捷键：

```text
Mod4 + Shift + F5
```

对应：

```janet
(action/reload-config)
```

热重载现在有三个重要行为：

1. 先保存当前可用配置。
2. 把 `config` 重置回源码默认值。
3. 再重新执行 `init.janet`。

如果 `init.janet` 报错，会完整恢复旧配置，不会留下半坏状态。

这解决了一个旧问题：以前你从 `init.janet` 删除某个 `(put config :xxx ...)` 后，F5 热重载可能仍然保留旧值。现在不会，因为 reload 前会先回到默认配置。

## 首次启动和热重载的区别

`init.janet` 末尾的自启动段现在包在：

```janet
(unless (config :reloading)
  ...)
```

所以：

- 第一次登录启动 Rijan：会启动 waybar、dunst、fcitx5、壁纸、swayidle、gsettings。
- 按 `Mod4+Shift+F5` 热重载：只重载 Rijan 配置，不重复跑这些登录初始化命令。

这是为了避免 F5 时重复启动或重置桌面环境。

## 自启动

首次启动会执行：

- `dbus-update-activation-environment`
- `fcitx5 -d`
- `systemctl --user start awww.service`
- `awww img <wallpaper>`
- `waybar`
- `dunst`
- GTK/icon/cursor/color-scheme 的 `gsettings`
- `swayidle`

`spawn-once` 用 `pgrep -x` 避免重复进程；`spawn-bg` 会把命令放后台执行，避免一个程序卡住拖死整个 init。

## 输入设备配置

当前启用：

```janet
(put config :tap-to-click true)
(put config :tap-button-map :lrm)
(put config :tap-drag true)
(put config :tap-drag-lock true)
(put config :three-finger-drag true)
(put config :accel-profile :adaptive)
(put config :natural-scroll true)
(put config :dwt true)
(put config :dwtp true)
(put config :middle-emulation true)
(put config :click-method :clickfinger)
(put config :clickfinger-button-map :lrm)
(put config :scroll-method :two-finger)
(put config :rotation 0)
```

注意：

- `three-finger-drag` 是“三指拖拽模拟按住左键”，不是三指手势切工作区。
- 它只有设备和 River/libinput 协议都报告支持时才会生效。
- `scroll-button-lock` 只对 `:scroll-method :on-button-down` 有意义；当前使用双指滚动，所以默认不启用。

## libinput 协议

当前源码启用了：

```text
river-input-management-v1
river-libinput-config-v1
```

它们的作用是让 Rijan 可以在运行时给输入设备下发 libinput 配置，例如：

- tap-to-click
- tap-drag
- drag-lock
- three-finger-drag
- accel-profile
- natural-scroll
- click-method
- middle-emulation
- scroll-method
- dwt / dwtp
- rotation

Rijan 不会盲目设置所有选项。设备上报支持后，才会应用对应配置。

## Rules DSL

rules 写在 `init.janet`：

```janet
(array/push
  (config :rules)
  [:title "~Picture-in-Picture" {:float true :sticky true}]
  [:title "~画中画" {:float true :sticky true}])
```

格式是：

```janet
[matcher pattern actions]
```

`matcher` 支持：

- `:app-id`
- `:title`

`pattern` 规则：

- 普通字符串：精确匹配。
- 以 `~` 开头：子串包含匹配。

重要：这里不是 regex，也不是 PEG。`~Picture-in-Picture` 的意思是“标题里包含 Picture-in-Picture”，特殊字符不会按正则解释。

`actions` 支持：

```janet
{:tag 2}
{:float true}
{:sticky true}
{:fullscreen true}
```

当前源码对每条 rule 单独 `protect`。坏 rule 只会打印：

```text
rule error: ...
```

不会打断新窗口管理流程，也不会导致 terminal 出现但拿不到焦点。

## 焦点系统

当前焦点逻辑被拆成几个小函数：

- `seat/resolve-focus-target`：决定应该聚焦谁。
- `seat/apply-focus`：实际调用 compositor 聚焦窗口。
- `seat/clear-focus`：清空焦点。
- `seat/focus`：统一处理普通窗口和 layer-shell 焦点。
- `seat/resolve-focus`：在每轮 manage 中处理新窗口、交互窗口、焦点返回。

这样比原来一大坨 `seat/manage` 更容易维护。

### waybar 焦点修复

waybar 属于 layer-shell。点击 waybar 之后，compositor 可能把键盘焦点交给 layer surface，导致 terminal 看起来还是 focused，但打不了字。

当前修复逻辑在 `:non-exclusive` layer focus 分支里：

```janet
(when-let [focused (seat :focused)]
  (:focus-window (seat :obj) (focused :obj)))
```

意思是：如果 waybar 这类 non-exclusive layer 交互结束后，Rijan 仍然认为某个窗口是当前 focused，就主动把 compositor 键盘焦点重新交还给这个窗口。

## 子窗口和弹窗

当前源码会识别：

- 正常 top-level window
- 有真实 parent 的 transient window
- XWayland client-leader 造成的 parent event 但 parent 为 nil 的窗口
- popup-like child window

子窗口行为：

- 默认 floating。
- 尽量跟随 parent 的 tag。
- 不轻易抢走主窗口焦点。
- 关闭后尽量把焦点返回 parent。
- 如果没有真实 parent，会用 app-id 寻找 logical parent，并居中到父窗口附近。

这主要是为了处理微信、登录框、文件选择器、XWayland 弹窗等复杂场景。

## 布局系统

当前支持：

- `:tile`
- `:scroller`
- `:grid`
- `:monocle`

切换快捷键：

```text
Mod4 + Alt + t    tile
Mod4 + Alt + s    scroller
Mod4 + Alt + g    grid
Mod4 + Alt + m    monocle
Mod4 + Alt + Tab  previous layout
```

### Tile

master-stack 布局，支持方向：

```text
Mod4 + Alt + h    master left
Mod4 + Alt + l    master right
Mod4 + Alt + k    master top
Mod4 + Alt + j    master bottom
```

### Scroller

类似 PaperWM/niri：当前 focused window 是主窗口，左右邻居向外展开，超出屏幕的窗口会隐藏。

默认宽度：

```janet
(put config :scroller-mfact 0.65)
```

调整当前窗口宽度：

```text
Mod4 + Shift + l    +0.05
Mod4 + Shift + h    -0.05
```

当前修复后，第一次调整会从 `:scroller-mfact` 起算，而不是从 `:main-ratio` 起算。

### Grid

自动根据窗口数量计算行列，最后一行会居中。

### Monocle

所有 tiled window 占满可用区域。

## 浮动窗口操作

鼠标：

```text
Mod4 + left-click   move
Mod4 + right-click  resize
```

键盘移动：

```text
Mod4 + Ctrl + Shift + h/j/k/l
```

键盘缩放：

```text
Mod4 + Alt + Shift + h/j/k/l
```

边缘吸附：

```text
Mod4 + Alt + Ctrl + h/j/k/l
```

这些只对 floating window 生效。

## 工作区和窗口操作

基础快捷键：

```text
Mod4 + t        kitty
Mod4 + b        qutebrowser
Mod4 + r        rofi drun
Mod4 + q        close
Mod4 + space    zoom
Mod4 + f        fullscreen
Mod4 + Alt + f  float
Mod4 + Shift+r  retile
```

焦点：

```text
Mod4 + p / n    previous / next window
Mod4 + k / j    previous / next output
```

窗口交换：

```text
Mod4 + Shift + j/k
```

发送窗口到其他输出：

```text
Mod4 + Ctrl + j/k
```

Sticky：

```text
Mod4 + Ctrl + s
```

Tags：

```text
Mod4 + 1..9               focus tag
Mod4 + Alt + 1..9         move window to tag
Mod4 + Alt + Shift + 1..9 toggle tag
Mod4 + 0                  show all tags
```

## 错误处理

核心 manage/render loop 被 `protect` 包住：

```text
wm/manage error: ...
wm/render error: ...
```

作用：某个半初始化 XWayland 窗口或坏 rule 报错时，尽量不让整个 WM 死掉。

但这不是让错误“消失”。它只是保证 Rijan 还能继续工作。真正出错仍然应该修配置或源码。

## REPL 调试

Rijan 启动后会创建 netrepl socket：

```text
$XDG_RUNTIME_DIR/rijan-$WAYLAND_DISPLAY
```

连接：

```bash
janet -e '(import spork/netrepl) (netrepl/client :unix (string (os/getenv "XDG_RUNTIME_DIR") "/rijan-" (os/getenv "WAYLAND_DISPLAY")))'
```

常用检查：

```janet
(wm :windows)
(wm :outputs)
(each output (wm :outputs) (print (output :layout)))
(each seat (wm :seats) (print (seat :focused)))
```

不要随便在 REPL 里 `(os/exit)` 或破坏 `wm` 表，除非你准备重启图形会话。

## 故障排查

### 黑屏

优先检查 `init.janet` 语法：

```bash
janet -e '(parse-all (slurp "init.janet"))'
```

如果是刚改输入设备配置后黑屏，先注释掉这些高风险项测试：

```janet
(put config :click-method :clickfinger)
(put config :scroll-method :two-finger)
```

某些设备/协议组合可能不支持特定 libinput 设置。

### terminal 打开但不能输入

常见原因是焦点丢失。当前源码已经修了 waybar non-exclusive layer 后的 focus reassert。如果仍出现，检查：

- 是否点了某个 layer-shell 程序后发生。
- journal/tty 是否有 `wm/manage error` 或 `rule error`。
- rules 是否写错。

### Picture-in-Picture rule 不生效

确认标题包含：

```text
Picture-in-Picture
```

或者中文：

```text
画中画
```

rules 现在是子串匹配，不是正则。

### F5 后自启动没有重新跑

这是设计行为。`Mod4+Shift+F5` 只重载 Rijan 配置，不重复启动 waybar、dunst、wallpaper、swayidle。

如果你确实想手动重启 waybar，可以用：

```text
Mod4 + Shift + b
```

当前绑定会尝试：

```bash
pkill -USR1 waybar || waybar ...
```

### Zig 0.16 编译失败

这是预期问题。当前依赖还没适配 Zig 0.16。使用：

```bash
./scripts/ensure-zig-0.15.sh
makepkg -Csf --holdver
```

如果 pacman 升级后又变回 Zig 0.16，可以在 `/etc/pacman.conf` 加：

```ini
IgnorePkg = zig
```

## 当前设计原则

这个 fork 的重点不是把 Rijan 变成一个庞大的桌面环境，而是保持 Janet 可读、可热重载，同时补足日用窗口管理必需功能。

核心原则：

- `init.janet` 管用户配置。
- `rijan.janet.patched` 管窗口管理逻辑。
- 自启动只在首次登录执行。
- 热重载必须干净、可回滚。
- rules 错误不能影响新窗口焦点。
- layer-shell 不应该让 terminal 永久丢键盘焦点。
- 输入设备配置只在设备报告支持时应用。
- 路径从 `$HOME` 推导，不写死用户名。
