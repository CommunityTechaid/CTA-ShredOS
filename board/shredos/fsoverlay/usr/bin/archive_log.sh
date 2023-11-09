#!/bin/bash
#
# This script will archive the nwipe log file/s, dmesg.txt files and PDF certificates
# to the first FAT32 formatted partition found, which should normally be the ShredOS
# USB flash drive. If there is more than one FAT32 drive this script will always
# archive to the first drive found. This is independant of the mode of operation, the
# log, dmesg and PDF files will always be written from ShredOS's RAM drive to the USB
# flash drive.
#
# It also checks whether /etc/nwipe/nwipe.conf and /etc/nwipe/customers.csv exist
# on the USB flash drive and assuming mode 0, read (-r argument) has been selected will
# read those two files from the USB drive into ShredOS's RAM disc, this is normally done
# prior to nwipe launch. Alternatively if mode 1, write (-w argument) is selected both
# /etc/nwipe/nwipe.conf and /etc/nwipe/customers.csv are copied from ShredOS's RAM
# disc back to the USB flash drive, which is normally done on Nwipe exit.
#
# Written by PartialVolume, a component of ShredOS - the disk eraser.

exit_code=0
mode=""

# What mode is required (read or write)
while getopts 'rw' opt; do
  case "$opt" in
    r)
      mode="read"
      ;;

    w)
      mode="write"
      ;;

    ?)
      echo -e "Invalid command option.\nUsage: $(basename $0) [-r] [-w]"
      exit 1
      ;;
  esac
done

# This is the temporary directory that the FAT32 drive is to be mounted on
archive_drive_directory="/archive_drive"

# The nwipe logs that have been sent are moved into this directory in RAM disk.
sent_directory="/sent"

# From all the drives on the system, find the first and probably only FAT32 partition
drive=$(fdisk -l | grep -i '/dev/*' | grep -i FAT32 | awk '{print $1}' | head -n 1)

if [ "$drive" == "" ]; then
	printf "archive_log.sh: No FAT32 formatted drive found, unable to archive nwipe log file\n"
	exit 1
else
	printf "Archiving nwipe logs to $drive\n"
fi

# Create the temporary directory we will mount the FAT32 partition onto.
if [ ! -d "$archive_drive_directory" ]; then
    mkdir "$archive_drive_directory"
    if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to create the temporary mount directory $archive_drive_directory\n"
                exit_code=2
    fi
fi

# mount the FAT32 partition onto the temporary directory
mount $drive $archive_drive_directory
status=$?
if [ $status != 0 ] && [ $status != 32 ]; then
    # exit only if error, except code 32 which means already mounted
    printf "archive_log.sh: Unable to mount the FAT32 partition $drive to $archive_drive_directory\n"
    exit_code=3
