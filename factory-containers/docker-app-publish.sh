#!/bin/sh -e
set -o pipefail

HERE=$(dirname $(readlink -f $0))
. $HERE/../helpers.sh

require_params FACTORY

CREDENTIALS=/var/cache/bitbake/credentials.zip
TAG=$(git log -1 --format=%h)

tufrepo=$(mktemp -u -d)

run garage-sign init --repo ${tufrepo} --credentials ${CREDENTIALS}
run garage-sign targets pull --repo ${tufrepo}

sha=$(sha256sum ${tufrepo}/roles/unsigned/targets.json)
apps=$(ls *.dockerapp)
for app in $apps ; do
	sed -i ${app} -e "s/image: hub.foundries.io\/${FACTORY}\/\(.*\):latest/image: hub.foundries.io\/${FACTORY}\/\1:$TAG/g"
	run ${HERE}/ota-dockerapp.py publish ${app} ${CREDENTIALS} ${H_BUILD} ${tufrepo}/roles/unsigned/targets.json
done

newsha=$(sha256sum ${tufrepo}/roles/unsigned/targets.json)
if [ "$sha" = "$newsha" ] && [ -n "$apps" ] ; then
	# there are two outcomes when pushing apps:
	# 1) the repo has online keys and the targets.json on the server was
	#    updated
	# 2) we have offline keys, and the script updated the local copy
	#    of targets.json
	# If we are here, #1 happened and we need to pull in the new version
	# of targets.json
	echo "Pulling updated TUF targets from the remote TUF repository"
	run garage-sign targets pull --repo ${tufrepo}
fi

run ${HERE}/ota-dockerapp.py add-build ${CREDENTIALS} ${H_BUILD} ${tufrepo}/roles/unsigned/targets.json `ls *.dockerapp`

echo "Signing local TUF targets"
run garage-sign targets sign --repo ${tufrepo} --key-name targets

echo "Publishing local TUF targets to the remote TUF repository"
run garage-sign targets push --repo ${tufrepo}
