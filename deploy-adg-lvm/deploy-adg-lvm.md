# Deploy ADG Process

In the following steps you will setup Data Guard from a Single Instance database to another Single Instance database. 

##Lab Prerequisites

This lab assumes you have already completed the following labs:

- Setup Connectivity between the primary and the standby



##Step 1: Manually Delete the standby database Created by Tooling 

Please perform the below operations to delete the starter database files in the standby and we will restore the primary database using RMAN. 

To delete the starter database, use the manual method of removing the database files from OS file system. Do not use DBCA as this will also remove the srvctl registration as well as the /etc/oratab entries which should be retained for the standby. 

To manually delete the database on the standby host, run the steps below.

1. Connect to the standby host  with opc user. Use putty tool (Windows) or command line (Mac, linux)

   ```
   ssh -i labkey opc@xxx.xxx.xxx.xxx
   ```

   

2. Switch to the **oracle** user. 

   ```
   <copy>sudo su - oracle</copy>
   ```

   

3. Connect database as sysdba. Get the current `db_unique_name` for the standby database. 

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Jun 23 04:37:00 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> select DB_UNIQUE_NAME from v$database;

DB_UNIQUE_NAME
------------------------------
ORCLSTBY

SQL> 
```

4. Copy the following scripts.

   ```
   <copy>
   set heading off linesize 999 pagesize 0 feedback off trimspool on
   spool /tmp/files.lst
   select 'rm '||name from v$datafile union all select 'rm '||name from v$tempfile union all select 'rm '||member from v$logfile;
   spool off
   create pfile='/tmp/ORCLSTBY.pfile' from spfile;
   </copy>
   ```

   

5. Run in sqlplus as sysdba. This will create a script to remove all database files. 

```
SQL> set heading off linesize 999 pagesize 0 feedback off trimspool on
SQL> spool /tmp/files.lst
SQL> select 'rm '||name from v$datafile union all select 'rm '||name from v$tempfile union all select 'rm '||member from v$logfile;
rm /u01/app/oracle/oradata/ORCLSTBY/system01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/sysaux01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/undotbs01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/pdbseed/system01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/pdbseed/sysaux01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/users01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/pdbseed/undotbs01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/orclpdb/system01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/orclpdb/sysaux01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/orclpdb/undotbs01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/orclpdb/users01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/temp01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/pdbseed/temp012020-06-22_09-21-57-597-AM.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/orclpdb/temp01.dbf
rm /u01/app/oracle/oradata/ORCLSTBY/redo03.log
rm /u01/app/oracle/oradata/ORCLSTBY/redo02.log
rm /u01/app/oracle/oradata/ORCLSTBY/redo01.log
SQL> spool off
SQL> create pfile='/tmp/ORCLSTBY.pfile' from spfile;
SQL> 
```

6. Shutdown the database. 

```
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@standby ~]$ 
```

7. Remove database files 

 Remove the existing data files, log files, and tempfile(s). The password file will be replaced and the spfile will be reused. 

 Edit /tmp/files.lst created previously to remove any unneeded lines from sqlplus. Leaving all lines beginning with 'rm'. Then run it.

 ```
 [oracle@standby ~]$ chmod a+x /tmp/files.lst
 [oracle@standby ~]$ vi /tmp/files.lst
 [oracle@standby ~]$ . /tmp/files.lst
 [oracle@standby ~]$ 
 ```

 All files for the starter database have now been removed. 



## Step 2: Copy the Password File to the standby host 

As **oracle** user, copy the on-premise database password file to cloud host `$ORACLE_HOME/dbs` directory. 

1. Copy the following command, change the `primary**` to the primary hostname or public ip.

```
<copy>scp oracle@primary**:/u01/app/oracle/product/19c/dbhome_1/dbs/orapwORCL $ORACLE_HOME/dbs</copy>
```

2. Run the command as **oracle** user.

```
[oracle@standby ~]$ scp oracle@primary**:/u01/app/oracle/product/19c/dbhome_1/dbs/orapwORCL $ORACLE_HOME/dbs
orapwORCL 100% 2048    63.5KB/s   00:00    
[oracle@standby ~]$
```



## Step 3: Configure Static Listeners 

A static listener is needed for initial instantiation of a standby database. The static listener enables remote connection to an instance while the database is down in order to start a given instance. See MOS 1387859.1 for additional details.  A static listener for Data Guard Broker is optional. 

1. From primary side

   - Switch to the **oracle** user, edit listener.ora

   ```
   <copy>vi $ORACLE_HOME/network/admin/listener.ora</copy>
   ```

   - Add following lines into listener.ora

```
<copy>
SID_LIST_LISTENER=
  (SID_LIST=
    (SID_DESC=
     (GLOBAL_DBNAME=ORCL)
     (ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1)
     (SID_NAME=ORCL)
    )
    (SID_DESC=
     (GLOBAL_DBNAME=ORCL_DGMGRL)
     (ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1)
     (SID_NAME=ORCL)
    )
  )
