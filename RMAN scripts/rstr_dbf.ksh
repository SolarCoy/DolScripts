#!/bin/ksh
#SRC_DIR="/u03/backup/tstand"
SRC_DIR="/pdb_bk/backup/pdb/Jul2505/dbf"
DEST_HEAD_DIR=""
cat all_files.lst |while read file
do
if [[ ! -z $file ]] then
  FILE_NAME=$(basename $file)
  DEST_DIR=$(dirname $file)
  print "cp -p ${SRC_DIR}/${FILE_NAME}.Z ${DEST_DIR}/${FILE_NAME}.Z"
#  cp -p ${SRC_DIR}/${FILE_NAME}.Z ${DEST_DIR}/${FILE_NAME}.Z
#  uncompress ${DEST_DIR}/${FILE_NAME}.Z
fi
done
