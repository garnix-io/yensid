## yensid\.builder\.enable



Whether to enable remote building…



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.caCertLocation

Where the CA signature lives



*Type:*
string *(read only)*



*Default:*
` "/etc/ssh/ssh_host_ed25519_key-cert.pub" `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.caDomain



The domain or IP address of the CA\.



*Type:*
string

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.caHostKey



The public key of the CA server



*Type:*
absolute path

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.clientAuthorizedKeyFiles



A list of authorized public ssh-key files that should be allowed to build on this machine



*Type:*
list of absolute path



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.name



The name used for this builder in the SSH module\.



*Type:*
string

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.builder\.sshClientKey



Path of the client key to use to SSH into the CA\.



*Type:*
string

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/builder.nix)



## yensid\.ca\.enable



Whether to enable certificate authority functionality\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca.nix)



## yensid\.ca\.builders



The list of builders\.



*Type:*
attribute set of (submodule)

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca.nix)



## yensid\.ca\.builders\.\<name>\.sshPubKeyFile



Path to the builder’s public SSH key\.



*Type:*
absolute path

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/ca.nix)



## yensid\.proxy\.enable



Whether to enable proxying Nix builds\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)



## yensid\.proxy\.builders



An attrset of builders\.



*Type:*
attribute set of (submodule)

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)



## yensid\.proxy\.builders\.\<name>\.ip



IP address of builder



*Type:*
string

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)



## yensid\.proxy\.builders\.\<name>\.port



The port to use when connecting to the builder\.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*
` 22 `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)



## yensid\.proxy\.loadBalancing\.luaFile



Path to a lua file to load\. It should register a fetch named ‘custom-strategy’



*Type:*
null or absolute path



*Default:*
` null `



*Example:*

```
pkgs.writeText "test.lua" ''
  core.register_fetches('custom-strategy', function(txn)
    return "name-of-backend"
  end)
''

```

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)



## yensid\.proxy\.loadBalancing\.strategy



How to load balance between builders\. The ‘custom’ option can be used to write your own logic in lua\.



*Type:*
string matching the pattern leastconn or string matching the pattern roundrobin or string matching the pattern source or string matching the pattern custom



*Default:*
` "leastconn" `

*Declared by:*
 - [/nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy\.nix](file:///nix/store/3x1p74n23zb7amcw529f3ak7drw529iz-source/modules/proxy.nix)


