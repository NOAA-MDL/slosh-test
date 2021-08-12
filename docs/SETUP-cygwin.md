> *SETUP-cygwin.md*     SLOSH Model Help Pages          Last Change: 2021-08-12

The intent of this file is to help the user install Cygwin.

-------------------------------------------------------------------------------
1. Get Cygwin's [setup.exe](http://cygwin.com/setup-x86_64.exe)
2. From a command prompt:
```bash
   c:\Users\tayloraa\>cd Downloads
   c:\Users\tayloraa\Downloads>setup-x86_64.exe --no-admin
      * Next; Install from internet
      * c:\cygwin64 ; Just Me
      * c:\Users\tayloraa\Downloads
      * Next; http://www.gtlib.gatech.edu

! If there is no mirror download list, quit and try:
   c:\Users\tayloraa\Downloads>setup-x86_64.exe --no-admin -B -O \
      -s http://mirror.clarkson.edu/cygwin

      * Select packages
         * Archive:       * unzip; zip
         * Devel:         * autoconf; automake; gcc-core; gcc-fortran
                          * git; indent; make; subversion
         * Editors:       * vim
         * Interpreters:  * python38; tcl
         * Net:           * curl; rsync; wget
      * Add icon to Start Menu
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
