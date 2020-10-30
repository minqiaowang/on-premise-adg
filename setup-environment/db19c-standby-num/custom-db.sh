#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - SIDNAME=ORCL DBNAME=ORCLSTBY DBCA_PLUGGABLE_DB_NAME=orclpdb /u01/ocidb/buildsingle.sh -s
