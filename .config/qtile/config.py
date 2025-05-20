import os
import subprocess
from typing import List

from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.backend.wayland import InputConfig
from libqtile.log_utils import logger

# --------------------------------
# --- Constants and Variables ---
# --------------------------------
mod = "mod4"  # Super key as the main modifier
alt = "mod1"  # Alt key for additional bindings
terminal = "alacritty"
browser = "firefox"
file_manager = "thunar"

# Colors - Modern Forest Theme
colors = {
    "bg": "#0c0f0a",
    "fg": "#8fa176",
    "accent": "#a1c16b",
    "accent2": "#7c9954",
    "inactive": "#3e4a3c",
    "urgent": "#e15d67",
    "alt_bg": "#151915",
    "widget_bg": "#1e231d",
    "transparent": "#00000000"
}

# --------------------------------
# --- Startup Configuration -----
# --------------------------------
@hook.subscribe.startup_once
def autostart():
    """Run once when Qtile starts"""
    home = os.path.expanduser("~")
    os.environ["PATH"] += f":{home}/.local/bin"
    subprocess.Popen([home + "/.config/qtile/autostart.sh"])

# --------------------------------
# --- Keybindings --------------
# --------------------------------
keys = [
    # ----- Window Management -----
    # Focus movement (vim-like keys)
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move focus to next window"),
    
    # Window movement
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    
    # Window resizing
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod, "control"], "m", lazy.layout.maximize(), desc="Maximize window"),
    
    # Window states
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod], "w", lazy.window.kill(), desc="Close focused window"),
    
    # Layout management
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod, "shift"], "Tab", lazy.prev_layout(), desc="Toggle to previous layout"),
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle split/unsplit"),
    
    # ----- Applications -----
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "e", lazy.spawn(file_manager), desc="Launch file manager"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch web browser"),
    Key([mod], "x", lazy.spawn("rofi -show drun -show-icons"), desc="App launcher"),
    Key([mod, alt], "space", lazy.spawn("rofi -show run"), desc="Run command"),
    
    # ----- System Controls -----
    # Audio
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%"), desc="Volume up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%"), desc="Volume down"),
    Key([], "XF86AudioMute", lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle"), desc="Toggle mute"),
    Key([], "XF86AudioMicMute", lazy.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), desc="Toggle mic mute"),
    
    # Media playback
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Play/pause media"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="Previous track"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Next track"),
    
    # Brightness
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%"), desc="Increase brightness"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-"), desc="Decrease brightness"),
    
    # ----- Custom Applications -----
    Key([mod], "s", lazy.spawn("scrot -s -f -q 100 ~/Pictures/Screenshots/%Y-%m-%d-%H%M%S.png"), desc="Take screenshot"),
    Key([mod, "shift"], "s", lazy.spawn("flameshot gui"), desc="Area screenshot"),
    Key([mod], "v", lazy.spawn("lxappearance"), desc="Change theme"),
    Key([mod], "p", lazy.spawn("nitrogen"), desc="Change wallpaper"),
    Key([mod], "z", lazy.spawn("archlinux-logout"), desc="Power menu"),
    Key([mod, "shift"], "z", lazy.spawn("powermenu"), desc="Alt power menu"),
    Key([mod], "u", lazy.spawn("obs"), desc="Screen recording"),
    Key([mod], "c", lazy.spawn("gpick"), desc="Color picker"),
    Key([mod], "q", lazy.spawn(f"{terminal} -e ranger"), desc="File manager"),
    
    # ----- Qtile Management -----
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload config"),
    Key([mod, "control", "shift"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    
    # ----- Additional Keychords -----
    # Create a key chord for layout-specific commands
    KeyChord([mod], "o", [
        Key([], "t", lazy.layout.rotate(), desc="Rotate layout"),
        Key([], "f", lazy.layout.flip(), desc="Flip layout"),
        Key([], "m", lazy.layout.maximize(), desc="Maximize in layout"),
        Key([], "n", lazy.layout.normalize(), desc="Normalize in layout"),
        Key([], "r", lazy.layout.reset(), desc="Reset layout"),
    ], name="Layout Operations"),
]

# --------------------------------
# --- Workspaces/Groups ---------
# --------------------------------
groups = []

# Define groups with specific names, labels and layouts
group_config = [
    # Name, Label, Layout, Matches
    ("1", "󰲠", "monadtall", [Match(wm_class=["alacritty", "kitty", "xfce4-terminal"])]),
    ("2", "󰖟", "monadtall", [Match(wm_class=["firefox", "brave-browser", "chromium", "vivaldi-stable"])]),
    ("3", "󱁤", "monadtall", [Match(wm_class=["thunar", "pcmanfm", "dolphin"])]),
    ("4", "󰨞", "monadtall", [Match(wm_class=["code", "vscodium", "emacs", "neovide"])]),
    ("5", "󰙯", "monadtall", [Match(wm_class=["gimp", "inkscape", "krita", "blender"])]),
    ("6", "󰭻", "monadtall", [Match(wm_class=["telegram-desktop", "discord", "slack", "signal"])]),
    ("7", "󱍙", "monadtall", [Match(wm_class=["mpv", "vlc", "jellyfin", "strawberry"])]),
    ("8", "󰝚", "monadtall", [Match(wm_class=["spotify", "audacity", "lmms"])]),
    ("9", "󰏘", "floating", [Match(wm_class=["pavucontrol", "arandr", "gnome-system-monitor", "lxappearance"])]),
]

for name, label, layout_name, matches in group_config:
    groups.append(
        Group(
            name=name,
            label=label,
            layout=layout_name,
            matches=matches,
        )
    )

# Add scratchpad with dropdown terminal
groups.append(
    ScratchPad("scratchpad", [
        # Define a dropdown terminal
        DropDown(
            "term", 
            terminal,
            opacity=0.95,
            height=0.6,
            width=0.6,
            x=0.2,
            y=0.1,
            on_focus_lost_hide=True
        ),
        # Define a dropdown calculator
        DropDown(
            "calc", 
            "qalculate-gtk",
            opacity=0.95,
            height=0.5,
            width=0.4,
            x=0.3,
            y=0.1,
            on_focus_lost_hide=True
        ),
    ])
)

# Add scratchpad keybindings
keys.extend([
    Key([mod], "grave", lazy.group["scratchpad"].dropdown_toggle("term"), desc="Toggle dropdown terminal"),
    Key([mod], "a", lazy.group["scratchpad"].dropdown_toggle("calc"), desc="Toggle calculator"),
])

# Add group hotkeys
for i in groups[:-1]:  # Exclude scratchpad from number keys
    keys.extend([
        # mod + group number = switch to group
        Key(
            [mod], 
            i.name, 
            lazy.group[i.name].toscreen(),
            desc=f"Switch to group {i.name}"
        ),
        # mod + shift + group number = move focused window to group
        Key(
            [mod, "shift"], 
            i.name, 
            lazy.window.togroup(i.name, switch_group=True),
            desc=f"Move focused window to group {i.name}"
        ),
    ])

# --------------------------------
# --- Layouts -------------------
# --------------------------------
layout_theme = {
    "margin": 10,
    "border_width": 2,
    "border_focus": colors["accent"],
    "border_normal": colors["inactive"],
    "single_border_width": 0,
    "single_margin": 0,
}

layouts = [
    layout.MonadTall(
        ratio=0.6,
        min_ratio=0.30,
        max_ratio=0.70,
        change_ratio=0.05,
        **layout_theme
    ),
    layout.MonadWide(
        ratio=0.65,
        min_ratio=0.30,
        max_ratio=0.70,
        **layout_theme
    ),
    layout.Columns(
        border_focus_stack=colors["accent2"],
        border_normal_stack=colors["inactive"],
        insert_position=1,
        **layout_theme
    ),
    layout.Matrix(
        columns=2,
        **layout_theme
    ),
    layout.Bsp(
        fair=False,
        grow_amount=5,
        **layout_theme
    ),
    layout.Tile(
        shift_windows=True,
        ratio=0.55,
        **layout_theme
    ),
    layout.Max(
        **layout_theme
    ),
    layout.Floating(
        **layout_theme
    ),
    # New in latest Qtile version
    layout.TreeTab(
        font="JetBrainsMono Nerd Font",
        fontsize=12,
        bg_color=colors["bg"],
        active_bg=colors["accent"],
        active_fg="#ffffff",
        inactive_bg=colors["widget_bg"],
        inactive_fg=colors["fg"],
        padding_left=4,
        padding_x=4,
        padding_y=4,
        sections=["Tabs"],
        section_fontsize=12,
        border_width=2,
        vspace=2,
        panel_width=200
    ),
    layout.Spiral(
        ratio=0.6,
        new_client_position='top',
        **layout_theme
    ),
]

# --------------------------------
# --- Widgets -------------------
# --------------------------------
widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=14,
    padding=4,
    background=colors["bg"],
    foreground=colors["fg"],
)
extension_defaults = widget_defaults.copy()

