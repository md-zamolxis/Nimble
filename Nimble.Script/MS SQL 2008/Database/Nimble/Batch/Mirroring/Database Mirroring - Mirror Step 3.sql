--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections

--At Mirror, set server instance on Principal as partner
USE [master];
ALTER DATABASE [Nimble] SET PARTNER = 'TCP://provectapos.cloudapp.net:57024';
GO
--ALTER DATABASE [Nimble] SET PARTNER OFF;
