# Introduction

Oracle’s Maximum Availability Architecture (Oracle MAA) is the best practices blueprint for data protection and availability for Oracle databases deployed on private, public or hybrid clouds. Data Guard and Active Data Guard provide disaster recovery (DR) for databases with recovery time objectives (RTO) that cannot be met by restoring from backup. Customers use these solutions to deploy one or more synchronized replicas (standby databases) of a production database (the primary database) in physically separate locations to provide high availability, comprehensive data protection, and disaster recovery for mission-critical data. 

During this Lab, You will learn how to setup Active Data Guard. You will using a compute instance in OCI to simulate the primary database, which is deployed in one region (For example: Seoul). The standby database is deployed in another region (For example: Tokyo). The primary and the standby database communicate through public internet. 

In a Data Guard configuration, the primary and standby must be able to communicate bi-directionally. This requires additional network configuration to allow access to ports between the hosts. 


## Acknowledgements

- **Authors/Contributors** - Minqiao Wang, DB Product Management, June 2020
- **Last Updated By/Date** - 
- **Workshop Expiration Date** - 

See an issue?  Please open up a request [here](https://github.com/oracle/learning-library/issues).   Please include the workshop name and lab in your request. 