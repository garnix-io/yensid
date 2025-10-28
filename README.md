# yensid

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fgarnix-io%2Fyensid)](https://garnix.io/repo/garnix-io/yensid)

> Remote builders, but more [fantastic](https://en.wikipedia.org/wiki/The_Sorcerer's_Apprentice#Adaptations)
#

This repo provides a proxy for Nix remote builders. The proxy has several
advantages over non-proxied remote builder setups:

- Load balancing is done globally rather than per-client.
- Load balancing strategies can be more sophisticated than just based on the
  number of ongoing builds.
- The load balancing strategy can easily be extended to include automatically
  provisioning (and deprovisioning) new servers when load is high (or low,
  respectively) - i.e., autoscaling.
- A certificate authority for SSH certificates (included in this repo) makes
  it easy to add new servers without having to update every client. Clients
  also don't need to trust-on-first-use.
- The same certificate authority is used for rotating limited-validity builder
  keys regularly. Keys of deprovisioned builders thus quickly and automatically
  become invalid, and handling compromised keys is much easier (it otherwise
  involves updating every client!).

These modules have been designed so that you only pay the complexity cost of
the features you actually use. You can, for example, just enable the proxy,
without changing anything about your existing builders (and without enabling
the CA); you can then *already* benefit from the first two advantages listed
above. You can even *run the proxy on your computer*; the proxy won't be able
to load-balance globally in that case, but it may be able to still make more
informed decisions about how to distribute load.

In addition to the documentation below, a list of all configuration options is
available [here](./docs/options.md).

# Usage

There are three modules included in this project: `proxy`, `ca`, and `builder`.
The main one is the `proxy`, and you don't need the others to get started.
`ca` adds functionality for a SSH certificate authority, and `builder` enables
additional functionality in the builders (such as renewing their SSH
certificates. You will also need to configure the clients (e.g., your developer
machine).

If you are using SSH certificates, the first step is to generate the key
(ideally already in the CA server, if it's already been provisioned).


## Client

On your client, remove all build machines and replace them with the single
ssh proxy:

```nix
buildMachines = [{
  sshUser = "builder-ssh";
  sshKey = <your-key>;
  protocol = "ssh-ng";
  hostName = <proxy-hostname>;
  # Each proxy can only service a homegenous set of builder systems (that is,
  # there can be multiple systems, but all builders must support all of those
  # systems.
  systems = [ "x86_64-linux" ];
}];
```

If you are using SSH certificates, you will also need some extra configuration:

```nix
programs.ssh = {
  knownHosts.yensid = {
    publicKeyFile = <path-to-public-key>
    certAuthority = true;
  };
};
```

If you are *not* using SSH certificates, you will get errors like this:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is ???.
Please contact your system administrator.
Add correct host key in .../.ssh/known_hosts to get rid of this message.
Offending ED25519 key in .../.ssh/known_hosts:306
```

This is because there will be multiple servers, with different SSH keys, behind
the same proxy. You can add multiple lines to your `known_hosts` manually
to fix this. That said, it's both safer and more pleasant to use certificates.


## Proxy

The proxy is the main component of yensid. It load balances between your remote
builders based on a configurable strategy and, if you are using SSH
certificates, allows clients to be oblivious to details of your builders (host
names, SSH keys, how many there are).

The main configuration options are what builders there are, and what the load
balancing strategy is (see the [Custom load balancing](#custom-load-balancing)
section for more details).

## CA

The CA is an optional component for when you want to use SSH certificates
(rather than keys) for authentication. This is both nicer and safer, but
requires corresponding changes to the builder, which you might not always
be able to make.

Usually, running the CA in the same server as the proxy is a sensible setup.
If you want to limit the amount of software running in, and access given to,
the CA, then you can run it as a separate server.

If you are not using SSH certificates, you do not need to enable or deploy
this module.


## Builder

If SSH-based certificates are enabled, the builders need to regularly request
new certificates from the CA. To do this, the CA is given the SSH keys of the
builders at configuration time. It then allows machines with those known SSH
keys to request SSH certificates *for just that key* (via `ForceCommand`). Those
certificates have a configurable validity (by default, a day).

The builder module thus enables a systemd service that automatically renews
its certificates.

If you want load balancing algorithm to take into account resource utilization
such as CPU, memory, and disk usage, you should also (safely) expose those to
the `proxy`.


## Custom load balancing

Load balancing by default is based on number of connections. This already gives
you (if every client uses the same yensid proxy) a *global* load balancing
(meaning that, unlike vanilla remote builders, *all* builds are considered, not
just the ones in the same client).

But you can also have arbitrarily complex load balancing strategies. You need
to write a HAProxy-compatible lua script describing the strategy. As an example,
you could (as a background [task](https://www.arpalert.org/src/haproxy-lua-api/3.2/index.html#core.register_task)) periodically query your builders for various usage
statistics (CPU, memory, disk, network, etc.).

# Running it with VMs

We've also added some VMs to the flake file of this repo so that you can
easily spin up the entire infrastructure for local testing. We use
[nixos-compose](https://github.com/garnix-io/nixos-compose) for that.

nixos-compose is in the dev shell, so after entering a devshell you can test it
out by running:

```bash
$ nixos-compose up
# nixos-compose adds /etc/hosts file too late for haproxy, so you will need to restart it:
$ nixos-compose ssh proxy -- sudo systemctl restart haproxy
# now, on the client `nix` will build on the cluster:
$ nixos-compose ssh client -- nix build ...
# you can also ssh in to the cluster directly to observe the load balancing:
$ nixos-compose ssh client -- sudo ssh cluster -i /etc/ssh/client -l builder-ssh hostname
```

# Running it on localhost

Though primarily meant as an external service. yensid can be an improvement
over vanilla remote builders even if you never deploy it to a remote, and run
it on localhost instead. This makes it easy to try it out.

If this is how you are using it, you probably want a custom lua load-balancing
script.

# Running it on garnix

We have provided a proxy NixOS configuration that you can quickly customize and
deploy on garnix. If you already have an account on garnix, deploying is simple:

- Fork this repository
- Make sure garnix is enabled in your fork
- Run `nix run .#deployProxyViaGarnix <your-repo>`
- Add any builders to ./deployment/proxy-ca.nix
- Commit and push the change (to the main branch)

Note that you should use [raw domains](https://garnix.io/docs/hosting/raw-domains)
to access the proxy.

# Get in touch
;
If you have questions or suggestions, either open an issue in this repo, or
come say hi in the garnix [Discord](https://discord.gg/XtDrPsqpVx) or
[Matrix](https://matrix.to/#/#garnix-main:matrix.org).
