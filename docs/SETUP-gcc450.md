> *setup-gcc.md*        SLOSH Model Help Pages          Last Change: 2021-08-12

The intent of this file is to help the user setup the version of gcc that
SLOSH used on a linux system.  Its been tested using debian-linux (buster).

-------------------------------------------------------------------------------
## GCC 4.5.0

1. Create a compiler area in your home directory:
```bash
   mkdir -p ~/gcc
   cd ~/gcc
   wget https://gfortran.meteodat.ch/download/x86_64/releases/gcc-4.5.0.tar.xz
   wget https://gfortran.meteodat.ch/download/x86_64/gcc-infrastructure.tar.xz
   tar -xJf gcc-4.5.0.tar.xz
   tar -xJf gcc-infrastructure.tar.xz
```

2. Teach the system about your compiler.

NOTE - *The most elegant way is via 'sudo update-alternatives --install'
  unfortunately that requires admin rights.*

Add it to the beginning of your path (You'll likely want to do this in
  your .bash_profile):

```bash
   # Teach it to use the gcc version
   export PATH=/home/$USER/gcc/gcc-4.5.0/bin:$PATH

   # Teach it where to find libgfortran.so.3 and gcc's shared libraries
   export LD_LIBRARY_PATH=/home/$USER/gcc/gcc-4.5.0/lib:/home/$USER/gcc/lib64
```

NOTE - While we could simplify the LD_LIBRARY_PATH via a softlink for
  libgfortran.so.3 in /home/$USER/gcc/lib64, that would obfuscate dependencies
  and make it harder to have multiple versions.

3. Link the 32-bit version of the crt1.o, crti.o, crtn.o libraries.
```bash
   cd ~/gcc/gcc-4.5.0/lib
   ln -s /lib32/crt1.o
   ln -s /lib32/crti.o
   ln -s /lib32/crtn.o
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
