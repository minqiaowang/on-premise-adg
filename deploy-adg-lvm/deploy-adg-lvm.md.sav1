# Deploy ADG Process

## Introduction
In this lab you will setup Active Data Guard from a Single Instance database to another Single Instance database. 

Estimated Lab Time: 30 minutes.

### Objectives
- Prepare the standby database.
- Configure Static Listeners.
- TNS Entries for Redo Transport.
- Duplicate the Database to the standby.
- Configure Data Guard broker

### Prerequisites

This lab assumes you have already completed the following labs:

- Setup Connectivity between the primary and the standby



## **Step 1:** Prepare the standby host

The standby host has the database software only installed. You need do some steps to prepare the standby host.

1. Connect to the standby VM hosts with opc user. Use putty tool (Windows) or command line (Mac, Linux).

   ```
   ssh -i labkey opc@xxx.xxx.xxx.xxx
   ```

   

2. Swtich to **oracle** user.

   ```
   sudo su - oracle
   ```

   

3. Modify the `.bash_profile` environment file.

   ```
   [oracle@standby ~]$ vi .bash_profile
   ```

   

4. Add the following lines to the file.

   ```
   <copy>
   export ORACLE_BASE=/u01/app/oracle; 
   export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1; 
   export PATH=$ORACLE_HOME/bin:$PATH
   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export ORACLE_SID=ORCL
   </copy>
   ```

   

5. Activate the environment variables.

   ```
   [oracle@standby ~]$ <copy>. .bash_profile</copy>
   ```

   

6. Configure the Listener.

   ```
   [oracle@standby ~]$ <copy>/u01/app/oracle/product/19c/dbhome_1/bin/netca /orahome /u01/app/oracle/product/19c/dbhome_1 /instype typical /inscomp client,oraclenet,javavm,server,ano /insprtcl tcp /cfg local /authadp NO_VALUE /responseFile /u01/app/oracle/product/19c/dbhome_1/network/install/netca_typ.rsp /lisport 1521 /silent /orahnam OraDB19Home1</copy>
   ```

   The result like the following:

   ```
   Parsing command line arguments:
       Parameter "orahome" = /u01/app/oracle/product/19c/dbhome_1
       Parameter "instype" = typical
       Parameter "inscomp" = client,oraclenet,javavm,server,ano
       Parameter "insprtcl" = tcp
       Parameter "cfg" = local
       Parameter "authadp" = NO_VALUE
       Parameter "responsefile" = /u01/app/oracle/product/19c/dbhome_1/network/install/netca_typ.rsp
       Parameter "lisport" = 1521
       Parameter "silent" = true
       Parameter "orahnam" = OraDB19Home1
   Done parsing command line arguments.
   Oracle Net Services Configuration:
   Profile configuration complete.
   Listener is using the port provided in the command line:1521
   Oracle Net Listener Startup:
       Running Listener Control: 
         /u01/app/oracle/product/19c/dbhome_1/bin/lsnrctl start LISTENER
       Listener Control complete.
       Listener started successfully.
   Listener configuration complete.
   Oracle Net Services configuration successful. The exit code is 0
   [oracle@standby ~]$ 
   ```

   

7. Check the listener status.

   ```
   [oracle@standby ~]$ lsnrctl status
   
   LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 06-NOV-2020 11:46:12
   
   Copyright (c) 1991, 2019, Oracle.  All rights reserved.
   
   Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=standby.subnet1.standbyvcn.oraclevcn.com)(PORT=1521)))
   STATUS of the LISTENER
   ------------------------
   Alias                     LISTENER
   Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
   Start Date                06-NOV-2020 11:45:27
   Uptime                    0 days 0 hr. 0 min. 45 sec
   Trace Level               off
   Security                  ON: Local OS Authentication
   SNMP                      OFF
   Listener Parameter File   /u01/app/oracle/product/19c/dbhome_1/network/admin/listener.ora
   Listener Log File         /u01/app/oracle/diag/tnslsnr/standby/listener/alert/log.xml
   Listening Endpoints Summary...
     (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=standby)(PORT=1521)))
     (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
   The listener supports no services
   The command completed successfully
   [oracle@standby ~]$ 
   ```
   
   

