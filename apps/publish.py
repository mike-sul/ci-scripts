#!/usr/bin/python3
#
# Copyright (c) 2020 Foundries.io
# SPDX-License-Identifier: Apache-2.0

import logging
import argparse


from helpers import status
from apps.target_manager import create_target
from apps.compose_apps import ComposeApps
from apps.apps_publisher import AppsPublisher
from apps.docker_to_compose import convert_docker_apps


logger = logging.getLogger(__name__)


def main(factory: str, sha: str, targets_json: str, app_root_dir: str, publish_tool: str, apps_version: str,
         target_tag: str, target_version: str, new_targets_file: str):
    convert_docker_apps()
    status('Searching for Compose Apps in {}'.format(app_root_dir))
    apps = ComposeApps(app_root_dir)
    status('Found Compose Apps: {}'.format(apps.str))

    status('Validating Compose Apps')
    apps.validate()
    status('Compose Apps has been validated: {}'.format(apps.str))

    apps_to_add_to_target = AppsPublisher(factory, publish_tool).publish(apps, apps_version)

    status('Creating Target(s) that refers to the published Apps; tag: {}, version: {} '
           .format(target_tag, target_version))
    new_targets = create_target(targets_json, apps_to_add_to_target, target_tag, sha, target_version, new_targets_file)
    if len(new_targets) == 0:
        logger.error('Failed to create Targets for the published Apps')
        return 1

    return 0


def get_args():
    parser = argparse.ArgumentParser('''Publish Target Compose Apps''')
    parser.add_argument('-f', '--factory', help='Apps Factory')
    parser.add_argument('-t', '--targets', help='Targets json file')
    parser.add_argument('-d', '--apps-root-dir', help='Compose Apps root directory')
    parser.add_argument('-p', '--publish-tool', help='A utility to be used for publishing (compose-ref)')
    parser.add_argument('-v', '--apps-version', help='Apps version which is by default is an abbreviated commit hash'
                                                     'of a given containers.git repo')
    parser.add_argument('-tt', '--target-tag', help='A tag to apply to Targets that will be created'
                                                    'by publishing the given apps')
    parser.add_argument('-s', '--git-sha', help='App/containers repo git sha')
    parser.add_argument('-tv', '--target-version', help='Version of Targets that will be created by a given call',
                        required=False, default=None)
    parser.add_argument('-o', '--new-targets-file', help='A file to put new Targets to')

    args = parser.parse_args()
    return args


if __name__ == '__main__':
    logging.basicConfig(format='%(levelname)s: Apps Publisher: %(module)s: %(message)s', level=logging.INFO)
    args = get_args()
    res = main(args.factory, args.git_sha, args.targets, args.apps_root_dir, args.publish_tool,
               args.apps_version, args.target_tag, args.target_version, args.new_targets_file)

    exit(res)
