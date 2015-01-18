
set -o errexit  # Exit if error
set -o nounset  # Exit if variable not initalized
set +h          # Disable hashall

#set -o xtrace

umask 022       # Make sure that newly created files has more restrictive

shopt -s -o pipefail


# Clear directory stack
dirs -c

_src_cache=$LFS/sources

stderr_color=`echo -e '\033[31m'`
reset_color=`echo -e '\033[0m'`

script_directory=$1

(
  cd "$LFS/build"

  for script in $(ls "$script_directory"); do
    stage=`basename ${script%*.sh}`

    prefix="${reset_color}${stage}: "

    echo ">> Building $script"
    (. "$script_directory/$script") 2> >(sed "s#^#${stderr_color}#") > >(sed "s#^#${prefix}${reset_color}#")

    rm -rf *
  done
)