</copy>
```

   - Reload the listener

   ```
   [oracle@primary ~]$ lsnrctl reload

   LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 31-JAN-2020 11:27:23

   Copyright (c) 1991, 2019, Oracle.  All rights reserved.

   Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=workshop)(PORT=1521)))
   The command completed successfully
   [oracle@primary ~]$ 
   ```

2. From standby side

   - Switch to the **oracle** user, edit listener.ora

   ```
   <copy>vi $ORACLE_HOME/network/admin/listener.ora</copy>
   ```

   - Add following lines into listener.ora.

```
<copy>
SID_LIST_LISTENER=
  (SID_LIST=
    (SID_DESC=
     (GLOBAL_DBNAME=ORCLSTBY)
     (ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1)
     (SID_NAME=ORCL)
    )
    (SID_DESC=
     (GLOBAL_DBNAME=ORCLSTBY_DGMGRL)
     (ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1)
     (SID_NAME=ORCL)
    )
  )
</copy>
```

   - Reload the listener

   ```
   [oracle@standby ~]$ lsnrctl reload

   LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 31-JAN-2020 11:39:12

   Copyright (c) 1991, 2019, Oracle.  All rights reserved.

   Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
   The command completed successfully
   [oracle@standby ~]$ 
   ```

3. Mount the Standby database.

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 10:50:18 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup mount
ORACLE instance started.

Total System Global Area 1.6106E+10 bytes
Fixed Size		    9154008 bytes
Variable Size		 2080374784 bytes
Database Buffers	 1.3992E+10 bytes
Redo Buffers		   24399872 bytes
Database mounted.
SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@dbstby ~]$ 
```



## Step 4: TNS Entries for Redo Transport 

1. From primary side, switch as **oracle** user, edit the tnsnames.ora

```
<copy>vi $ORACLE_HOME/network/admin/tnsnames.ora</copy>
```

Add following lines into tnsnames.ora, replace `standby**` with the public ip or hostname of the standby hosts.

```
ORCLSTBY =
  (DESCRIPTION =
   (SDU=65536)
   (RECV_BUF_SIZE=134217728)
   (SEND_BUF_SIZE=134217728)
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby**)(PORT = 1521))
   )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLSTBY)
      (UR=A)
    )
  )
```

2. From the standby side, switch as **oracle** user, edit the tnsnames.ora

```
vi $ORACLE_HOME/network/admin/tnsnames.ora
```

Add the ORCL description, replace `primary**` with the public ip or hostname of the primary hosts.  It's looks like the following.  

```
ORCL =
  (DESCRIPTION =
   (SDU=65536)
   (RECV_BUF_SIZE=134217728)
   (SEND_BUF_SIZE=134217728)
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = TCP)(HOST = primary**)(PORT = 1521))
   )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
      (UR=A)
    )
  )
```



## Step 5: Instantiate the Standby Database 

The standby database can be created from the active primary database.

1. From the standby side, switch to **oracle** user, create pdb directory,  If the directory exist, ignore the error

```
[oracle@standby ~]$ mkdir /u01/app/oracle/oradata/ORCLSTBY/pdbseed
mkdir: cannot create directory '/u01/app/oracle/oradata/ORCLSTBY/pdbseed': File exists
[oracle@standby ~]$ mkdir /u01/app/oracle/oradata/ORCLSTBY/orclpdb
```

