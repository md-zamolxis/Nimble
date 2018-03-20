--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections
--To configure Principal for inbound connections

--Create a login on Principal for Mirror
USE [master];
CREATE LOGIN [MirrorLogin] WITH PASSWORD = 'P@ssw0rd';
GO
--DROP LOGIN [MirrorLogin];

--Create a user for [MirrorLogin]
USE [master];
CREATE USER [MirrorUser] FOR LOGIN [MirrorLogin];
GO
--DROP USER [MirrorUser];

--Associate [MirrorCertificate] with [MirrorUser]
USE [master];
CREATE CERTIFICATE [MirrorCertificate]
AUTHORIZATION [MirrorUser]
FROM FILE = 'I:\Apps\Database\MirrorCertificate.cer';
GO
--DROP CERTIFICATE [MirrorCertificate];

--Grant CONNECT permission on [MirrorLogin] for [PrincipalEndpoint]
USE [master];
GRANT CONNECT ON ENDPOINT::[PrincipalEndpoint] TO [MirrorLogin];
GO
