#!/usr/bin/env -S uv run --script

# encoding: utf-8
from __future__ import print_function, unicode_literals

import argparse
import json
import os
import shutil

try:
    # Python 2
    input = raw_input
except NameError:
    # Python 3: `raw_input` is not defined, and we "fall back"
    #           to `input` -- which is what we want
    pass


def pretty_path(path):
    # type: (str) -> str
    user_home = os.path.expanduser('~')

    return path.replace(user_home, '~')


def parse_path(path, path_app_dir):
    if path.startswith('./'):
        return os.path.join(path_app_dir, path[2:])

    # http://stackoverflow.com/questions/4028904/how-to-get-the-home-directory-in-python
    return os.path.expanduser(path)


def ensure_dir_exists(path):
    # Make any directories that don't exist, e.g. "~/.config"
    assert not path.endswith('/'), (
        'Ending "/" should already have been stripped from path'
    )

    paths = []
    for i in range(100):
        parent_dir = os.path.dirname(path)
        if parent_dir == '/':
            break
        paths.append(parent_dir)
        path = parent_dir
    paths = reversed(paths)

    for path in paths:
        if not os.path.exists(path):
            yesno = input(
                "`%s` doesn't exist - do you want to create it? (Yes/No) "
                % pretty_path(path)
            )
            if yesno.lower() == 'yes':
                os.mkdir(path)
            else:
                print('Not creating `%s`' % pretty_path(path))
                return False

    return True


def create_symlink(source_path, target_path, replace_only=False, should_force=False):
    # type: (str, str, bool, bool) -> None
    # Use `.lexists()` to make sure we don't follow the symlink
    if replace_only and not os.path.lexists(target_path):
        print(
            '%s does not exist. Skipping due to `--replace-only`'
            % pretty_path(target_path)
        )
        return

    # If `target_path` ends in a "/" (to indicate a directory) then
    # both `os.path.is_link()` and `os.symlink()` won't work so we strip it.
    target_path = target_path.rstrip('/')

    if os.path.lexists(target_path):
        if should_force:
            yesno = 'Yes'
        else:
            yesno = input(
                '`%s` exists - do you want to overwrite it? (Yes/No) '
                % pretty_path(target_path)
            )
        if yesno == 'Yes':
            if os.path.islink(target_path):
                os.remove(target_path)
            elif os.path.isdir(target_path):
                shutil.rmtree(target_path)
            else:
                os.remove(target_path)
        else:
            return

    if ensure_dir_exists(target_path):
        print(
            'Symlinking %s to %s'
            % (pretty_path(full_path_source), pretty_path(full_path_target))
        )
        os.symlink(source_path, target_path)


def check_file(full_path_source, full_path_target, verbose):
    # type: (str, str, bool) -> bool
    if not os.path.lexists(full_path_target):
        if verbose:
            print('❌ %s does not exist.' % (pretty_path(full_path_target),))
        return False

    # Strip ending '/' as symlink operations don't work with paths ending in '/'
    if full_path_target.endswith('/'):
        full_path_target = full_path_target.rstrip('/')

    if not os.path.islink(full_path_target):
        if verbose:
            print(
                '❌ %s exists but is not a symlink.' % (pretty_path(full_path_target),)
            )
        return False

    current_symlink_target = os.readlink(full_path_target)
    if current_symlink_target != full_path_source:
        if verbose:
            print(
                '❓ %s is a symlink, but points to %s. Expected %s'
                % (
                    pretty_path(full_path_target),
                    pretty_path(current_symlink_target),
                    pretty_path(full_path_source),
                )
            )
        return False

    if current_symlink_target == full_path_source:
        if verbose:
            print(
                '✅ %s is a symlink correctly pointing to %s'
                % (pretty_path(full_path_target), pretty_path(full_path_source))
            )
        return True

    return False


def import_file(full_path_source, full_path_target):
    # type: (str, str) -> None
    full_path_target += '.import'

    if not os.path.exists(full_path_source):
        print('%s does not exist. Not importing.' % (pretty_path(full_path_source),))
        return

    if os.path.lexists(full_path_target):
        print(
            '%s already exist. Import would overwrite. Skipping.'
            % (pretty_path(full_path_target),)
        )
        return

    print(
        'Copying %s to %s'
        % (pretty_path(full_path_source), pretty_path(full_path_target))
    )
    if os.path.isdir(full_path_source):
        shutil.copytree(
            full_path_source,
            full_path_target,
        )
    else:
        shutil.copy2(
            full_path_source,
            full_path_target,
            follow_symlinks=False,
        )


