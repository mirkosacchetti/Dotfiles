# Environments: linux is the base; mac and server reuse its shared configs
# and override specific apps with their own version (mac/, server/).
.PHONY: linux mac server font font-mac relink clean-links

# default target follows the OS: `make` does the right thing everywhere
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
all: mac
else
all: linux font
endif

# drop dangling symlinks pointing into Dotfiles, then restow for this OS
relink: clean-links all

clean-links:
	find $(HOME)/.config -maxdepth 2 -type l -lname '*Dotfiles*' ! -exec test -e '{}' \; -print -delete
	find $(HOME) -maxdepth 1 -type l -lname '*Dotfiles*' ! -exec test -e '{}' \; -print -delete

linux:
	# remember to install fzf and ripgrep!
	-git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	# everything in linux/ targets ~/.config, except the $$HOME dotfile packages below
	stow --verbose --target=$(HOME)/.config --restow --ignore='^(Xorg|bash|npm)$$' linux
	stow --verbose --dir=linux --target=$(HOME) --restow Xorg bash npm
	mkdir -p $(HOME)/.local/share/applications
	ln -sf $(HOME)/Dotfiles/applications/*.desktop $(HOME)/.local/share/applications/

mac:
	# remember to install stow, fzf and ripgrep (brew)!
	-git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	mkdir -p $(HOME)/.config/alacritty $(HOME)/.config/tmux $(HOME)/.config/fish $(HOME)/.config/nvim
	# shared from the linux base
	stow --verbose --dir=linux --target=$(HOME)/.config/nvim --restow nvim
	stow --verbose --dir=linux --target=$(HOME)/.config/fish --restow fish
	# mac-specific overrides
	stow --verbose --dir=mac --target=$(HOME)/.config/alacritty --restow alacritty
	stow --verbose --dir=mac --target=$(HOME)/.config/tmux --restow tmux

font-mac:
	brew install --cask font-jetbrains-mono-nerd-font font-fira-code-nerd-font font-ubuntu-nerd-font

server:
	stow --verbose --target=$(HOME) --restow server

font:
	stow --verbose --target=$(HOME)/.config --restow fonts
	rm -rf /tmp/fonts
	mkdir -p /tmp/fonts
	#ubuntu font
	wget -O /tmp/font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Ubuntu.zip
	unzip /tmp/font.zip -d /tmp/fonts/
	cp -R /tmp/fonts/* ~/.local/share/fonts/
	rm -rf /tmp/fonts/*
	#firacode font
	wget -O /tmp/font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
	unzip /tmp/font.zip -d /tmp/fonts/
	cp -R /tmp/fonts/* ~/.local/share/fonts/
	rm -rf /tmp/fonts/*
	#jetbrainsmono font (omarchy/lumon)
	wget -O /tmp/font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
	unzip /tmp/font.zip -d /tmp/fonts/
	cp -R /tmp/fonts/* ~/.local/share/fonts/
	rm -rf /tmp/fonts/*
	#reload font cache
	fc-cache -f -v
