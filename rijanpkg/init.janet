# ============================================================
# 1. 常量与环境路径 (单一事实来源)
# ============================================================
(def- home (os/getenv "HOME"))

(def paths {
  :waybar-conf   (string home "/.config/river/statusbar/waybar/config.json")
  :waybar-css    (string home "/.config/river/statusbar/waybar/river_style.css")
  :wallpaper     (string home "/.config/river/wallpapers/blackhole.gif")
  :dunst-conf    (string home "/.config/dunst/dunstrc")
  :mihomo-script (string home "/.config/river/scripts/mihomo_status.sh")
  :volume-script (string home "/.config/river/scripts/volume-notify.sh")
})

# ============================================================
# 2. 核心工具函数 (通知、重载与容错)
# ============================================================

# [桌面通知]
(defn- notify [msg &opt title level]
  (default title "Rijan 系统")
  (default level "normal")
  (ev/spawn
    (os/proc-wait (os/spawn ["notify-send" "-a" "Rijan" "-u" level title msg] :p))))

# [Waybar 启动指令定义]
(def waybar-cmd (string "waybar -c '" (paths :waybar-conf) "' -s '" (paths :waybar-css) "'"))

(defn- spawn-bg [cmd]
  (ev/spawn
    (os/proc-wait
      (os/spawn ["sh" "-c"
                 (string "( " cmd " ) > /dev/null 2>&1 &")]
                :p))))

(defn- spawn-once [process cmd]
  (spawn-bg
    (string "pgrep -x '" process "' > /dev/null || " cmd)))

# [光标主题说明] {{{
# :xcursor-theme 字符串，光标主题名；必须是系统 icon/cursor 主题里实际存在的名字。
# :xcursor-size  整数，光标大小，单位是像素。
# }}}

# [光标主题]
(put config :xcursor-theme "broodwar")
(put config :xcursor-size 24)

# [输入设备说明] {{{
# 布尔类选项一般是 true/false；Rijan 只会在设备报告支持时应用。
# :send-events
#   控制输入设备是否发送事件。默认不设置时使用设备/river 默认值，通常就是正常启用。
#   :enabled                    = 正常发送输入事件。
#   :disabled                   = 禁用该设备输入事件。
#   :disabled-on-external-mouse = 检测到外接鼠标时禁用该设备，常用于触摸板。
#   当前保持默认正常，不主动设置：
# (put config :send-events :enabled)
# :tap-to-click
#   true  = 轻触触摸板当点击。
#   false = 禁用轻触点击。
# :tap-button-map
#   :lrm = 一指/二指/三指轻触分别映射为 left/right/middle。
#   :lmr = 一指/二指/三指轻触分别映射为 left/middle/right。
# :tap-drag
#   true  = 轻点后拖动可以模拟按住鼠标拖拽。
#   false = 禁用轻点拖拽。
# :tap-drag-lock
#   true 或 :enabled-timeout = 拖拽中短暂抬手再放回去，仍继续拖拽。
#   :enabled-sticky        = 更粘滞的拖拽锁定模式。
#   false 或 :disabled     = 抬手后立即结束拖拽。
# :three-finger-drag
#   true 或 :enabled-3fg = 三指移动模拟按住左键拖拽。
#   :enabled-4fg        = 四指移动模拟按住左键拖拽。
#   false 或 :disabled  = 禁用。
#   注意：这不是“三指滑动手势动作”，不会切 tag 或触发快捷键。
# :accel-profile
#   :adaptive = 自适应加速度，适合触摸板。
#   :flat     = 线性加速度，适合外接鼠标/精确控制。
#   :none     = 不选择具体 profile。
#   :custom   = 协议支持，但当前 init 没有提供 custom accel config，不建议用。
# :natural-scroll
#   true  = 自然滚动，手指向上内容向上，类似触屏/macOS。
#   false = 传统滚动方向。
# :dwt
#   disable-while-typing。true = 打字时临时禁用触摸板，减少误触。
# :dwtp
#   disable-while-trackpointing。true = 使用小红点/trackpoint 时临时禁用触摸板。
# :middle-emulation
#   true = 同时按左右键时模拟中键。
# :click-method
#   :clickfinger  = 按下触摸板时按手指数判断键：一指左键、二指右键、三指中键。
#   :button-areas = 触摸板底部区域分左右键。
#   :none         = 不设置点击方法。
# :clickfinger-button-map
#   只在 :click-method 为 :clickfinger 时有意义。
#   :lrm = 一指/二指/三指按压分别是 left/right/middle。
#   :lmr = 一指/二指/三指按压分别是 left/middle/right。
# :scroll-method
#   :two-finger     = 双指滚动。
#   :edge           = 边缘滚动。
#   :on-button-down = 按住指定按钮移动时滚动，需要配合 :scroll-button。
#   :no-scroll      = 禁用滚动。
# :scroll-button-lock
#   true/false，只有 :scroll-method 为 :on-button-down 时才有意义。
#   true = 按一下滚动按钮后锁定滚动模式；false = 必须一直按住按钮。
# :rotation
#   输入设备坐标顺时针旋转角度，整数范围为 0 到 359。
#   常见值：0、90、180、270。普通触摸板通常保持 0。
# }}}

