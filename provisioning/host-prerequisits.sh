#!/bin/bash
# Simple script to list version numbers of critical development tools

semver_comp () {
    if [[ $1 == $2 ]] ;then
        return 0
    fi

    local IFS=.

    local i ver1=($1) ver2=($2)

    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi

        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi

        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi

    done

    return 0
}

green='\033[0;32m'
red='\033[0;31m'
clear='\033[0m'

failure=0

assert () {
  if ${@:2} &>/dev/null; then
    color="${green}"
    status=" OK "
  else
    color="${red}"
    status="FAIL"

    failure=1
  fi

  echo -e "${clear}[${color}${status}${clear}] ${1}"
}

test_version () {
  current_version=$2
  required_version=$3

  semver_comp $current_version $required_version

  if [ $? -eq 2 ]; then
    success=false
  else
    success=true
  fi

  assert "${1} $current_version >= $required_version" $success
}

get_version () {
  grep -P -o -m 1 "(([0-9]+\.){1,}[0-9]+)"
}

export LC_ALL=C

test_version bash `bash --version | head -n1 | get_version` 3.2
test_version binutils `ld --version | head -n1 | get_version` 2.17
test_version bison `bison --version | head -n1 | get_version` 2.3
test_version bzip2 `bzip2 --version 2>&1 < /dev/null | head -n1 | get_version` 1.0.4
test_version coreutils `chown --version | head -n1 | get_version` 6.9
test_version diffutils `diff --version | head -n1 | get_version` 2.8.1
test_version findutils `find --version | head -n1 | get_version` 4.2.31
test_version gawk `gawk --version | head -n1 | get_version` 4.0.1
test_version gcc `gcc --version | head -n1 | get_version` 4.1.2
test_version glibc `ldd --version | head -n1 | get_version` 2.5.1
test_version grep `grep --version | head -n1 | get_version` 2.5.1
test_version gzip `gzip --version | head -n1 | get_version` 1.3.12
test_version linux `cat /proc/version | cut -d' ' -f3 | get_version` 2.6.32
test_version m4 `m4 --version | head -n1 | get_version` 1.4.10
test_version make `make --version | head -n1 | get_version` 3.81
test_version patch `patch --version | head -n1 | get_version` 2.5.4
test_version perl `perl -V:version | get_version` 5.8.8
test_version sed `sed --version | head -n1 | get_version` 4.1.5
test_version tar `tar --version | head -n1 | get_version` 1.18
test_version xz `xz --version | head -n1 | get_version` 5.0.0

assert "/bin/sh is a link to bash" [ `readlink /bin/sh` == 'bash' ]

for tool in /usr/bin/awk /usr/bin/yacc; do
  assert "has $tool" [ -e $tool ];
done
unset tool

echo 'main(){}' | g++ -x c++ -o dummy -

assert "g++ can compile" [ -x dummy ]

rm dummy

found_libs=`find /usr/lib* \( -name libgmp.la -o -name libmpfr.la -o -name libmpc.la \) | wc -l`

assert "lib{gmp,mpfr,mpc}.la are all absent or all present" [ $found_libs -eq 0 ] || [ $found_libs -eq 3 ]

exit $failure
