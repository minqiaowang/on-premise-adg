#cloud-config
runcmd:
   - mount /u01
   - /u01/ocidb/GenerateNetconfig.sh > /u01/ocidb/netconfig.ini
   - sudo /bin/chown -HRf oracle:oinstall /u01/app
   - sudo -u oracle /u01/app/oracle/product/19c/dbhome_1/oui/bin/runInstaller -silent -ignoreSysPrereqs -waitforcompletion -attachHome INVENTORY_LOCATION='/u01/app/oraInventory' ORACLE_HOME='/u01/app/oracle/product/19c/dbhome_1' ORACLE_HOME_NAME='OraDB19Home1' ORACLE_BASE='/u01/app/oracle'   -local
   - sudo -u oracle /u01/app/oraInventory/orainstRoot.sh