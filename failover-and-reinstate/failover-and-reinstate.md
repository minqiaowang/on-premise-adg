# Failover and Reinstate

A failover is an unplanned event that assumes the primary database is lost. The standby database is converted to a primary database immediately. A failover might result in some data loss when you use **Maximum Performance** protection mode. After a failover the old primary database must be reinstated as a physical standby which is made simpler with flashback database and Data Guard broker enabled. To execute a failover and reinstatement execute the following commands in Data Guard Broker. 

## Lab Prerequisites

This lab assumes you have already completed the following labs:

- Deploy Active Data Guard
- Test with Active Data Guard

## Step 1: Setup the current primary database flashback on

In the previous lab, you have done the Data Guard switch over. Now, the current primary database is the **ORCLSTBY** and the current standby database is the **ORCL**.

1. From the current primary side. Check the flashback status of the current primary database

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Wed Feb 5 05:31:25 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> select open_mode,database_role,flashback_on from v$database;

OPEN_MODE	     DATABASE_ROLE    FLASHBACK_ON
-------------------- ---------------- ------------------
READ WRITE	     PRIMARY	      NO

SQL> 
```

2. If the flashback is not enabled you need to setup database flashback on, otherwise you won't be able to reinstate the primary after the failover.

```
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> startup mount;
ORACLE instance started.

Total System Global Area 1.6106E+10 bytes
Fixed Size		    9154008 bytes
Variable Size		 2080374784 bytes
Database Buffers	 1.3992E+10 bytes
Redo Buffers		   24399872 bytes
Database mounted.
SQL> alter database flashback on;

Database altered.

SQL> alter database open;

Database altered.

SQL> alter pluggable database all open;

Pluggable database altered.

SQL> select open_mode,database_role,flashback_on from v$database;

OPEN_MODE	     DATABASE_ROLE    FLASHBACK_ON
-------------------- ---------------- ------------------
READ WRITE	     PRIMARY	      YES

SQL> exit
Disconnected from Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0
[oracle@dbstby ~]$ 
```

## Step 2: Failover

1. Connect with DGMGRL, validate the primary and standby database

```
[oracle@standby ~]$ dgmgrl sys/Ora_DB4U@orcl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Wed Feb 5 05:41:24 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "ORCL"
Connected as SYSDBA.
DGMGRL> show configuration

Configuration - adgconfig

  Protection Mode: MaxPerformance
  Members:
  orclstby - Primary database
    orcl     - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 56 seconds ago)

DGMGRL> validate database orclstby

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Flashback Database Status:
    orclstby:  Off

  Managed by Clusterware:
    orclstby:  NO             
    Validating static connect identifier for the primary database orclstby...
    The static connect identifier allows for a connection to database "orclstby".

DGMGRL> validate database orcl

  Database Role:     Physical standby database
  Primary Database:  orclstby

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Flashback Database Status:
    orclstby:  Off
    orcl    :  On

  Managed by Clusterware:
    orclstby:  NO             
    orcl    :  NO             
    Validating static connect identifier for the primary database orclstby...
    The static connect identifier allows for a connection to database "orclstby".

  Log Files Cleared:
    orclstby Standby Redo Log Files:  Cleared
    orcl Online Redo Log Files:       Not Cleared
    orcl Standby Redo Log Files:      Available

  Current Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (orclstby)              (orcl)                               
    1         3                       1                       Insufficient SRLs

  Future Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (orcl)                  (orclstby)                           
    1         3                       2                       Insufficient SRLs

DGMGRL> 
```

2. Failover to current standby.

```
DGMGRL> failover to orcl
Performing failover NOW, please wait...
Failover succeeded, new primary is "orcl"
DGMGRL> show configuration

Configuration - adgconfig

  Protection Mode: MaxPerformance
  Members:
  orcl     - Primary database
    orclstby - Physical standby database (disabled)
      ORA-16661: the standby database needs to be reinstated

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 114 seconds ago)

DGMGRL> 
```

Now, the primary is the back to the **ORCL** database, and the standby database is disabled, which needs to be reinstated.

## Step 3: Reinstate the previous primary database

1. In the previous primary side, connect to sqlplus as sysdba, shutdown the database and startup mount before reinstating. 

```
[oracle@standby ~]$ sqlplus / as sysdba  

SQL*Plus: Release 19.0.0.0.0 - Production on Wed Feb 5 05:48:11 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.
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
[oracle@standby ~]$  
```

2. Reinstate the database.

```
[oracle@standby ~]$ dgmgrl sys/Ora_DB4U@orcl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Jun 23 06:06:36 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
Connected to "ORCL"
Connected as SYSDBA.
DGMGRL> reinstate database orclstby
Reinstating database "orclstby", please wait...
Reinstatement of database "orclstby" succeeded
DGMGRL> show configuration

Configuration - adgconfig

  Protection Mode: MaxPerformance
  Members:
  orcl        - Primary database
    orclstby - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 21 seconds ago)

DGMGRL> 
```

3. Check the status of the new standby database

```
[oracle@standby ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Wed Feb 5 05:53:48 2020
Version 19.7.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c EE Extreme Perf Release 19.0.0.0.0 - Production
Version 19.7.0.0.0

SQL> select open_mode,database_role from v$database;

OPEN_MODE	     DATABASE_ROLE
-------------------- ----------------
READ ONLY WITH APPLY PHYSICAL STANDBY

SQL> 
```

