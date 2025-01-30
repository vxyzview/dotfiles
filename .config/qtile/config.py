import os
import subprocess
from libqtile import bar, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

# ---------------------------- #
#       Config Constants       #
# ---------------------------- #
class Config:
    # Appearance
    BAR_HEIGHT = 28
    BAR_COLOR = "#0A0D09"
    TEXT_COLOR = "#667855"
    FONT = "JetBrainsMono Nerd Font"
    FONT_SIZE = 13
    
    # Icons
    GROUP_ICON = "󰝥"
    LAUNCHER_ICON = ""
    BATTERY_ICON = ""
    CLOCK_ICON = "󰥔"
    POWER_ICON = "⏻"
    
    # Applications
    TERMINAL = guess_terminal() or "alacritty"
    LAUNCHER = "rofi -show drun"
    FILE_MANAGER = "thunar"
    
    # Layout
    MARGIN = 14
    BORDER_WIDTH = 0

# ---------------------------- #
#        Auto-Startup          #
# ---------------------------- #
@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser("~")
    scripts = [
        f"{home}/.setup",
        "nm-applet",
        "blueman-applet",
        "xfce4-power-manager"
    ]
    
    for script in scripts:
        try:
            subprocess.Popen(script.split(), cwd=home)
        except FileNotFoundError:
            qtile.log.error(f"Failed to launch: {script}")

# ---------------------------- #
#      Keybindings Factory     #
# ---------------------------- #
def create_keys():
    keys = [
        # Window Control
        Key([mod], "h", lazy.layout.left()),
        Key([mod], "l", lazy.layout.right()),
        Key([mod], "j", lazy.layout.down()),
        Key([mod], "k", lazy.layout.up()),
        Key([mod], "space", lazy.layout.next()),
        
        # Layout Operations
        Key([mod, "shift"], "h", lazy.layout.swap_left()),
        Key([mod, "shift"], "l", lazy.layout.swap_right()),
        Key([mod, "control"], "h", lazy.layout.grow_left()),
        Key([mod, "control"], "l", lazy.layout.grow_right()),
        Key([mod], "n", lazy.layout.normalize()),
        
        # System Control
        Key([mod], "Return", lazy.spawn(Config.TERMINAL)),
        Key([mod], "x", lazy.spawn(Config.LAUNCHER)),
        Key([mod], "q", lazy.window.kill()),
        Key([mod, "control"], "r", lazy.reload_config()),
        Key([mod, "control"], "q", lazy.shutdown()),
    ]

    # Media Keys
    media_keys = [
        Key([], "XF86AudioMute", lazy.spawn("pamixer --toggle-mute")),
        Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer --decrease 5")),
        Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer --increase 5")),
        Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +10%")),
        Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 10%-")),
    ]
    
    return keys + media_keys

keys = create_keys()

# ---------------------------- #
#    Smart Workspace Groups    #
# ---------------------------- #
groups = [
    Group("1", label="", matches=[Match(wm_class="firefox")]),
    Group("2", label="", matches=[Match(wm_class=Config.TERMINAL)]),
    Group("3", label="", matches=[Match(wm_class="code")]),
    Group("4", label="", matches=[Match(wm_class="gimp")]),
    Group("5", label="", matches=[Match(wm_class="spotify")]),
    Group("6", label="", matches=[Match(wm_class="discord")]),
    Group("7", label="", matches=[Match(wm_class=Config.FILE_MANAGER)]),
    Group("8", label="", layout="max"),
    Group("9", label="", layout="floating"),
]

# ---------------------------- #
#    Adaptive Window Layouts   #
# ---------------------------- #
layouts = [
    layout.MonadTall(
        margin=Config.MARGIN,
        border_width=Config.BORDER_WIDTH,
        ratio=0.6
    ),
    layout.Max(),
    layout.Floating(
        border_width=Config.BORDER_WIDTH,
        float_rules=[
            *layout.Floating.default_float_rules,
            Match(wm_type="notification"),
            Match(wm_class="ark"),
            Match(title="File Operation Progress")
        ]
    ),
    layout.Bsp(
        margin=Config.MARGIN,
        border_width=Config.BORDER_WIDTH,
        fair=False
    )
]

# ---------------------------- #
#    Dynamic Status Bar        #
# ---------------------------- #
def create_status_bar():
    return bar.Bar(
        widgets=[
            widget.CurrentLayoutIcon(
                scale=0.7,
                foreground=Config.TEXT_COLOR
            ),
            widget.Spacer(length=8),
            widget.GroupBox(
                highlight_method="block",
                active=Config.TEXT_COLOR,
                inactive="#404040",
                this_current_screen_border=Config.BAR_COLOR,
                fontsize=Config.FONT_SIZE + 2,
                margin_y=4,
                padding_y=6
            ),
            widget.Prompt(),
            widget.WindowName(
                max_chars=40,
                empty_group_string="Desktop",
                foreground=Config.TEXT_COLOR
            ),
            widget.Systray(
                icon_size=Config.FONT_SIZE,
                padding=8
            ),
            widget.Clock(
                format="%a %d %b %H:%M",
                foreground=Config.TEXT_COLOR
            ),
            widget.BatteryIcon(
                theme_path="/usr/share/icons/Paper/24x24/status/",
                scale=0.8
            ),
            widget.QuickExit(
                default_text=Config.POWER_ICON,
                foreground=Config.TEXT_COLOR,
                padding=12
            )
        ],
        size=Config.BAR_HEIGHT,
        background=Config.BAR_COLOR,
        margin=[8, 8, 4, 8],
        opacity=0.95
    )

screens = [Screen(top=create_status_bar())]

# ---------------------------- #
#    Window Management Rules   #
# ---------------------------- #
@hook.subscribe.client_new
def assign_app_group(window):
    for group in groups:
        if any(window.match(rule) for rule in group.matches):
            window.togroup(group.name)
            break

# ---------------------------- #
#    Quality-of-Life Tweaks    #
# ---------------------------- #
wl_input_rules = {
    "type:keyboard": {
        "options": [
            "caps:swapescape",
            "compose:menu",
            "numlock:true"
        ]
    }
}

dgroups_key_binder = None
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
auto_fullscreen = True
reconfigure_screens = True
focus_on_window_activation = "urgent"