def export_file(full_path_source, full_path_target, should_force=False):
    # type: (str, str, bool) -> None
    if not os.path.exists(full_path_source):
        print(
            'Source "%s" does not exist. Not exporting.'
            % (pretty_path(full_path_source),)
        )
        return

    does_exist = False
    str_overwritten = ''
    if os.path.lexists(full_path_target):
        does_exist = True
        str_overwritten = ' (overwritten)'
        if not should_force:
            print(
                'Target "%s" already exist. Export would overwrite. Skipping.'
                % (pretty_path(full_path_target),)
            )
            return

    print(
        'Exporting %s to %s%s'
        % (
            pretty_path(full_path_source),
            pretty_path(full_path_target),
            str_overwritten,
        )
    )
    # Even with `follow_symlinks=False` `shutil.copyfile`/`shutil.copy2` will
    # still raise `SameFileError` when the target is a symlink pointing to the
    # source. Therefore, we have to remove the target first.
    if should_force and does_exist:
        os.remove(full_path_target)

    if os.path.isdir(full_path_source):
        shutil.copytree(
            full_path_source,
            full_path_target,
        )
    else:
        shutil.copy2(
            full_path_source,
            full_path_target,
            follow_symlinks=False,
        )


def uninstall_file(full_path_source, full_path_target, should_force=False):
    # type: (str, str, bool) -> None
    if not os.path.lexists(full_path_target):
        print('%s does not exist. Not uninstalling.' % (pretty_path(full_path_target),))
        return

    is_symlink = os.path.islink(full_path_target)

    if not should_force:
        if not is_symlink:
            print(
                '%s is not a symlink. Not uninstalling.'
                % (pretty_path(full_path_target),)
            )
            return

        current_symlink_target = os.readlink(full_path_target)
        if current_symlink_target != full_path_source:
            print(
                '%s points to %s. Expected %s. Not removing.'
                % (
                    pretty_path(full_path_target),
                    pretty_path(current_symlink_target),
                    pretty_path(full_path_source),
                )
            )
            return

    print('Removing %s' % pretty_path(full_path_target))
    if is_symlink:
        os.remove(full_path_target)
    else:
        shutil.rmtree(full_path_target)


parser = argparse.ArgumentParser()
parser.add_argument('-v', '--verbose', action='count', default=0, dest='verbosity')
parser.add_argument(
    '-a', '--all', action='store_true', help='Install dotfiles for all apps'
)
parser.add_argument(
    '-f', '--force', action='store_true', help='Overwrite existing files'
)
parser.add_argument(
    '--check',
    action='store_true',
    help='Check which dotfiles are already symlinked',
)
parser.add_argument(
    '--replace-only',
    action='store_true',
    help='Do not install new config files, only replace existing ones',
)
parser.add_argument(
    '--import',
    action='store_true',
    dest='_import',
    help='Import existing dotfiles for selected apps (pass --all to select all apps)',
)
parser.add_argument(
    '--export',
    action='store_true',
    dest='_export',
    help='Export dotfiles for selected apps (pass --all to select all apps)',
)
parser.add_argument(
    '--uninstall',
    action='store_true',
    help='Uninstall dotfiles for selected apps (pass --all to select all apps)',
)
parser.add_argument('app_dirs', nargs='*')  # , default=None)
args = parser.parse_args()

if args.app_dirs == []:
    if args.all:
        app_dirs = [
            f
            for f in os.listdir(os.getcwd())
            if os.path.isdir(f) and not f.endswith('.disabled')
        ]
    else:
        print('Please pass one or more app directories, or pass the `--all` flag.')
        exit(5)
else:
    app_dirs = args.app_dirs


this_directory = os.path.dirname(os.path.realpath(__file__))
for app_dir in app_dirs:
    path_app_dir = os.path.join(this_directory, app_dir)
    dotfile_json_path = app_dir + '/dotfile.json'

    if not os.path.exists(dotfile_json_path):
        continue

    if not args.check:
        print(app_dir)

    is_installed = True
    with open(dotfile_json_path) as dotfile:
        files = json.load(dotfile)

        for file in files:
            if file['type'] == 'symlink':
                full_path_source = parse_path(file['source'], path_app_dir)
                full_path_target = parse_path(file['target'], path_app_dir)
                if not os.path.exists(full_path_source) and not args._import:
                    print('"%s" was not found' % (pretty_path(full_path_source),))
                    continue

                if args.check:
                    is_file_correct_installed = check_file(
                        full_path_source, full_path_target, verbose=args.verbosity > 0
                    )
                    is_installed = is_installed and is_file_correct_installed
                elif args.uninstall:
                    uninstall_file(
                        full_path_source, full_path_target, should_force=args.force
                    )
                elif args._import:
                    import_file(full_path_target, full_path_source)
                elif args._export:
                    export_file(
                        full_path_source, full_path_target, should_force=args.force
                    )
                else:
                    is_installed = check_file(
                        full_path_source, full_path_target, verbose=True
                    )
                    if not is_installed:
                        create_symlink(
                            full_path_source,
                            full_path_target,
                            replace_only=args.replace_only,
                            should_force=args.force,
                        )
            else:
                print('Unknown type: ' + file['type'])

    if args.check:
        if is_installed:
            print('✅ %s' % app_dir)
        else:
            print('❌ %s' % app_dir)
