--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections
--To configure Mirror for outbound connections

--On the master database, create the database master key, if needed
USE [master];
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';
GO
--DROP MASTER KEY;

--Create a certificate on the Mirror server instance
USE [master];
CREATE CERTIFICATE [MirrorCertificate] WITH SUBJECT = 'Mirror Certificate';
GO
--DROP CERTIFICATE [MirrorCertificate];

--Create a mirroring endpoint for the server instance on Mirror using [MirrorEndpoint]
USE [master];
CREATE ENDPOINT [MirrorEndpoint]
STATE = STARTED
AS TCP 
(
	 LISTENER_PORT	= 57024
	,LISTENER_IP	= ALL
) 
FOR DATABASE_MIRRORING 
( 
	 AUTHENTICATION	= CERTIFICATE [MirrorCertificate]
	,ENCRYPTION		= REQUIRED ALGORITHM AES
	,ROLE			= ALL
);
GO
--DROP ENDPOINT [MirrorEndpoint];

--Back up Mirror certificate and copy it to Principal
USE [master];
BACKUP CERTIFICATE [MirrorCertificate] TO FILE = 'G:\Backup\MirrorCertificate.cer';
GO 
