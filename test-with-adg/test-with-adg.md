# Test with ADG

Now we can run some testing with the ADG.

## Lab Prerequisites

This lab assumes you have already completed the following labs:

- Deploy Active Data Guard

## Step 1: Test transaction replication

1. From the primary side, create a test user in orclpdb, and grant privileges to the user. You need  to check if the pdb is open.

```
[oracle@primary ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 06:52:50 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> show pdbs

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  READ ONLY  NO
	 3 ORCLPDB			  MOUNTED
SQL> alter pluggable database all open;

Pluggable database altered.

SQL> alter session set container=orclpdb;

Session altered.

SQL> create user testuser identified by testuser;

User created.

SQL> grant connect,resource to testuser;

Grant succeeded.

SQL> alter user testuser quota unlimited on users;

User altered.

SQL> exit;
```

2. Connect with testuser, create test table and insert a test record.

```
[oracle@primary ~]$ sqlplus testuser/testuser@localhost:1521/orclpdb

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 06:59:56 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> create table test(a number,b varchar2(20));

Table created.
SQL> insert into test values(1,'line1');

1 row created.

SQL> commit;

Commit complete.

SQL>  
```

3. From the standby side, open the standby database as read only.

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 07:04:39 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> select open_mode,database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
MOUNTED 	     PHYSICAL STANDBY

SQL> alter database open;

Database altered.

SQL> alter pluggable database orclpdb open;

Pluggable database altered.

SQL> show pdbs

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  READ ONLY  NO
	 3 ORCLPDB			  READ ONLY  NO
	 
SQL> select open_mode,database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
READ ONLY WITH APPLY PHYSICAL STANDBY

SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@dbstby ~]$ 
```

4. From the standby side, connect as testuser to orclpdb. Check if the test table and record has replicated to the standby.

```
[oracle@standby ~]$ sqlplus testuser/testuser@localhost:1521/orclpdb

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 07:09:27 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Last Successful login time: Sat Feb 01 2020 06:59:56 +00:00

Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> select * from test;

	 A B
---------- --------------------
	 1 line1

SQL> 
```



## Step 2: Test DML Redirection

Starting  with Oracle DB 19c, we can run DML operations on Active Data Guard standby databases. This enables you to occasionally execute DMLs on read-mostly applications on the standby database.

Automatic redirection of DML operations to the primary can be configured at the system level or the session level. The session level setting overrides the system level

1. From the standby side, connect to orclpdb as testuser. Test the DML before and after the DML Redirection is enabled.

```
SQL> insert into test values(2,'line2');
insert into test values(2,'line2')
            *
ERROR at line 1:
ORA-16000: database or pluggable database open for read-only access


SQL> ALTER SESSION ENABLE ADG_REDIRECT_DML;

Session altered.

SQL> insert into test values(2,'line2');

1 row created.

SQL> commit; 

Commit complete.

SQL> select * from test;

	 A B
---------- --------------------
	 2 line2
	 1 line1

SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@standby ~]$ 
```

2. From the primary side, connect to orclpdb as testuser. Check the records in the test table.

```
SQL> select * from test;

	 A B
---------- --------------------
	 2 line2
	 1 line1

SQL> exit
Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@adgstudent1 ~]$ 
```



## Step 3: Switchover to the Cloud 

At any time, you can manually execute a Data Guard switchover (planned event) or failover (unplanned event). Customers may also choose to automate Data Guard failover by configuring Fast-Start failover. Switchover and failover reverse the roles of the databases in a Data Guard configuration – the standby in the cloud becomes primary and the original on-premise primary becomes a standby database. Refer to Oracle MAA Best Practices for additional information on Data Guard role transitions. 

Switchovers are always a planned event that guarantees no data is lost. To execute a switchover, perform the following in Data Guard Broker 

1. Connect DGMGRL from the primary side, validate the standby database to see if Ready For Switchover is Yes. 

```
[oracle@primary ~]$ dgmgrl sys/Ora_DB4U@orcl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Sat Feb 1 07:21:55 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "ORCL"
Connected as SYSDBA.
DGMGRL> validate database ORCLSTBY

  Database Role:     Physical standby database
  Primary Database:  orcl

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Flashback Database Status:
    orcl    :  On
    orclstby:  Off

  Managed by Clusterware:
    orcl    :  NO             
    orclstby:  NO             
    Validating static connect identifier for the primary database orcl...
    The static connect identifier allows for a connection to database "orcl".

  Current Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (orcl)                  (orclstby)                           
    1         3                       2                       Insufficient SRLs

  Future Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (orclstby)              (orcl)                               
    1         3                       0                       Insufficient SRLs
    Warning: standby redo logs not configured for thread 1 on orcl

DGMGRL> 
```

2. Switch over to the standby database.

```
DGMGRL> switchover to orclstby
Performing switchover NOW, please wait...
Operation requires a connection to database "orclstby"
Connecting ...
Connected to "ORCLSTBY"
Connected as SYSDBA.
New primary database "orclstby" is opening...
Operation requires start up of instance "ORCL" on database "orcl"
Starting instance "ORCL"...
Connected to an idle instance.
ORACLE instance started.
Connected to "ORCL"
Database mounted.
Database opened.
Connected to "ORCL"
Switchover succeeded, new primary is "orclstby"
DGMGRL> show configuration

Configuration - adgconfig

  Protection Mode: MaxPerformance
  Members:
  orclstby - Primary database
    orcl     - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 65 seconds ago)

DGMGRL> exit
```

3. Check from the primary side. You can see the previous primary side becomes the new standby side.

```
[oracle@primary ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 10:16:54 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> show pdbs

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  READ ONLY  NO
	 3 ORCLPDB			  READ ONLY  NO
SQL> select open_mode,database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
READ ONLY WITH APPLY PHYSICAL STANDBY

SQL> 
```

4. Check from the standby side. You can see it's becomes the new primary side.

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Feb 1 10:20:06 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> show pdbs

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  READ ONLY  NO
	 3 ORCLPDB			  READ WRITE NO
SQL> select open_mode,database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
READ WRITE	     PRIMARY

SQL> 
```

