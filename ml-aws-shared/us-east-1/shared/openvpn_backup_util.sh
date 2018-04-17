#!/usr/bin/env bash

set -e

function usage()
{
    printf "Usage: $0 [backup | restore <filename>]\n"
    printf "  backup - takes a backup and puts the results in /tmp\n"
    printf "  restore - restores from backup file created by backup command\n"
    printf "\n"
    exit 0
}

# Must be run as root
userid=$(id -u)
if (( $userid != 0 )); then printf "Command must be run as root\n" ; fi

# Must have an argument
if (( $# == 0 )); then usage; fi

#
# BACKUP
# https://openvpn.net/index.php/access-server/docs/admin-guides-sp-859543150/howto-commands/381-backing-up-the-access-server.html
# This function does a db dump so that backups can be taken while the system is running.
#
function backup()
{
    today=$(date '+%Y_%m_%d__%H_%M_%S')
    backup_dir="/tmp/openvpn_backup"
    backup_tgz="/tmp/openvpn_backup_${today}.tgz"

    if [ -d "$backup_dir" ]; then
        printf "directory ${backup_dir} exists!  can not proceed with backup.\n"
        exit 1
    fi

    mkdir ${backup_dir}

    cd /usr/local/openvpn_as/etc/db

    printf "Backing up files to temp dir at ${backup_dir}:\n"
    for file in *.db; do
        printf "\t${file}..."
        /usr/local/openvpn_as/scripts/sqlite3 ${file} .dump > ${backup_dir}/${file}.dump
        printf "done\n"
    done

    printf "Creating backup file ${backup_tgz}\n"
    tar -C ${backup_dir} -czf ${backup_tgz} .
    rm -rf ${backup_dir}

    printf "Contents of backup file ${backup_tgz}:\n"
    tar -tzvf ${backup_tgz}
}


case $1 in
    backup)
        backup
        ;;
    restore)
        printf "TODO\n"
        ;;
    *)
        usage
        ;;
esac
