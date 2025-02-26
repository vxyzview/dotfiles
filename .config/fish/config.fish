# ~/.config/fish/config.fish
# Maximalist-Minimalist Fish Shell Config for Yogyakarta, Indonesia
# Last updated: February 26, 2025

# --- Core Setup ---
if status is-interactive
    # Auto-start X on tty1
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec startx -- -keeptty
    end

    # Silence greeting
    set -U fish_greeting ""

    # Starship prompt with fallback
    if command -q starship
        starship init fish | source
    else
        function fish_prompt
            set_color cyan; echo -n "$USER@$HOSTNAME:"
            set_color yellow; echo -n (basename $PWD)
            set_color normal; echo -n '> '
        end
    end
end

# --- Environment ---
set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_CACHE_HOME "$HOME/.cache"
set -x PATH "$XDG_CONFIG_HOME/nvim/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$PATH"
set -x VISUAL "nvim"
set -x EDITOR "geany"
set -x TERM "alacritty"
set -x QT_QPA_PLATFORMTHEME "gtk3"
set -x HISTCONTROL "ignoredups:erasedups"
set -x XCURSOR_THEME "oreo_white_cursors"
set -x NVIM_APPNAME "nvim"
set -x RUSTUP_HOME "$XDG_DATA_HOME/rustup"
set -x CARGO_HOME "$XDG_DATA_HOME/cargo"
set -x SSH_AUTH_SOCK (ssh-agent -c | grep -m 1 setenv | awk '{print $2}' | tr -d ';') &

# --- Terminal Magic ---
function _set_title --on-variable PWD
    switch $TERM
        case "xterm*" "alacritty" "st"
            echo -ne "\033]0;$USER@$HOSTNAME:(basename $PWD)\007"
        case "screen*"
            echo -ne "\033_$USER@$HOSTNAME:(basename $PWD)\033\\"
    end
end

# --- Functions ---
function up --description "Navigate up N dirs"
    set -l limit (math max 1, "$argv[1]" 2>/dev/null; or echo 1)
    cd (string repeat -n $limit "../") || echo "Failed to climb $limit dirs."
end

function cdown --description "Countdown with Yogyakarta flair"
    set -l N (math max 1, "$argv[1]" 2>/dev/null; or echo 10)
    while test $N -ge 0
        clear
        echo "$N" | figlet -f slant -c | lolcat -a -s 50
        sleep 1
        set N (math $N - 1)
    end
    echo "Selesai from Yogyakarta!" | figlet -f mini -c | lolcat
    sleep 1
end

function backup --description "Timestamped file backup"
    set -l file $argv[1]
    test -n "$file" -a -e "$file" && cp -v "$file" "$file.bak.(date +%Y%m%d_%H%M%S)" || echo "Backup what? Usage: backup <file>"
end

function extract --description "Universal archive extractor"
    if test -f "$argv[1]"
        switch (string lower (path extension "$argv[1]"))
            case ".tar.gz" ".tgz"; tar xzf "$argv[1]"
            case ".tar.bz2" ".tbz2"; tar xjf "$argv[1]"
            case ".tar.xz" ".txz"; tar xJf "$argv[1]"
            case ".tar"; tar xf "$argv[1]"
            case ".zip"; unzip -q "$argv[1]"
            case ".rar"; unrar x -inul "$argv[1]"
            case ".7z"; 7z x "$argv[1]" -o(output dirname "$argv[1]") >/dev/null
            case "*"; echo "Unknown archive: $argv[1]"
        end
    else
        echo "Extract what? Usage: extract <archive>"
    end
end

function mkcd --description "Make and enter directory"
    mkdir -p "$argv[1]" && cd "$argv[1]" || echo "Failed to mkcd $argv[1]"
end

function sizeof --description "Size of file or dir"
    if test -e "$argv[1]"
        du -sh "$argv[1]" | cut -f1
    else
        echo "Size of what? Usage: sizeof <path>"
    end
end

function cheat --description "Quick cheat.sh lookup"
    curl -s "cheat.sh/$argv[1]" | less -R
end

# --- Aliases ---
# Basics
alias c 'clear'
alias e 'exit'
alias h 'history --max 50 | grep -v "^ "' # Skip trivial commands
alias t 'tmux new -A -s main' # Persistent tmux session