# Define icons
icons = {
    "launcher": "󰣇",
    "battery": "󰂄",
    "battery_charging": "󰂄",
    "battery_discharging": "󰁿",
    "clock": "󰥔", 
    "date": "󰸗",
    "power": "󰐥",
    "memory": "󰍛",
    "cpu": "󰘚",
    "temp": "󰔏",
    "disk": "󰋊",
    "volume": "󰕾",
    "muted": "󰖁",
    "microphone": "󰍬",
    "wifi": "󰖩",
    "ethernet": "󰈀",
    "bluetooth": "󰂯",
    "layout": "󰕮",
    "updates": "󰚰",
    "brightness": "󰃟",
}

# Widget creation helper
def create_separator(size=8):
    return widget.Sep(
        linewidth=0,
        padding=size,
        background=colors["bg"],
    )

# Create a styled widget
def create_icon_widget(icon, foreground=colors["accent"], background=colors["bg"], callback=None):
    return widget.TextBox(
        text=icon,
        fontsize=18,
        padding=6,
        background=background,
        foreground=foreground,
        mouse_callbacks=callback if callback else {},
    )

def create_rounded_edge(direction, foreground=colors["widget_bg"], background=colors["bg"]):
    if direction == "left":
        icon = ""  # Left rounded edge
    else:
        icon = ""  # Right rounded edge
    
    return widget.TextBox(
        text=icon,
        padding=0,
        fontsize=22,
        background=background,
        foreground=foreground,
    )

