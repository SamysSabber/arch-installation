# CLAUDE.md — Arch Linux Dotfiles & Installation Scripts

This repository contains automated Arch Linux installation scripts and personal dotfiles for a Hyprland-based desktop environment.

## Repository Structure

```
arch-installation/
├── install.sh          # Full Arch Linux base installation script
├── post-install.sh     # Post-install: AUR helper, apps, and dotfile deployment
├── alacritty/
│   └── alacritty.toml  # Alacritty terminal configuration
├── btop/
│   └── btop.conf       # btop system monitor configuration
├── hypr/
│   ├── hyprland.conf   # Main Hyprland config (sources all sub-configs)
│   ├── monitors.conf   # Monitor layout definitions
│   ├── programs.conf   # Application variable definitions ($terminal, $browser, etc.)
│   ├── autostart.conf  # exec-once entries for session startup
│   ├── env.conf        # Environment variables (cursor size, gaming flags)
│   └── permissions.conf # Hyprland permission rules (screencopy, plugins)
└── nvim/
    ├── init.lua        # Neovim entry point (bootstraps lazy.nvim via LazyVim)
    ├── lazyvim.json    # LazyVim extras and version pin
    ├── lazy-lock.json  # Plugin lockfile (do not edit manually)
    ├── stylua.toml     # Lua formatter settings (2-space indent, 120 col width)
    └── lua/
        ├── config/
        │   ├── lazy.lua      # lazy.nvim bootstrap
        │   ├── options.lua   # Neovim options (extends LazyVim defaults)
        │   ├── keymaps.lua   # Custom keymaps (extends LazyVim defaults)
        │   └── autocmds.lua  # Autocommands
        └── plugins/
            ├── colorscheme.lua  # tokyonight (moon, transparent)
            ├── lualine.lua      # Statusline (fully transparent, mode-colored)
            ├── claudecode.lua   # Claude Code Neovim integration
            ├── wich-key.lua     # which-key configuration
            └── example.lua     # LazyVim plugin example/template
```

## Installation Workflow

### 1. Base Installation (`install.sh`)

Run from the Arch ISO live environment **as root**. The script is interactive and will prompt for:

- Disk selection (supports both NVMe `nvme0n1` and SATA/virtio `sda`/`vda`)
- Hostname, username, root password, user password

**What it does:**
1. Sets German keyboard layout and Berlin timezone
2. Runs `reflector` to select fastest German mirrors
3. GPT-partitions the disk: 1 GB EFI (`ef00`) + remaining root (`8300`)
4. Formats: FAT32 for EFI, Btrfs for root
5. Creates Btrfs subvolumes: `@` (root), `@home`, `@snapshots`
6. Mounts with `compress=zstd`
7. `pacstrap`s: `base linux linux-firmware vim sudo`
8. `arch-chroot`s and configures: locale (`de_DE.UTF-8`), hostname, users, sudo (`wheel` group), NetworkManager, GRUB (EFI), Hyprland + `xdg-desktop-portal-hyprland`, Dolphin, Kitty, GDM
9. Unmounts and reboots

> **Note:** The script uses German prompts and confirms with `j` (ja) instead of `y`.

### 2. Post-Installation (`post-install.sh`)

Run as the **regular user** after first boot. No arguments needed.

**What it does:**
1. Installs `base-devel git`, builds and installs `yay` (AUR helper) from source
2. Installs pacman packages: `alacritty neovim obsidian bitwarden steam btop spotify-launcher hyprshot hyprpolkitagent`
3. Installs AUR packages via yay: `visual-studio-code-bin vesktop zen-browser-bin peaclock protonup-qt brave-bin`
4. Installs fonts: `ttf-jetbrains-mono-nerd noto-fonts-emoji`
5. Sets up PipeWire audio stack: `pipewire pavucontrol easyeffects wireplumber pipewire-pulse`
6. Sets up QEMU/KVM virtualisation: `qemu-full libvirt virt-manager`, enables `libvirtd`, adds user to `libvirt` group
7. Clones this repository and copies configs: `cp -r .config ~/`

> **Important:** The `cp -r .config ~/` step assumes the dotfiles are structured as `.config/<app>/` inside the repo. Verify the directory layout before running if repo structure changes.

## Dotfile Conventions

### Hyprland (`hypr/`)

The main `hyprland.conf` sources all sub-configs. **Always edit the appropriate sub-file** rather than the monolithic main file:

| File | Purpose |
|---|---|
| `monitors.conf` | `monitor =` directives |
| `programs.conf` | `$variable` definitions for app paths |
| `autostart.conf` | `exec-once =` entries |
| `env.conf` | `env =` entries |
| `permissions.conf` | `permission =` entries |

