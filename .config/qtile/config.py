import os
import subprocess
from typing import List

from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

# --------------------------------
# --- Constants and Variables ---
# --------------------------------
mod = "mod4"  # Super key as the main modifier
alt = "mod1"  # Alt key for additional bindings
terminal = "alacritty"
browser = "firefox"
file_manager = "thunar"

# Colors
colors = {
    "bg": "#0A0D09",
    "fg": "#667855",
    "accent": "#88AA77",
    "inactive": "#445544",
    "urgent": "#CC6666",
}

# --------------------------------
# --- Startup Configuration -----
# --------------------------------
@hook.subscribe.startup_once
def autostart():
    """Run once when Qtile starts"""
    home = os.path.expanduser("~")
    os.environ["PATH"] += f":{home}/.local/bin"
    subprocess.call([home + "/.setup"])

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
    Key([mod], "x", lazy.spawn("rofi -show drun"), desc="App launcher"),
    
    # ----- System Controls -----
    # Audio
    Key([], "XF86AudioRaiseVolume", lazy.spawn("control volume +5"), desc="Volume up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("control volume -5"), desc="Volume down"),
    Key([], "XF86AudioMute", lazy.spawn("control mute x"), desc="Toggle mute"),
    
    # Media playback
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Play/pause media"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="Previous track"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Next track"),
    
    # Brightness
    Key([], "XF86MonBrightnessUp", lazy.spawn("control brightness 100+"), desc="Increase brightness"),
    Key([], "XF86MonBrightnessDown", lazy.spawn("control brightness 100-"), desc="Decrease brightness"),
    
    # ----- Custom Applications -----
    Key([mod], "s", lazy.spawn("screenshot"), desc="Take screenshot"),
    Key([mod], "v", lazy.spawn("change"), desc="Change theme"),
    Key([mod], "p", lazy.spawn("wallset"), desc="Change wallpaper"),
    Key([mod], "z", lazy.spawn("powermenu"), desc="Power menu"),
    Key([mod], "u", lazy.spawn("record"), desc="Screen recording"),
    Key([mod], "c", lazy.spawn("pick"), desc="Color picker"),
    Key([mod], "m", lazy.spawn("msplay"), desc="Music player"),
    Key([mod], "q", lazy.spawn("search"), desc="Search tool"),
    
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
    ("1", "󰲠", "monadtall", [Match(wm_class=["alacritty", "kitty"])]),
    ("2", "󰖟", "monadtall", [Match(wm_class=["firefox", "brave", "chromium"])]),
    ("3", "󱁤", "monadtall", [Match(wm_class=["thunar", "pcmanfm"])]),
    ("4", "󰨞", "monadtall", [Match(wm_class=["code", "vscodium"])]),
    ("5", "󰙯", "monadtall", [Match(wm_class=["gimp", "inkscape"])]),
    ("6", "󰭻", "monadtall", [Match(wm_class=["telegram-desktop", "discord"])]),
    ("7", "󱍙", "monadtall", [Match(wm_class=["mpv", "vlc"])]),
    ("8", "󰝚", "monadtall", [Match(wm_class=["spotify", "mpd"])]),
    ("9", "󰏘", "floating", [Match(wm_class=["pavucontrol", "arandr"])]),
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

# Add group hotkeys
for i in groups:
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
    "border_normal": colors["bg"],
    "single_border_width": 0,
}

layouts = [
    layout.MonadTall(
        ratio=0.6,
        min_ratio=0.30,
        max_ratio=0.70,
        **layout_theme
    ),
    layout.MonadWide(
        ratio=0.6,
        min_ratio=0.30,
        max_ratio=0.70,
        **layout_theme
    ),
    layout.Columns(
        insert_position=1,
        **layout_theme
    ),
    layout.Matrix(
        columns=2,
        **layout_theme
    ),
    layout.Bsp(
        fair=False,
        **layout_theme
    ),
    layout.RatioTile(
        ratio=1.6,
        **layout_theme
    ),
    layout.Max(**layout_theme),
    layout.Floating(**layout_theme),
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
    "launcher": "",
    "battery": "",
    "clock": "󰥔",
    "power": "⏻",
    "memory": "󰍛",
    "cpu": "󰘚",
    "disk": "󰋊",
    "volume": "󰕾",
    "microphone": "󰍬",
    "wifi": "󰖩",
    "ethernet": "󰈀",
}

