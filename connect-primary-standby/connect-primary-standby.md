# Set connectivity between on-premise host and cloud host

## Introduction
In a Data Guard configuration, information is transmitted in both directions between the primary and standby databases. This requires basic configuration, network tuning and opening of ports at both primary and standby databases site. 

Estimated Lab Time: 30 minutes.

### Objectives
- Open the 1521 port for both hosts.
- Enable ssh connect for the oracle user.
- Configure the Name Resolution.
- Set TCP socket size for performance.
- Prompt-less SSH configure.

### Prerequisites

This lab assumes you have already completed the following labs:

- Setup environment for primary and standby
- Prepare the Primary Database

In this Lab, you can use 2 terminal windows, one connected to the primary host, the other connected to the standby host. 

## **Step 1:** Open the 1521 port for both database hosts

1. Connect to the both hosts with **opc** user. Use putty tool (Windows) or command line (Mac, Linux).

   ```
   ssh -i labkey opc@xxx.xxx.xxx.xxx
   ```

2. Copy and run the following command to open the 1521 port on both side.

   ```
   <copy>
   sudo firewall-cmd --zone=public --add-port=1521/tcp --permanent
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-all
   </copy>
   ```

   

## **Step 2:** Enable ssh connect for the oracle user

1. Work as opc user, edit the ssh configure file on both side

```
<copy>sudo vi /etc/ssh/sshd_config</copy>
```

2. Add the following lines in the end of the file.

```
<copy>
AllowUsers oracle
AllowUsers opc
</copy>
```

3. Restart the ssh service.

```
<copy>sudo systemctl restart sshd.service</copy>
```


## **Step 3:** Name Resolution Configure

1. Connect as the opc user. Edit `/etc/hosts` on both sides.

   ```
   <copy>sudo vi /etc/hosts</copy>
   ```

   - From the primary side, add the standby host public ip and host name in the file like the following:

      ```
      xxx.xxx.xxx.xxx  standby.subnet1.standbyvcn.oraclevcn.com standby
      ```

      

   - From the standby side, add the primary host public ip and host name in the file like the following:

      ```
      xxx.xxx.xxx.xxx primary.subnet1.primaryvcn.oraclevcn.com primary
      ```

      

2. Validate the connectivity, install telnet on both sides.

   ```
   <copy>sudo yum -y install telnet</copy>
   ```

   - From the primary side, telnet the public ip or hostname of the standby host with port 1521, enter `^]` and return to exit.

      ```
      $ telnet standby 1521
      Trying 158.101.136.61...
      Connected to 158.101.136.61.
      Escape character is '^]'.
      ^]
           
      telnet> q
      Connection closed.
      $ 
      ```

      

   - From the standby side, telnet the public ip or hostname of the primary host with port 1521, enter `^]` and return to exit.

      ```
      $ telnet primary 1521
      Trying 140.238.18.190...
      Connected to 140.238.18.190.
      Escape character is '^]'.
      ^]
           
      telnet> q
      Connection closed.
      $
      ```

      



## **Step 4:** Set TCP socket size

According to the best practice, set TCP socket size, adjust all socket size maximums to 128MB or 134217728. This is needed to setup in both primary and standby side.  

1. From both side, connect as **opc** user, edit the config file.

```
<copy>sudo vi /etc/sysctl.conf</copy>
```

2. Search and modify following entry to the values, save and exit.

```
<copy>
net.core.rmem_max = 134217728 
net.core.wmem_max = 134217728
</copy>
```

3. Reload and check the values.

```
$ sudo /sbin/sysctl -p
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500

$ sudo /sbin/sysctl -a | egrep net.core.[w,r]mem_max
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
sysctl: reading key "net.ipv6.conf.all.stable_secret"
sysctl: reading key "net.ipv6.conf.default.stable_secret"
sysctl: reading key "net.ipv6.conf.ens3.stable_secret"
sysctl: reading key "net.ipv6.conf.lo.stable_secret"
$ 
```


## **Step 5:** Prompt-less SSH configure

Now you will configure the prompt-less ssh for oracle users between the primary and the standby.

1. su to **oracle** user in both side.

```
<copy>sudo su - oracle</copy>
```

