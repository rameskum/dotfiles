# My DOTFILES

This directory contains the dotfiles for my system.

## Requirements

Ensure you have the following installed on your machine.

### Brew

Install [Homebrew](https://brew.sh/)

### Git

```bash
brew install git
```

### Stow

```bash
brew install stow
```

### Alacritty

```bash
brew install --cask alacritty
```

## Installation

First, checkout the dotfiles repo in your $HOME directory using git.

```bash
git clone git@github.com:rameskum/dotfiles.git
cd dotfiles
```

Thew use GNU stow to create symlinks.

```bash
stow .
```

Restart the terminal.
