# Common tasks for script using this framework.

SUCCESS=0
FAIL=1
SKIP=2

download_file() {
  #1 : URL to download
  #2 : File to store
  echo -n "Downloading $2... "
  (! is_file_present $2 && curl -# $1 -o $2) ||\
    (return $SKIP)
}

checksum_file() {
  #! : URL checksum
  #2 : file to validate
  target_file=$(basename $2)
  target_folder=$(dirname $2)
  echo -n "Checking $target_file... "
  curl -s $1 -o $2.md5
  pushd $target_folder >/dev/null
  md5sum -c $target_file.md5 > .md5out 2>&1
  popd >/dev/null
  cat $target_folder/.md5out | grep "OK" > /dev/null
  valid=$?
  mv $target_folder/.md5out .err
  rm $2.md5
  return $valid
}

is_file_present() {
  #1 file
  test -f $1
}

check_command() {
  #1 command
  echo -n "Checking command $1... "
  ( hash $1 2>/dev/null ) ||\
    (echo "ERROR: Command $1 is not available" 1>&2 &&\
    return $FAIL )
}

failed() {
  echo "Failed"
  echo "---> Execution failed:"
  cat .err
  rm .err
  exit 1
}

skipped() {
  echo "Skipped"
  rm .err
}

success() {
  echo "Ok"
  rm .err
}

check_task() {
  "$@" 2> .err
  result_proc=$?
  (test "$result_proc" -eq $SUCCESS && success )\
    || (test "$result_proc" -eq $SKIP && skipped )\
    || failed;
}

error_msg() {
  echo $1 1>&2
}
