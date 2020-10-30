# Prepare the Primary Database

## Introduction
In this lab, You will check and modify the status of the primary site database, make it ready to ADG.

Estimated Lab Time: 30 minutes.

### Objectives
- Enable achivelog and flashback for the primary database.
- Change redo log size and create standby log.
- Modify the init parameters for best practice.

### Prerequisites
This lab assumes you have completed the following labs:

- Environment Setup for Primary and Standby

Now you have 2 VM hosts:

- `primary`: The primary database host, DB unique name **ORCL**, SID is **ORCL**
- `standby`: The standby database host, DB unique name **ORCLSTBY**, SID is **ORCL**



## **Step 1:** Enable achivelog and flashback

1. Connect to the primary VM hosts with opc user. Use putty tool (Windows) or command line (Mac, Linux).

   ```
   ssh -i labkey opc@xxx.xxx.xxx.xxx
   ```

2. Swtich to **oracle** user, and connect to the database with sysdba

   ```
   sudo su - oracle
   sqlplus / as sysdba
   ```

   

3. Check the achivelog mode, you can find it's disable now.

```
SQL> archive log list
Database log mode	       No Archive Mode
Automatic archival	       Disabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     10
Current log sequence	       12
SQL> 
```

2. Enable the archive mode and flashback on.

```
SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.

SQL> startup mount
ORACLE instance started.

Total System Global Area 6845104048 bytes
Fixed Size		    9150384 bytes
Variable Size		 1275068416 bytes
Database Buffers	 5553258496 bytes
Redo Buffers		    7626752 bytes
Database mounted.

SQL> alter database archivelog;

Database altered.

SQL> !mkdir -p /u01/app/oracle/fra/ORCL
SQL> ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 10G SCOPE=BOTH SID='*';
SQL> ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = '/u01/app/oracle/fra/ORCL' SCOPE=BOTH SID='*';

SQL> alter database flashback on;

Database altered.

SQL> alter database open;

Database altered.

SQL> 
```

3. Check the status again, it's enable now.

```
SQL> archive log list
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     10
Next log sequence to archive   12
Current log sequence	       12
SQL> 
```

4. Enable force logging.

```
SQL> alter database force logging;

Database altered.

SQL>
```

## **Step 2:** Change redo log size and create standby log

1. Change the redo log size to 1024M according to the best practice. Check the status of the redo log first.

```
SQL> select group#, bytes, status from v$log;

    GROUP#	BYTES STATUS
---------- ---------- ----------------
	 1  209715200 INACTIVE
	 2  209715200 INACTIVE
	 3  209715200 CURRENT
```

2. Add 3 new redo log group.

```
<copy>
alter database add logfile group 4 '/u01/app/oracle/oradata/ORCL/redo04.log' size 1024M; 
alter database add logfile group 5 '/u01/app/oracle/oradata/ORCL/redo05.log' size 1024M; 
alter database add logfile group 6 '/u01/app/oracle/oradata/ORCL/redo06.log' size 1024M;
</copy>
```

3. Switch the logfile serveral times.

```
<copy>
alter system switch logfile;
alter system checkpoint;
</copy>
```

4. Check the status again.

```
SQL> select group#, bytes, status from v$log;

    GROUP#	BYTES STATUS
---------- ---------- ----------------
	 1  209715200 INACTIVE
	 2  209715200 INACTIVE
	 3  209715200 INACTIVE
	 4 1073741824 CURRENT
	 5 1073741824 UNUSED
	 6 1073741824 UNUSED

6 rows selected.

SQL> 
```

5. When the first 3 groups status is INACTIVE, you can drop these group now.

```
SQL> alter database drop logfile group 1; 

Database altered.

SQL> alter database drop logfile group 2; 

Database altered.

SQL> alter database drop logfile group 3; 

Database altered.

SQL> 
```

6. Create 4 standby log group.

```
SQL> alter database add standby logfile thread 1 '/u01/app/oracle/oradata/ORCL/srl_redo01.log' size 1024M;

Database altered.

SQL> alter database add standby logfile thread 1 '/u01/app/oracle/oradata/ORCL/srl_redo02.log' size 1024M;

Database altered.

SQL> alter database add standby logfile thread 1 '/u01/app/oracle/oradata/ORCL/srl_redo03.log' size 1024M;

Database altered.

SQL> alter database add standby logfile thread 1 '/u01/app/oracle/oradata/ORCL/srl_redo04.log' size 1024M;

Database altered.

SQL> select group#,thread#,bytes from v$standby_log;

    GROUP#    THREAD#	   BYTES
---------- ---------- ----------
	 1	    1 1073741824
	 2	    1 1073741824
	 3	    1 1073741824
	 7	    1 1073741824

SQL> 
```



## **Step 3:** Modify the init parameters for best practice

Modify some init parameters for best practice.

```
SQL> alter system set STANDBY_FILE_MANAGEMENT=AUTO scope=both;

System altered.

SQL> alter system set DB_LOST_WRITE_PROTECT=TYPICAL scope=both;

System altered.

SQL> alter system set FAST_START_MTTR_TARGET=300 scope=both;

System altered.

SQL> exit;
```

You may proceed to the next lab.

## Acknowledgements
* **Author** - Minqiao Wang, DB Product Management, Oct 2020
* **Contributors** -  
* **Last Updated By/Date** - Minqiao Wang, DB Product Management, Oct 2020

## See an issue?
Please submit feedback using this [form](https://apexapps.oracle.com/pls/apex/f?p=133:1:::::P1_FEEDBACK:1). Please include the *workshop name*, *lab* and *step* in your request.  If you don't see the workshop name listed, please enter it manually. If you would like us to follow up with you, enter your email in the *Feedback Comments* section.