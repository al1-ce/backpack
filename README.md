# backpack
Simple GIT based backup tool written in D

[![aur](https://img.shields.io/aur/version/backpack.svg?logo=archlinux&style=flat-square&logoColor=white)](https://aur.archlinux.org/packages/backpack) 
[![dub](https://img.shields.io/dub/v/backpack.svg?logo=d&style=flat-square)](https://code.dlang.org/packages/backpack) 
[![git](https://img.shields.io/github/v/release/al1-ce/backpack?label=git&logo=github&style=flat-square)](https://github.com/al1-ce/backpack)
![license](https://img.shields.io/aur/license/backpack.svg?style=flat-square)
![aur votes](https://img.shields.io/aur/votes/backpack.svg?style=flat-square) 
![dub rating](https://badgen.net/dub/rating/backpack?style=flat)
![](https://img.shields.io/badge/status-⠀-success?style=flat-square)

## Installation
### Source
Compilation of this repository requires [dlang](https://dlang.org).

1. Clone [this repo](https://github.com/al1-ce/backpack) and build it with `dub build -b release`
2. Copy created binary `./bin/backpack` to somewhere in your path, for example `~/.local/bin/`
3. Or build project with `dub build backpack -b release -c install` to automatically move compiled binary into `/usr/bin`

### Binary

1. Go to [releases](https://github.com/al1-ce/backpack/releases) and download binary.
2. Copy downloaded binary `backpack` to somewhere in your path, for example `~/.local/bin/`

### AUR

1. Install with any aur helper of your choice. Assuming you have `yay` install with `yay -Syu backpack`

### dub

1. Fetch package with `dub fetch backpack`
2. Build and install into `/usr/bin` with `dub build backpack -b release -c install`

## Usage

Backpack keeps configuration in `~/.config/backpack/backup_list` in format `absolutePath:originName:branchName`.

- To add new path to list use `--add`, `-a` flag. You also can set custom origin with `--origin`, `-o` and custom branch with `--branch`, `-B`, otherwise origin of `origin` and branch `master` will be assumed.
- To remove existing path use `--remove`, `-r` flag.
- To start backup use `--backup`, `-b` flag.

Example:
```
Add current folder to paths:
backpack -a .

Add folder to path with custom branch and origin:
backpack -B main -o customOriginAlias -a projectFolder

Remove current folder from paths:
backpack -r .

Backup all:
backpack -b
```

