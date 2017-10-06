# Installation of the script

1.) Copy the dbb-Skript into /usr/local/bin:

```bash
sudo cp dbb /usr/local/bin/
```

2.) Create a symlink
```bash
sudo ln -s /usr/local/bin/dbb /usr/local/bin/dbbi
```

3.) Copy the configfile to /etc/dbb.cfg or into ~/.dbb.cfg of the backupuser

```bash
sudo cp dbb.cfg /etc
```

or

```bash
sudo cp dbb.cfg /home/backupuser/.dbb.cfg
```

Please use the correct path of the homedirectory of your backupuser.

4.) Edit the configfile that it fits to your environment.

5.) Make changes to the skript and make som pull requests ;-).


