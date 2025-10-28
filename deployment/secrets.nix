let key = builtins.readFile ./repo-key;
in
{
  "ca.age".publicKeys = [ key ];
  "hostKey.age".publicKeys = [ key ];
  "builderHostKey.age".publicKeys = [ key ];
}
