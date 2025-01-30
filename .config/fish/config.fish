# -*- mode: fish -*-
# Minimalist Fish configuration optimized for Void Linux

### Environment Variables ###
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERM alacritty
set -gx QT_QPA_PLATFORMTHEME gtk3
set -gx XCURSOR_THEME oreo_white_cursors
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"

### Xdeb Configuration ###
set -gx XDEB_OPT_DEPS true
set -gx XDEB_OPT_SYNC true
set -gx XDEB_OPT_WARN_CONFLICT true
set -gx XDEB_OPT_FIX_CONFLICT true

### Path Management ###
fish_add_path -g --prepend \
    $HOME/.local/bin \
    $HOME/.config/nvim/bin \
    $HOME/.cargo/bin

### Prompt Configuration ###
starship init fish | source
set -U fish_greeting  # Disable welcome message

### Terminal Title ###
function fish_title
    set -q argv[1]; or set argv fish
    echo (prompt_pwd): $argv
end

### Core Utilities ###
abbr -a c clear
abbr -a q exit
abbr -a v nvim
abbr -a e $EDITOR

### Modern Linux Commands ###
abbr -a ls 'exa --group-directories-first -l --git --icons'
abbr -a la 'exa --group-directories-first -la --git --icons'
abbr -a tree 'exa --tree --level=2'
abbr -a cat 'bat --theme=base16'

### Package Management ###
function xbps
    switch $argv[1]
        case update vu; sudo xbps-install -Syuv
        case install vp; sudo xbps-install -Sy $argv[2..]
        case remove vr; sudo xbps-remove -Rcon $argv[2..]
        case purge vfr; sudo xbps-remove -Rcon -F $argv[2..]
        case search vs; xbps-query -Rs $argv[2..]
        case files; xbps-query -f $argv[2]
        case '*'; xbps-query $argv
    end
end

function flat
    switch $argv[1]
        case update fu; flatpak update
        case install fi; flatpak install $argv[2..]
        case remove fr; flatpak uninstall --delete-data $argv[2..]
        case search fs; flatpak search $argv[2..]
        case list fl; flatpak list
        case '*'; flatpak $argv
    end
end

### Git Shortcuts ###
abbr -a g git
abbr -a gs 'git status -sb'
abbr -a ga 'git add'
abbr -a gc 'git commit -m'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gco 'git checkout'
abbr -a gl 'git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"'

### System Utilities ###
abbr -a df 'df -hT xfs,ext4,vfat'
abbr -a free 'free -h'
abbr -a mk 'make -j(nproc)'
abbr -a myip 'curl ifconfig.co'

function mkcd
    mkdir -p $argv && cd $argv
end

function clrk
    read -P "Really remove all old kernels? [y/N] " confirm
    string match -qi "y*" $confirm && sudo vkpurge rm all
end

### SSH Agent Management ###
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c | sed 's/^echo/#echo/') >/dev/null
    ssh-add -q ~/.ssh/id_ed25519 2>/dev/null
end

### Development Tools ###
abbr -a dc docker-compose
abbr -a k kubectl
abbr -a t terraform

function venv
    set -l venv_dir .venv
    python -m venv $venv_dir
    source $venv_dir/bin/activate.fish
end

### System Controls ###
abbr -a reboot 'sudo reboot'
abbr -a poweroff 'sudo poweroff'
abbr -a suspend 'systemctl suspend'

### Clipboard Utilities ###
abbr -a clipp 'xclip -selection clipboard'
abbr -a clippaste 'xclip -selection clipboard -o'

### Fun Utilities ###
function cdown --argument-names minutes
    set -l seconds (math $minutes \* 60)
    termdown $seconds --font doom --exec-cmd 'notify-send "Timer Complete!"'
end

function cheat
    curl -s "cheat.sh/$argv" | bat --language=man --paging=always
end

### Key Bindings ###
bind \cr 'history | fzf --height 40% | read -l cmd; and commandline $cmd'

### Final Initialization ###
if status is-interactive && test -z "$DISPLAY" -a "$XDG_VTNR" = 1
    exec startx -- -keeptty
end