# Create workspace indicator
def create_groupbox():
    return widget.GroupBox(
        highlight_method="line",
        this_current_screen_border=colors["accent"],
        this_screen_border=colors["accent2"],
        other_current_screen_border=colors["inactive"],
        other_screen_border=colors["inactive"],
        background=colors["bg"],
        active=colors["fg"],
        inactive=colors["inactive"],
        urgent_border=colors["urgent"],
        urgent_text=colors["urgent"],
        highlight_color=[colors["alt_bg"], colors["widget_bg"]],
        fontsize=20,
        margin_y=3,
        margin_x=2,
        padding_x=6,
        padding_y=6,
        disable_drag=True,
        use_mouse_wheel=True,
        borderwidth=2,
        rounded=True,
    )

# Create a module with background
def create_module(widgets, background=colors["widget_bg"]):
    module = []
    module.append(create_rounded_edge("left", background))
    
    for w in widgets:
        if isinstance(w, dict):
            widget_type = w.pop("type")
            w["background"] = background
            module.append(getattr(widget, widget_type)(**w))
        else:
            w.background = background
            module.append(w)
            
    module.append(create_rounded_edge("right", background))
    return module

# --------------------------------
# --- Screens -------------------
# --------------------------------
screens = [
    Screen(
        top=bar.Bar(
            [
                # Left side - groups and tasks
                create_icon_widget(
                    icons["launcher"],
                    foreground="#ffffff",
                    background=colors["accent"],
                    callback={"Button1": lambda: qtile.spawn("rofi -show drun -show-icons")},
                ),
                create_separator(4),
                
                create_groupbox(),
                
                create_separator(4),
                
                # Current layout
                *create_module([
                    create_icon_widget(icons["layout"], foreground="#ffffff"),
                    {"type": "CurrentLayout", "padding": 5, "foreground": "#ffffff"},
                ], background=colors["accent2"]),
                
                create_separator(6),
                
                # Window name
                widget.WindowName(
                    format="{name}",
                    max_chars=40,
                    background=colors["bg"],
                    foreground=colors["fg"],
                    empty_group_string="Desktop",
                    markup=True,
                ),
                
                widget.Spacer(),
                
                # Right side - System info
                *create_module([
                    create_icon_widget(icons["updates"], foreground="#ffffff"),
                    {"type": "CheckUpdates", 
                     "foreground": "#ffffff",
                     "colour_have_updates": "#ffffff",
                     "colour_no_updates": "#ffffff",
                     "display_format": "{updates}",
                     "no_update_string": "0",
                     "update_interval": 1800,
                     "distro": "Arch_checkupdates",
                     "padding": 5,
                    },
                ], background=colors["accent2"]),
                
                create_separator(6),
                
                # System monitors
                *create_module([
                    create_icon_widget(icons["memory"]),
                    {"type": "Memory", 
                     "format": "{MemPercent:.0f}%",
                     "padding": 5,
                     "mouse_callbacks": {"Button1": lambda: qtile.spawn(f"{terminal} -e htop")},
                    },
                ]),
                
                create_separator(6),
                
                *create_module([
                    create_icon_widget(icons["cpu"]),
                    {"type": "CPU", 
                     "format": "{load_percent}%",
                     "padding": 5,
                     "mouse_callbacks": {"Button1": lambda: qtile.spawn(f"{terminal} -e htop")},
                    },
                ]),
                
                create_separator(6),
                
                *create_module([
                    create_icon_widget(icons["temp"]),
                    {"type": "ThermalSensor", 
                     "format": "{temp:.0f}°C",
                     "padding": 5,
                     "threshold": 80,
                     "foreground_alert": colors["urgent"],
                    },
                ]),
                
                create_separator(6),
                
                # Volume control
                *create_module([
                    widget.PulseVolume(
                        fmt="{}",
                        padding=5,
                        get_volume_command=None,
                        volume_app="pavucontrol",
                        mouse_callbacks={"Button3": lambda: qtile.spawn("pavucontrol")},
                        foreground=colors["fg"],
                        emoji=True,
                        emoji_list=["󰖁", "󰕿", "󰖀", "󰕾"],
                    ),
                ]),
                
                create_separator(6),
                
                # Battery
                *create_module([
                    widget.Battery(
                        format="{char} {percent:2.0%}",
                        charge_char=icons["battery_charging"],
                        discharge_char=icons["battery_discharging"],
                        full_char=icons["battery"],
                        unknown_char=icons["battery"],
                        empty_char="󱃍",
                        padding=5,
                        foreground=colors["fg"],
                        low_foreground=colors["urgent"],
                        low_percentage=0.15,
                        update_interval=10,
                        show_short_text=False,
                    ),
                ]),
                
                create_separator(6),
                
                # Clock and date
                *create_module([
                    create_icon_widget(icons["clock"], foreground="#ffffff"),
                    {"type": "Clock", 
                     "format": "%H:%M", 
                     "padding": 5,
                     "foreground": "#ffffff",
                    },
                ], background=colors["accent"]),
                
                create_separator(6),
                
                *create_module([
                    create_icon_widget(icons["date"], foreground="#ffffff"),
                    {"type": "Clock", 
                     "format": "%a, %b %d", 
                     "padding": 5,
                     "foreground": "#ffffff",
                    },
                ], background=colors["accent"]),
                
                create_separator(6),
                
                # System tray
                widget.Systray(
                    padding=5,
                    background=colors["bg"],
                    icon_size=18,
                ),
                
                create_separator(4),
                
                # Power menu
                create_icon_widget(
                    icons["power"],
                    foreground="#ffffff",
                    background=colors["accent2"],
                    callback={"Button1": lambda: qtile.spawn("powermenu")},
                ),
            ],
            32,  # Bar height
            background=colors["bg"],
            margin=[6, 6, 0, 6],  # [top, right, bottom, left]
            opacity=0.95,
        ),
    ),
]