2. Copy the following command.

   ```
   <copy>
   alter system set db_file_name_convert='/u01/app/oracle/oradata/ORCL','/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;
   alter system set db_create_online_log_dest_1='/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;
   alter system set log_file_name_convert='/u01/app/oracle/oradata/ORCL','/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;
   alter system set db_name='ORCL' scope=spfile;
   alter system set db_unique_name=ORCLSTBY scope=spfile;
   </copy>
   ```

   

3. Run the command in sqlplus as sysdba. This will modify the db and log file name convert parameter.

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Jun 23 02:46:13 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> alter system set db_file_name_convert='/u01/app/oracle/oradata/ORCL','/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;

System altered.

SQL> alter system set db_create_online_log_dest_1='/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;

System altered.

SQL> alter system set log_file_name_convert='/u01/app/oracle/oradata/ORCL','/u01/app/oracle/oradata/ORCLSTBY' scope=spfile;

System altered.

SQL> alter system set db_name='ORCL' scope=spfile;

System altered.

SQL> alter system set db_unique_name=ORCLSTBY scope=spfile;

System altered.
```

4. Shutdown the database, connect with RMAN. Then startup database nomount.

```
SQL> shutdown immediate
ORA-01109: database not open


Database dismounted.
ORACLE instance shut down.

SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@dbstby ~]$ rman target /

Recovery Manager: Release 19.0.0.0.0 - Production on Fri Jan 31 12:41:27 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

connected to target database (not started)

RMAN> startup nomount

Oracle instance started

Total System Global Area   16106126808 bytes

Fixed Size                     9154008 bytes
Variable Size               2181038080 bytes
Database Buffers           13891534848 bytes
Redo Buffers                  24399872 bytes

RMAN> 
```

5. Restore control file from the primary database and mount the standby database.

```
RMAN> restore standby controlfile from service 'ORCL';

Starting restore at 01-FEB-20
using target database control file instead of recovery catalog
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=11 device type=DISK

channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: using network backup set from service ORCL
channel ORA_DISK_1: restoring control file
channel ORA_DISK_1: restore complete, elapsed time: 00:00:02
output file name=/u02/app/oracle/oradata/ORCL_nrt1d4/control01.ctl
output file name=/u03/app/oracle/fast_recovery_area/ORCL_nrt1d4/control02.ctl
Finished restore at 01-FEB-20

RMAN> alter database mount;

released channel: ORA_DISK_1
Statement processed

RMAN> 
```

6. Now, restore database from the primary database.

```
RMAN> restore database from service 'ORCL' section size 5G;

Starting restore at 01-FEB-20
Starting implicit crosscheck backup at 01-FEB-20
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=17 device type=DISK
Crosschecked 2 objects
Finished implicit crosscheck backup at 01-FEB-20

Starting implicit crosscheck copy at 01-FEB-20
using channel ORA_DISK_1
Finished implicit crosscheck copy at 01-FEB-20

searching for all files in the recovery area
cataloging files...
cataloging done

channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: using network backup set from service ORCL
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00001 to /u02/app/oracle/oradata/ORCL_nrt1d4/system01.dbf
channel ORA_DISK_1: restoring section 1 of 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:16
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: using network backup set from service ORCL
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00003 to /u02/app/oracle/oradata/ORCL_nrt1d4/sysaux01.dbf
channel ORA_DISK_1: restoring section 1 of 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:16
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: using network backup set from service ORCL
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00004 to /u02/app/oracle/oradata/ORCL_nrt1d4/undotbs01.dbf
channel ORA_DISK_1: restoring section 1 of 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:04
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: using network backup set from service ORCL
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00005 to /u02/app/oracle/oradata/ORCL_nrt1d4/pdbseed/system01.dbf
......
......
channel ORA_DISK_1: restoring section 1 of 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:02
Finished restore at 01-FEB-20

RMAN> 
```

7. Shutdown the database, connect to sqlplus as sysdba and mount the database again.

```
RMAN> shutdown immediate

database dismounted
Oracle instance shut down

RMAN> exit


Recovery Manager complete.
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 11:16:31 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Connected to an idle instance.

SQL> startup mount
ORACLE instance started.

