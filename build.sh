#!/bin/bash

if command -v gsed 2>/dev/null; then
  SED=gsed
else
  SED=sed
fi

rustc_crawl() {
  ptrn='\[pkg\.rust\]\nversion = "\K[^"]+'
  relday=$(date -I)  # Today's date
  # Rust stable updates happen every 6 weeks, starting at 2015-12-10.
  # This would be a very clean method of extracting versions, were it not for patches.
  # Rust 1.72.1 was released 21 days after 1.72.0 for example, but 1.73.0 was still
  # on schedule. This makes last modified time of the stable file unreliable.
  if [[ "$1" = 'stable' ]] ; then
      rustup run stable rustc --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
      return 0
  fi

  # nightly releases should be found on the first check here, making it equivalent to an if,
  # but beta releases are a pain in the behind to track down, so we probe a few days for those.
  # On the off chance this ever runs before nightly builds, nightly falls back to yesterday's.
  while [[ $(curl -s "https://static.rust-lang.org/?prefix=dist/$relday" | grep -c "$1") == '0' ]] ; do
    relday=$(date -I -d "$relday -1 day")
  done
  # Extract whatever version information upstream provides!
  curl -s "https://static.rust-lang.org/dist/$relday/channel-rust-$1.toml" | grep -ozP "$ptrn" | tr -d '\0'
}

rustup update stable >&2

s=$(rustc_crawl 'stable')
b=$(rustc_crawl 'beta' | $SED 's/\(.*beta.*\s(\).*\s\(.*)\)/\1\2/')
n=$(rustc_crawl 'nightly' | $SED 's/\(.*\)-nightly\(\s(\).*\s\(.*)\)/\1\2\3/')

betaDate=$($SED 's/.*(\(.*\))/\1/' <<< $b)
nightlyDate=$($SED 's/.*(\(.*\))/\1/' <<< $n)

$SED \
  -e "s/{STABLE}/$s/" \
  -e "s/{BETA}/$b/" \
  -e "s/{NIGHTLY}/$n/" \
  index.html.tmpl > index.html

cat <<EOS > stable
[toolchain]
channel = "$s"
EOS

# We can't pick the beta version without knowing the _exact_ release date,
# which is not even exposed anywhere.
# Maybe we can eventually parse https://static.rust-lang.org/manifests.txt
cat <<EOS > beta
[toolchain]
channel = "beta-${betaDate}"
EOS

cat <<EOS > nightly
[toolchain]
channel = "nightly-${nightlyDate}"
EOS