# --------------------------------
# --- Mouse Configuration -------
# --------------------------------
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
    Click([mod, "control"], "Button1", lazy.window.toggle_floating()),
]

# --------------------------------
# --- Floating Window Rules -----
# --------------------------------
floating_layout = layout.Floating(
    float_rules=[
        # System windows
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
        
        # Application windows
        Match(wm_class="confirm"),
        Match(wm_class="dialog"),
        Match(wm_class="download"),
        Match(wm_class="error"),
        Match(wm_class="file_progress"),
        Match(wm_class="notification"),
        Match(wm_class="splash"),
        Match(wm_class="toolbar"),
        Match(wm_class="Arandr"),
        Match(wm_class="feh"),
        Match(wm_class="Galculator"),
        Match(wm_class="Lxappearance"),
        Match(wm_class="Nitrogen"),
        Match(wm_class="Oblogout"),
        Match(wm_class="Pavucontrol"),
        Match(wm_class="Xfce4-terminal"),
        Match(wm_class="copyq"),
        Match(wm_class="gnome-font-viewer"),
        Match(wm_class="gpick"),
        Match(wm_class="nm-connection-editor"),
        Match(wm_class="qalculate-gtk"),
        Match(wm_class="blueman-manager"),
        Match(wm_class="polkit-gnome-authentication-agent-1"),
        Match(wm_class="xdg-desktop-portal-gnome"),
        Match(title="Picture-in-Picture"),
        Match(role="pop-up"),
        Match(role="GtkFileChooserDialog"),
        Match(role="conversation"),
        Match(wm_instance_class="Places"),
        Match(wm_instance_class="bluetooth"),
        Match(wm_instance_class="nm-connection-editor"),
        # For Firefox
        Match(wm_class="firefox", role="About"),
        Match(wm_class="firefox", title="Library"),
        Match(title="Firefox — Sharing Indicator"),
    ],
    fullscreen_border_width=0,
    border_width=2,
    border_focus=colors["accent"],
    border_normal=colors["inactive"],
)

