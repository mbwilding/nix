#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
search_dir="$root/modules/features/core"

for bin in curl jq nix; do
  command -v "$bin" >/dev/null || {
    echo "missing dependency: $bin" >&2
    exit 1
  }
done

prefetch_hash() {
  local hash_type="$1" url="$2"
  nix store prefetch-file --hash-type "$hash_type" --json "$url" 2>/dev/null | jq -r '.hash // empty'
}

first_match() {
  # first_match <pattern> <file>
  grep -oP "$1" "$2" | head -1 || true
}

update_github_release_file() {
  local file="$1" repo cur_version latest

  repo=$(first_match '(?<=github\.com/)[^/]+/[^/]+(?=/releases/download)' "$file")
  if [[ -z "$repo" ]]; then
    echo "  skip: no github release url found"
    return
  fi

  cur_version=$(first_match '(?<=version = ")[^"]+' "$file")
  if [[ -z "$cur_version" ]]; then
    echo "  skip: no version assignment found"
    return
  fi

  latest=$(curl -sf "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty')
  latest="${latest#v}"

  if [[ -z "$latest" ]]; then
    echo "  skip: could not resolve latest release for $repo"
    return
  fi

  if [[ "$latest" == "$cur_version" ]]; then
    echo "  up to date ($cur_version) [$repo]"
    return
  fi

  echo "  $repo: $cur_version -> $latest"
  sed -i "s/version = \"$cur_version\"/version = \"$latest\"/g" "$file"

  local line_no url old_hash new_hash
  while IFS=: read -r line_no _; do
    url=$(sed -n "${line_no}p" "$file" | sed -E 's/^\s*url = "(.*)";/\1/')
    url=${url//\$\{version\}/$latest}

    old_hash=$(sed -n "$((line_no + 1))p" "$file" | sed -E 's/^\s*hash = "(.*)";/\1/')

    echo "    prefetching: $url"
    new_hash=$(prefetch_hash sha256 "$url")
    if [[ -z "$new_hash" ]]; then
      echo "    FAILED to prefetch $url"
      continue
    fi
    sed -i "s#$old_hash#$new_hash#" "$file"
  done < <(grep -n 'url = "https://github.com' "$file" | cut -d: -f1,1)
}

update_vscode_marketplace_file() {
  local file="$1" publisher name cur_version cur_hash latest url new_hash query

  publisher=$(first_match '(?<=publisher = ")[^"]+' "$file")
  name=$(first_match '(?<=name = ")[^"]+' "$file")
  cur_version=$(first_match '(?<=version = ")[^"]+' "$file")
  cur_hash=$(first_match '(?<=hash = ")[^"]+' "$file")

  if [[ -z "$publisher" || -z "$name" || -z "$cur_version" ]]; then
    echo "  skip: could not parse marketplace extension fields"
    return
  fi

  query=$(curl -sf -X POST "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    -d "{\"filters\":[{\"criteria\":[{\"filterType\":7,\"value\":\"$publisher.$name\"}]}],\"flags\":950}")

  latest=$(echo "$query" | jq -r '.results[0].extensions[0].versions[0].version // empty')

  if [[ -z "$latest" ]]; then
    echo "  skip: could not resolve latest marketplace version for $publisher.$name"
    return
  fi

  if [[ "$latest" == "$cur_version" ]]; then
    echo "  up to date ($cur_version) [$publisher.$name]"
    return
  fi

  echo "  $publisher.$name: $cur_version -> $latest"

  url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$publisher/vsextensions/$name/$latest/vspackage"
  new_hash=$(prefetch_hash sha256 "$url")
  if [[ -z "$new_hash" ]]; then
    echo "    FAILED to prefetch vsix"
    return
  fi

  sed -i "s/version = \"$cur_version\"/version = \"$latest\"/g" "$file"
  sed -i "s#$cur_hash#$new_hash#" "$file"
}

prefetch_npm_deps_hash() {
  local lock_file="$1" fetcher_version="$2"
  NPM_FETCHER_VERSION="$fetcher_version" nix run nixpkgs#prefetch-npm-deps -- "$lock_file" 2>/dev/null | tail -1
}

# Downloads the new tarball, runs `npm install --package-lock-only` against its
# package.json to regenerate the bundled lock file, then reprefetches npmDepsHash.
update_npm_lock_and_deps_hash() {
  local file="$1" lock_file="$2" tarball_url="$3"
  local workdir pkgdir cur_deps_hash new_deps_hash status=0 fetcher_version

  fetcher_version=$(first_match '(?<=npmDepsFetcherVersion = )[0-9]+' "$file")
  fetcher_version="${fetcher_version:-1}"

  command -v npm >/dev/null || {
    echo "    skip lock regen: npm not found on PATH"
    return 1
  }

  workdir=$(mktemp -d)

  echo "    downloading tarball to regenerate lock file"
  if curl -sfL "$tarball_url" -o "$workdir/pkg.tgz" && tar -xzf "$workdir/pkg.tgz" -C "$workdir"; then
    pkgdir="$workdir/package"
    [[ -d "$pkgdir" ]] || pkgdir="$workdir"

    echo "    running npm install --package-lock-only"
    if (cd "$pkgdir" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund) >/dev/null &&
      [[ -f "$pkgdir/package-lock.json" ]]; then
      cp "$pkgdir/package-lock.json" "$lock_file"

      cur_deps_hash=$(first_match '(?<=npmDepsHash = ")[^"]+' "$file")
      new_deps_hash=$(prefetch_npm_deps_hash "$lock_file" "$fetcher_version")

      if [[ -n "$new_deps_hash" && -n "$cur_deps_hash" ]]; then
        sed -i "s#$cur_deps_hash#$new_deps_hash#" "$file"
        echo "    regenerated lock file and npmDepsHash"
      elif [[ -z "$cur_deps_hash" ]]; then
        echo "    WARNING: could not find existing npmDepsHash to replace"
        status=1
      else
        status=1
      fi
    else
      status=1
    fi
  else
    status=1
  fi

  rm -rf "$workdir"
  return "$status"
}

update_npm_file() {
  local file="$1" pname cur_version cur_hash lock_rel lock_file latest url new_hash

  pname=$(first_match '(?<=pname = ")[^"]+' "$file")
  cur_version=$(first_match '(?<=version = ")[^"]+' "$file")
  cur_hash=$(first_match '(?<=hash = ")[^"]+' "$file")
  lock_rel=$(first_match '(?<=\$\{\./)[^}]+(?=\})' "$file")

  if [[ -z "$pname" || -z "$cur_version" ]]; then
    echo "  skip: could not parse npm package fields"
    return
  fi

  latest=$(curl -sf "https://registry.npmjs.org/$pname/latest" | jq -r '.version // empty')

  if [[ -z "$latest" ]]; then
    echo "  skip: could not resolve latest npm version for $pname"
    return
  fi

  if [[ "$latest" == "$cur_version" ]]; then
    echo "  up to date ($cur_version) [$pname]"
    return
  fi

  echo "  $pname: $cur_version -> $latest"

  url="https://registry.npmjs.org/$pname/-/$pname-$latest.tgz"
  new_hash=$(prefetch_hash sha512 "$url")
  if [[ -z "$new_hash" ]]; then
    echo "    FAILED to prefetch tarball"
    return
  fi

  sed -i "s/version = \"$cur_version\"/version = \"$latest\"/g" "$file"
  sed -i "s#$cur_hash#$new_hash#" "$file"

  if [[ -z "$lock_rel" ]]; then
    echo "    NOTE: no bundled package-lock.json reference found; npmDepsHash left untouched"
    return
  fi

  lock_file="$(dirname "$file")/$lock_rel"
  update_npm_lock_and_deps_hash "$file" "$lock_file" "$url" ||
    echo "    FAILED to regenerate lock file / npmDepsHash for $pname; left as-is"
}

main() {
  local files file
  mapfile -t files < <(find "$search_dir" -type f -name '_*.nix' | sort)

  for file in "${files[@]}"; do
    echo "==> ${file#"$root"/}"
    if grep -q 'buildVscodeMarketplaceExtension' "$file"; then
      update_vscode_marketplace_file "$file"
    elif grep -q 'registry\.npmjs\.org' "$file"; then
      update_npm_file "$file"
    elif grep -q 'github\.com/.*releases/download' "$file"; then
      update_github_release_file "$file"
    else
      echo "  skip: no recognized updater pattern (likely wraps an existing nixpkgs package)"
    fi
  done
}

main "$@"
