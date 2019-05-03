#!/bin/bash
# Possible timestamps: s, m, h, D, W, M, or Y

## This script helps restoring and backing up data using Duplicity
## Target Machine is available via SSH, no password is used to login, only a Key

# Backup with Key only
#
export PASSPHRASE=Passwort


# SSH Location
#
TARGET_MACHINE="scp://username@server:port"
TARGET_FOLDER="/path/to/backup-folder"
TEST_TARGET_MACHINE="scp://username@server:port"
TEST_TARGET_FOLDER="/path/to/backup-test-folder"
SSH_LOGIN="username@server"
SSH_PORT="port"
SSH_SHORTCUT="archiv"
RESTORE_PATH="/home/localuser/Restore"
KEYPATH=".ssh/key"


# Is SSH server available?
#
function ssh_server_test {

ssh -p ${SSH_PORT} -q ${SSH_LOGIN} exit
ssh_is_up=$(echo $?)

if [ ${ssh_is_up} = 0 ]; then
	echo -e "Backup machine is available. That is good..."
    sleep 1
	ask_user
else
	echo -e "Backup machine is not available. \nPlease take care to get your backup machine online or adapt this script.\nQuitting."
	exit
fi
}

function ask_user {
	echo -e "If you want to backup files, press [1]."
    echo -e "If you want to recovr files, press [2]."
    echo -e "If you want to test backup functionality, press [3]."
    read -p "> " decision
        case ${decision} in
            1)
                echo "Start Backup"
                start_duplicity_backup
                ;;
            2)
                echo "Start Restore"
                start_duplicity_restore
                ;;
            3)
                echo "Test Backup Functionality"
                start_duplicity_backup_test
                ;;
            4)
                echo "Quitting, goodbye!"
                exit 0
                ;;
            *)
                echo "Please chose between [1] and [3] or press [4] for quitting the program."
                ask_user
                ;;
        esac
}


# Start Restore-Prozess. 
# Show Content of Backup, let User chose by number
#
function start_duplicity_restore {
    # Restore Option
    # duplicity --file-to-restore projects scp://archiv/path/to/backup-folder/ /home/localuser/Restore
    # duplicity --no-encryption --file-to-restore projects --ssh-options="-oIdentityFile=.ssh/key" scp://username@server:port/path/to/backup/ /home/localuser/Restore
    echo -e "Would you like to take a look at the date and type of backups? [1]"
    echo -e "Would you like to see the available files in your backup? [2]"
    echo -e "Would you like to restore a file or folder? [3]"
    echo -e "Would you like to restore the full backup? [4]"
    read -p "> " decision
        case ${decision} in
            1)
                echo "Getting data, this can take a little time..."
                get_backup_infos
                ;;
            2)
                echo "Get data..."
                list_files_in_backup
                ;;
            3)
                echo "Chose a folder or file to restore."
                restore_folder_file
                ;;
            4)
                echo "Starting a full restore..."
                restore_full
                ;;
	q | Q)
		echo "Quitting."
		exit 0
		;;
            *)
                echo "Please chose one of the numbers or [Q] for quit."
                start_duplicity_restore
                ;;
        esac
    #duplicity --no-encryption collection-status --ssh-options="-oIdentityFile=.ssh/key" scp://username@server:port/path/to/backup-folder/
    #echo "Restore "
}


# Get infos from backup 
# Show number and dates from backup
#
function get_backup_infos {
    duplicity --no-encryption \
    collection-status \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    ${TARGET_MACHINE}${TARGET_FOLDER} | grep "Full\|Incremental"
    start_duplicity_restore
    }

# Puts a list of files in backup in archive.data 
# Shows list with less
#
function list_files_in_backup {
    duplicity --no-encryption \
    list-current-files \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    ${TARGET_MACHINE}${TARGET_FOLDER} > archive.data
    less archive.data
    }

function restore_folder_file {
	echo -e "What file would you like to restore?"
    	read -p "> " filefolder
	duplicity --no-encryption \
    	--file-to-restore ${filefolder} \
	--ssh-options="-oIdentityFile="${KEYPATH}"" \
	${TARGET_MACHINE}${TARGET_FOLDER} ${RESTORE_PATH}/${filefolder}
}

function start_duplicity_backup {

# Backup files and folders
nice -n 10 duplicity --no-encryption \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    --full-if-older-than 12M \
    --include /home/localuser/backup.sh \
    --include /home/localuser/Dokumente \
    --include /home/localuser/Software \
    --include /home/localuser/Videos \
    --include /home/localuser/projects \
    --exclude /home/localuser \
    /home/localuser \
    ${TARGET_MACHINE}${TARGET_FOLDER}
}

# Start Backup if SSH is available
# Take care of tabs in duplicity command
# 
function start_duplicity_backup_test {

echo "## TEST MODE!!! ##"
nice -n 10 duplicity \
    --encrypt-key "KEYID" \
    --ssh-options="-oIdentitiyFile="${KEYPATH}"" \
    --full-if-older-than 12M \
    --include /home/localuser/testfile \
    --exclude /home/localuser \
    /home/localuser \
    ${TEST_TARGET_MACHINE}${TEST_TARGET_FOLDER} > logback
    write_mail_test
}

function write_mail_test {
	echo "## MAIL TEST SEND ##"
	/usr/bin/nodejs /home/localuser/mailer.js
}

ssh_server_test
