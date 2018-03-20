--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections
--To configure Principal for outbound connections

--On the master database, create the database master key, if needed
USE [master];
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';
GO
--DROP MASTER KEY;

--Create a certificate on the Principal server instance
USE [master];
CREATE CERTIFICATE [PrincipalCertificate] WITH SUBJECT = 'Principal Certificate';
GO
--DROP CERTIFICATE [PrincipalCertificate];

--Create a mirroring endpoint for server instance on Principal using [PrincipalCertificate]
USE [master];
CREATE ENDPOINT [PrincipalEndpoint]
STATE = STARTED
AS TCP 
(
	 LISTENER_PORT	= 57024
	,LISTENER_IP	= ALL
) 
FOR DATABASE_MIRRORING 
( 
	 AUTHENTICATION	= CERTIFICATE [PrincipalCertificate]
	,ENCRYPTION		= REQUIRED ALGORITHM AES
	,ROLE			= ALL
);
GO
--DROP ENDPOINT [PrincipalEndpoint];

--Back up Principal certificate and copy it to Mirror
USE [master];
BACKUP CERTIFICATE [PrincipalCertificate] TO FILE = 'I:\Apps\Database\PrincipalCertificate.cer';
GO
