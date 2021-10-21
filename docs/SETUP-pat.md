> *SETUP-PAT.md*     SLOSH Model Help Pages          Last Change: 2021-10-21

The intent of this file is to help the user get a gitHub Private Access Token.

-------------------------------------------------------------------------------
## Reference:
https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token

> Log into your github account (via web)  
> Choose setting (on the right pull-down menu)  
> On left sidebar choose developer settings  
> Choose Personal acces tokens  
> Generate token  
   * Repo, workflow

Save token to "~/.ssh/gitHub_pat"  
```bash 
   vi ~/.ssh/gitHub_pat
   # Paste the token, save, and quit
```

-------------------------------------------------------------------------------
> vim:norl:fdm=marker:fmr=```bash,```
