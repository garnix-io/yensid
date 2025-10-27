## zzz\.builder\.enable



Whether to enable Enable this machine as a remote builder\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.caCertLocation

Where the CA signature lives



*Type:*
string *(read only)*



*Default:*
` "/etc/ssh/ssh_host_ed25519_key-cert.pub" `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.caDomain



The domain or IP address of the CA\.



*Type:*
string

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.caHostKey



The public key of the CA server



*Type:*
absolute path

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.clientAuthorizedKeyFiles



A list of authorized public ssh-key files that should be allowed to build on this machine



*Type:*
list of absolute path



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.name



The name used for this builder in the SSH module\.



*Type:*
string

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.builder\.sshClientKey



Path of the client key to use to SSH into the CA\.



*Type:*
string

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/builder.nix)



## zzz\.ca\.enable



Whether to enable Enable this machine as a certificate authority\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca.nix)



## zzz\.ca\.builders



The list of builders\.



*Type:*
attribute set of (submodule)

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca.nix)



## zzz\.ca\.builders\.\<name>\.sshPubKeyFile



Path to the builder’s public SSH key\.



*Type:*
absolute path

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/ca.nix)



## zzz\.proxy\.enable



Whether to enable Enable this machine as a proxy\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy.nix)



## zzz\.proxy\.builders



The list of builders



*Type:*
list of (submodule)

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy.nix)



## zzz\.proxy\.builders\.\*\.ip



IP address of builder



*Type:*
string

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy.nix)



## zzz\.proxy\.builders\.\*\.name



Name for the builder\. Used internally\.



*Type:*
string

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy.nix)



## zzz\.proxy\.builders\.\*\.port



The port to use when connecting to the builder\.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*
` 22 `

*Declared by:*
 - [/nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy\.nix](file:///nix/store/1108rj2qdqk89gbw4nj8qh7xzzh11dwp-source/modules/proxy.nix)


