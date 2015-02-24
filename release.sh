#!/usr/bin/env bash

# set +e # break script on first error
set -e # make script exit when a command fails
# set -u # to exit when script tries to use undeclared variables
set -x # to trace what gets executed. Useful for debugging

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__script_path="${__file/${__root}/.}" # subsring replace: ${string/pattern/replacement}
__base="$(basename ${__file} .sh)"

# /---------------------------------------------\
# |           CHANGE THESE VALUES               |
# |---------------------------------------------|
# |                  ↓↓↓↓↓                      |

base_repo_name="travis-deploy-source"
base_github_repo="Bazai/travis-deploy-source"
bower_repo_name="travis-deploy-destination"
bower_github_repo="Bazai/travis-deploy-destination"

git_config_email="robot@health-samurai.io"
git_config_name="Travis CI Deployer"

deploy_key_name="travis_deploy_source_deploy_key"
encoded_deploy_key_location="script/travis_deploy_source_deploy_key.enc"
deploy_enc_key="${encrypted_733433ba94d5_key}"
deploy_enc_iv="${encrypted_733433ba94d5_iv}"

# TODO: Check on Travis
function build() {
  echo -e "# Hello 1\n##Hello 2\n###Hello 3" > file.md
}

# BazZy: CHECKED
function copy() {
  cp script/release.sh  ../"${bower_repo_name}"/
  cp file.md            ../"${bower_repo_name}"/
  cp README.md          ../"${bower_repo_name}"/
}

# |                  ↑↑↑↑↑                      |
# |---------------------------------------------|
# |            STOP CHANGE VALUES               |
# \---------------------------------------------/

function precheck() {
  # make sure script is run from correct place
  if [ ! -d .git ]; then
      echo "ERROR: You should run this script from ROOT of ${base_repo_name} GIT repo"
      echo "Example: cd ${__root} && ${__script_path}"
      exit 1
  fi

  # Travis check: if not Travis - need to prompt new version
  # Place it into TRAVIS_TAG
  if [ ! -n "${TRAVIS}" ]; then
      echo "Script not being run in Travis environment"
      read -p "Enter new ${bower_repo_name} version: " TRAVIS_TAG
      echo "${TRAVIS_TAG}"
  # TODO: remove after check on Travis
  else
      TRAVIS_TAG="0.0.6"
  fi
}

# BazZy: checked
function travis_decrypt_deploy_key() {
  if [ "${TRAVIS}" = true ]; then
    openssl aes-256-cbc -K "${deploy_enc_key}" -iv "${deploy_enc_iv}" -in "${encoded_deploy_key_location}" -out ~/.ssh/"${bower_repo_name}" -d
    chmod 600 ~/.ssh/"${bower_repo_name}"
    echo -e "Host github.com\n  IdentityFile ~/.ssh/${bower_repo_name}" > ~/.ssh/config
    git config --global user.email "${git_config_email}"
    git config --global user.name "${git_config_name}"
  fi
}

# BazZy: checked
function clone() {
  # Run Travis deploy key file decryption
  travis_decrypt_deploy_key

  # Check for sibling bower repo
  if [ -d ../"${bower_repo_name}"/ ]; then
    # If git repo exists - just pull latest changes
    if [ -d ../"${bower_repo_name}"/.git ]; then
      cd ../"${bower_repo_name}" && git pull -f origin master && cd ../"${base_repo_name}"
    # If git not exists - show info to remove bower repo manually
    else
      cwd=$(pwd)
      echo "You have sibling ${bower_repo_name} directory, but there is no git repo"
      echo "Remove it manually, and rerun script. ${bower_github_repo} would be auto cloned"
      echo "Example: cd $(dirname ${cwd}) && rm -rf ${bower_repo_name}"
      exit 1
    fi
  else
    # No sibling bower repo? Ok, just clone it from Github
    cd .. && git clone --depth=50 --branch=master git@github.com:"${bower_github_repo}".git && cd "${base_repo_name}"
  fi
}

# function push_tag() {
# }

# BazZy: checked
function push() {
  cd ../"${bower_repo_name}"

  # Replace version number
  # TODO: replace in real project
  sed -i.bak "s/AUTO_VERSION/$TRAVIS_TAG/g" README.md && rm README.md.bak

  git add .
  git commit -m "Travis deploy"
  git tag -a -m "${TRAVIS_TAG}" "${TRAVIS_TAG}"

  git push --follow-tags origin master

  echo "Released version ${TRAVIS_TAG} successfully!"
}

# 1. Precheck operations
precheck

# 2.1 Decrypt private key, if on Travis
# 2.2 Clone repositories
clone

# 3. Build files for Bower
build

# 4. Copy builded files to Bower repo
copy

# 5. Commit and push new bower files to github
push
