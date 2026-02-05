(array/push
  (config :xkb-bindings)
  [:XF86MonBrightnessUp {} (action/spawn ["brightnessctl" "set" "10%+"])]
  [:XF86MonBrightnessDown {} (action/spawn ["brightnessctl" "set" "10%-"])]
  [:XF86AudioRaiseVolume {} (action/spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-l" "1"])]
  [:XF86AudioLowerVolume {} (action/spawn ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" "-l" "1"])]
  [:XF86AudioMute {} (action/spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"])]
  [:XF86AudioMicMute {} (action/spawn ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"])]
  [:XF86AudioPause {} (action/spawn ["playerctl" "play-pause"])]
  [:XF86AudioPlay {} (action/spawn ["playerctl" "play-pause"])]
  [:XF86AudioNext {} (action/spawn ["playerctl" "next"])]
  [:XF86AudioPrev {} (action/spawn ["playerctl" "previous"])]
  [:XF86Eject {} (action/spawn ["eject" "-T"])]
  [:0x1008ff41 {} (action/spawn ["chromium"])]
  [:b {:mod4 true} (action/spawn ["chromium"])]
  [:t {:mod4 true} (action/spawn ["kitty"])]
  [:r {:mod4 true} (action/spawn ["rofi" "-show" "drun"])]
  [:q {:mod4 true} (action/close)]
  [:space {:mod4 true} (action/zoom)]
  [:p {:mod4 true} (action/focus :prev)]
  [:n {:mod4 true} (action/focus :next)]
  [:k {:mod4 true} (action/focus-output)]
  [:j {:mod4 true} (action/focus-output)]
  [:f {:mod4 true} (action/fullscreen)]
  [:f {:mod4 true :mod1 true} (action/float)]
  [:a {:mod4 true} (action/spawn ["sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"])]
  [:Escape {:mod4 true :mod1 true :shift true :ctrl true} (action/passthrough)]
  [:0 {:mod4 true} (action/focus-all-tags)])

(for i 1 10
  (def keysym (keyword i))
  (array/push
    (config :xkb-bindings)
    [keysym {:mod4 true} (action/focus-tag i)]
    [keysym {:mod4 true :mod1 true} (action/set-tag i)]
    [keysym {:mod4 true :mod1 true :shift true} (action/toggle-tag i)]))

(array/push
  (config :pointer-bindings)
  [:left {:mod4 :true} (action/pointer-move)]
  [:right {:mod4 :true} (action/pointer-resize)])
