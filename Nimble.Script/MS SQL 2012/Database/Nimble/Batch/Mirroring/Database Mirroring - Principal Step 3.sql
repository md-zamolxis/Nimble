--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections

--At Principal, set server instance on Mirror as partner
USE [master];
ALTER DATABASE [Nimble] SET PARTNER = 'TCP://zamolxis.cloudapp.net:57024';
GO
--ALTER DATABASE [Nimble] SET PARTNER OFF;
