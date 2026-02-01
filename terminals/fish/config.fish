# Fish Settings
set fish_greeting
set -g theme_nerd_fonts yes
set -g TERM xterm-256color
export TERM=xterm-256color
export EDITOR=nvim
# Aliases
alias jn="jupyter notebook"
alias python="python3"
alias vim="nvim"
alias vi="vim"
# Aliases as Shortcuts
alias dl="cd ~/Downloads"
alias do="cd ~/Dotfiles"
alias wn="cd ~/Code/WiNet"
alias ms="cd ~/Writings/MS/"
alias rr="cd ~/Writings/RR/"
alias co="cd ~/Code"
# Sunday as first day of the week is a bestemmia
alias cal="cal -3m"

# Set Environment Variables
# NPM
set -x NPM_PACKAGES $HOME/.npm-packages
set -x PATH $PATH $NPM_PACKAGES/bin
# Go
set -x GOPATH $HOME/.go
set -x PATH $PATH $GOPATH/bin
# Cargo/Rustup
set -x CARGO_HOME $HOME/.cargo
set -x PATH $PATH $CARGO_HOME/bin
set -x RUSTUP_HOME $HOME/.rustup
set -x PATH $PATH $RUSTUP_HOME/bin
# Local apps and Web apps
set -x PATH $PATH $HOME/.local/bin
# Set Environment Variables for Linux or MacOS
set os (uname)
switch $os
    case Darwin
        set -x PATH $PATH /opt/homebrew/bin
end

# Functions and Tools
function coin
    if test ( math (random) % 2) -eq 0
        echo "No."
    else
        echo "Yes."
    end
end

function pickrandom
    find . -maxdepth 1 | shuf -n 14
end

function newpass
    set -l length 8
    if not test (count $argv) -eq 0
        set length $argv[1]
    end
    for i in (seq 3)
        openssl rand -base64 40 | tr -d '/+=\n' | head -c "$length"
        echo
    end
end

function colorpicker
    grim -g "(slurp -p)" -t ppm - | magick - -format '%[pixel:p{0,0}]' txt:-
end

function sanitize_title
    if test (count $argv) -eq 0
        echo "No title..."
        return 1
    end
    set title $argv[1]
    set clean (string replace -ra '[\W]+' '_' $title)
    set clean (string replace -ra '_+' '_' $clean)
    set clean (string replace -ra '^_+|_+$' '' $clean)
    echo $clean
end

function dl_audio
    set rawtitle (yt-dlp --get-title $argv[1] 2>/dev/null)
    if test $status -ne 0
        echo "Error: Could not get video title"
        return 1
    end
    set title (sanitize_title $rawtitle)
    yt-dlp -f "bestaudio[ext=webm]/bestaudio[ext=m4a]/bestaudio" \
        --extract-audio \
        --audio-format opus \
        --audio-quality 0 \
        -o "~/Audio/dl_audio/$title.%(ext)s" \
        $argv[1]
end

function dl_video
    set rawtitle (yt-dlp --get-title $argv[1] 2>/dev/null)
    if test $status -ne 0
        echo "Error: Could not get video title"
        return 1
    end
    set title (sanitize_title $rawtitle)
    yt-dlp -f "bestvideo+bestaudio/best" \
        --merge-output-format mp4 \
        -o "~/Videos/dl_video/$title.%(ext)s" \
        $argv[1]
end

function convert_audio_to_opus
    if test (count $argv) -lt 1
        echo "no input file"
        return 1
    end
    set rawtitle $argv[1]
    set title (sanitize_title $rawtitle)
    set output "$title.opus"
    ffmpeg -i $rawtitle -c:a libopus -b:a 160k $output
end

# Load Local Api Keys (es. ANTHROPIC_API_KEY GOOGLE_AI_API_KEY OPENAI_API_KEY )
# 1. Iterates through files in ~/.config/keys
# 2. Converting filenames to uppercase variable names
# 3. exporting their contents as environment variables
function load_my_api_keys
    if test -d ~/.config/keys
        for key_file in ~/.config/keys/*
            if test -f $key_file
                set file_name (basename $key_file)
                set var_name (string upper $file_name)
                set key_content (cat $key_file)
                if test -n "$key_content"
                    set -gx $var_name $key_content
                end
            end
        end
    end
end


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/home/m/.opam/opam-init/init.fish' && source '/home/m/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
# END opam configuration
