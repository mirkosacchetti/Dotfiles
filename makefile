.PHONY: work linux font

all: work linux font

work:
	# remember to install fzf and ripgrep!
	-git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	stow --verbose --target=$(HOME)/.config --restow nvim
	stow --verbose --target=$(HOME)/.config --restow terminals
	stow --verbose --target=$(HOME) --restow npm

linux:
	stow --verbose --target=$(HOME)/.config --restow linux
	stow --verbose --target=$(HOME) --restow Xorg
	stow --verbose --target=$(HOME) --restow bash

font:
	stow --verbose --target=$(HOME)/.config --restow fonts
	#cleaning 
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
	
