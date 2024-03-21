#!/bin/bash

if command -v gsed 2>/dev/null; then
  SED=gsed
else
  SED=sed
fi

if command -v ggrep 2>/dev/null; then
  GREP=ggrep
else
  GREP=grep
fi

rustc_crawl() {
  # as per https://forge.rust-lang.org/infra/channel-layout.html we should be
  # able to get the latest release from "dist/channel-rust-$channelname.toml".
  # For nightly, component selection might make an upgrade impossible, for which
  # the solution is looping 21 (unless user overrides) releases back in time.
  # see: https://github.com/rust-lang/rustup/blob/cd3a10fba80e10f176985d8afd8d20a9be3ec0c4/src/dist/dist.rs#L754
  # But for whatrustisit, we just need to know the latest base toolchain, for
  # which the channel pattern does provide proper information.
  curl -s "https://static.rust-lang.org/dist/channel-rust-$1.toml" | \
  $GREP -ozP '\[pkg\.rust\]\nversion = "\K[^"]+' | \
  tr -d '\0'
}

s=$(rustc_crawl 'stable')
echo "rustc $s" > ./toot/stable
s=$($SED 's/\(.*\)\s(.*)/\1/' <<< $s)

beta_date=$(curl -s "https://static.rust-lang.org/dist/channel-rust-beta.toml" | \
            $GREP -ozP 'date = "\K[^"]+' | tr -d '\0')
b=$(rustc_crawl 'beta')
echo "rustc $b" > ./toot/beta
b=$($SED 's/\(.*beta.*\s(\).*\s\(.*)\)/\1\2/' <<< $b)

n=$(rustc_crawl 'nightly' | $SED 's/\(.*\)-nightly\(\s(\).*\s\(.*)\)/\1\2\3/')

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

# We can't pick any specific beta version without knowing the
# _exact_ release date, which is not even exposed anywhere.
# Luckily static.rust-lang.org _can_ provide us with the latest TOML beta!
cat <<EOS > beta
[toolchain]
channel = "beta-$beta_date"
EOS

cat <<EOS > nightly
[toolchain]
channel = "nightly-${nightlyDate}"
EOS
