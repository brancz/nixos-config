# nixos-config

Frederic's NixOS + home-manager flake.

- `flake.nix` — entry point; home-manager is wired in as a NixOS module, so one
  `nixos-rebuild switch` updates system *and* user environment atomically.
- `hosts/<host>/` — per-machine system config + generated hardware config.
- `home/brancz/` — home-manager user config (shell, editor, gpg, terminal).

## Rebuilding

```sh
sudo nixos-rebuild switch --flake ~/nixos    # or just: rebuild
```

No `#attr` needed: `nixos-rebuild` defaults to looking up
`nixosConfigurations.<current hostname>`, and the flake attribute is named
`brancz-desktop` to match `networking.hostName`. Keep those two in sync when
adding a host, or you'll need an explicit `--flake ~/nixos#<attr>`.

## Setting up a new machine

### 1. Base install

Install NixOS from the ISO (minimal is fine — this flake pulls in the rest),
then clone this repo:

```sh
nix-shell -p git
git clone https://github.com/brancz/nixos-config ~/nixos
```

### 2. Add the host

Generate hardware config for the new machine and commit it:

```sh
mkdir -p ~/nixos/hosts/<host>
nixos-generate-config --show-hardware-config > ~/nixos/hosts/<host>/hardware-configuration.nix
```

Set `networking.hostName = "<host>"` in `hosts/<host>/configuration.nix` and add
a matching `nixosConfigurations.<host>` entry in `flake.nix` — same name in both
places, so `nixos-rebuild` finds it by hostname. Then:

```sh
sudo nixos-rebuild switch --flake ~/nixos#<host>   # explicit: hostname isn't set yet
```

### 3. GPG / YubiKey

**This is the step that is not automated and will bite you.** The Nix config
sets up `gpg-agent`, `scdaemon` and pinentry, but it cannot provision the key
material. On a fresh machine GPG has an *empty keyring*, and:

- The **secret** keys live on the YubiKey — nothing to install.
- The **public** key does **not** live on the YubiKey. GPG needs it in the
  keyring before it can use the card at all: without it there is nothing to
  create the card *stubs* from, and gpg reports a confusing
  `No secret key` even though the key is plugged in.

So the public key must be imported by hand:

```sh
curl -fsSL https://github.com/brancz.gpg | gpg --import

# Trust it ultimately -- it's our own key.
echo "C9384400334E14F446ACBCD5FCC0DBF56269BFB2:6:" | gpg --import-ownertrust

# Let gpg see the card. This is what creates the shadow private-key stubs.
gpg --card-status
```

If you ever renew the subkeys, re-upload the key to GitHub
(`gpg --armor --export 0xFCC0DBF56269BFB2 | gh gpg-key add`). GitHub serves
whatever copy you last uploaded and never refetches, so a stale copy there
means fresh machines import subkeys that look expired — and gpg refuses to
sign with an expired subkey.

Verify. You want `sec#` (primary key absent — it lives offline) and `ssb>`
(the `>` means "on a smartcard"):

```
$ gpg --list-secret-keys --keyid-format=0xlong
sec#  rsa4096/0xFCC0DBF56269BFB2 2020-08-01 [C]
uid                   [ultimate] Frederic Branczyk <fbranczyk@gmail.com>
ssb>  rsa4096/0x98FBDB62D861054B 2020-08-01 [S]
ssb>  rsa4096/0x3FC4AB26A70517C2 2020-08-01 [E]
ssb>  rsa4096/0x576DA6AF8CB9027F 2020-08-01 [SA]
```

Then check signing end to end:

```sh
echo test | gpg --clearsign          # should prompt for the card PIN
git log --show-signature -1          # should say "Good signature ... [ultimate]"
```

SSH needs no extra setup: `gpg-agent` advertises the on-card authentication
subkey automatically once `gpg --card-status` has run once. Get the public
half with `ssh-add -L`.

## Troubleshooting

### Every gpg command hangs, then fails with "No public key"

Symptom — gpg stalls for ~30s and signing/verifying fails:

```
gpg: Note: database_open ... waiting for lock (held by 3850) ...
gpg: keydb_search failed: Connection timed out
gpg: Can't check signature: No public key
```

Cause: a stale lock in `~/.gnupg/public-keys.d/`. A gpg process died without
releasing it. Normally GPG breaks such a lock on its own — but *only* when the
lock's hostname matches the current one, since that's what lets it check
whether the recorded PID is still alive. The lock file is named
`.#lk<addr>.<hostname>.<pid>`, so **renaming the host strands any existing
lock**: to the new hostname it looks like a lock held by a *different machine*,
which GPG will never break. Renaming this host has stranded a lock exactly this
way before, so if you rename again, `gpgconf --kill all` first — that lets the
daemons drop their locks cleanly under the old name.

Fix — confirm the PID is really dead, then clear it:

```sh
ls -la ~/.gnupg/public-keys.d/     # note the pid in the .#lk... filename
ps -p <pid>                        # no output => stale, safe to remove
gpgconf --kill keyboxd gpg-agent
rm ~/.gnupg/public-keys.d/pubring.db.lock ~/.gnupg/public-keys.d/.#lk*
```

### Commits are signed by the wrong subkey

`user.signingkey` must carry a trailing `!` to pin an *exact* subkey. Without
it, gpg treats the ID only as a way to find the primary key and then picks the
newest signing-capable subkey on its own — here that's the `[SA]` auth subkey
(`0x576DA6AF8CB9027F`), not the `[S]` signing subkey. See the comment in
`home/brancz/home.nix`.
