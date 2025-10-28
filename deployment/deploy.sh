#!/usr/bin/env bash

set -o errexit

cd "$(dirname "$0")"


REPO=$1

if [ -z "$REPO" ]; then
    printf "Missing argument (GitHub repo; e.g. me/my-repo)\n"
    exit 1
fi


printf "Getting your repo's public key\n"
REPO_KEY=$(curl "https://garnix.io/api/keys/$REPO/repo-key.public")


printf "Replacing recipient key with the right one for your repo\n"
sed -i -e "s/age1ntnen5gwxluad96zly8jjaqycffhehm5hw9glyd5pazhrtp9c5cs8yg2w5/$REPO_KEY/g" ./secrets.nix

printf "Generating and encrypting the CA key\n"
rm ca.age || true
(mkfifo key && ((cat key ; rm key)&) && (echo y | ssh-keygen -N '' -q -f key > ./caHostKey.pub)) | agenix -e ca.age

printf "Generating and encrypting the host key\n"
rm hostKey.age || true
(mkfifo key && ((cat key ; rm key)&) && (echo y | ssh-keygen -N '' -q -f key > /dev/null)) | agenix -e hostKey.age
