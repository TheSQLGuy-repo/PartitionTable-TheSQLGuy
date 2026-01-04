SELECT DISTINCT
    p.partition_number AS [Partition], 
	s.name,
	o.name,
    fg.name AS [Filegroup], 
    p.Rows,
	p.index_id
FROM sys.partitions p
    INNER JOIN sys.allocation_units au ON au.container_id = p.hobt_id
    INNER JOIN sys.filegroups fg ON fg.data_space_id = au.data_space_id
	INNER JOIN sys.objects o ON o.object_id = p.object_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type = 'U'
AND p.index_id =1
AND fg.name <> 'PRIMARY'
AND p.rows > 0
ORDER BY 
	o.name,
	fg.name,
	s.name


##########################################################

USE [AdventureWorks2019]
GO

CREATE SCHEMA [staging]
GO


CREATE TABLE [staging].[SalesOrderDetail](
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] IDENTITY(1,1) NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal]  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Index [AK_SalesOrderDetail_rowguid] ******/
CREATE UNIQUE NONCLUSTERED INDEX [AK_SalesOrderDetail_rowguid] ON [staging].[SalesOrderDetail]
(
	[rowguid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_SalesOrderDetail_ProductID] ******/
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] ON [staging].[SalesOrderDetail]
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [staging].[SalesOrderDetail] ADD  CONSTRAINT [DF_SalesOrderDetail_UnitPriceDiscount]  DEFAULT ((0.0)) FOR [UnitPriceDiscount]
GO

ALTER TABLE [staging].[SalesOrderDetail] ADD  CONSTRAINT [DF_SalesOrderDetail_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO

ALTER TABLE [staging].[SalesOrderDetail] ADD  CONSTRAINT [DF_SalesOrderDetail_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO


###########################################################

ALTER DATABASE AdventureWorks2019 ADD FILEGROUP [2011]
GO
ALTER DATABASE AdventureWorks2019 ADD FILEGROUP [2012]
GO
ALTER DATABASE AdventureWorks2019 ADD FILEGROUP [2013]
GO
ALTER DATABASE AdventureWorks2019 ADD FILEGROUP [2014]
GO

ALTER DATABASE AdventureWorks2019 ADD FILE
(
	NAME = 'SalesOrderDetail_2011',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019_SalesOrderDetail_2011.ndf',
	SIZE = 3072KB , 
	FILEGROWTH = 65536KB 
) TO FILEGROUP [2011]
GO

ALTER DATABASE AdventureWorks2019 ADD FILE
(
	NAME = 'SalesOrderDetail_2012',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019_SalesOrderDetail_2012.ndf',
	SIZE = 3072KB , 
	FILEGROWTH = 65536KB 
) TO FILEGROUP [2012]
GO

ALTER DATABASE AdventureWorks2019 ADD FILE
(
	NAME = 'SalesOrderDetail_2013',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019_SalesOrderDetail_2013.ndf',
	SIZE = 3072KB , 
	FILEGROWTH = 65536KB 
) TO FILEGROUP [2013]
GO

ALTER DATABASE AdventureWorks2019 ADD FILE
(
	NAME = 'SalesOrderDetail_2014',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2019_SalesOrderDetail_2014.ndf',
	SIZE = 3072KB , 
	FILEGROWTH = 65536KB 
) TO FILEGROUP [2014]
GO

IF NOT EXISTS (SELECT name FROM sys.partition_functions WHERE name = 'pfn_AdventureWorks2019_ModifiedDate')
BEGIN
CREATE PARTITION FUNCTION [pfn_AdventureWorks2019_ModifiedDate](DATETIME) 
AS RANGE LEFT FOR VALUES 
(	
	N'2011-12-31 23:59:59', 
	N'2012-12-31 23:59:59', 
	N'2013-12-31 23:59:59', 
	N'2014-12-31 23:59:59'
)
END
GO

IF NOT EXISTS (SELECT name FROM sys.partition_schemes WHERE name = 'ps_AdventureWorks2019_ModifiedDate')
BEGIN
CREATE PARTITION SCHEME [ps_AdventureWorks2019_ModifiedDate] AS PARTITION [pfn_AdventureWorks2019_ModifiedDate] 
TO 
(
	[2011],
	[2012],
	[2013],
	[2014],
	[PRIMARY]
)
END

/****** Object:  Index [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] ******/
ALTER TABLE [staging].[SalesOrderDetail] DROP CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID]
GO

/****** Object:  Index [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] ******/
ALTER TABLE [staging].[SalesOrderDetail] ADD  CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY NONCLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC,
	ModifiedDate
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ps_AdventureWorks2019_ModifiedDate](ModifiedDate)
GO



ALTER TABLE [Sales].[SalesOrderDetail]
SWITCH PARTITION 2 TO [staging].[SalesOrderDetail] PARTITION 2


TRUNCATE TABLE [staging].[SalesOrderDetail] WITH (PARTITIONS (1))