**Current monitor layout:**
- `DP-2`: 2560×1440 @ 165 Hz, position `0,0`, scale `1` (primary)
- `HDMI-A-1`: 1920×1080 @ 60 Hz, position `-1920,260`, scale `1` (left secondary)

**Application variables (from `programs.conf`):**
```
$terminal        = alacritty
$fileManager     = dolphin
$menu            = wofi --show drun
$browser         = zen-browser
$processManager  = alacritty -e btop
$screenshotRegion = hyprshot -m region -o ~/screenshots/
```

**Key bindings (modifier = SUPER):**

| Binding | Action |
|---|---|
| `SUPER + Q` | Open terminal (alacritty) |
| `SUPER + C` | Close active window |
| `SUPER + E` | Open file manager (dolphin) |
| `SUPER + T` | Open browser (zen-browser) |
| `SUPER + B` | Open btop in terminal |
| `SUPER + SPACE` | App launcher (wofi) |
| `SUPER + F` | Fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Toggle pseudotile (dwindle) |
| `SUPER + J` | Toggle split (dwindle) |
| `SUPER + PRINT` | Screenshot region |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + M` | Exit Hyprland |
| `SUPER + [1-0]` | Switch workspace |
| `SUPER + SHIFT + [1-0]` | Move window to workspace |

**Layout:** Dwindle with `pseudotile` and `preserve_split` enabled.

**Gaming environment variables (in `env.conf`):**
- `DXVK_ASYNC=1` — async shader compilation
- `PROTON_NO_ESYNC=0` / `PROTON_NO_FSYNC=0` — esync and fsync enabled

### Alacritty (`alacritty/`)

- **Font:** JetBrainsMono Nerd Font, size 11.5
- **Opacity:** 0.65 (transparent background)
- **Custom binding:** `Shift+Return` → sends `ESC + CR` (useful for some TUI apps)

### Neovim (`nvim/`)

Based on **LazyVim** (v8). Entry point is `init.lua` → `lua/config/lazy.lua`.

**Formatter:** StyLua — 2-space indents, 120-character column width.

**Active LazyVim extras (from `lazyvim.json`):**
- AI: `claudecode`, `copilot`
- Coding: `yanky`, `dial`, `inc-rename`
- Languages: clangd, cmake, docker, git, go, java, kotlin, markdown, php, prisma, python, ruby, rust, sql, svelte, tailwind, toml, typescript
- Testing: `test.core`
- Utils: `dot`, `mini-hipatterns`

**Custom plugins:**
- `folke/tokyonight.nvim` — moon style, fully transparent (bg + sidebars + floats)
- `nvim-lualine/lualine.nvim` — transparent statusline, mode-aware color (normal=blue, insert=green, visual=magenta, command=yellow, replace=red)
- `coder/claudecode.nvim` — Claude Code integration, loaded eagerly (`lazy = false`)

**When modifying Neovim config:**
- Add new plugins under `lua/plugins/` as separate files returning a plugin spec table
- Do not edit `lazy-lock.json` directly — it is managed by `lazy.nvim`
- Run `:Lazy sync` inside Neovim after adding plugins; the lockfile will update automatically
- Lua formatting: run `stylua` before committing (2 spaces, 120 cols)

### btop (`btop/`)

Minimal config: `theme_background = false` (transparent background to match the desktop aesthetic).

## System Details

| Setting | Value |
|---|---|
| OS | Arch Linux |
| Display server | Wayland (Hyprland compositor) |
| Locale | `de_DE.UTF-8` |
| Keyboard layout | `de` (German) / `de-latin1` (console) |
| Timezone | `Europe/Berlin` |
| Shell user default | bash |
| Filesystem | Btrfs with zstd compression, subvolumes |
| Bootloader | GRUB (EFI, `x86_64-efi` target) |
| Display manager | GDM |
| Audio | PipeWire + WirePlumber + pipewire-pulse |
| Networking | NetworkManager |
| Virtualisation | QEMU/KVM + libvirt + virt-manager |

## Development Notes for AI Assistants

- **Shell scripts use German comments and prompts.** Maintain this convention when extending them.
- **Hyprland config is split across files.** Always check `hyprland.conf` `source =` lines and edit the correct sub-file.
- **The `post-install.sh` `cp -r .config ~/` step** expects dotfile directories to sit under a `.config/` directory in the repo root. If you add a new application's config, place it under `.config/<appname>/` accordingly.
- **Neovim plugin files** must return a valid lazy.nvim plugin spec (a table). Each file in `lua/plugins/` is auto-loaded by LazyVim.
- **Do not commit `lazy-lock.json` changes** unless intentionally updating plugin versions.
- **Gaming-related env vars** in `env.conf` are intentional — do not remove them.
- **Tearing is enabled** in Hyprland (`allow_tearing = true`) — this is intentional for gaming performance.
