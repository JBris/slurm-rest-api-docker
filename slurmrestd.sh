#!/usr/bin/env bash

gosu munge /usr/sbin/munged

until 2>/dev/null >/dev/tcp/slurmctld/6817
do
    echo "-- slurmctld is not available.  Sleeping ..."
    sleep 2
done
echo "-- slurmctld is now active ..."

sacctmgr -i add account rest 
sacctmgr -i add user rest account=rest

export SLURMRESTD_SECURITY=disable_unshare_files,disable_unshare_sysv

SLURM_JWT=daemon SLURMRESTD_DEBUG=5 exec gosu rest /usr/sbin/slurmrestd 0.0.0.0:9200