## **Step 2:** Configure Static Listeners 

A static listener is needed for initial instantiation of a standby database. The static listener enables remote connection to an instance while the database is down in order to start a given instance. See MOS 1387859.1 for additional details.  A static listener for Data Guard Broker is optional. 

1. From the primary side

   - Switch to the **oracle** user, edit `listener.ora`

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
   
   - Reload the listener.
   
      ```
      [oracle@primary ~]$ lsnrctl reload
      
      LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 31-JAN-2020 11:27:23
      
      Copyright (c) 1991, 2019, Oracle.  All rights reserved.
      
      Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=workshop)(PORT=1521)))
      The command completed successfully
      [oracle@primary ~]$ 
      ```
   
      



2. From the standby side

   - Switch to the **oracle** user, edit `listener.ora`

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
   
      





## **Step 3:** TNS Entries for Redo Transport 

1. From the primary side, switch as **oracle** user, edit the `tnsnames.ora`

```
<copy>vi $ORACLE_HOME/network/admin/tnsnames.ora</copy>
```

Add following lines into tnsnames.ora. Save the file.

```
<copy>
ORCLSTBY =
  (DESCRIPTION =
   (SDU=65536)
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby)(PORT = 1521))
   )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLSTBY)
      (UR=A)
    )
  )</copy>
```

2. From the standby side, switch as **oracle** user, edit the `tnsnames.ora`

```
vi $ORACLE_HOME/network/admin/tnsnames.ora
```

Add the following lines to the file.  It's looks like the following. Save the file.  

```
<copy>
LISTENER_ORCLSTBY =
  (ADDRESS = (PROTOCOL = TCP)(HOST = standby.subnet1.standbyvcn.oraclevcn.com)(PORT = 1521))
  
ORCLSTBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby.subnet1.standbyvcn.oraclevcn.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLSTBY)
    )
  )
  
ORCL =
  (DESCRIPTION =
   (SDU=65536)
   (ADDRESS_LIST =
    (ADDRESS = (PROTOCOL = TCP)(HOST = primary)(PORT = 1521))
   )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
      (UR=A)
    )
  )</copy>
```



## **Step 4:** Duplicate the Database to Standby  

The standby database can be duplicated from the primary database.

1. From the standby side, copy the password file from the primary side.

   ```
   [oracle@standby ~]$ <copy>scp oracle@primary:/u01/app/oracle/product/19c/dbhome_1/dbs/orapwORCL $ORACLE_HOME/dbs</copy>
   orapwORCL 100% 2048    63.5KB/s   00:00    
   [oracle@standby ~]$
   ```

   

2. From the standby side, create the database directory.

   ```
   <copy>
   mkdir -p /u01/app/oracle/oradata/ORCLSTBY/pdbseed
   mkdir -p /u01/app/oracle/oradata/ORCLSTBY/orclpdb
   mkdir -p /u01/app/oracle/admin/ORCLSTBY/adump
   mkdir -p /u01/app/oracle/admin/ORCLSTBY/dpdump
   mkdir -p /u01/app/oracle/admin/ORCLSTBY/pfile
   </copy>
   ```

   

2. Edit an init file.

   ```
   [oracle@standby ~]$ <copy>vi /u01/app/oracle/product/19c/dbhome_1/dbs/initorclstby.ora</copy>
   ```
   
   
   
3. Add the following lines into this file.

   ```
   <copy>
   DB_NAME=ORCL
   DB_UNIQUE_NAME=ORCLSTBY
   </copy>
   ```

   