# [输入设备]
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
# 只在 :scroll-method 为 :on-button-down 时有意义；双指滚动时保持默认。
# (put config :scroll-button-lock true)
(put config :rotation 0)

# [布局默认值说明] {{{
# :scroller-mfact
#   scroller 布局中窗口默认宽度比例；未设置时回退到 :main-ratio。
#   建议范围 0.1 到 0.9。当前 0.65 表示当前窗口默认占可用宽度 65%。
# }}}

# [布局默认值]
(put config :scroller-mfact 0.65)

# [窗口规则说明] {{{
# rules 条目格式：
#   格式为 matcher、pattern、actions 三项。
# matcher:
#   :app-id = 匹配窗口 app-id。
#   :title  = 匹配窗口标题。
# pattern:
#   普通字符串 = 精确匹配。
#   以 "~" 开头 = 子串包含匹配，例如 "~Picture-in-Picture"。
#   注意：这里不是正则/PEG，特殊字符不会按正则语法解释。
# actions:
#   {:tag n}          = 放到指定 tag。
#   {:float true}    = 自动浮动。
#   {:sticky true}   = 在所有 tag 可见。
#   {:fullscreen true} = 自动全屏。
# }}}

# [窗口规则]
(array/push
  (config :rules)
  [:title "~Picture-in-Picture" {:float true :sticky true}]
  [:title "~画中画" {:float true :sticky true}])

# ============================================================
# 3. 按键绑定 (声明式逻辑)
# ============================================================
(array/push
  (config :xkb-bindings)
  # --- Waybar Toggle (最优解：信号隐藏 || 失败救活)
  [:m {:mod4 true} (action/spawn ["sh" (paths :mihomo-script) "toggle_mode"])]
  [:b {:mod4 true :shift true} (action/spawn ["sh" "-c" (string "pkill -USR1 waybar || " waybar-cmd " &")])]
  [:XF86MonBrightnessUp {} (action/spawn ["brightnessctl" "set" "10%+"])]
  [:XF86MonBrightnessDown {} (action/spawn ["brightnessctl" "set" "10%-"])]
  [:XF86AudioRaiseVolume {} (action/spawn ["sh" (paths :volume-script) "up"])]
  [:XF86AudioLowerVolume {} (action/spawn ["sh" (paths :volume-script) "down"])]
  [:XF86AudioMute {} (action/spawn ["sh" (paths :volume-script) "toggle"])]
  [:XF86AudioMicMute {} (action/spawn ["sh" (paths :volume-script) "mic"])]
  [:XF86AudioPause {} (action/spawn ["playerctl" "play-pause"])]
  [:XF86AudioPlay {} (action/spawn ["playerctl" "play-pause"])]
  [:XF86AudioNext {} (action/spawn ["playerctl" "next"])]
  [:XF86AudioPrev {} (action/spawn ["playerctl" "previous"])]
  [:XF86Eject {} (action/spawn ["eject" "-T"])]
  [:0x1008ff41 {} (action/spawn ["qutebrowser"])]
  [:b {:mod4 true} (action/spawn ["qutebrowser"])]
  [:t {:mod4 true} (action/spawn ["kitty"])]
  [:r {:mod4 true} (action/spawn ["rofi" "-show" "drun"])]
  [:q {:mod4 true} (action/close)]
  [:space {:mod4 true} (action/zoom)]
  [:p {:mod4 true} (action/focus :prev)]
  [:n {:mod4 true} (action/focus :next)]
  [:k {:mod4 true} (action/focus-output :prev)]
  [:j {:mod4 true} (action/focus-output :next)]
  [:f {:mod4 true} (action/fullscreen)]
  [:f {:mod4 true :mod1 true} (action/float)]
  [:r {:mod4 true :shift true} (action/retile)]
  [:F5 {:mod4 true :shift true} (action/reload-config)]
  [:a {:mod4 true} (action/spawn ["sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"])]
  [:Escape {:mod4 true :mod1 true :shift true :ctrl true} (action/passthrough)]
  [:BackSpace {:mod4 true :mod1 true :shift true :ctrl true} (action/exit-session)]
  [:0 {:mod4 true} (action/focus-all-tags)]

  # ---- 新增功能 ----

  # 窗口交换
  [:j {:mod4 true :shift true} (action/swap :next)]
  [:k {:mod4 true :shift true} (action/swap :prev)]

  # 发送窗口到其他输出
  [:j {:mod4 true :ctrl true} (action/send-to-output :next)]
  [:k {:mod4 true :ctrl true} (action/send-to-output :prev)]

  # 布局切换: Mod4+Alt+t/s/g
  [:t {:mod4 true :mod1 true} (action/set-layout :tile)]
  [:s {:mod4 true :mod1 true} (action/set-layout :scroller)]
  [:g {:mod4 true :mod1 true} (action/set-layout :grid)]
  [:m {:mod4 true :mod1 true} (action/set-layout :monocle)]
  [:Tab {:mod4 true :mod1 true} (action/switch-to-previous-layout)]

  # master 方向: Mod4+Alt+方向布局
  [:h {:mod4 true :mod1 true} (action/set-tile-location :left)]
  [:l {:mod4 true :mod1 true} (action/set-tile-location :right)]
  [:k {:mod4 true :mod1 true} (action/set-tile-location :top)]
  [:j {:mod4 true :mod1 true} (action/set-tile-location :bottom)]

  # main-ratio 调整
  [:l {:mod4 true} (action/set-main-ratio 0.05)]
  [:h {:mod4 true} (action/set-main-ratio -0.05)]

  # scroller 当前窗口宽度比例调整
  [:l {:mod4 true :shift true} (action/window-ratio 0.05)]
  [:h {:mod4 true :shift true} (action/window-ratio -0.05)]

  # nmaster 调整
  [:equal {:mod4 true} (action/set-nmaster 1)]
  [:minus {:mod4 true} (action/set-nmaster -1)]

  # sticky 窗口
  [:s {:mod4 true :ctrl true} (action/sticky)]

  # 浮动窗口键盘移动: Mod4+Ctrl+Shift+hjkl
  [:h {:mod4 true :ctrl true :shift true} (action/float-move -20 0)]
  [:l {:mod4 true :ctrl true :shift true} (action/float-move 20 0)]
  [:k {:mod4 true :ctrl true :shift true} (action/float-move 0 -20)]
  [:j {:mod4 true :ctrl true :shift true} (action/float-move 0 20)]

  # 浮动窗口键盘缩放: Mod4+Mod1+Shift+hjkl
  [:h {:mod4 true :mod1 true :shift true} (action/float-resize -20 0)]
  [:l {:mod4 true :mod1 true :shift true} (action/float-resize 20 0)]
  [:k {:mod4 true :mod1 true :shift true} (action/float-resize 0 -20)]
  [:j {:mod4 true :mod1 true :shift true} (action/float-resize 0 20)]

  # 浮动窗口吸附屏幕边缘: Mod4+Mod1+Ctrl+hjkl
  [:h {:mod4 true :mod1 true :ctrl true} (action/float-snap :left)]
  [:l {:mod4 true :mod1 true :ctrl true} (action/float-snap :right)]
  [:k {:mod4 true :mod1 true :ctrl true} (action/float-snap :top)]
  [:j {:mod4 true :mod1 true :ctrl true} (action/float-snap :bottom)])