# Files & Dirs
alias ls 'exa -al --color=always --group-directories-first --git --time-style=long-iso'
alias la 'exa -a --color=always'
alias ll 'exa -l --color=always --git'
alias lt 'exa -aT --color=always --level=2'
alias l. 'exa -a | grep "^\."'
alias duh 'du -h --max-depth=1 | sort -hr'
alias f 'fd --hidden --no-ignore --type f'
alias d 'fd --hidden --no-ignore --type d'

# Editors
alias v 'nvim'
alias n 'nvim +Nvdash'
alias g 'geany'

# System
alias off 'systemctl poweroff'
alias boot 'systemctl reboot'
alias zzz 'systemctl suspend'
alias topc 'ps aux | sort -nr -k 3 | head -10'
alias topm 'ps aux | sort -nr -k 4 | head -10'
alias j 'journalctl -p 3 -xb --no-pager'
alias k 'killall'
alias clrk 'sudo vkpurge rm all'

# Package Managers
# XBPS (Void Linux)
alias xu 'sudo xbps-install -Syu'
alias xi 'sudo xbps-install -S'
alias xr 'sudo xbps-remove -R'
alias xs 'xbps-query -Rs'
alias xl 'xbps-query -l | sort'

# Flatpak
alias fu 'flatpak update -y'
alias fi 'flatpak install -y'
alias fr 'flatpak uninstall --delete-data'
alias fl 'flatpak list --app'

# Nix
alias nu 'nix-env -u'
alias ni 'nix-env -iA'
alias nr 'nix-env -e'
alias ns 'nix search'

# Arch (Pacman & Paru)
alias pu 'sudo pacman -Syu'
alias pi 'sudo pacman -S --noconfirm'
alias pr 'sudo pacman -Rs'
alias pq 'pacman -Q | sort'
alias pl 'paccache -r; sudo pacman -Sc'
alias pup 'paru -Syu'
alias pui 'paru -S'

# Rust (Cargo)
alias cr 'cargo run'
alias cb 'cargo build'
alias ct 'cargo test'
alias cup 'rustup update'

# Git
alias ga 'git add .'
alias gc 'git commit -s -m'
alias gp 'git push'
alias gl 'git pull'
alias gs 'git status -s'
alias gd 'git diff --color-words'
alias gb 'git branch'
alias gcl 'git clone --depth=1'
alias glog 'git log --oneline --graph --all'

# Network
alias ipa 'ip -c a'
alias p 'ping -c 10 google.com'
alias speed 'speedtest-cli --simple'
alias ipi 'curl -s ifconfig.me/all.json | jq -r ".ip_addr + \" (\" + .city + \", \" + .country + \")\""'
alias w 'curl "wttr.in/Yogyakarta,Indonesia?format=%C+%t+%w+%m&lang=id"' # Weather in Yogyakarta, Bahasa Indonesia

# Media & Web
alias mp3 'mpv --shuffle --loop *.mp3'
alias mp4 'mpv --shuffle --loop *.mp4'
alias yt 'yt-dlp -f "bestvideo+bestaudio/best" -o "%(title)s.%(ext)s"'
alias ytm 'yt-dlp -x --audio-format mp3 -o "%(title)s.%(ext)s"'

# Local Flavor
alias jam 'date +"%H:%M WIB"' # Waktu Indonesia Barat (Yogyakarta time)
alias pray 'curl -s "https://api.myquran.com/v2/sholat/jadwal/1301/(date +%Y-%m-%d)" | jq -r ".data.jadwal | [.subuh, .dzuhur, .ashar, .maghrib, .isya] | join(\" | \")"' # Prayer times for Yogyakarta (code 1301)

# Utils
alias tb 'nc termbin.com 9999'
alias calc 'python3 -ic "from math import *; from statistics import *; import cmath"'
alias rand 'openssl rand -int 100'
alias uuid 'uuidgen | tr "[:upper:]" "[:lower:]"'

# --- Lazy Load for Heavy Tools ---
function lazyload
    set -l cmd $argv[1]
    if not functions -q "__original_$cmd"
        function __original_$cmd -V cmd
            eval (functions $cmd | string replace "__original_$cmd" "$cmd")
            unfunction $cmd
            eval "$cmd $argv"
        end
        function $cmd
            __original_$cmd $argv
        end
    end
end
lazyload nvim
lazyload cargo

# --- Initialization ---
_set_title