4. Start the database in NOMOUNT status using the init parameter file you create in the previous step.

   ```
   [oracle@standby dbs]$ sqlplus / as sysdba
   
   SQL*Plus: Release 19.0.0.0.0 - Production on Fri Nov 6 04:13:11 2020
   Version 19.10.0.0.0
   
   Copyright (c) 1982, 2020, Oracle.  All rights reserved.
   
   Connected to an idle instance.
   
   SQL> startup nomount pfile='/u01/app/oracle/product/19c/dbhome_1/dbs/initorclstby.ora'
   ORACLE instance started.
   
   Total System Global Area  251656872 bytes
   Fixed Size		    8895144 bytes
   Variable Size		  184549376 bytes
   Database Buffers	   50331648 bytes
   Redo Buffers		    7880704 bytes
   SQL> exit
   ```

   

5. Connect with RMAN.

   ```
   [oracle@standby ~]$ <copy>rman target sys/Ora_DB4U@ORCL auxiliary sys/Ora_DB4U@ORCLSTBY</copy>
   
   Recovery Manager: Release 19.0.0.0.0 - Production on Fri Nov 6 04:19:38 2020
   Version 19.10.0.0.0
   
   Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.
   
   connected to target database: ORCL (DBID=1583512061)
   connected to auxiliary database: ORCL (not mounted)
   
   RMAN>
   ```

   

6. Run the following command in RMAN to duplicate the database.

   ```
   <copy>
   run {
   duplicate target database for standby from active database
   spfile
   parameter_value_convert 'ORCL','ORCLSTBY'
   set db_name='ORCL'
   set db_unique_name='ORCLSTBY'
   set db_create_file_dest='/u01/app/oracle/oradata/ORCLSTBY'
   set db_recovery_file_dest='/u01/app/oracle/oradata/ORCLSTBY'
   set db_file_name_convert='/ORCL/','/ORCLSTBY/'
   set log_file_name_convert='/ORCL/','/ORCLSTBY/'
   ;
   }</copy>
   ```

   

