#!/usr/bin/bash

set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

TARGET_DIR="$(mktemp -d)"
SOURCE_DIR="$(git rev-parse --show-toplevel)"

# set git identity
source $DIR/identity.sh

echo "[-] Setting up repo T=$SECONDS"

mkdir -p $TARGET_DIR
cd $TARGET_DIR
cp -r $SOURCE_DIR/.git $TARGET_DIR
#git init
#git remote add origin git@github.com:commaai/openpilot.git
pre-commit uninstall || true

echo "[-] bringing master-ci and devel in sync T=$SECONDS"
cd $TARGET_DIR
git fetch origin master-ci
git fetch origin devel

git checkout -f --track origin/master-ci
git reset --hard master-ci
git checkout master-ci
git reset --hard origin/devel
git clean -xdf

# remove everything except .git
echo "[-] erasing old openpilot T=$SECONDS"
find . -maxdepth 1 -not -path './.git' -not -name '.' -not -name '..' -exec rm -rf '{}' \;

# reset source tree
cd $SOURCE_DIR
git clean -xdf

# do the files copy
echo "[-] copying files T=$SECONDS"
cd $SOURCE_DIR
cp -pR --parents $(cat release/files_*) $TARGET_DIR/
if [ ! -z "$EXTRA_FILES" ]; then
  cp -pR --parents $EXTRA_FILES $TARGET_DIR/
fi

# TODO: fix this
# append source commit hash and build date to version
GIT_HASH=$(git --git-dir=$SOURCE_DIR/.git rev-parse --short HEAD)
DATETIME=$(date '+%Y-%m-%dT%H:%M:%S')
VERSION=$(cat selfdrive/common/version.h | awk -F\" '{print $2}')
#echo "#define COMMA_VERSION \"$VERSION-$GIT_HASH-$DATETIME\"" > $TARGET_DIR/selfdrive/common/version.h

# in the directory
cd $TARGET_DIR
rm -f panda/board/obj/panda.bin.signed

echo "[-] committing version $VERSION T=$SECONDS"
git add -f .
git status
git commit -a -m "openpilot v$VERSION release"

#if [ ! -z "$PUSH" ]; then
#  echo "[-] Pushing to $PUSH T=$SECONDS"
#  git remote set-url origin git@github.com:commaai/openpilot.git
#  git push -f origin master-ci:$PUSH
#fi

echo $TARGET_DIR
echo "[-] done T=$SECONDS"
