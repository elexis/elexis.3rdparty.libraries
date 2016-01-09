#!/bin/bash
# abort bash on error
set -e

if [ -z "$ROOT_3RDPARTY" ]
then
  export ROOT_3RDPARTY=/srv/download.elexis.info/elexis.3.3rdparty.libraries
fi

if [ ! -d "$ROOT_3RDPARTY" ]
then
  echo "ROOT_3RDPARTY (actually defined as $ROOT_3RDPARTY) must exist"
  exit 1
fi

# set some default values
export parent=`dirname $0`
if [ -z "$VARIANT" ]
then
  export VARIANT=snapshot
fi
if [ -z "$path_to_eclipse_4_2" ]
then
  export path_to_eclipse_4_2=/home/srv/p2Helpers/eclipse/eclipse
fi

# Maven must have prepared a repo.properties file under ch.medelexis.p2site
# If such a file exists in the destination directory, we get the version for the zip file from there
# else the zip_version will be the actual date/time
export act_version_file=${PWD}/repo.properties
if [ ! -f $act_version_file ]
then
  echo "File ${act_version_file} must exist!"
  exit 1
fi
export backup_root=${ROOT_3RDPARTY}/backup/$VARIANT

echo $0: ROOT_3RDPARTY is $ROOT_3RDPARTY and VARIANT is $VARIANT.

# Check whether we have to backup the old version of the repository
export old_version_file=${ROOT_3RDPARTY}/${VARIANT}/repo.version
if [ -f ${old_version_file}  ]
then
  awk -i inplace '{gsub(/[.\\ :]/,"_")}; 1'  ${old_version_file}
  source ${old_version_file}
  if [ ! -d $backup_root/$git_commit_time ]
  then
    echo "Backup of version found under $ROOT_3RDPARTY/$VARIANT necessary"
    mkdir -p $backup_root
    mv -v $ROOT_3RDPARTY/$VARIANT $backup_root/$git_commit_time
  else
    echo Skipping backup as  $backup_root/$git_commit_time already present
  fi
fi

rm -rf ${ROOT_3RDPARTY}/$VARIANT
cp -rpu target/repository/ ${ROOT_3RDPARTY}/$VARIANT
cp -rpvu repo.properties ${ROOT_3RDPARTY}/$VARIANT/repo.version
export title="Elexis-Application P2-repository ($VARIANT)"
echo "Creating repository $ROOT_3RDPARTY/$VARIANT/index.html"
tee  ${ROOT_3RDPARTY}/$VARIANT/index.html <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<html>
  <head><title>$title</title></head>
  <body>
    <h1>$title</h1>
      <li><a href="products">ZIP files for Elexis-Application (OS-specific)</a></li>
      <li><a href="binary">binary</a></li>
      <li><a href="plugins">plugins</a></li>
      <li><a href="features">features</a></li>
    </ul>
    </p>
    <p>Installed `date`
    </p>
  </body>
</html>
EOF