# Widget creation helper
def create_separator(size=8):
    return widget.Sep(
        linewidth=0,
        padding=size,
        background=colors["bg"],
    )

# Create a styled widget
def create_icon_widget(icon, callback=None):
    return widget.TextBox(
        text=f" {icon} ",
        fontsize=16,
        padding=6,
        background=colors["bg"],
        foreground=colors["accent"],
        mouse_callbacks=callback if callback else {},
    )

# --------------------------------
# --- Screens -------------------
# --------------------------------
screens = [
    Screen(
        top=bar.Bar(
            [
                # Left side
                create_icon_widget(
                    icons["launcher"],
                    {"Button1": lambda: qtile.spawn("rofi -show drun")},
                ),
                widget.GroupBox(
                    highlight_method="block",
                    this_current_screen_border=colors["accent"],
                    background=colors["bg"],
                    active=colors["fg"],
                    inactive=colors["inactive"],
                    urgent_border=colors["urgent"],
                    fontsize=18,
                    margin=3,
                    padding=4,
                    disable_drag=True,
                    use_mouse_wheel=True,
                ),
                create_separator(),
                
                # Center - Window name
                widget.WindowName(
                    format="{name}",
                    max_chars=50,
                    background=colors["bg"],
                    foreground=colors["fg"],
                ),
                widget.Spacer(),
                
                # Music player
                widget.Mpd2(
                    status_format='{play_status} {artist}/{title}',
                    foreground=colors["fg"],
                    padding=10,
                    host='localhost',
                    port='6600',
                    idle_message='No music',
                    format='{play_status} {artist} - {title}',
                    max_chars=30,
                ),
                create_separator(),
                
                # System monitors
                create_icon_widget(icons["memory"]),
                widget.Memory(
                    format='{MemUsed:.0f}M',
                    foreground=colors["fg"],
                    padding=5,
                    mouse_callbacks={"Button1": lambda: qtile.spawn(f"{terminal} -e htop")},
                ),
                create_separator(),
                
                create_icon_widget(icons["cpu"]),
                widget.CPU(
                    format="{load_percent}%",
                    foreground=colors["fg"],
                    padding=5,
                    mouse_callbacks={"Button1": lambda: qtile.spawn(f"{terminal} -e htop")},
                ),
                create_separator(),
                
                # Right side
                create_icon_widget(icons["clock"]),
                widget.Clock(
                    format="%H:%M",
                    foreground=colors["fg"],
                    padding=5,
                ),
                widget.Clock(
                    format="%a, %b %d",
                    foreground=colors["fg"],
                    padding=5,
                ),
                create_separator(),
                
                create_icon_widget(icons["battery"]),
                widget.Battery(
                    battery=0,
                    format="{percent:2.0%}",
                    foreground=colors["fg"],
                    padding=5,
                    low_foreground=colors["urgent"],
                    low_percentage=0.15,
                    mouse_callbacks={"Button1": lambda: qtile.spawn("xfce4-power-manager-settings")},
                ),
                create_separator(),
                
                # System tray
                widget.Systray(
                    padding=5,
                    background=colors["bg"],
                ),
                create_separator(),
                
                # Power menu
                create_icon_widget(
                    icons["power"],
                    {"Button1": lambda: qtile.spawn("powermenu")},
                ),
            ],
            30,  # Bar height
            background=colors["bg"],
            margin=[5, 5, 0, 5],  # [top, right, bottom, left]
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
    ],
    fullscreen_border_width=0,
    border_width=2,
    border_focus=colors["accent"],
    border_normal=colors["bg"],
)

# Set transient windows to floating mode
@hook.subscribe.client_new
def set_floating(window):
    if (window.window.get_wm_transient_for() or 
        window.window.get_wm_type() in ["notification", "toolbar", "splash", "dialog"]):
        window.floating = True

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

# Window manager name 
wmname = "LG3D"
