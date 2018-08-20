#!/bin/bash

stable() {
  rustup toolchain add stable >&2
  rustup run stable rustc --version | egrep -o '1\.[0-9]+\.[0-9]+'
}

beta() {
  rustup toolchain add beta >&2
  rustup run beta rustc --version | \
    sed 's/.\+\(1\.[0-9]\+\.[0-9]\+[^ ]*\).*/\1/'
}

nightly() {
  rustup toolchain add nightly >&2
  rustup run nightly rustc --version | \
    sed 's/.\+\(1\.[0-9]\+\.[0-9]\+\)-nightly ([0-9a-f]\+ \(.\+\))/\1 (\2)/'
}

rustup update

s=$(stable)
b=$(beta)
n=$(nightly)

sed \
  -e "s/{STABLE}/$s/" \
  -e "s/{BETA}/$b/" \
  -e "s/{NIGHTLY}/$n/" \
  index.html.tmpl > index.html
