#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 YOUR_DOMAIN_NAME";
  exit 1
fi

if !(type npm > /dev/null 2>&1); then
  echo "Please install \`node\` and \`npm\` command."
  exit 1
fi

# 0. bash configure
shopt -s dotglob
BASE_URL="https://astro.debiru.net"
DOMAIN_NAME="$1"

tmps=()
trap 'rm -f "${tmps[@]}"' EXIT

function apply_patch() {
  tmp=$(mktemp)
  tmps+=("$tmp")
  curl -fsSL "${BASE_URL}/build/patch/$1" -o "$tmp"
  cat "$tmp" | awk '/^diff --git /{p=$4;sub(/^b\//,"",p);n=0}/^new file mode/{n=1}n&&p{print p;n=0}' | sort -u | xargs -r rm -f --
  cat "$tmp" | git apply --allow-empty --quiet
}

function git_commit_if() {
  if [ "$(git status --short | wc -l)" = "1" ]; then
    git_commit_ifs "$1" "$2"
  fi
}

function git_commit_ifs() {
  if [ -n "$(git status --short | grep $1)" ]; then
    git add .
    git commit --quiet -m "$2"
  fi
}

# 1. Generate Astro Project
[ ! -e "astro.config.mjs" ] && npm create astro@latest project -- --template minimal --no-install --no-git
[ -d "project" ] && [ -n "$(ls -A project)" ] && mv project/* . && rm -r project
git_commit_ifs ".vscode" "(ask-1) npm create astro@latest"

# 2. Update .gitignore
apply_patch "gitignore.patch"
git_commit_if ".gitignore" "(ask-2) update .gitignore"

# 3. Generate deploy.yml
apply_patch "deploy.yml.patch"
git_commit_if ".github" "(ask-3) add .github/workflows/deploy.yml"

# 4. Remove src/* files
[ -d "src" ] && rm -r src
[ ! -e "src" ] && mkdir src
git_commit_ifs "src/" "(ask-4) remove default src files"

# 5. Update package.json
apply_patch "package.json.patch"
perl -i -pe "BEGIN{undef $/;} s@(?<=[^\n])\z@\n@smg" package.json
git_commit_if "package.json" "(ask-5) update package.json"

# 6. Prepare starter kit
apply_patch "starter-kit.patch"
apply_patch "starter-kit-binary.patch"
perl -i -pe "s@site: '[^']+'@site: 'https://${DOMAIN_NAME}'@smg" src/config/astro.mjs
git_commit_ifs "public/favicon.ico" "(ask-6) generate starter kit"

# 7. Generate package-lock.json
npm install -D glob js-beautify sass stylelint stylelint-config-standard prettier
git_commit_ifs "package-lock.json" "(ask-7) npm install"

# 8. Build
npm run build
git_commit_ifs "astro.json" "(ask-8) npm run build"
