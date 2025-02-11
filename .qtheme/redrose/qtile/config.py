import os
import subprocess

from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.dgroups import simple_key_binder
from libqtile.lazy import lazy

# Define some variables
mod = "mod4"  # Use the Super key as the main modifier
terminal = "alacritty"  # Use the default terminal emulator


@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser("~")
    os.environ["PATH"] += f":{home}/.local/bin"
    subprocess.call([home + "/.setup"])


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(
        [mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"
    ),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key(
        [mod],
        "t",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window",
    ),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    #    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    # Misc and my custom cmd
    Key([mod], "x", lazy.spawn("rofi -show drun"), desc="Spawn a command launcher"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("control volume +1"), desc="Volume Up"),
    Key(
        [], "XF86AudioLowerVolume", lazy.spawn("control volume -1"), desc="Volume Down"
    ),
    Key([], "XF86AudioMute", lazy.spawn("control mute x"), desc="Volume Mute"),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="playerctl"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="playerctl"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="playerctl"),
    Key(
        [],
        "XF86MonBrightnessUp",
        lazy.spawn("control brightness 10+"),
        desc="Brightness Up",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        lazy.spawn("control brightness 10-"),
        desc="Brightness Down",
    ),
    Key([mod], "e", lazy.spawn("thunar"), desc="File manager"),
    Key([mod], "h", lazy.spawn("xclip"), desc="Clipboard"),
    Key([mod], "s", lazy.spawn("screenshot"), desc="Screenshot"),
    Key([mod], "v", lazy.spawn("change"), desc="Theme Change"),
    Key([mod], "b", lazy.spawn("wallset"), desc="Wallpaper Change"),
    Key([mod], "z", lazy.spawn("powermenu"), desc="Power Menu"),
    Key([mod], "u", lazy.spawn("record"), desc="Screen Record"),
    Key([mod], "c", lazy.spawn("pick"), desc="Color Picker"),
    Key([mod], "m", lazy.spawn("msplay"), desc="Music Player"),
    Key([mod], "q", lazy.spawn("search"), desc="Searcher"),
]

# Groups
groups = []
group_names = ["1", "2", "3", "4", "5", "6", "7", "8", "9",]
group_labels = ["󰝥", "󰝥", "󰝥", "󰝥", "󰝥", "󰝥", "󰝥", "󰝥", "󰝥",]
#group_labels = ["DEV", "WWW", "SYS", "DOC", "VBOX", "CHAT", "MUS", "VID", "GFX",]
#group_labels = ["", "", "", "", "", "", "", "", "",]

for i in range(len(group_names)):
    groups.append(
        Group(
            name=group_names[i],
            label=group_labels[i],
        ))
 
for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=False),
                desc="Move focused window to group {}".format(i.name),
            ),
        ]
    )

# Layouts
def init_layout_theme():
    return {
        "margin": 10,
        "border_width": 0,
    }


layout_theme = init_layout_theme()

layouts = [
    layout.MonadTall(**layout_theme),
    layout.MonadWide(**layout_theme),
    layout.Matrix(**layout_theme),
    layout.Bsp(**layout_theme),
    layout.Floating(**layout_theme),
    layout.RatioTile(**layout_theme),
    layout.Max(**layout_theme),
]

# Widget Defaults
widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=14,
    padding=2,
)
extension_defaults = [widget_defaults.copy()]


# Remove Parse text
def no_text(text):
    return ""


# remove bar
# screens = [ Screen() ]
# Define the glyphs for your icons

launcher_icon = ""
# net_icon = "󰀂"
# bluetooth_icon = ""
# pulsevolume_icon = ""
battery_icon = ""
clock_icon = "󰥔"
powermenu_icon = "⏻"
# Bar configuration
screens = [
    Screen(
        top=bar.Bar(
            [
                widget.TextBox(
                    text=f" {launcher_icon} ",
                    fontsize=18,
                    padding=10,
                    background="#100C0F",
                    foreground="#D73C58",
                    mouse_callbacks={
                        "Button1": lambda: qtile.spawn("rofi -show drun")
                    },
                ),
                widget.Mpd2(
                    status_format='{play_status} {artist}/{title}',
                    foreground="#D73C58",
                    padding=10,
                    host='localhost',
                    port='6600',
                    idle_message='Not any music playing ',
                    idle_format='{play_status} {idle_message}[{repeat}{random}{single}{consume}{updating_db}]',
                ),
                widget.Spacer(
                    background="#100C0F",
                ),
                widget.GroupBox(
                    use_mouse_wheel=True,
                    highlight_method="block",
                    this_current_screen_border="#100C0F",
                    fontsize=20,
                    foreground="#100C0F",
                    active="#D73C58",
                    margin=0,
                    margin_x=0,
                    margin_y=2,
                    padding=0,
                    padding_x=2,
                    padding_y=6,
                ),
                widget.Spacer(
                    background="#100C0F",
                ),
                widget.TextBox(
                    text=f" {clock_icon} ", fontsize=14, foreground="#D73C58"
                ),
                widget.Clock(format="%I:%M %p", fontsize=14, padding=10, foreground="#D73C58"),
                widget.TextBox(
                    text=f" {battery_icon} ",
                    fontsize=14,
                    foreground="#D73C58",
                    mouse_callbacks={
                        "Button1": lambda: qtile.spawn(
                            "xfce4-power-manager-settings"
                        )
                    },
                ),
                widget.Battery(
                    battery=0,
                    format="{percent:2.0%} -",
                    fontsize=14,
                    foreground="#D73C58",
                    mouse_callbacks={
                        "Button1": lambda: qtile.spawn(
                            "xfce4-power-manager-settings"
                        )
                    },
                ),
                widget.Battery(
                    battery=1,
                    format="{percent:2.0%}",
                    padding=10,
                    fontsize=14,
                    foreground="#D73C58",
                    mouse_callbacks={
                        "Button1": lambda: qtile.spawn(
                            "xfce4-power-manager-settings"
                        )
                    },
                ),
                widget.Systray(
                    padding=10,
                    fontsize=10,
                    foreground="#D73C58",
                ),
                widget.TextBox(
                    text=f" {powermenu_icon} ",
                    padding=10,
                    fontsize=14,
                    background="#100C0F",
                    foreground="#D73C58",
                    mouse_callbacks={"Button1": lambda: qtile.spawn("powermenu")},
                ),
            ],
            50,  # Set height of the bar
            background="#100C0F",  # Set the background color
            margin=[0, 0, 0, 0],  # Set the left, top, right, and bottom margins
        ),
    ),
]

# Drag floating layouts
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
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
        Match(wm_class="xfce4-terminal"),
        Match(wm_class="alacritty"),
    ],
    fullscreen_border_width=0,
    border_width=0,
)


@hook.subscribe.client_new
def set_floating(window):
    if window.window.get_wm_transient_for() or window.window.get_wm_type() in [
        "notification",
        "toolbar",
        "splash",
        "dialog",
    ]:
        window.floating = True


# Configuration
focus_on_window_activation = "smart"
reconfigure_screens = True
dgroups_key_binder = None
follow_mouse_focus = True
bring_front_click = False
dgroups_app_rules = []
auto_fullscreen = True
wl_input_rules = None
auto_minimize = True
cursor_warp = False
wmname = "LG3D"