Total System Global Area 1.6106E+10 bytes
Fixed Size		    9154008 bytes
Variable Size		 2080374784 bytes
Database Buffers	 1.3992E+10 bytes
Redo Buffers		   24399872 bytes
Database mounted.
SQL> 
```



## Step 7: Clear all online and standby redo logs 

1. Copy the following command.

   ```
   <copy>
   set pagesize 0 feedback off linesize 120 trimspool on
   spool /tmp/clearlogs.sql
   select distinct 'alter database clear logfile group '||group#||';' from v$logfile;
   spool off
   @/tmp/clearlogs.sql
   </copy>
   ```

   

2. Run the command in sqlplus as sysdba, this will clear or create new online and standby redo log, ignore the unknown command.

```
SQL> set pagesize 0 feedback off linesize 120 trimspool on
SQL> spool /tmp/clearlogs.sql
SQL> select distinct 'alter database clear logfile group '||group#||';' from v$logfile;
alter database clear logfile group 1;
alter database clear logfile group 2;
alter database clear logfile group 3;
alter database clear logfile group 4;
alter database clear logfile group 5;
alter database clear logfile group 6;
alter database clear logfile group 7;
SQL> spool off
SQL> @/tmp/clearlogs.sql
SP2-0734: unknown command beginning "SQL> selec..." - rest of line ignored.

SP2-0734: unknown command beginning "SQL> spool..." - rest of line ignored.
SQL> 
```



## Step 8: Configure Data Guard broker

1. Copy the following command.

   ```
   <copy>
   show parameter dg_broker_config_file;
   show parameter dg_broker_start;
   alter system set dg_broker_start=true;
   select pname from v$process where pname like 'DMON%';
   </copy>
   ```

   

2. Run the command on primary and standby database to enable the data guard broker.

- From the primary side,

```
SQL> show parameter dg_broker_config_file;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
dg_broker_config_file1		     string	 /u01/app/oracle/product/19.0.0
						 /dbhome_1/dbs/dr1ORCL.dat
dg_broker_config_file2		     string	 /u01/app/oracle/product/19.0.0
						 /dbhome_1/dbs/dr2ORCL.dat
SQL> show parameter dg_broker_start

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
dg_broker_start 		     boolean	 FALSE
SQL> alter system set dg_broker_start=true;

System altered.

SQL> select pname from v$process where pname like 'DMON%';

PNAME
-----
DMON

SQL> 
```

- From the standby side

```
SQL> show parameter dg_broker_config_file

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
dg_broker_config_file1		     string	 /u01/app/oracle/product/19.0.0
						 .0/dbhome_1/dbs/dr1ORCL_nrt1d4
						 .dat
dg_broker_config_file2		     string	 /u01/app/oracle/product/19.0.0
						 .0/dbhome_1/dbs/dr2ORCL_nrt1d4
						 .dat
SQL> show parameter dg_broker_start

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
dg_broker_start 		     boolean	 FALSE
SQL> alter system set dg_broker_start=true;

System altered.

SQL> select pname from v$process where pname like 'DMON%';

PNAME
-----
DMON

SQL> 
```

3. Register the database via DGMGRL. From the primary side.

```
[oracle@primary ~]$ dgmgrl sys/Ora_DB4U@ORCL
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Sat Feb 1 03:51:49 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "ORCL"
Connected as SYSDBA.
DGMGRL> CREATE CONFIGURATION adgconfig AS PRIMARY DATABASE IS ORCL CONNECT IDENTIFIER IS ORCL;
Configuration "adgconfig" created with primary database "orcl"
DGMGRL> ADD DATABASE ORCLSTBY AS CONNECT IDENTIFIER IS ORCLSTBY MAINTAINED AS PHYSICAL;
Database "orclstby" added
DGMGRL> ENABLE CONFIGURATION;
Enabled.
DGMGRL> SHOW CONFIGURATION;

Configuration - adgconfig

  Protection Mode: MaxPerformance
  Members:
  orcl        - Primary database
    orclstby - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 42 seconds ago)
```

If there is a warning message, Warning: ORA-16809: multiple warnings detected for the member or Warning: ORA-16854: apply lag could not be determined. You can wait serveral minutes and show configuration again.

Now, the Data Guard is ready. The standby database is in mount status.

