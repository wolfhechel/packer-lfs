set -o errexit  # Exit if error
set -o nounset  # Exit if variable not initalized
set +h          # Disable hashall

#set -o xtrace

umask 022       # Make sure that newly created files has more restrictive

LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
MAKEFLAGS='-j $(nprocs)'

shopt -s -o pipefail

_src_cache="$LFS/sources"

stderr_color=`echo -e '\033[31m'`
reset_color=`echo -e '\033[0m'`

script_directory="$LFS/commands/chapter05"

toolchain_tar_path="${_src_cache}/toolchains/${LFS_VERSION}-$(cat ${script_directory}/* | sha1sum | cut -d' ' -f1).txz"

echo "Looking for toolchain backup at ${toolchain_tar_path}"

cd $LFS

if [ -f "$toolchain_tar_path" ]; then
  echo "Unpacking existing toolchain"
  (
    tar xvf "$toolchain_tar_path"
  )
else
  (
    cd build

    for script in $(ls "$script_directory"); do
      stage=`basename ${script%*.sh}`

      prefix="${reset_color}${stage}: "
      keep_files=$(ls)

      echo ">> Building $script"
      (. "$script_directory/$script") 2> >(sed "s#^#${stderr_color}#") > >(sed "s#^#${prefix}${reset_color}#")

      rm -rf *
    done
  )

  echo "Backing upp the temporary system"
  mkdir -p `dirname $toolchain_tar_path`
  tar cJf "$toolchain_tar_path" tools
fi