# [工作区 1-10 自动化循环生成]
(for i 1 10
  (let [tag (keyword i)]
    (array/push (config :xkb-bindings)
      [tag {:mod4 true} (action/focus-tag i)]
      [tag {:mod4 true :mod1 true} (action/set-tag i)]
      [tag {:mod4 true :mod1 true :shift true} (action/toggle-tag i)])))

(array/push
  (config :pointer-bindings)
  [:left {:mod4 true} (action/pointer-move)]
  [:right {:mod4 true} (action/pointer-resize)])
# ============================================================
# 4. 首次启动序列
# ============================================================
# 热重载时只更新 Rijan 配置；这些登录初始化命令只在首次启动执行。
(unless (config :reloading)
  # 环境同步可以串行；桌面程序必须彼此独立，避免一个失败拖死 waybar。
  (spawn-bg
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")

  (spawn-once "fcitx5" "fcitx5 -d")

  # 登录时只启动服务，不强制 restart，避免 stop/start 时序和超时影响状态栏。
  (spawn-bg "systemctl --user start awww.service")
  (spawn-bg (string "sleep 1; awww img '" (paths :wallpaper) "'"))

  (spawn-once "waybar" waybar-cmd)
  (spawn-once "dunst" (string "dunst -config '" (paths :dunst-conf) "'"))

  # ── GNOME/GTK 主题设置 ──
  (spawn-bg (string
    "gsettings set org.gnome.desktop.interface gtk-theme Orchis-dark; "
    "gsettings set org.gnome.desktop.interface icon-theme tela-circle-dark; "
    "gsettings set org.gnome.desktop.interface cursor-theme broodwar; "
    "gsettings set org.gnome.desktop.interface cursor-size 24; "
    "gsettings set org.gnome.desktop.interface color-scheme prefer-dark; "
    "gsettings set org.gnome.desktop.wm.preferences button-layout ''"
  ))

  # ── 显示器电源管理 ──
  # 先终止旧的 swayidle 进程，再启动新实例
  # 300 秒无操作关闭所有显示器，恢复操作时重新打开
  (spawn-bg
    "pkill -x swayidle; swayidle -w timeout 300 'wlopm --off \"*\"' resume 'wlopm --on \"*\"'")

  # [初始化完成通知]
  (notify "所有服务已就绪" "Rijan 启动完成"))

# vim: set foldmethod=marker foldlevel=0 foldenable:
