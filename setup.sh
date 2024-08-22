#!/usr/bin/env sh

if [ "$#" -lt 4 ]; then
	echo "setup.sh <PLUGIN_NAME> <PLUGIN_DESCRIPTION> <GITHUB_USERNAME> <LICENSE>"
fi

PLUGIN_NAME=$1
PLUGIN_DESCRIPTION=$2
GITHUB_USER=$3
LICENSE=$4

if ! test -f $LICENSE; then
	echo "Please choose license from LICENSES folder"
	exit 1
fi

cp $LICENSE LICENSE

# Replace [year] and [yyyy]
YEAR=$(date +%Y)
sed -i "s/\[year\]/$YEAR/g; s/\[yyyy\]/$YEAR/g" LICENSE
# Replace [fullname] and [name of copyright owner]
sed -i "s/\[fullname\]/$GITHUB_USER/g; s/\[name of copyright owner\]/$GITHUB_USER/g" LICENSE

# Search & Replace {} placeholders
find ! -path "./.git/*"  ! -name 'setup.sh' -type f -exec sed -i '' -e "s/{PLUGIN_NAME}/$PLUGIN_NAME/g; s/{PLUGIN_DESCRIPTION}/$PLUGIN_DESCRIPTION/g; s/{GITHUB_USERNAME}/$GITHUB_USER/g" {} \;

# Replace directories
mv lua/PLUGIN_NAME lua/$PLUGIN_NAME

# Replace README files
rm -f README.md
mv PLUGIN_README.md README.md

# Generate doc
./.github/scripts/gen_doc.sh
./.github/scripts/update_readme.sh

# Activate workflows
mv ./.github/workflows_disabled/ ./.github/workflows

# Destroy setup.sh
rm ./setup.sh
