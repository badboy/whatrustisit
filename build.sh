#!/bin/bash

stable() {
  rustup run stable rustc --version | egrep -o '1\.[0-9]+\.[0-9]+'
}

beta() {
  rustup run beta rustc --version | egrep -o '1\.[0-9]+\.[0-9]+'
}

nightly() {
  rustup run nightly rustc --version | \
    sed 's/.\+\(1\.[0-9]\+\.[0-9]\+\)-nightly ([0-9a-f]\+ \(.\+\))/\1 (\2)/'
}


s=$(stable)
b=$(beta)
n=$(nightly)
sed \
  -e "s/{STABLE}/$s/" \
  -e "s/{BETA}/$b/" \
  -e "s/{NIGHTLY}/$n/" \
  index.html.tmpl > index.html