else
    printf "archive_log.sh: FAT32 partition $drive is now mounted to $archive_drive_directory\n"

    # Copy the dmesg.txt and PDF files over to the FAT32 partition
    dmesg > dmesg.txt
    cp /dmesg.txt "$archive_drive_directory/"
    if [ $? != 0 ]; then
	printf "archive_log.sh: Unable to copy the dmesg.txt file to the root of $drive:/\n"
    else
	printf "archive_log.sh: Sucessfully copied dmesg.txt to $drive:/\n" 
    fi

    # Copy the PDF certificates over to the FAT32 partition
    cp /nwipe_report_*pdf "$archive_drive_directory/"
    if [ $? != 0 ]; then
	printf "archive_log.sh: Unable to copy the nwipe_report...pdf file to the root of $drive:/\n"
    else
	printf "archive_log.sh: Sucessfully copied nwipe_report...pdf to $drive:/\n"
    fi

    # Copy the nwipe log files over to the FAT32 partition
    cp /nwipe_log* "$archive_drive_directory/"
    if [ $? != 0 ]; then
        printf "archive_log.sh: Unable to copy the nwipe log files to the root of $drive:/\n"
    else
        printf "archive_log.sh: Successfully copied the nwipe logs to $drive:/\n"

        # Create the temporary sent directory we will move log files that have already been copied
        if [ ! -d "$sent_directory" ]; then
            mkdir "$sent_directory"
            if [ $? != 0 ]; then
                        printf "archive_log.sh: Unable to create the temporary directory $sent_directory on the RAM disc\n"
                        exit_code=5
            fi
        fi

        if [ exit_code != 5 ]; then
                # Move the nwipe logs into the RAM disc sent directory
                mv /nwipe_log* "$sent_directory/"
                if [ $? != 0 ]; then
                            printf "archive_log.sh: Unable to move the nwipe logs into the $sent_directory on the RAM disc\n"
                            exit_code=6
                else
                            printf "archive_log.sh: Moved the nwipe logs into the $sent_directory\n"
                fi
                # Move the nwipe PDF certificates into the RAM disc sent directory
                mv /nwipe_report*pdf "$sent_directory/"
                if [ $? != 0 ]; then
                            printf "archive_log.sh: Unable to move the PDF certificates into the $sent_directory on the RAM disc\n"
                else
                            printf "archive_log.sh: Moved the PDF certificates into the $sent_directory\n"
                fi
        fi
    fi
    # If mode 0 (read USB flash drive), read the /etc/nwipe/nwipe.conf and /etc/nwipe/customers.csv files from
    # the USB flash drive into the ShredOS RAM disc
    #
    #
    # Check that the /etc/nwipe directory exists on the ShredOS ram drive, if not create it.
    test -d "/etc/nwipe"
    if [ $? != 0 ]
    then
        mkdir "/etc/nwipe"
        if [ $? != 0 ]; then
            printf "archive_log.sh: Unable to create directory /etc/nwipe on ShredOS ram drive\n"
        else
            printf "archive_log.sh: Successfully created directory /etc/nwipe on ShredOS ram drive\n"
        fi
    fi
    if [[ "$mode" == "read" ]]; then
        # Copy /etc/nwipe/nwipe.conf from USB to ShredOS's ram disc
        test -f "$archive_drive_directory/etc/nwipe/nwipe.conf"
        if [ $? == 0 ]
        then
            # Copy nwipe.conf from USB flash to ShredOS ram disc
            cp "$archive_drive_directory/etc/nwipe/nwipe.conf" /etc/nwipe.conf
            if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to copy $drive:/etc/nwipe/nwipe.conf to ShredOS's ram disc\n"
            else
                printf "archive_log.sh: Sucessfully copied $drive:/etc/nwipe/nwipe.conf to ShredOS's ram disc\n"
            fi
        fi

        # Copy /etc/nwipe/customers.csv from USB to ShredOS's ram disc
        test -f "$archive_drive_directory/etc/nwipe/nwipe_customers.csv"
        if [ $? == 0 ]
        then
            # Copy nwipe.conf from USB flash to ShredOS ram disc
            cp "$archive_drive_directory/etc/nwipe/nwipe_customers.csv" /etc/nwipe/nwipe_customers.csv
            if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to copy $drive:/etc/nwipe/nwipe_customers.csv to /etc/nwipe/nwipe_customers.csv\n"
            else
                printf "archive_log.sh: Sucessfully copied $drive:/etc/nwipe/nwipe_customers.csv to /etc/nwipe/nwipe_customers.csv\n"
            fi
        fi
    fi
    # If mode 1 (write USB flash drive), write the /etc/nwipe/nwipe.conf and /etc/nwipe/customers.csv files to
    # the USB flash drive from the ShredOS RAM disc.
    #
    #
    # Check the /etc/ and /etc/nwipe directories exist on the USB drive, if not create them
    test -d "$archive_drive_directory/etc"
    if [ $? != 0 ]
    then
        mkdir "$archive_drive_directory/etc"
        if [ $? != 0 ]; then
            printf "archive_log.sh: Unable to create directory /etc on $drive:/\n"
        else
            printf "archive_log.sh: Successfully created directory /etc on $drive:/\n"
        fi
    fi

    test -d "$archive_drive_directory/etc/nwipe"
    if [ $? != 0 ]
    then
        mkdir "$archive_drive_directory/etc/nwipe"
        if [ $? != 0 ]; then
            printf "archive_log.sh: Unable to create directory /etc/nwipe on $drive:/\n"
        else
            printf "archive_log.sh: Successfully created directory /etc/nwipe on $drive:/\n"
        fi
    fi
    if [[ "$mode" == "write" ]]; then
        # Copy /etc/nwipe/nwipe.conf from ShredOS's ram disc to USB
        test -f "/etc/nwipe/nwipe.conf"
        if [ $? == 0 ]
        then
            cp /etc/nwipe/nwipe.conf "$archive_drive_directory/etc/nwipe/nwipe.conf"
            if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to copy /etc/nwipe/nwipe.conf to $drive:/etc/nwipe/nwipe.conf\n"
            else
                printf "archive_log.sh: Successfully copied /etc/nwipe/nwipe.conf to $drive:/etc/nwipe/nwipe.conf\n"
            fi
        fi

        # Copy /etc/nwipe/customers.csv from ShredOS's ram disc to USB
        test -f "/etc/nwipe/nwipe_customers.csv"
        if [ $? == 0 ]
        then
            cp /etc/nwipe/nwipe_customers.csv "$archive_drive_directory/etc/nwipe/nwipe_customers.csv"
            if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to copy /etc/nwipe/nwipe_customers.csv file to the root of $drive:/etc/nwipe/nwipe_customers.csv\n"
            else
                printf "archive_log.sh: Successfully copied /etc/nwipe/nwipe_customers.csv to $drive:/etc/nwipe/nwipe_customers.csv\n"
            fi
        fi
    fi
fi

# unmount the FAT32 drive
sleep 1
umount "$archive_drive_directory"
if [ $? != 0 ]; then
                printf "archive_log.sh: Unable to unmount the FAT32 partition\n"
                exit_code=7
else
    printf "archive_log.sh: Successfully unmounted $archive_drive_directory ($drive)\n"
fi

if [ $exit_code != 0 ]; then
    printf "archive_log.sh: Failed to copy nwipe log files to $drive, exit code $exit_code\n"
fi
exit $exit_code
