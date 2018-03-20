--http://technet.microsoft.com/en-us/library/ms191140.aspx#ConfiguringOutboundConnections

--Change to high-performance mode on Principal by turning off transacton safety
USE [master];
ALTER DATABASE [Nimble] SET PARTNER SAFETY OFF;
GO
--ALTER DATABASE [Nimble] SET PARTNER SAFETY ON;
