#!/bin/bash

if command -v gsed 2>/dev/null; then
  SED=gsed
else
  SED=sed
fi

stable() {
  rustup toolchain add stable >&2
  rustup run stable rustc --version | egrep -o '1\.[0-9]+\.[0-9]+'
}

beta() {
  rustup toolchain add beta >&2
  rustup run beta rustc --version | \
    $SED 's/.\+\(1\.[0-9]\+\.[0-9]\+[^ ]*\).*/\1/'
}

nightly() {
  rustup toolchain add nightly >&2
  rustup run nightly rustc --version | \
    $SED 's/.\+\(1\.[0-9]\+\.[0-9]\+\)-nightly ([0-9a-f]\+ \(.\+\))/\1 (\2)/'
}

pickdate() {
  echo "$1" | $SED 's/\(1\.[0-9]\+\.[0-9]\+\) (\(.\+\))/\2/'
}

rustup update

s=$(stable)
b=$(beta)
n=$(nightly)
nightlyDate=$(pickdate "$n")

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
channel = "beta"
EOS

cat <<EOS > nightly
[toolchain]
channel = "nightly-${nightlyDate}"
EOS
