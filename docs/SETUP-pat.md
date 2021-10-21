> *SETUP-PAT.md*     SLOSH Model Help Pages          Last Change: 2021-10-21

The intent of this file is to help the user get a gitHub Private Access Token.

-------------------------------------------------------------------------------
## Reference:
https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

1. Log into your github account (via web)
2. Choose setting (on the right pull-down menu
3. On left sidebar choose developer settings
4. Choose Personal acces token
5. Generate token
   * Repo, workflow

Non **WCOSS** systems:
* Save token to "~/.ssh/gitHub_pat"
```bash
   vi ~/.ssh/gitHub_pat
   # Paste the token, save, and quit
```

**WCOSS** system has ~/.ssh owned by root with 755, so:
* Save token to "~/.ssh2/gitHub_pat"
* You'll need to switch to $(cat ~/.ssh2/gitHub_pat) {from ~/.ssh/) in the rest
of the instructions.
```bash
   mkdir ~/.ssh2
   chmod 755 ~/.ssh2
   vi ~/.ssh2/gitHub_pat
   # Paste the token, save, and quit
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