2. Configure prompt-less ssh from the primary to the standby.

     - From the primary side, generate the ssh key, and cat the public key, copy all the content in the id_rsa.pub

     ```
     [oracle@primary ~]$ ssh-keygen -t rsa
     Generating public/private rsa key pair.
     Enter file in which to save the key (/home/oracle/.ssh/id_rsa): 
     Enter passphrase (empty for no passphrase): 
     Enter same passphrase again: 
     Your identification has been saved in /home/oracle/.ssh/id_rsa.
     Your public key has been saved in /home/oracle/.ssh/id_rsa.pub.
     The key fingerprint is:
     SHA256:2S+UtAXQdwgNLRA7hjLP4RsMfDM0pW3p75hus8UQaG8 oracle@adgstudent1
     The key's randomart image is:
     +---[RSA 2048]----+
     |      o.==+= .   |
     |   . . * oo.= .  |
     |    = X O .o..   |
     |     @ O * +     |
     |      * E =      |
     |       + = .     |
     |      .   = .    |
     |        o= .     |
     |       o=o.      |
     +----[SHA256]-----+
     [oracle@primary ~]$ cat .ssh/id_rsa.pub
     ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCLV6NiFihUY4ItgfPLJR1EcjC7DjuVOL86G3VperrA8hEKP2uLSh7AEeKm4MZmPPIzO/HlMw3KkhhUZNX/C+b29tQ2l8+fbCzzMGmZSAGmT2vEmot/9lVT714l/rcfWNXv8qcj6x4wHUqygH87XSDcCRaQt7vUcFNITOb/4yGRc9LcSQdlV1Yf1eOfUnkpB1fOoEXFfkAxgd1UeuFS0pIiejutqbPSeppu9X2RrbAmZymAVa7MiNNG2mZHf9tWJrigXsTwmgOgPlsAIcbutoVRGPcP1xc43ut9oUWk8reBEyDj8X2bgeafG+KeXD6YRh53lqIbTNYz+k1sfHwyuUl oracle@workshop  
     ```

     - From the standby side, edit the `authorized_keys` file, copy all the content in the id_rsa.pub into it, save and close

     ```
     <copy>
     mkdir .ssh
     vi .ssh/authorized_keys
     </copy>
     ```

     - Change mode of the file.

       ```
       <copy>chmod 600 .ssh/authorized_keys</copy>
       ```

       

     - From primary side, test the connection from the primary to the standby, using the public ip or hostname of the standby hosts.

     ```
     [oracle@primary ~]$ ssh oracle@standby echo Test success
     The authenticity of host '158.101.136.61 (158.101.136.61)' can't be established.
     ECDSA key fingerprint is SHA256:c3ghvWrZxvOnJc6aKWIPbFC80h65cZCxvQxBVdaRLx4.
     ECDSA key fingerprint is MD5:a8:34:53:0f:3e:56:64:56:72:a1:cb:47:18:44:ac:4c.
     Are you sure you want to continue connecting (yes/no)? yes
     Warning: Permanently added '158.101.136.61' (ECDSA) to the list of known hosts.
     Test success
     [oracle@primary ~]$ 
     ```

3. Configure prompt-less ssh from the standby to primary.

     - From the standby side, generate the ssh key, and cat the public key, copy all the content in the id_rsa.pub.

     ```
     [oracle@standby ~]$ ssh-keygen -t rsa
     Generating public/private rsa key pair.
     Enter file in which to save the key (/home/oracle/.ssh/id_rsa): 
     Enter passphrase (empty for no passphrase): 
     Enter same passphrase again: 
     Your identification has been saved in /home/oracle/.ssh/id_rsa.
     Your public key has been saved in /home/oracle/.ssh/id_rsa.pub.
     The key fingerprint is:
     SHA256:60bMHAglf6pIHKjDnQAm+35L79itld48VVg1+HCQxIM oracle@dbstby
     The key's randomart image is:
     +---[RSA 2048]----+
     |o.  ...     +o+o.|
     |+o  .o     E *...|
     |o..  ....    o=  |
     |ooo.. .o.   . .. |
     |o.+o  .+S.   .   |
     | + . .  =o  .    |
     |  o +  .+  .     |
     |   o = =.o.      |
     |    o.=o+ o.     |
     +----[SHA256]-----+
     [oracle@standby ~]$ cat .ssh/id_rsa.pub
     ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC61WzEm1bYRkPnFf96Loq/eRGJKiSkeh9EFg3NzMBUmRq4rSWMsMkIkrLmrJUNF8I5tFMnSV+AQZo5vrtU23NVvxsQHF7rKYiMm9ARkACQmr1th8kefc/sJMn/3hQDm27FB5RLeZzbxyZoJAq7ZtLMfudlogaYxqLZLBnuHT8Oky/5FOa1EUVOaqiKm8f7pPlqnxpf1QdO8lswMvInWh3Zq9newfTmu/qt56shNd462uOyNjjCgRtmxsYXIxFhJecvDnkGJ+Tekq27nozBI+c3GyQS8tsyPnjt3DRg35sXJFWOeEswmxqxAjP0KWDFlSZ3aNm4ESS3ZPaTfSlgx0E1 oracle@dbstby
     [oracle@standby ~]$ 
     ```

     - From the primary side, edit the `authorized_keys` file, copy all the content in the `id_rsa.pub` into it, save and close

     ```
     <copy>vi .ssh/authorized_keys</copy>
     ```

     - Change mode of the file.

     ```
     <copy>chmod 600 .ssh/authorized_keys</copy>
     ```

     - From the standby side, test the connection from standby to primary, using the public ip or hostname of the primary hosts.

     ```
     [oracle@standby ~]$ ssh oracle@primary echo Test success
     The authenticity of host '140.238.18.190 (140.238.18.190)' can't be established.
     ECDSA key fingerprint is SHA256:1GMD9btUlIjLABsTsS387MUGD4LrZ4rxDQ8eyASBc8c.
     ECDSA key fingerprint is MD5:ff:8b:59:ac:05:dd:27:07:e1:3f:bc:c6:fa:4e:5d:5c.
     Are you sure you want to continue connecting (yes/no)? yes
     Warning: Permanently added '140.238.18.190' (ECDSA) to the list of known hosts.
     Test success
     [oracle@standby ~]$ 
     ```

You may proceed to the next lab.

## Acknowledgements
* **Author** - Minqiao Wang, DB Product Management, Oct 2020
* **Contributors** -  
* **Last Updated By/Date** - Minqiao Wang, DB Product Management, Nov 2020

## See an issue?
Please submit feedback using this [form](https://apexapps.oracle.com/pls/apex/f?p=133:1:::::P1_FEEDBACK:1). Please include the *workshop name*, *lab* and *step* in your request.  If you don't see the workshop name listed, please enter it manually. If you would like us to follow up with you, enter your email in the *Feedback Comments* section.
