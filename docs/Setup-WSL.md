---
layout: default
title: Setup (WSL)
order: 3
---
<!-- Setup-WSL.md                                    Last Change: 2026-11-23 -->

This document is intended to help the user install the Windows Subsystem for
Linux ([WSL](https://learn.microsoft.com/windows/wsl/)) with Debian and prepare
it to build the SLOSH model.  It is an alternative to
[setup-msys](./Setup-MSYS.md) for those who prefer a Linux environment.

<!----------------------------------------------------------------------------->
## ADMINISTRATOR PERMISSION

Step 1 of the installation requires **MS-Windows administrator** rights, which
are usually held by IT rather than the owner of the PC.  On some PCs the Windows
features are already on, so try step 2 first.  If `wsl --install` says a feature
is missing or disabled, ask your IT support to enable WSL (Windows Subsystem for
Linux) for you.  WSL also needs hardware virtualization turned on in the
BIOS/UEFI.  If `wsl --install` reports that virtualization is disabled, IT must
enable it.  Everything after that uses only your own accounts.

<!----------------------------------------------------------------------------->
## INSTALLATION

1. Turn on the Windows features (**requires MS-Windows administrator**):
    1. Windows Start, search for **Windows Features**
    2. Check **Virtual Machine Platform** and **Windows Subsystem for Linux**
    3. Click **OK** and **reboot**

2. Install Debian from a Windows PowerShell window:

    ```powershell
    wsl --update             # Update wsl to the latest version
    wsl --list --online      # Show available distributions
    wsl --install -d Debian  # Install Debian Linux
    ```

    When the installation finishes, Debian starts and asks you to choose a
    Linux user name and password.  These are separate from your MS-Windows
    login.  (Later, start Debian from the Windows Start menu.)

    **Optional:** If you already use Debian for other work, you can give SLOSH
    its own instance, so the two stay separate.  Install it with
    `wsl --install -d Debian --name SLOSH`, and start it with `wsl -d SLOSH`.
    To remove it later, see the last section.

<!----------------------------------------------------------------------------->
## PACKAGE MANAGEMENT

Debian uses 'apt' for its package management.  Some key commands are:

* `sudo apt update` - Update the database of versions.
* `sudo apt upgrade` - Update installed packages.
* `apt search <name>` - Search for packages.
* `apt list --installed` - List all installed packages.
* `sudo apt remove <name>` - Remove a package.

`sudo` asks for the Debian password you chose in step 2 of the installation.

<!----------------------------------------------------------------------------->
## INSTALL SOFTWARE

After an initial install, update the package database and the base packages,
and install the extra packages required by the SLOSH model.

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install git make         # version control; build tool
sudo apt install gcc-multilib     # 32-bit libraries, linker tools
sudo apt install curl xz-utils    # download files; unpack the compiler
sudo apt install vim man-db       # editor; 'man' help pages (optional)
```

SLOSH uses its own copy of the gcc compiler (v4.5.0).  Downloading it and
putting it in your path is the first step (**Linux**) of
[install-slosh](./Install-SLOSH.md).  The 32-bit libraries are needed because
the SLOSH Linux makefile compiles in 32-bit mode by default.  A new Debian
install has neither `curl` nor `xz-utils`, which the download and unpacking of
the compiler need.

<!----------------------------------------------------------------------------->
## CONFIGURATION FILES (OPTIONAL)

Debian already provides a usable `~/.bashrc` and `~/.profile`.  A minimal
`~/.vimrc` will improve vim:

```bash
vim ~/.vimrc
```

Enter the following [vimrc](./config/vimrc)

<!----------------------------------------------------------------------------->
## NEXT STEPS

Keep the SLOSH files in your Linux home directory (`~`), not under `/mnt/c`,
since Linux file access there is much slower.  Continue with
[install-slosh](./Install-SLOSH.md).

<!----------------------------------------------------------------------------->
## REMOVING THE INSTANCE (OPTIONAL)

If you created a separate instance (`--name SLOSH`) and no longer need it,
remove it from a Windows PowerShell window:

```powershell
wsl --unregister SLOSH
```

**Warning:** this permanently deletes the instance and all the files in it.

<!----------------------------------------------------------------------------->
<!-- vim: set norl fdl=0 spell: -->