7. The output like the following.

   ```
   RMAN> run {
   duplicate target database for standby from active database
   spfile
   parameter_value_convert 'ORCL','ORCLSTBY'
   set db_name='ORCL'
   set db_unique_name='ORCLSTBY'
   set db_create_file_dest='/u01/app/oracle/oradata/ORCLSTBY'
   set db_recovery_file_dest='/u01/app/oracle/oradata/ORCLSTBY'
   set db_file_name_convert='/ORCL/','/ORCLSTBY/'
   set log_file_name_convert='/ORCL/','/ORCLSTBY/'
   ;
   }2> 3> 4> 5> 6> 7> 8> 9> 10> 11> 12> 
   
   Starting Duplicate Db at 06-NOV-20
   using target database control file instead of recovery catalog
   allocated channel: ORA_AUX_DISK_1
   channel ORA_AUX_DISK_1: SID=21 device type=DISK
   
   contents of Memory Script:
   {
      backup as copy reuse
      passwordfile auxiliary format  '/u01/app/oracle/product/19c/dbhome_1/dbs/orapwORCL'   ;
      restore clone from service  'ORCL' spfile to 
    '/u01/app/oracle/product/19c/dbhome_1/dbs/spfileORCL.ora';
      sql clone "alter system set spfile= ''/u01/app/oracle/product/19c/dbhome_1/dbs/spfileORCL.ora''";
   }
   executing Memory Script
   
   Starting backup at 06-NOV-20
   allocated channel: ORA_DISK_1
   channel ORA_DISK_1: SID=42 device type=DISK
   Finished backup at 06-NOV-20
   
   Starting restore at 06-NOV-20
   using channel ORA_AUX_DISK_1
   
   channel ORA_AUX_DISK_1: starting datafile backup set restore
   channel ORA_AUX_DISK_1: using network backup set from service ORCL
   channel ORA_AUX_DISK_1: restoring SPFILE
   output file name=/u01/app/oracle/product/19c/dbhome_1/dbs/spfileORCL.ora
   channel ORA_AUX_DISK_1: restore complete, elapsed time: 00:00:01
   Finished restore at 06-NOV-20
   
   sql statement: alter system set spfile= ''/u01/app/oracle/product/19c/dbhome_1/dbs/spfileORCL.ora''
   
   contents of Memory Script:
   {
      sql clone "alter system set  audit_file_dest = 
    ''/u01/app/oracle/admin/ORCLSTBY/adump'' comment=
    '''' scope=spfile";
   ......
   
      sql clone "alter system set  db_file_name_convert = 
    ''/ORCL/'', ''/ORCLSTBY/'' comment=
    '''' scope=spfile";
      sql clone "alter system set  log_file_name_convert = 
    ''/ORCL/'', ''/ORCLSTBY/'' comment=
    '''' scope=spfile";
      shutdown clone immediate;
      startup clone nomount;
   }
   executing Memory Script
   
   sql statement: alter system set  audit_file_dest =  ''/u01/app/oracle/admin/ORCLSTBY/adump'' comment= '''' scope=spfile
   
   sql statement: alter system set  control_files =  ''/u01/app/oracle/oradata/ORCLSTBY/control01.ctl'', ''/u01/app/oracle/oradata/ORCLSTBY/control02.ctl'' comment= '''' scope=spfile
   
   sql statement: alter system set  dispatchers =  ''(PROTOCOL=TCP) (SERVICE=ORCLSTBYXDB)'' comment= '''' scope=spfile
   
   sql statement: alter system set  local_listener =  ''LISTENER_ORCLSTBY'' comment= '''' scope=spfile
   
   sql statement: alter system set  db_name =  ''ORCL'' comment= '''' scope=spfile
   
   sql statement: alter system set  db_unique_name =  ''ORCLSTBY'' comment= '''' scope=spfile
   
   sql statement: alter system set  db_create_file_dest =  ''/u01/app/oracle/oradata/ORCLSTBY'' comment= '''' scope=spfile
   
   sql statement: alter system set  db_recovery_file_dest =  ''/u01/app/oracle/oradata/ORCLSTBY'' comment= '''' scope=spfile
   
   sql statement: alter system set  db_file_name_convert =  ''/ORCL/'', ''/ORCLSTBY/'' comment= '''' scope=spfile
   
   sql statement: alter system set  log_file_name_convert =  ''/ORCL/'', ''/ORCLSTBY/'' comment= '''' scope=spfile
   
   Oracle instance shut down
   
   connected to auxiliary database (not started)
   Oracle instance started
   
   Total System Global Area    4647286504 bytes
   
   Fixed Size                     9144040 bytes
   Variable Size                855638016 bytes
   Database Buffers            3774873600 bytes
   Redo Buffers                   7630848 bytes
   
   contents of Memory Script:
   {
      restore clone from service  'ORCL' standby controlfile;
   }
   executing Memory Script
   
   Starting restore at 06-NOV-20
   allocated channel: ORA_AUX_DISK_1
   channel ORA_AUX_DISK_1: SID=18 device type=DISK
   
   channel ORA_AUX_DISK_1: starting datafile backup set restore
   channel ORA_AUX_DISK_1: using network backup set from service ORCL
   channel ORA_AUX_DISK_1: restoring control file
   channel ORA_AUX_DISK_1: restore complete, elapsed time: 00:00:01
   output file name=/u01/app/oracle/oradata/ORCLSTBY/control01.ctl
   output file name=/u01/app/oracle/oradata/ORCLSTBY/control02.ctl
   Finished restore at 06-NOV-20
   
   contents of Memory Script:
   {
      sql clone 'alter database mount standby database';
   }
   executing Memory Script
   
   sql statement: alter database mount standby database
   
   contents of Memory Script:
   {
      set newname for tempfile  1 to 
    "/u01/app/oracle/oradata/ORCLSTBY/temp01.dbf";
      set newname for tempfile  2 to 
    "/u01/app/oracle/oradata/ORCLSTBY/pdbseed/temp012020-11-06_03-04-06-412-AM.dbf";
   ......
   
      set newname for datafile  11 to 
    "/u01/app/oracle/oradata/ORCLSTBY/orclpdb/undotbs01.dbf";
      set newname for datafile  12 to 
    "/u01/app/oracle/oradata/ORCLSTBY/orclpdb/users01.dbf";
      restore
      from  nonsparse   from service 
    'ORCL'   clone database
      ;
      sql 'alter system archive log current';
   }
   executing Memory Script
   
   executing command: SET NEWNAME
   
   executing command: SET NEWNAME
   
   executing command: SET NEWNAME
   
   renamed tempfile 1 to /u01/app/oracle/oradata/ORCLSTBY/temp01.dbf in control file
   renamed tempfile 2 to /u01/app/oracle/oradata/ORCLSTBY/pdbseed/temp012020-11-06_03-04-06-412-AM.dbf in control file
   renamed tempfile 3 to /u01/app/oracle/oradata/ORCLSTBY/orclpdb/temp01.dbf in control file
   
   executing command: SET NEWNAME
   ......
   
   executing command: SET NEWNAME
   
   Starting restore at 06-NOV-20
   using channel ORA_AUX_DISK_1
   
   channel ORA_AUX_DISK_1: starting datafile backup set restore
   channel ORA_AUX_DISK_1: using network backup set from service ORCL
   channel ORA_AUX_DISK_1: specifying datafile(s) to restore from backup set
   channel ORA_AUX_DISK_1: restoring datafile 00001 to /u01/app/oracle/oradata/ORCLSTBY/system01.dbf
   channel ORA_AUX_DISK_1: restore complete, elapsed time: 00:00:15
   ......
   
   channel ORA_AUX_DISK_1: using network backup set from service ORCL
   channel ORA_AUX_DISK_1: specifying datafile(s) to restore from backup set
   channel ORA_AUX_DISK_1: restoring datafile 00012 to /u01/app/oracle/oradata/ORCLSTBY/orclpdb/users01.dbf
   channel ORA_AUX_DISK_1: restore complete, elapsed time: 00:00:01
   Finished restore at 06-NOV-20
   
   sql statement: alter system archive log current
   
   contents of Memory Script:
   {
      switch clone datafile all;
   }
   executing Memory Script
   
   datafile 1 switched to datafile copy
   input datafile copy RECID=4 STAMP=1055745153 file name=/u01/app/oracle/oradata/ORCLSTBY/system01.dbf
   datafile 3 switched to datafile copy
   input datafile copy RECID=5 STAMP=1055745153 file name=/u01/app/oracle/oradata/ORCLSTBY/sysaux01.dbf
   datafile 4 switched to datafile copy
   ......
   
   input datafile copy RECID=13 STAMP=1055745154 file name=/u01/app/oracle/oradata/ORCLSTBY/orclpdb/undotbs01.dbf
   datafile 12 switched to datafile copy
   input datafile copy RECID=14 STAMP=1055745154 file name=/u01/app/oracle/oradata/ORCLSTBY/orclpdb/users01.dbf
   Finished Duplicate Db at 06-NOV-20
   
   RMAN> 
   ```

8. Exit the RMAN.





## **Step 5:** Configure Data Guard broker

1. Copy the following command.

   ```
   <copy>
   show parameter dg_broker_config_file;
   show parameter dg_broker_start;
   alter system set dg_broker_start=true;
   select pname from v$process where pname like 'DMON%';
   </copy>
   ```

   

2. Run the command as sysdba on the primary and the standby database to enable the data guard broker.

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

3. Register the database via DGMGRL. You can run the DGMGRL command from primary site or standby site.

```
[oracle@primary ~]$ dgmgrl sys/Ora_DB4U@ORCL
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Sat Feb 1 03:51:49 2020
Version 19.10.0.0.0

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

You may proceed to the next lab.

## Acknowledgements
* **Author** - Minqiao Wang, DB Product Management, Oct 2020
* **Contributors** -  
* **Last Updated By/Date** - Minqiao Wang, DB Product Management, Nov 2020

## See an issue?
Please submit feedback using this [form](https://apexapps.oracle.com/pls/apex/f?p=133:1:::::P1_FEEDBACK:1). Please include the *workshop name*, *lab* and *step* in your request.  If you don't see the workshop name listed, please enter it manually. If you would like us to follow up with you, enter your email in the *Feedback Comments* section.