# Set transient windows to floating mode
@hook.subscribe.client_new
def set_floating(window):
    if (window.window.get_wm_transient_for() or 
        window.window.get_wm_type() in ["notification", "toolbar", "splash", "dialog"]):
        window.floating = True

# --------------------------------
# --- Additional Hooks ----------
# --------------------------------
# Focus urgent windows automatically
@hook.subscribe.client_urgent_hint_changed
def focus_urgent(client):
    client.togroup()
    client.group.cmd_toscreen()

# Set environment variables
os.environ["QT_QPA_PLATFORMTHEME"] = "qt5ct"
os.environ["QT_STYLE_OVERRIDE"] = "kvantum"
os.environ["GTK_IM_MODULE"] = "fcitx"
os.environ["QT_IM_MODULE"] = "fcitx"
os.environ["XMODIFIERS"] = "@im=fcitx"

# --------------------------------
# --- Wayland Configuration -----
# --------------------------------
# Enable these if using Wayland
# wl_input_rules = {
#     "type:keyboard": InputConfig(kb_layout="us"),
#     "type:touchpad": InputConfig(
#         natural_scroll=True,
#         tap=True,
#         dwt=True,
#     ),
# }

# --------------------------------
# --- General Configuration -----
# --------------------------------
# Focus behavior
focus_on_window_activation = "smart"
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False

# Screen behavior
reconfigure_screens = True
auto_fullscreen = True
auto_minimize = True

# Groups
dgroups_key_binder = None
dgroups_app_rules = []

# Window manager name - for Java applications compatibility
wmname = "LG3D"
