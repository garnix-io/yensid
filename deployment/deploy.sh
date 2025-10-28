#!/usr/bin/env bash

set -o errexit

cd "$(dirname "$0")"


REPO=$1

if [ -z "$REPO" ]; then
    printf "Missing argument (GitHub repo; e.g. me/my-repo)\n"
    exit 1
fi


printf "Getting your repo's public key\n"
curl "https://garnix.io/api/keys/$REPO/repo-key.public" > repo-key

printf "Generating and encrypting the CA key\n"
rm key.pub || true
rm ca.age || true
(mkfifo key && ((cat key ; rm key)&) && (echo y | ssh-keygen -N '' -q -f key > /dev/null)) | agenix -e ca.age
mv key.pub caHostKey.pub

printf "Generating and encrypting the host key\n"
rm hostKey.age || true
(mkfifo key && ((cat key ; rm key)&) && (echo y | ssh-keygen -N '' -q -f key > /dev/null)) | agenix -e hostKey.age
rm key.pub

printf "Done. Check the changes, commit, and push (to 'main') for garnix to deploy\n"
