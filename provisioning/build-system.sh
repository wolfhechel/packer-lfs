set -o errexit  # Exit if error
set -o nounset  # Exit if variable not initalized
set +h          # Disable hashall

set -o xtrace

umask 022       # Make sure that newly created files has more restrictive

LFS=

LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
MAKEFLAGS='-j $(nprocs)'

shopt -s -o pipefail

_src_cache="$LFS/sources"

stderr_color=`echo -e '\033[31m'`
reset_color=`echo -e '\033[0m'`

(
  cd $LFS/build

  for script_directory in $LFS/commands/chapter0{6..8}; do
    for script in $(ls "$script_directory"); do
      stage=`basename ${script%*.sh}`

      prefix="${reset_color}${stage}: "
      keep_files=$(ls)

      echo ">> Building $script"
      (. "$script_directory/$script") 2> >(sed "s#^#${stderr_color}#") > >(sed "s#^#${prefix}${reset_color}#")

      rm -rf *
    done
  done
)
