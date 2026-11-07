# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

export EDITOR=nvim
export VISUAL=nvim
. "$HOME/.cargo/env"


#######################################################################
# Gruvbox PS1
__prompt_info() {
    local git=""
    local branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git=$' \001\e[1;38;5;3m\002('"${branch}"$')\001\e[m\002'
    fi

    local venv=""
    if [ -n "$VIRTUAL_ENV" ]; then
        venv=$' \001\e[1;38;5;5m\002('"$(basename $VIRTUAL_ENV)"$')\001\e[m\002'
    fi

    echo "$git$venv"
}

if [ $(id -u) -eq 0 ]; then
    usercol="\[\033[1;38;5;1m\]"
else
    usercol="\[\033[1;38;5;6m\]"
fi

timecol="\[\033[1;38;5;2m\]"
pathcol="\[\033[1;38;5;4m\]"
bracketcol="\[\033[1;38;5;8m\]"
reset="\[\033[m\]"

# PS1="\n${bracketcol}[ ${timecol}\@ ${usercol}\u${bracketcol} ]${reset}\$(__prompt_info) ${pathcol}\w${reset}\n❯ "
PS1="\n${bracketcol}[ ${timecol}\$(date +'%I:%M:%S') ${usercol}\u${bracketcol} ]${reset}\$(__prompt_info) ${pathcol}\w${reset}\n❯ "
unset usercol timecol pathcol bracketcol reset
#######################################################################

power() {
    local file="/sys/class/power_supply/macsmc-battery/capacity"
    if [[ -r "$file" ]]; then
        printf "%s\n" "$(cat "$file")"
    else
        echo "Battery information unavailable"
    fi
}

watt() {
    local file="/sys/class/power_supply/macsmc-battery/power_now"
    if [[ -r "$file" ]]; then
        printf "%s\n" "$(cat "$file")"
    else
        echo "Battery information unavailable"
    fi
}

earphones() {
    bluetoothctl power on
    bluetoothctl agent on
    bluetoothctl connect 74:D7:13:CD:21:E6
}
