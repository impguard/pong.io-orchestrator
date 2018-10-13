#!/bin/bash


function __find_versions ()
{
  (grep -E "v_\\.*" | sort -t. -n -k1,1 -k2,2 -k3,3 -k4,4) || echo
}


function version.exists ()
{
  local existing_version
  existing_version=$(git tag -l --contains HEAD | __find_versions | tail -1 | cut -d _ -f 2)
  test -n "$existing_version"
}


function version.latest ()
{
  local prev_version

  prev_version=$(git tag | __find_versions | tail -1 | cut -d _ -f 2)

  echo "$prev_version"
}


function version.next ()
{
  local existing_version

  existing_version=$(git tag -l --contains HEAD | __find_versions | tail -1 | cut -d _ -f 2)

  if [ -n "$existing_version" ]; then
    echo "$existing_version"
    return 0
  fi

  local prev_versions prev_version prev_major_minor_version prev_patch_version
  local patch_version

  prev_versions=$(git tag | grep -E "v_\\.*" | sort -t. -n -k1,1 -k2,2 -k3,3 -k4,4 | cut -d _ -f 2)

  if [ -z "$prev_versions" ]; then
    prev_version=0.0.0
  else
    prev_version=$(echo "$prev_versions" | tail -n 1)
  fi

  prev_major_minor_version=$(echo "$prev_version" | cut -d . -f 1,2)
  prev_patch_version=$(echo "$prev_version" | cut -d . -f 3)

  patch_version=$((prev_patch_version + 1))

  echo "$prev_major_minor_version.$patch_version"
}


function version.json
{
  local version tier
  local git_url git_sha git_message escaped_git_message
  local build_timestamp build_host build_user

  tier=$1
  version=$2

  git_url="$(git config --get remote.origin.url || echo none)"
  git_sha="$(git rev-parse HEAD || echo none)"
  git_message="$(git log -1 --pretty=%B || echo none)"
  escaped_git_message="$(echo "$git_message" | perl -pe 's/[^a-zA-Z0-9\#\.\-_ \t\@\\r\\n]/ /g')"

  build_timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
  build_host="${BUILD_HOST:-$(hostname)}"
  build_user="${USER:-robot}"

  cat > version.json <<END
{
  "version": "$version",
  "tier": "$tier",
  "git-url": "$git_url",
  "git-sha": "$git_sha",
  "git-message": "$escaped_git_message",
  "build-host": "$build_host",
  "build-timestamp": "$build_timestamp",
  "build-user": "$build_user"
}
END

  bake_echo_green "Created version.json:"
  bake_echo_yellow "$(sed -e '2,$s/^/  /' <(cat version.json))"
}
