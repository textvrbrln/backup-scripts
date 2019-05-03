#!/bin/bash
# Possible timestamps: s, m, h, D, W, M, or Y

## This script helps restoring and backing up data using Duplicity
## Target Machine is available via SSH, no password is used to login, only a Key

# Backup with Key only
#
export PASSPHRASE=password


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
DISPLAY=:0
LANG=de_DE.UTF-8

# Is SSH server available?
#
function ssh_server_test {

ssh_is_up=$(ssh -p ${SSH_PORT} -q ${SSH_LOGIN} exit)

if [[ !${ssh_is_up} ]]; then
  sleep 1
  if !  zenity --question --text \
            "Soll ich das Backup jetzt starten?"; then
	          zenity --info --text  \
            "Breche Backup ab. Nächstes Mal."
	          exit
	else
	          zenity --info --text \
            "Starte Backup jetzt. Stay tuned..."
	          start_duplicity_backup
      	    #zenity --info --text "Starte TEST f. Backup jetzt. Stay tuned..."
            #test_start_duplicity_backup
	          zenity --info --text \
            "Backup komplett. Bis nächstes Mal."
	fi
else
	zenity --info --text \
  "Der Zielrechner für das Backup ist nicht \
  online. Kontaktiere den Admin."
	exit
fi
}


function start_duplicity_backup {

# Backup files and folders
nice -n 10 duplicity --no-encryption \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    --full-if-older-than 12M \
    --include /home/localuser/backup.sh \
    --include /home/localuser/autobackup.sh \
    --include /home/localuser/Webseiten \
    --include /home/localuser/Dokumente \
    --include /home/localuser/Software \
    --include /home/localuser/Bilder \
    --include /home/localuser/Videos \
    --include /home/localuser/projects \
    --exclude /home/localuser \
    /home/localuser \
    ${TARGET_MACHINE}${TARGET_FOLDER}
}

function test_start_duplicity_backup {

# Backup files and folders
nice -n 10 duplicity --no-encryption \
    --ssh-options="-oIdentityFile="${KEYPATH}"" \
    --full-if-older-than 12M \
    --include /home/localuser/backup.sh \
    --exclude /home/localuser \
    /home/localuser \
    ${TEST_TARGET_MACHINE}${TEST_TARGET_FOLDER}
}

ssh_server_test
