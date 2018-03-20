--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections
--To configure Mirror for inbound connections

--Create a login on Mirror for Principal
USE [master];
CREATE LOGIN [PrincipalLogin] WITH PASSWORD = 'P@ssw0rd';
GO
--DROP LOGIN [PrincipalLogin];

--Create a user for [PrincipalLogin]
USE [master];
CREATE USER [PrincipalUser] FOR LOGIN [PrincipalLogin];
GO
--DROP USER [PrincipalUser];

--Associate [PrincipalCertificate] with [PrincipalUser]
USE [master];
CREATE CERTIFICATE [PrincipalCertificate]
AUTHORIZATION [PrincipalUser]
FROM FILE = 'G:\Backup\PrincipalCertificate.cer';
GO
--DROP CERTIFICATE [PrincipalCertificate];

--Grant CONNECT permission on [PrincipalLogin] for [MirrorEndpoint]
USE [master];
GRANT CONNECT ON ENDPOINT::[MirrorEndpoint] TO [PrincipalLogin];
GO