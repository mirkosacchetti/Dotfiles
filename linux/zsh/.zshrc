# Zsh Settings
unsetopt beep
export TERM=xterm-256color

# Aliases
alias jn="jupyter notebook"
alias python="python3"
alias vim="nvim"
alias vi="vim"
# Aliases as Shortcuts for My Favorite Folders
alias do="cd ~/Dotfiles"
alias wn="cd ~/Code/WiNet"
alias ms="cd ~/Writing/MirkoSacchetti"
alias co="cd ~/Code"
# Sunday as first day of the week is an abomination
alias cal="cal -3m"

# Set Environment Variables
# NPM
export NPM_PACKAGES=$HOME/.npm-packages
export PATH=$PATH:$NPM_PACKAGES/bin
# Go
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin
# Cargo e Rustup
export CARGO_HOME=$HOME/.cargo
export PATH=$PATH:$CARGO_HOME/bin
export RUSTUP_HOME=$HOME/.rustup
export PATH=$PATH:$RUSTUP_HOME/bin

# Set Environment for Linux or MacOS
os=$(uname)
case $os in
    "Darwin")
        export PATH=$PATH:/opt/homebrew/bin
        ;;
    "Linux")
        export PATH=$PATH:/opt/nvim-linux64/bin
        ;;
esac

# Find a random file in the current folder
pickrandom() {
    find . -maxdepth 1 -mindepth 1 -type d | shuf -n 14
}

# Generate random strings for passwords
newpass() {
    for i in {1..3}; do
        openssl rand -base64 10 | tr -d '/+=\n' | head -c 8; echo
    done
}

# Print the color value of a pixel
colorpicker() {
    grim -g "$(slurp -p)" -t ppm - | magick - -format '%[pixel:p{0,0}]' txt:-
}

# Make a Quick Decision
coin() {
    if (( RANDOM % 2 == 0 )); then
        echo "No."
    else
        echo "Yes."
    fi
}

# Make a Poderate Decision
m8b() {
    net_responses=(
        "Yes, prioritize this right away to push your venture forward"
        "No, you should focus on a more profitable or strategic activity"
        "Absolutely, it aligns perfectly with your long-term vision"
        "No, it doesn't seem to be the best use of your limited resources"
        "Yes, it's a wise investment that can elevate you"
        "Better not, you risk stretching yourself too thin"
        "Yes, it's a strategic move that could boost your brand presence"
        "Hold off: reconsider how to make the most of your resources"
    )
    reflection_questions=(
        "How does this choice affect your core business goals?"
        "Are you investing your time in the area with the highest leverage?"
        "Could a simpler or more automated approach save you effort?"
        "Is this decision aligned with your envisioned growth trajectory?"
        "What measurable outcome do you hope to achieve?"
        "Are you focusing on what truly drives revenue or just staying busy?"
        "Could outsourcing or a short-term partnership provide better results?"
        "What's the opportunity cost of waiting versus acting now?"
    )
    combined_prompts=(
        "Yes, but check if you have enough funds and time to see it through"
        "No, yet consider a low-effort alternative to test this idea"
        "Go for it, but set clear milestones to monitor progress"
        "Pause: are there more pressing tasks that need attention first?"
        "Proceed, but track results carefully to pivot if needed"
        "Wait: gather more market data or user feedback before committing"
        "Yes, but plan how you'll balance this with your daily operations"
        "No, but use the insights gained to refine your overall strategy"
    )
    
    output_type=$((RANDOM % 3))
    case $output_type in
        0)
            index=$((RANDOM % ${#net_responses[@]} + 1))
            echo ${net_responses[$index-1]}
            ;;
        1)
            index=$((RANDOM % ${#reflection_questions[@]} + 1))
            echo ${reflection_questions[$index-1]}
            ;;
        2)
            index=$((RANDOM % ${#combined_prompts[@]} + 1))
            echo ${combined_prompts[$index-1]}
            ;;
    esac
}

# Iterates through files in ~/.config/keys, converting filenames to uppercase variable names and exporting their contents as environment variables
if [ -d ~/.config/keys ]; then
    for key_file in ~/.config/keys/*; do
        if [ -f "$key_file" ]; then
            file_name=$(basename "$key_file")
            var_name=$(echo "$file_name" | tr '[:lower:]' '[:upper:]')
            key_content=$(cat "$key_file")
            if [ -n "$key_content" ]; then
                export "$var_name"="$key_content"
            fi
        fi
    done
fi

# Optional: Add zsh-specific settings
# Enable autocompletion
autoload -Uz compinit
compinit

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

