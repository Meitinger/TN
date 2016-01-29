/* Copyright (C) 2015, Manuel Meitinger
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

USE [Teilnehmer_innen]
GO
CREATE USER [Training] FOR LOGIN [AUFBAUWERK\000120]
GO
CREATE USER [Sekretariat] FOR LOGIN [AUFBAUWERK\000910]
GO
CREATE USER [Rechnungswesen] FOR LOGIN [AUFBAUWERK\000920]
GO
CREATE USER [Leitung] FOR LOGIN [AUFBAUWERK\000999]
GO
CREATE USER [Integrationsassistenz] FOR LOGIN [AUFBAUWERK\000110]
GO
CREATE USER [app] FOR LOGIN [AUFBAUWERK\ERP$] WITH DEFAULT_SCHEMA=[dbo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Einrichtung](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Standortnummer] [int] NOT NULL,
	[Leitung] [varbinary](85) NOT NULL,
	[Training] [varbinary](85) NOT NULL,
	[Integrationsassistenz] [varbinary](85) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Einrichtung] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Einrichtung_Name] ON [dbo].[Einrichtung] 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Einrichtung', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'200' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Einrichtung', @level2type=N'COLUMN',@level2name=N'Standortnummer'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstTelefonnummer](@Telefonnummer varchar(50)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Telefonnummer IS NULL THEN NULL
		WHEN
			LEN(@Telefonnummer) = 0 OR
			@Telefonnummer LIKE '%[^ +\-0-9]%' ESCAPE '\' OR -- only numbers, spaces, plus and minus
			@Telefonnummer NOT LIKE '+[0-9]%' OR -- start with country code
			@Telefonnummer NOT LIKE '% %' OR -- at least one separator (after cc)
			@Telefonnummer LIKE '+%+%' OR -- only one cc
			@Telefonnummer LIKE '%-%-%' OR -- only one extension
			@Telefonnummer LIKE '%[ \-]' ESCAPE '\' OR -- no trailing space or minus
			@Telefonnummer LIKE '%[ \-][ \-]%' ESCAPE '\' -- no consecutive spaces or minus followed/led by a space
		THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Feiertag](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Datum] [datetime] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Feiertag] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Feiertag_Datum] ON [dbo].[Feiertag] 
(
	[Datum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Feiertag', @level2type=N'COLUMN',@level2name=N'Name'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[BerichteFehler] AS
BEGIN
	SET NOCOUNT ON

	DECLARE @MESSAGE nvarchar(2048)
	DECLARE @SEVERITY int
	DECLARE @STATE int

	SELECT
		@MESSAGE = ERROR_MESSAGE(),
		@SEVERITY = ERROR_SEVERITY(),
		@STATE = ERROR_STATE()

	RAISERROR(@MESSAGE,@SEVERITY,@STATE)
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ErstelleFehler](@Fehler AS smallint, @Tabelle AS sysname = NULL, @Spalte AS sysname = NULL) RETURNS bigint AS
BEGIN
	RETURN CASE
		WHEN @Tabelle IS NULL THEN @Fehler
		WHEN @Spalte IS NULL THEN @Fehler + (SELECT 4294967296*object_id FROM sys.tables WHERE name = @Tabelle)
		ELSE @Fehler + (SELECT 4294967296*t.object_id + 65536*c.column_id FROM sys.tables AS t JOIN sys.columns AS c ON t.object_id = c.object_id WHERE t.name = @Tabelle AND c.name = @Spalte)
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstKlientennummer](@Klientennummer char(10)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Klientennummer IS NULL THEN NULL
		WHEN @Klientennummer LIKE 'SA[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' COLLATE Latin1_General_BIN THEN 1
		ELSE 0
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Einheit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Kürzel] [varchar](5) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Faktor] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Einheit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Einheit_Bezeichnung] ON [dbo].[Einheit] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'200' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Einheit', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rechnung](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Datum] [datetime] NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Rechnung] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstMehrzeiler](@Adresse nvarchar(200)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Adresse IS NULL THEN NULL
		WHEN
			LEN(@Adresse) = 0 OR
			@Adresse LIKE N'%[' + NCHAR(1)+NCHAR(2)+NCHAR(3)+NCHAR(4)+NCHAR(5)+NCHAR(6)+NCHAR(7)+NCHAR(8)+NCHAR(9)+NCHAR(11)+NCHAR(12)+NCHAR(13)+NCHAR(14)+NCHAR(15)+NCHAR(16)+NCHAR(17)+NCHAR(18)+NCHAR(19)+NCHAR(20)+NCHAR(21)+NCHAR(22)+NCHAR(23)+NCHAR(24)+NCHAR(25)+NCHAR(26)+NCHAR(27)+NCHAR(28)+NCHAR(29)+NCHAR(30)+NCHAR(31) + N']%' OR
			@Adresse LIKE N' %' OR
			@Adresse LIKE N'%  %' OR
			@Adresse LIKE N'% ' OR
			@Adresse LIKE NCHAR(10) + N'%' OR
			@Adresse LIKE N'%' + NCHAR(10) + N' %' OR
			@Adresse LIKE N'% ' + NCHAR(10) + N'%' OR
			@Adresse LIKE N'%' + NCHAR(10) + NCHAR(10) + N'%' OR
			@Adresse LIKE N'%' + NCHAR(10)
		THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstEinzeiler](@Bezeichnung nvarchar(50)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Bezeichnung IS NULL THEN NULL
		WHEN
			LEN(@Bezeichnung) = 0 OR
			@Bezeichnung LIKE N'%[' + NCHAR(1)+NCHAR(2)+NCHAR(3)+NCHAR(4)+NCHAR(5)+NCHAR(6)+NCHAR(7)+NCHAR(8)+NCHAR(9)+NCHAR(10)+NCHAR(11)+NCHAR(12)+NCHAR(13)+NCHAR(14)+NCHAR(15)+NCHAR(16)+NCHAR(17)+NCHAR(18)+NCHAR(19)+NCHAR(20)+NCHAR(21)+NCHAR(22)+NCHAR(23)+NCHAR(24)+NCHAR(25)+NCHAR(26)+NCHAR(27)+NCHAR(28)+NCHAR(29)+NCHAR(30)+NCHAR(31) + N']%' OR
			@Bezeichnung LIKE N' %' OR
			@Bezeichnung LIKE N'%  %' OR
			@Bezeichnung LIKE N'% '
		THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Standort_Bereich](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [char](1) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Standort_Bereich] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Standort_Bereich_Bezeichnung] ON [dbo].[Standort_Bereich] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Standort_Bereich_Code] ON [dbo].[Standort_Bereich] 
(
	[Code] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort_Bereich', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Kostensatz](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Kürzel] [varchar](5) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Platzhalter] [bit] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Kostensatz] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Kostensatz_Bezeichnung] ON [dbo].[Kostensatz] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Kostensatz', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[MonthDiff](@From datetime, @To datetime) RETURNS int AS
BEGIN
	DECLARE @Diff int
	SET @Diff = DATEDIFF(month,@From,@To)
	IF @From > @To
	BEGIN
		IF (DATEPART(day,@From) < DATEPART(day,@To))
		BEGIN
			SET @Diff = @Diff + 1
		END
	END
	ELSE
	BEGIN
		IF (DATEPART(day,@From) > DATEPART(day,@To))
		BEGIN
			SET @Diff = @Diff - 1
		END
	END
	RETURN @Diff
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Praktikum_Kategorie](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Praktikum_Kategorie] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Praktikum_Kategorie_Bezeichnung] ON [dbo].[Praktikum_Kategorie] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Praktikum_Kategorie', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Time](@dt datetime) RETURNS datetime AS
BEGIN
	RETURN DATEADD(day,-DATEDIFF(day,0,@dt),@dt)
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[YearDiff](@From datetime, @To datetime) RETURNS int AS
BEGIN
	DECLARE @Diff int
	SET @Diff = DATEDIFF(year,@From,@To)
	IF @From > @To
	BEGIN
		IF
		(
			DATEPART(month,@To) > DATEPART(month,@From) OR
			(
				DATEPART(month,@To) = DATEPART(month,@From) AND
				DATEPART(day,@To) > DATEPART(day,@From)
			)
		)
		BEGIN
			SET @Diff = @Diff + 1
		END
	END
	ELSE
	BEGIN
		IF
		(
			DATEPART(month,@From) > DATEPART(month,@To) OR
			(
				DATEPART(month,@From) = DATEPART(month,@To) AND
				DATEPART(day,@From) > DATEPART(day,@To)
			)
		)
		BEGIN
			SET @Diff = @Diff - 1
		END
	END
	RETURN @Diff
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstKürzel](@Kürzel varchar(5)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Kürzel IS NULL THEN NULL
		WHEN LEN(@Kürzel) = 0 OR @Kürzel LIKE '%[^A-Z0-9]%' COLLATE Latin1_General_BIN THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bescheid_Typ](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Abrechnung] [bit] NOT NULL,
	[Anschrift] [nvarchar](200) NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Bescheid_Typ] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Bescheid_Typ_Bezeichnung] ON [dbo].[Bescheid_Typ] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid_Typ', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid_Typ', @level2type=N'COLUMN',@level2name=N'Anschrift'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstGeschäftszahl](@Geschäftszahl varchar(50)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Geschäftszahl IS NULL THEN NULL
		WHEN @Geschäftszahl LIKE '???-%-%' OR @Geschäftszahl LIKE 'ABW-%-%' THEN
			CASE WHEN
				CHARINDEX('-',@Geschäftszahl,5) = LEN(@Geschäftszahl) OR
				SUBSTRING(@Geschäftszahl,CHARINDEX('-',@Geschäftszahl,5),(LEN(@Geschäftszahl)-(CHARINDEX('-',@Geschäftszahl,5)+1))) LIKE '%[^0-9]%' OR
				CHARINDEX('-',@Geschäftszahl,5) = 5 OR
				SUBSTRING(@Geschäftszahl,5,CHARINDEX('-',@Geschäftszahl,5)-5) LIKE '%[^A-Z]%'
			THEN 0
			ELSE 1
			END
		WHEN @Geschäftszahl LIKE '[0-9][0-9]-BH-[0-9][0-9][0-9][0-9]' THEN 1
		WHEN @Geschäftszahl LIKE '[0-9][0-9]-BH-[0-9][0-9][0-9][0-9]/%/%' THEN
			CASE WHEN
				CHARINDEX('/',@Geschäftszahl,12) = 12 OR
				CHARINDEX('/',@Geschäftszahl,12) = LEN(@Geschäftszahl) OR
				SUBSTRING(@Geschäftszahl,12,(CHARINDEX('/',@Geschäftszahl,12)-12)) LIKE '%[^0-9]%' OR
				SUBSTRING(@Geschäftszahl,CHARINDEX('/',@Geschäftszahl,12)+1,(LEN(@Geschäftszahl)-CHARINDEX('/',@Geschäftszahl,12))) LIKE '%[^0-9]%'
			THEN 0
			ELSE 1
			END
		WHEN @Geschäftszahl LIKE '[0-9][0-9][0-9][0-9][0-9]-BEH/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/%-[0-9][0-9][0-9][0-9]' THEN
			CASE WHEN
				LEN(@Geschäftszahl) = 25 OR
				SUBSTRING(@Geschäftszahl,21,(LEN(@Geschäftszahl)-25)) LIKE '%[^0-9/]%'
			THEN 0
			ELSE 1
			END
		WHEN
			LEN(@Geschäftszahl) = 0 OR
			@Geschäftszahl LIKE '%[^0-9/]%' OR
			@Geschäftszahl LIKE '/%' OR
			@Geschäftszahl LIKE '%//%' OR
			@Geschäftszahl LIKE '%/'
		THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Zeitspanne_Austrittsgrund](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Zeitspanne_Austrittsgrund] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Zeitspanne_Austrittsgrund_Bezeichnung] ON [dbo].[Zeitspanne_Austrittsgrund] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Zeitspanne_Austrittsgrund', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fehler](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[Meldung] [nvarchar](2048) NOT NULL,
 CONSTRAINT [PK_Fehler] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Version](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Zeile] [xml] NOT NULL,
	[Uhrzeit] [datetime] NOT NULL CONSTRAINT [DF_Version_Zeit]  DEFAULT (getdate()),
	[Benutzer] [varbinary](85) NOT NULL CONSTRAINT [DF_Version_Benutzer]  DEFAULT (suser_sid()),
 CONSTRAINT [PK_Version] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
CREATE PRIMARY XML INDEX [XML_IX_Version] ON [dbo].[Version] 
(
	[Zeile]
)WITH (PAD_INDEX  = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Teilnehmer](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Vorname] [nvarchar](50) NOT NULL,
	[Nachname] [nvarchar](50) NOT NULL,
	[Geburtstag] [datetime] NOT NULL,
	[Klientennummer] [char](10) NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Teilnehmer] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Teilnehmer_Klientennummer] ON [dbo].[Teilnehmer] 
(
	[Klientennummer] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Teilnehmer_Vorname_Nachname_Geburtstag] ON [dbo].[Teilnehmer] 
(
	[Vorname] ASC,
	[Nachname] ASC,
	[Geburtstag] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Teilnehmer', @level2type=N'COLUMN',@level2name=N'Vorname'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Teilnehmer', @level2type=N'COLUMN',@level2name=N'Nachname'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Teilnehmer', @level2type=N'COLUMN',@level2name=N'Klientennummer'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IstEmail](@Email varchar(200)) RETURNS bit AS
BEGIN
	RETURN CASE
		WHEN @Email IS NULL THEN NULL
		WHEN
			LEN(@Email) = 0 OR
			@Email NOT LIKE '%@%' OR
			@Email LIKE '%@%@%' OR
			@Email LIKE '@%' OR
			@Email LIKE '%@' OR
			@Email LIKE '%[^.@a-zA-Z0-9!#$\%&''*+\-/=?\^\_`{|}~]%' ESCAPE '\' COLLATE Latin1_General_BIN OR
			@Email LIKE '.%' OR
			@Email LIKE '%..%' OR
			@Email LIKE '%.' OR
			@Email LIKE '%.@%' OR
			@Email LIKE '%@.%'
		THEN 0
		ELSE 1
	END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Bescheid](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Geschäftszahl] [varchar](50) NOT NULL,
	[Einrichtung] [int] NOT NULL,
	[Teilnehmer] [int] NOT NULL,
	[Leistungsart] [int] NOT NULL,
	[Beginn] [datetime] NOT NULL,
	[Ende] [datetime] NOT NULL,
	[Maximum] [decimal](9, 2) NULL,
	[Ausstellungsdatum] [datetime] NOT NULL,
	[Typ] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Bescheid] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Bescheid_Einrichtung_Teilnehmer_Beginn_Ende] ON [dbo].[Bescheid] 
(
	[Einrichtung] ASC,
	[Teilnehmer] ASC,
	[Beginn] ASC,
	[Ende] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Bescheid_Geschäftszahl] ON [dbo].[Bescheid] 
(
	[Geschäftszahl] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Bescheid_Maximum] ON [dbo].[Bescheid] 
(
	[Maximum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Bescheid_Teilnehmer_Leistungsart_Beginn_Ende] ON [dbo].[Bescheid] 
(
	[Teilnehmer] ASC,
	[Leistungsart] ASC,
	[Beginn] ASC,
	[Ende] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'170' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Geschäftszahl'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Einrichtung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'250' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Teilnehmer'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'330' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Leistungsart'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Ausstellungsdatum'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Bescheid', @level2type=N'COLUMN',@level2name=N'Typ'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Planung](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Einrichtung] [int] NOT NULL,
	[Leistungsart] [int] NOT NULL,
	[Jahr] [int] NOT NULL,
	[Monat] [int] NOT NULL,
	[Schätzung] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Planung] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Planung_Einrichtung_Leistungsart_Jahr_Monat] ON [dbo].[Planung] 
(
	[Einrichtung] ASC,
	[Leistungsart] ASC,
	[Jahr] ASC,
	[Monat] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Planung', @level2type=N'COLUMN',@level2name=N'Einrichtung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'350' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Planung', @level2type=N'COLUMN',@level2name=N'Leistungsart'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Zeitspanne](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Einrichtung] [int] NOT NULL,
	[Teilnehmer] [int] NOT NULL,
	[Eintritt] [datetime] NOT NULL,
	[Überprüft] [datetime] NULL,
	[Austritt] [datetime] NULL,
	[Austrittsgrund] [int] NULL,
	[Austrittsnotiz] [nvarchar](200) NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Zeitspanne] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Zeitspanne_Austritt_Austrittsgrund_Austrittsnotiz] ON [dbo].[Zeitspanne] 
(
	[Austritt] ASC,
	[Austrittsgrund] ASC,
	[Austrittsnotiz] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Zeitspanne_Einrichtung_Teilnehmer_Eintritt_Austritt] ON [dbo].[Zeitspanne] 
(
	[Einrichtung] ASC,
	[Teilnehmer] ASC,
	[Eintritt] ASC,
	[Austritt] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Zeitspanne_Eintritt_Austritt_Überprüft] ON [dbo].[Zeitspanne] 
(
	[Eintritt] ASC,
	[Austritt] ASC,
	[Überprüft] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Zeitspanne', @level2type=N'COLUMN',@level2name=N'Einrichtung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'250' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Zeitspanne', @level2type=N'COLUMN',@level2name=N'Teilnehmer'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'220' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Zeitspanne', @level2type=N'COLUMN',@level2name=N'Austrittsgrund'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'330' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Zeitspanne', @level2type=N'COLUMN',@level2name=N'Austrittsnotiz'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Praktikum](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Einrichtung] [int] NOT NULL,
	[Teilnehmer] [int] NOT NULL,
	[Von] [datetime] NOT NULL,
	[Bis] [datetime] NOT NULL,
	[Standort] [int] NOT NULL,
	[Begleitung] [bit] NOT NULL,
	[Kategorie] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Praktikum] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Praktikum_Einrichtung_Teilnehmer_Von_Bis] ON [dbo].[Praktikum] 
(
	[Einrichtung] ASC,
	[Teilnehmer] ASC,
	[Von] ASC,
	[Bis] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Praktikum', @level2type=N'COLUMN',@level2name=N'Einrichtung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'250' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Praktikum', @level2type=N'COLUMN',@level2name=N'Teilnehmer'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Praktikum', @level2type=N'COLUMN',@level2name=N'Standort'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Praktikum', @level2type=N'COLUMN',@level2name=N'Kategorie'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Leistungsart](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Kürzel] [varchar](5) NOT NULL,
	[Bezeichnung] [nvarchar](50) NOT NULL,
	[Einheit] [int] NOT NULL,
	[Platzhalter] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Leistungsart] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Leistungsart_Bezeichnung] ON [dbo].[Leistungsart] 
(
	[Bezeichnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Leistungsart', @level2type=N'COLUMN',@level2name=N'Bezeichnung'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'200' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Leistungsart', @level2type=N'COLUMN',@level2name=N'Einheit'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Anwesenheit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Zeitspanne] [int] NOT NULL,
	[Datum] [datetime] NOT NULL,
	[Vormittags] [bit] NOT NULL,
	[Nachmittags] [bit] NOT NULL,
	[Nachts] [bit] NOT NULL,
	[Zusatz] [smalldatetime] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Anwesenheit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Anwesenheit_Vormittags_Nachmittags_Nachts_Zusatz] ON [dbo].[Anwesenheit] 
(
	[Vormittags] ASC,
	[Nachmittags] ASC,
	[Nachts] ASC,
	[Zusatz] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Anwesenheit_Zeitspanne_Datum] ON [dbo].[Anwesenheit] 
(
	[Zeitspanne] ASC,
	[Datum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Abrechnung](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Rechnung] [int] NOT NULL,
	[Bescheid] [int] NOT NULL,
	[Datum] [datetime] NOT NULL,
	[Preis] [money] NOT NULL,
	[Menge] [decimal](9, 2) NOT NULL,
	[Kostensatz] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Abrechnung] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Abrechnung_Bescheid_Datum] ON [dbo].[Abrechnung] 
(
	[Bescheid] ASC,
	[Datum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Abrechnung_Bescheid_Kostensatz] ON [dbo].[Abrechnung] 
(
	[Bescheid] ASC,
	[Kostensatz] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Abrechnung_Rechnung] ON [dbo].[Abrechnung] 
(
	[Rechnung] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Standort](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Adresse] [nvarchar](200) NOT NULL,
	[Telefon] [varchar](50) NULL,
	[Fax] [varchar](50) NULL,
	[Email] [varchar](200) NULL,
	[Bereich] [int] NOT NULL,
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Standort] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_Standort_Name_Adresse] ON [dbo].[Standort] 
(
	[Name] ASC,
	[Adresse] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Adresse'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Telefon'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'150' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Fax'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'250' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Email'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Standort', @level2type=N'COLUMN',@level2name=N'Bereich'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Verrechnungssatz](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Leistungsart] [int] NOT NULL,
	[Kostensatz] [int] NOT NULL,
	[Jahr] [int] NOT NULL,
	[Preis] [money] NOT NULL,
	[Vormittags] [bit] NOT NULL CONSTRAINT [DF_Verrechnungssatz_Vormittags]  DEFAULT ((0)),
	[Nachmittags] [bit] NOT NULL CONSTRAINT [DF_Verrechnungssatz_Nachmittags]  DEFAULT ((0)),
	[Nachts] [bit] NOT NULL CONSTRAINT [DF_Verrechnungssatz_Nachts]  DEFAULT ((0)),
	[Zusatz] [bit] NOT NULL CONSTRAINT [DF_Verrechnungssatz_Zusatz]  DEFAULT ((0)),
	[Praktikum] [bit] NOT NULL CONSTRAINT [DF_Verrechnungssatz_Praktikum]  DEFAULT ((0)),
	[Version] [timestamp] NOT NULL,
 CONSTRAINT [PK_Verrechnungssatz] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Verrechnungssatz_Leistungsart_Jahr_Vormittags_Nachmittags_Nachts_Zusatz_Praktikum] ON [dbo].[Verrechnungssatz] 
(
	[Leistungsart] ASC,
	[Jahr] ASC,
	[Vormittags] ASC,
	[Nachmittags] ASC,
	[Nachts] ASC,
	[Zusatz] ASC,
	[Praktikum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'400' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Verrechnungssatz', @level2type=N'COLUMN',@level2name=N'Leistungsart'
GO
EXEC sys.sp_addextendedproperty @name=N'width', @value=N'300' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Verrechnungssatz', @level2type=N'COLUMN',@level2name=N'Kostensatz'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ÜberprüfeRechnung] @Von datetime, @Bis datetime AS
BEGIN
	SET NOCOUNT ON;

	WITH AktiveZeitspannen AS
	(
		SELECT *
		FROM dbo.Zeitspanne
		WHERE
			Eintritt <= @Bis AND
			(Austritt IS NULL OR Austritt >= @Von)
	)
	SELECT
		E.Name AS Einrichtung,
		T.Nachname + N', ' + Vorname AS Teilnehmer,
		W.Datum,
		W.Warnung
	FROM
		(
			SELECT
				'Nicht ' + CASE WHEN Überprüft >= @Von THEN 'vollständig ' ELSE '' END + 'überprüfte Zeitspanne' AS Warnung,
				Einrichtung,
				Teilnehmer,
				CASE WHEN Überprüft >= @Von THEN DATEADD(dd, 1, Überprüft) ELSE CASE WHEN @Von < Eintritt THEN Eintritt ELSE @Von END END AS Datum
			FROM
				AktiveZeitspannen
			WHERE
				(Überprüft IS NULL OR Überprüft < CASE WHEN Austritt < @Bis THEN Austritt ELSE @Bis END)
		UNION
			SELECT
				'Fehlender Bescheid/Satz:' +
					CASE WHEN W.KeinGanztags = 1 THEN ' Vormittags+Nachmittags' ELSE '' END +
					CASE WHEN W.KeinVormittags = 1 THEN ' Vormittags' ELSE '' END +
					CASE WHEN W.KeinNachmittags = 1 THEN ' Nachmittags' ELSE '' END +
					CASE WHEN W.KeinNachts = 1 THEN ' Nachts' ELSE '' END +
					CASE WHEN W.KeinZusatz = 1 THEN ' Zusatz' ELSE '' END
				AS Warnung,
				Einrichtung,
				Teilnehmer,
				Datum
			FROM
				(
					SELECT
						Z.Einrichtung,
						Z.Teilnehmer,
						A.Datum,
						CASE WHEN A.Vormittags = 1 AND A.Nachmittags = 1 AND MAX(CAST(V.Vormittags AS int) + CAST(V.Nachmittags AS int)) < 2 THEN 1 ELSE 0 END AS KeinGanztags,
						CASE WHEN A.Vormittags = 1 AND A.Nachmittags = 0 AND MAX(CAST(V.Vormittags AS int)) < 1 THEN 1 ELSE 0 END AS KeinVormittags,
						CASE WHEN A.Vormittags = 0 AND A.Nachmittags = 1 AND MAX(CAST(V.Nachmittags AS int)) < 1 THEN 1 ELSE 0 END AS KeinNachmittags,
						CASE WHEN A.Nachts = 1 AND MAX(CAST(V.Nachts AS int)) < 1 THEN 1 ELSE 0 END AS KeinNachts,
						CASE WHEN A.Zusatz <> 0 AND MAX(CAST(V.Zusatz AS int)) < 1 THEN 1 ELSE 0 END AS KeinZusatz
					FROM
						AktiveZeitspannen AS Z JOIN
						dbo.Anwesenheit AS A ON A.Zeitspanne = Z.ID AND A.Datum BETWEEN @Von AND @Bis AND A.Datum <= Z.Überprüft JOIN
						dbo.Bescheid AS B ON B.Einrichtung = Z.Einrichtung AND B.Teilnehmer = Z.Teilnehmer AND A.Datum BETWEEN B.Beginn AND B.Ende JOIN
						dbo.Verrechnungssatz AS V ON V.Leistungsart = B.Leistungsart AND V.Jahr = CASE WHEN MONTH(A.Datum) = 1 THEN YEAR(A.Datum) - 1 ELSE YEAR(A.Datum) END
					GROUP BY
						A.ID, Z.Einrichtung, Z.Teilnehmer, A.Datum, A.Vormittags, A.Nachmittags, A.Nachts, A.Zusatz
				) AS W
			WHERE
				W.KeinGanztags = 1 OR
				W.KeinVormittags = 1 OR
				W.KeinNachmittags = 1 OR
				W.KeinNachts = 1 OR
				W.KeinZusatz = 1
		UNION
			SELECT
				'Begleitetes Praktikum ohne Bescheid/Satz' AS Warnung,
				Z.Einrichtung AS Einrichtung,
				Z.Teilnehmer AS Teilnehmer,
				CASE WHEN @Von < P.Von THEN P.Von ELSE @Von END AS Datum
			FROM
				AktiveZeitspannen AS Z JOIN
				dbo.Praktikum AS P ON P.Einrichtung = Z.Einrichtung AND P.Teilnehmer = Z.Teilnehmer AND P.Bis >= Z.Eintritt AND (Z.Austritt IS NULL OR P.Von <= Z.Austritt)
			WHERE
				P.Von <= @Bis AND
				P.Bis >= @Von AND
				NOT EXISTS
				(
					SELECT *
					FROM
						dbo.Verrechnungssatz AS V JOIN
						(
							SELECT
								B.Leistungsart,
								CASE WHEN B.Beginn < @Von THEN @Von ELSE B.Beginn END AS Beginn,
								CASE WHEN B.Ende > @Bis THEN @Bis ELSE B.Ende END AS Ende
							FROM
								(
									SELECT
										B.Leistungsart,
										CASE WHEN B.Beginn < P.Von THEN P.Von ELSE B.Beginn END AS Beginn,
										CASE WHEN B.Ende > P.Bis THEN P.Bis ELSE B.Ende END AS Ende
									FROM dbo.Bescheid AS B
									WHERE B.Einrichtung = Z.Einrichtung AND B.Teilnehmer = Z.Teilnehmer AND B.Ende >= P.Von AND B.Beginn <= P.Bis
								) AS B
						) AS B ON V.Leistungsart = B.Leistungsart AND V.Jahr BETWEEN CASE WHEN MONTH(B.Beginn) = 1 THEN YEAR(B.Beginn) - 1 ELSE YEAR(B.Beginn) END AND CASE WHEN MONTH(B.Ende) = 1 THEN YEAR(B.Ende) - 1 ELSE YEAR(B.Ende) END
					WHERE
						V.Praktikum = 1
				)
		) AS W JOIN
		dbo.Einrichtung AS E ON E.ID = W.Einrichtung JOIN
		dbo.Teilnehmer AS T ON T.ID = W.Teilnehmer
	ORDER BY E.Name, T.Nachname, T.Vorname, W.Datum
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DownloadRechnung] @Rechnung int AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Typ int
	DECLARE @TypBezeichnung nvarchar(50)
	DECLARE @RechnungBezeichnung nvarchar(50)
	DECLARE @RechnungDatum datetime
	DECLARE @Zeilen int

	IF NOT EXISTS(SELECT * FROM dbo.Rechnung WHERE ID = @Rechnung) RETURN

	SELECT
		@RechnungBezeichnung = R.Bezeichnung,
		@RechnungDatum = R.Datum
	FROM dbo.Rechnung AS R
	WHERE R.ID = @Rechnung

	SELECT
		@RechnungBezeichnung + N'.zip' AS [FileName],
		@RechnungDatum AS [LastModified],
		'utf-8' AS [Encoding],
		'application/x-zip-compressed' AS [ContentType]

	DECLARE Typen CURSOR LOCAL FAST_FORWARD FOR
		SELECT T.ID, T.Bezeichnung
		FROM dbo.Bescheid_Typ AS T
		WHERE
			T.Abrechnung = 1 AND
			EXISTS(
				SELECT *
				FROM
					dbo.Bescheid AS B JOIN
					dbo.Abrechnung AS A ON A.Bescheid = B.ID
				WHERE
					B.Typ = T.ID AND
					A.Rechnung = @Rechnung
			)

	OPEN Typen

	FETCH NEXT FROM Typen INTO @Typ, @TypBezeichnung
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT
			@TypBezeichnung + N'\Detail.txt' AS [FileName],
			'windows-1252' AS [Encoding],
			'de-AT' AS [Culture],
			CHAR(9) AS [Separator],
			CAST(1 AS BIT) AS [Header]

		SELECT
			@Rechnung AS [re_nr],
			'AUFBAUWERK' AS [l_erbringer],
			T.Klientennummer AS [klient_nr_tlr],
			T.ID AS [klient_nr_le],
			B.Geschäftszahl AS [geschaeftszahl],
			L.Kürzel AS [l_art],
			K.Kürzel AS [k_art],
			YEAR(A.Datum) AS [jahr],
			MONTH(A.Datum) AS [monat],
			S.Standortnummer AS [sto_nr],
			L.Bezeichnung AS [leistung_le],
			SUM(A.Menge) AS [einheiten],
			A.Preis AS [satz_netto],
			E.Kürzel AS [einheit],
			NULL AS [einheiten_sb],
			NULL AS [sb_je_einheit],
			NULL AS [einheit_sb]
		FROM
			dbo.Teilnehmer AS T JOIN
			dbo.Bescheid AS B ON B.Teilnehmer = T.ID JOIN
			dbo.Abrechnung AS A ON A.Bescheid = B.ID JOIN
			dbo.Leistungsart AS L ON L.ID = B.Leistungsart JOIN
			dbo.Kostensatz AS K ON K.ID = A.Kostensatz JOIN
			dbo.Einrichtung AS S ON S.ID = B.Einrichtung JOIN
			dbo.Einheit AS E ON E.ID = L.Einheit
		WHERE
			B.Typ = @Typ AND
			A.Rechnung = @Rechnung
		GROUP BY
			B.ID, B.Geschäftszahl, L.Kürzel, L.Bezeichnung, E.Kürzel, T.ID, T.Klientennummer, S.Standortnummer,
			YEAR(A.Datum), MONTH(A.Datum),
			A.Kostensatz, K.Kürzel, A.Preis

		SET @Zeilen = @@ROWCOUNT

		SELECT
			@TypBezeichnung + N'\Gesamt.txt' AS [FileName],
			'windows-1252' AS [Encoding],
			'de-AT' AS [Culture],
			CHAR(9) AS [Separator],
			CAST(1 AS BIT) AS [Header]

		SELECT
			@Rechnung AS [re_nr],
			'AUFBAUWERK' AS [ktr],
			@RechnungDatum AS [re_datum],
			SUM(A.Preis*CAST(A.Menge AS money)) AS [summe_netto_file],
			SUM(A.Preis*CAST(A.Menge AS money))*CAST(1.1 AS money) AS [summe_brutto_file],
			SUM(A.Preis*CAST(A.Menge AS money)) AS [summe_netto_re],
			SUM(A.Preis*CAST(A.Menge AS money))*CAST(1.1 AS money) AS [summe_brutto_re],
			MIN(YEAR(A.Datum)) AS [von_jahr],
			MIN(MONTH(A.Datum)) AS [von_monat],
			MAX(YEAR(A.Datum)) AS [bis_jahr],
			MAX(MONTH(A.Datum)) AS [bis_monat],
			@Zeilen AS [zeilen_file],
			@Zeilen AS [zeilen_re]
		FROM
			Bescheid AS B JOIN
			Abrechnung AS A ON A.Bescheid = B.ID
		WHERE
			B.Typ = @Typ AND
			A.Rechnung = @Rechnung

		FETCH NEXT FROM Typen INTO @Typ, @TypBezeichnung
	END

	CLOSE Typen
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Druckform]
AS
SELECT
	A.Rechnung,
	B.Typ AS Empfänger,
	T.ID AS Teilnehmer,
	T.Nachname,
	T.Vorname,
	B.Geschäftszahl,
	L.Kürzel AS Leistungsart,
	K.Kürzel AS Kostensatz,
	YEAR(A.Datum) AS Jahr,
	MONTH(A.Datum) AS Monat,
	CAST(SUM(A.Menge) AS float) AS Einheiten,
	A.Preis AS Nettosatz,
	E.Kürzel AS Einheit
FROM
	dbo.Teilnehmer AS T JOIN
	dbo.Bescheid AS B ON T.ID = B.Teilnehmer JOIN
	dbo.Abrechnung AS A ON A.Bescheid = B.ID JOIN
	dbo.Leistungsart AS L ON B.Leistungsart = L.ID JOIN
	dbo.Kostensatz AS K ON A.Kostensatz = K.ID JOIN
	dbo.Einrichtung AS S ON B.Einrichtung = S.ID JOIN
	dbo.Einheit AS E ON L.Einheit = E.ID
GROUP BY
	A.Rechnung,
	B.ID,
	B.Geschäftszahl,
	B.Typ,
	L.Kürzel,
	E.Kürzel,
	T.ID,
	T.Nachname,
	T.Vorname,
	YEAR(A.Datum),
	MONTH(A.Datum),
	A.Kostensatz,
	K.Kürzel,
	A.Preis
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Tagsatzplanung]
AS
SELECT
	P.Jahr AS Jahr,
	P.Monat AS Monat,
	E.Name AS Einrichtung,
	L.Bezeichnung AS Leistungsart,
	CASE
		WHEN MIN(YEAR(A.Datum)) = P.Jahr
		THEN NULL
		ELSE
			SUM
			(
				CASE
					WHEN YEAR(A.Datum) < P.Jahr
					THEN CAST(A.Menge AS money) * A.Preis
					ELSE 0
				END
			) /
			COUNT
			(
				DISTINCT CASE
					WHEN YEAR(A.Datum) < P.Jahr
					THEN YEAR(A.Datum)
					ELSE NULL
				END
			)
	END AS Schätzung,
	SUM(CASE WHEN YEAR(A.Datum) = P.Jahr THEN CAST(A.Menge AS money) * A.Preis ELSE 0 END) AS Tatsächlich
FROM
	dbo.Planung AS P JOIN
	dbo.Einrichtung AS E ON P.Einrichtung = E.ID JOIN
	dbo.Leistungsart AS L ON P.Leistungsart = L.ID JOIN
	dbo.Bescheid AS B ON P.Einrichtung = B.Einrichtung AND P.Leistungsart = B.Leistungsart JOIN
	dbo.Abrechnung AS A ON A.Bescheid = B.ID AND YEAR(A.Datum) <= P.Jahr AND MONTH(A.Datum) = P.Monat
GROUP BY P.Jahr, P.Monat, P.Einrichtung, E.Name, P.Leistungsart, L.Bezeichnung
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Standort]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Standort','Name') AS Fehler
	FROM dbo.Standort
	WHERE dbo.IstEinzeiler(Name) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(37,'Standort','Adresse') AS Fehler
	FROM dbo.Standort
	WHERE dbo.IstMehrzeiler(Adresse) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(41,'Standort','Telefon') AS Fehler
	FROM dbo.Standort
	WHERE dbo.IstTelefonnummer(Telefon) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(41,'Standort','Fax') AS Fehler
	FROM dbo.Standort
	WHERE dbo.IstTelefonnummer(Fax) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(42,'Standort','Email') AS Fehler
	FROM dbo.Standort
	WHERE dbo.IstEmail(Email) = 0
UNION
	SELECT S1.ID, dbo.ErstelleFehler(55,'Standort',DEFAULT) AS Fehler
	FROM dbo.Standort AS S1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Standort AS S2
			WHERE
				S1.ID <> S2.ID AND
				S1.Name = S2.Name AND
				S1.Adresse = S2.Adresse
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Anwesenheit]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(60,'Anwesenheit','Zusatz') AS Fehler
	FROM dbo.Anwesenheit
	WHERE Zusatz > 1
UNION
	SELECT ID, dbo.ErstelleFehler(61,'Anwesenheit',DEFAULT) AS Fehler
	FROM dbo.Anwesenheit
	WHERE Vormittags = 0 AND Nachmittags = 0 AND Nachts = 0 AND Zusatz = 0
UNION
	SELECT A1.ID, dbo.ErstelleFehler(55,'Anwesenheit',DEFAULT) AS Fehler
	FROM dbo.Anwesenheit AS A1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Anwesenheit AS A2
			WHERE
				A1.ID <> A2.ID AND
				A1.Zeitspanne = A2.Zeitspanne AND
				A1.Datum = A2.Datum
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Feiertag]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Feiertag','Name') AS Fehler
	FROM dbo.Feiertag
	WHERE dbo.IstEinzeiler(Name) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Feiertag','Datum') AS Fehler
	FROM dbo.Feiertag
	WHERE dbo.Time(Datum) <> 0
UNION
	SELECT F1.ID, dbo.ErstelleFehler(16,'Feiertag','Datum') AS Fehler
	FROM dbo.Feiertag AS F1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Feiertag AS F2
			WHERE F1.ID <> F2.ID AND F1.Datum = F2.Datum
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Bescheid_Typ]() RETURNS TABLE AS RETURN
(
	SELECT
		B.ID AS Bescheid,
		T.ID AS Bescheid_Typ,
		dbo.ErstelleFehler(26,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Bescheid AS B JOIN
		dbo.Bescheid_Typ AS T ON B.Typ = T.ID
	WHERE
		B.Maximum IS NULL AND T.Abrechnung = 1 OR
		B.Maximum IS NOT NULL AND T.Abrechnung = 0
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Einheit]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Einheit','Bezeichnung') AS Fehler
	FROM dbo.Einheit
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(38,'Einheit','Kürzel') AS Fehler
	FROM dbo.Einheit
	WHERE dbo.IstKürzel(Kürzel) = 0
UNION
	SELECT E1.ID, dbo.ErstelleFehler(16,'Einheit','Bezeichnung') AS Fehler
	FROM dbo.Einheit AS E1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Einheit AS E2
			WHERE E1.ID <> E2.ID AND E1.Bezeichnung = E2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Zeitspanne]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(4,'Zeitspanne','Eintritt') AS Fehler
	FROM dbo.Zeitspanne
	WHERE dbo.Time(Eintritt) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Zeitspanne','Austritt') AS Fehler
	FROM dbo.Zeitspanne
	WHERE dbo.Time(Austritt) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(37,'Zeitspanne','Austrittsnotiz') AS Fehler
	FROM dbo.Zeitspanne
	WHERE dbo.IstMehrzeiler(Austrittsnotiz) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Zeitspanne','Überprüft') AS Fehler
	FROM dbo.Zeitspanne
	WHERE dbo.Time(Überprüft) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(29,'Zeitspanne',DEFAULT) AS Fehler
	FROM dbo.Zeitspanne
	WHERE Eintritt > Austritt
UNION
	SELECT ID, dbo.ErstelleFehler(59,'Zeitspanne',DEFAULT) AS Fehler
	FROM dbo.Zeitspanne
	WHERE Überprüft < Eintritt OR Austritt < Überprüft
UNION
	SELECT ID, dbo.ErstelleFehler(57,'Zeitspanne',DEFAULT) AS Fehler
	FROM dbo.Zeitspanne
	WHERE
		Austritt IS NULL AND (Austrittsgrund IS NOT NULL OR Austrittsnotiz IS NOT NULL) OR
		Austritt IS NOT NULL AND Austrittsgrund IS NULL
UNION
	SELECT Z1.ID, dbo.ErstelleFehler(55,'Zeitspanne',DEFAULT) AS Fehler
	FROM dbo.Zeitspanne AS Z1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Zeitspanne AS Z2
			WHERE
				Z1.ID <> Z2.ID AND
				Z1.Einrichtung = Z2.Einrichtung AND
				Z1.Teilnehmer = Z2.Teilnehmer AND
				(Z1.Eintritt <= Z2.Austritt OR Z2.Austritt IS NULL) AND (Z1.Austritt IS NULL OR Z1.Austritt >= Z2.Eintritt)
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Verrechnungssatz_Platzhalter]() RETURNS TABLE AS RETURN
(
	SELECT
		V.ID AS Verrechnungssatz,
		L.ID AS Leistungsart,
		K.ID AS Kostensatz,
		dbo.ErstelleFehler(23,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Verrechnungssatz AS V JOIN
		dbo.Leistungsart AS L ON V.Leistungsart = L.ID JOIN
		dbo.Kostensatz AS K ON V.Kostensatz = K.ID
	WHERE
		(K.Platzhalter = 1 AND (L.Platzhalter = 0 OR V.Vormittags = 1 OR V.Nachmittags = 1 OR V.Nachts = 1 OR V.Zusatz = 1 OR V.Praktikum = 1)) OR
		(K.Platzhalter = 0 AND V.Vormittags = 0 AND V.Nachmittags = 0 AND V.Nachts = 0 AND V.Zusatz = 0 AND V.Praktikum = 0)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Kostensatz]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Kostensatz','Bezeichnung') AS Fehler
	FROM dbo.Kostensatz
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(38,'Kostensatz','Kürzel') AS Fehler
	FROM dbo.Kostensatz
	WHERE dbo.IstKürzel(Kürzel) = 0
UNION
	SELECT K1.ID, dbo.ErstelleFehler(16,'Kostensatz','Bezeichnung') AS Fehler
	FROM dbo.Kostensatz AS K1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Kostensatz AS K2
			WHERE K1.ID <> K2.ID AND K1.Bezeichnung = K2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Leistungsart]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Leistungsart','Bezeichnung') AS Fehler
	FROM dbo.Leistungsart
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(38,'Leistungsart','Kürzel') AS Fehler
	FROM dbo.Leistungsart
	WHERE dbo.IstKürzel(Kürzel) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(39,'Leistungsart','Platzhalter') AS Fehler
	FROM dbo.Leistungsart
	WHERE Platzhalter < 0
UNION
	SELECT L1.ID, dbo.ErstelleFehler(16,'Leistungsart','Bezeichnung') AS Fehler
	FROM dbo.Leistungsart AS L1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Leistungsart AS L2
			WHERE L1.ID <> L2.ID AND L1.Bezeichnung = L2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Rechnung]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Rechnung','Bezeichnung') AS Fehler
	FROM dbo.Rechnung
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Rechnung','Datum') AS Fehler
	FROM dbo.Rechnung
	WHERE dbo.Time(Datum) <> 0
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Einrichtung]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Einrichtung','Name') AS Fehler
	FROM dbo.Einrichtung
	WHERE dbo.IstEinzeiler(Name) = 0
UNION
	SELECT E1.ID, dbo.ErstelleFehler(16,'Einrichtung','Name') AS Fehler
	FROM dbo.Einrichtung AS E1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Einrichtung AS E2
			WHERE E1.ID <> E2.ID AND E1.Name = E2.Name
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Planung]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(39,'Planung','Schätzung') AS Fehler
	FROM dbo.Planung
	WHERE Schätzung < 0
UNION
	SELECT ID, dbo.ErstelleFehler(40,'Planung','Monat') AS Fehler
	FROM dbo.Planung
	WHERE Monat NOT BETWEEN 1 AND 12
UNION
	SELECT P1.ID, dbo.ErstelleFehler(55,'Planung',DEFAULT) AS Fehler
	FROM dbo.Planung AS P1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Planung AS P2
			WHERE
				P1.ID <> P2.ID AND
				P1.Einrichtung = P2.Einrichtung AND
				P1.Leistungsart = P2.Leistungsart AND
				P1.Jahr = P2.Jahr AND
				P1.Monat = P2.Monat
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Praktikum]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(4,'Praktikum','Von') AS Fehler
	FROM dbo.Praktikum
	WHERE dbo.Time(Von) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Praktikum','Bis') AS Fehler
	FROM dbo.Praktikum
	WHERE dbo.Time(Bis) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(29,'Praktikum',DEFAULT) AS Fehler
	FROM dbo.Praktikum
	WHERE Von > Bis
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Verrechnungssatz]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(5,'Verrechnungssatz','Preis') AS Fehler
	FROM dbo.Verrechnungssatz
	WHERE Preis <= 0
UNION
	SELECT ID, dbo.ErstelleFehler(65,'Verrechnungssatz','Preis') AS Fehler
	FROM dbo.Verrechnungssatz
	WHERE SIGN(0 + Vormittags + Nachmittags) + Nachts + Zusatz + Praktikum > 1
UNION
	SELECT V1.ID, dbo.ErstelleFehler(55,'Verrechnungssatz',DEFAULT) AS Fehler
	FROM dbo.Verrechnungssatz AS V1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Verrechnungssatz AS V2
			WHERE
				V1.ID <> V2.ID AND
				V1.Leistungsart = V2.Leistungsart AND
				V1.Jahr = V2.Jahr AND
				V1.Vormittags = V2.Vormittags AND
				V1.Nachmittags = V2.Nachmittags AND
				V1.Nachts = V2.Nachts AND
				V1.Zusatz = V2.Zusatz AND
				V1.Praktikum = V2.Praktikum
		)

)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Teilnehmer]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Teilnehmer','Vorname') AS Fehler
	FROM dbo.Teilnehmer
	WHERE dbo.IstEinzeiler(Vorname) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(36,'Teilnehmer','Nachname') AS Fehler
	FROM dbo.Teilnehmer
	WHERE dbo.IstEinzeiler(Nachname) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Teilnehmer','Geburtstag') AS Fehler
	FROM dbo.Teilnehmer
	WHERE dbo.Time(Geburtstag) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(48,'Teilnehmer','Klientennummer') AS Fehler
	FROM dbo.Teilnehmer
	WHERE dbo.IstKlientennummer(Klientennummer) = 0
UNION
	SELECT T1.ID, dbo.ErstelleFehler(16,'Teilnehmer','Klientennummer') AS Fehler
	FROM dbo.Teilnehmer AS T1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Teilnehmer AS T2
			WHERE T1.ID <> T2.ID AND T1.Klientennummer = T2.Klientennummer
		)
UNION
	SELECT T1.ID, dbo.ErstelleFehler(55,'Teilnehmer',DEFAULT) AS Fehler
	FROM dbo.Teilnehmer AS T1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Teilnehmer AS T2
			WHERE
				T1.ID <> T2.ID AND
				T1.Vorname = T2.Vorname AND
				T1.Nachname = T2.Nachname AND
				T1.Geburtstag = T2.Geburtstag
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Standort_Bereich]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Standort_Bereich','Bezeichnung') AS Fehler
	FROM dbo.Standort_Bereich
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(50,'Standort_Bereich','Code') AS Fehler
	FROM dbo.Standort_Bereich
	WHERE Code NOT BETWEEN 'A' AND 'Z' COLLATE Latin1_General_BIN
UNION
	SELECT S1.ID, dbo.ErstelleFehler(16,'Standort_Bereich','Bezeichnung') AS Fehler
	FROM dbo.Standort_Bereich AS S1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Standort_Bereich AS S2
			WHERE S1.ID <> S2.ID AND S1.Bezeichnung = S2.Bezeichnung
		)
UNION
	SELECT S1.ID, dbo.ErstelleFehler(16,'Standort_Bereich','Code') AS Fehler
	FROM dbo.Standort_Bereich AS S1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Standort_Bereich AS S2
			WHERE S1.ID <> S2.ID AND S1.Code = S2.Code
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Zeitspanne_Austrittsgrund]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Zeitspanne_Austrittsgrund','Bezeichnung') AS Fehler
	FROM dbo.Zeitspanne_Austrittsgrund
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT A1.ID, dbo.ErstelleFehler(16,'Zeitspanne_Austrittsgrund','Bezeichnung') AS Fehler
	FROM dbo.Zeitspanne_Austrittsgrund AS A1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Zeitspanne_Austrittsgrund AS A2
			WHERE A1.ID <> A2.ID AND A1.Bezeichnung = A2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Bescheid]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(28,'Bescheid','Geschäftszahl') AS Fehler
	FROM dbo.Bescheid
	WHERE dbo.IstGeschäftszahl(Geschäftszahl) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Bescheid','Beginn') AS Fehler
	FROM dbo.Bescheid
	WHERE dbo.Time(Beginn) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Bescheid','Ende') AS Fehler
	FROM dbo.Bescheid
	WHERE dbo.Time(Ende) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(4,'Bescheid','Ausstellungsdatum') AS Fehler
	FROM dbo.Bescheid
	WHERE dbo.Time(Ausstellungsdatum) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(29,'Bescheid',DEFAULT) AS Fehler
	FROM dbo.Bescheid
	WHERE Beginn > Ende
UNION
	SELECT ID, dbo.ErstelleFehler(5,'Bescheid','Maximum') AS Fehler
	FROM dbo.Bescheid
	WHERE Maximum <= 0
UNION
	SELECT B1.ID, dbo.ErstelleFehler(16,'Bescheid','Geschäftszahl') AS Fehler
	FROM dbo.Bescheid AS B1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Bescheid AS B2
			WHERE B1.ID <> B2.ID AND B1.Geschäftszahl = B2.Geschäftszahl
		)
UNION
	SELECT B1.ID, dbo.ErstelleFehler(17,'Bescheid',DEFAULT) AS Fehler
	FROM dbo.Bescheid AS B1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Bescheid AS B2
			WHERE
				B1.ID <> B2.ID AND
				B1.Teilnehmer = B2.Teilnehmer AND
				B1.Leistungsart = B2.Leistungsart AND
				(B1.Beginn <= B2.Ende) AND (B1.Beginn >= B2.Ende)
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Abrechnung]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(4,'Abrechnung','Datum') AS Fehler
	FROM dbo.Abrechnung
	WHERE dbo.Time(Datum) <> 0
UNION
	SELECT ID, dbo.ErstelleFehler(5,'Abrechnung','Dauer') AS Fehler
	FROM dbo.Abrechnung
	WHERE Menge <= 0
UNION
	SELECT A1.ID, dbo.ErstelleFehler(55,'Abrechnung',DEFAULT) AS Fehler
	FROM dbo.Abrechnung AS A1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Abrechnung AS A2
			WHERE
				A1.ID <> A2.ID AND
				A1.Bescheid = A2.Bescheid AND
				A1.Datum = A2.Datum
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Abrechnung_Bescheid]() RETURNS TABLE AS RETURN
(
	SELECT
		A.ID AS Abrechnung,
		B.ID AS Bescheid,
		dbo.ErstelleFehler(12,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Abrechnung AS A JOIN
		dbo.Bescheid AS B ON A.Bescheid = B.ID
	WHERE
		NOT (A.Datum BETWEEN B.Beginn AND B.Ende)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Bescheid_Maximum]() RETURNS TABLE AS RETURN
(
	SELECT
		B.ID AS Bescheid,
		dbo.ErstelleFehler(21,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Bescheid AS B JOIN
		dbo.Abrechnung AS A ON A.Bescheid = B.ID
	WHERE
		B.Maximum IS NOT NULL
	GROUP BY B.ID, B.Maximum
	HAVING SUM(A.Menge) > B.Maximum
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Abrechnung_Platzhalter]() RETURNS TABLE AS RETURN
(
	SELECT
		B.ID AS Bescheid,
		B.Leistungsart AS Leistungsart,
		dbo.ErstelleFehler(22,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Bescheid AS B JOIN
		dbo.Leistungsart AS L ON B.Leistungsart = L.ID JOIN
		dbo.Abrechnung AS A ON A.Bescheid = B.ID JOIN
		dbo.Kostensatz AS K ON A.Kostensatz = K.ID
	WHERE
		K.Platzhalter = 1
	GROUP BY
		B.ID, B.Leistungsart, B.Beginn, B.Ende, L.Platzhalter, dbo.YearDiff(B.Beginn,A.Datum)
	HAVING
		(dbo.YearDiff(B.Beginn,B.Ende) > dbo.YearDiff(B.Beginn,A.Datum) AND COUNT(*) > L.Platzhalter) OR
		(dbo.YearDiff(B.Beginn,B.Ende) = dbo.YearDiff(B.Beginn,A.Datum) AND COUNT(*) > ROUND(L.Platzhalter*(dbo.MonthDiff(DATEADD(year,dbo.YearDiff(B.Beginn,B.Ende),B.Beginn),B.Ende)+1)/12.0,0))
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Bescheid_Typ]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Bescheid_Typ','Bezeichnung') AS Fehler
	FROM dbo.Bescheid_Typ
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT ID, dbo.ErstelleFehler(37,'Bescheid_Typ','Anschrift') AS Fehler
	FROM dbo.Bescheid_Typ
	WHERE dbo.IstMehrzeiler(Anschrift) = 0
UNION
	SELECT T1.ID, dbo.ErstelleFehler(16,'Bescheid_Typ','Bezeichnung') AS Fehler
	FROM dbo.Bescheid_Typ AS T1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Bescheid_Typ AS T2
			WHERE T1.ID <> T2.ID AND T1.Bezeichnung = T2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler_Praktikum_Kategorie]() RETURNS TABLE AS RETURN
(
	SELECT ID, dbo.ErstelleFehler(36,'Praktikum_Kategorie','Bezeichnung') AS Fehler
	FROM dbo.Praktikum_Kategorie
	WHERE dbo.IstEinzeiler(Bezeichnung) = 0
UNION
	SELECT K1.ID, dbo.ErstelleFehler(16,'Praktikum_Kategorie','Bezeichnung') AS Fehler
	FROM dbo.Praktikum_Kategorie AS K1
	WHERE
		EXISTS
		(
			SELECT *
			FROM dbo.Praktikum_Kategorie AS K2
			WHERE K1.ID <> K2.ID AND K1.Bezeichnung = K2.Bezeichnung
		)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Fehler__Anwesenheit_Zeitspanne]() RETURNS TABLE AS RETURN
(
	SELECT
		A.ID AS Anwesenheit,
		Z.ID AS Zeitspanne,
		dbo.ErstelleFehler(58,DEFAULT,DEFAULT) AS Fehler
	FROM
		dbo.Anwesenheit AS A JOIN
		dbo.Zeitspanne AS Z ON A.Zeitspanne = Z.ID
	WHERE
		A.Datum < Z.Eintritt OR (Z.Austritt IS NOT NULL AND A.Datum > Z.Austritt)
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Schätzung](@Jahr int, @Monat int) RETURNS TABLE AS RETURN
(
	SELECT
		B.Einrichtung AS Einrichtung,
		B.Leistungsart AS Leistungsart,
		A.Kostensatz AS Kostensatz,
		SUM(A.Menge) AS Summe
	FROM
		dbo.Bescheid AS B JOIN
		dbo.Abrechnung AS A ON A.Bescheid = B.ID
	WHERE
		YEAR(A.Datum) < @Jahr AND MONTH(A.Datum) = @Monat
	GROUP BY
		B.Einrichtung, B.Leistungsart, A.Kostensatz
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[WerfeFehler] @Fehler AS bigint AS
BEGIN
	SET NOCOUNT ON

	IF @Fehler IS NULL RETURN

	DECLARE @Meldung nvarchar(2048)
	DECLARE @TabelleId int
	DECLARE @SpalteId int

	SELECT
		@Meldung = Meldung + ' [TN]',
		@TabelleId = (@Fehler & 0xFFFFFFFF00000000) / 0x100000000,
		@SpalteId = (@Fehler & 0x00000000FFFF0000) / 0x10000
	FROM dbo.Fehler
	WHERE ID = @Fehler & 0x000000000000FFFF

	IF @TabelleId > 0
	BEGIN
		DECLARE @Tabelle sysname

		SELECT
			@Tabelle = name,
			@Meldung = @Meldung + '[' + name + ']'
		FROM sys.tables
		WHERE object_id = @TabelleId

		IF @SpalteId > 0
		BEGIN
			DECLARE @Spalte sysname

			SELECT
				@Spalte = name,
				@Meldung = @Meldung + '[' + name + ']'
			FROM sys.columns
			WHERE object_id = @TabelleId AND column_id = @SpalteId

			RAISERROR(@Meldung, 16, 1, @Spalte, @Tabelle)
		END
		ELSE
			RAISERROR(@Meldung, 16, 1, @Tabelle)
	END
	ELSE
		RAISERROR(@Meldung, 16, 1)
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteAnwesenheit] ON [dbo].[Anwesenheit] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Anwesenheit() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist ein Anwesenheitstag nicht vollständig in einer Zeitspanne?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Anwesenheit_Zeitspanne() AS F JOIN inserted AS I ON F.Anwesenheit = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist der User nicht privilegiert?
		IF NOT (IS_MEMBER('Sekretariat') = 1)
		BEGIN
			-- stimmt die Einrichtung?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(1,'Anwesenheit',DEFAULT)
			FROM
				dbo.Zeitspanne AS Z JOIN
				(
					SELECT Zeitspanne FROM inserted
					UNION
					SELECT Zeitspanne FROM deleted
				) AS A ON A.Zeitspanne = Z.ID
			WHERE
				Z.Einrichtung NOT IN
				(
					SELECT E.ID
					FROM dbo.Einrichtung AS E
					WHERE IS_MEMBER(SUSER_SNAME(E.Training)) = 1
				)
			EXEC dbo.WerfeFehler @Fehler

			-- wurde ein überprüfter Tag geändert?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(64,'Anwesenheit','Datum')
			FROM
				dbo.Zeitspanne AS Z JOIN
				(
					SELECT Datum, Zeitspanne FROM inserted
					UNION
					SELECT Datum, Zeitspanne FROM deleted
				) AS A ON A.Zeitspanne = Z.ID
			WHERE
				A.Datum <= Z.Überprüft
			EXEC dbo.WerfeFehler @Fehler
		END

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Anwesenheit')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Anwesenheit')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TesteAlles] AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Fehler bigint

	SELECT TOP(1) @Fehler = U.Fehler
	FROM
	(
		SELECT Fehler FROM dbo.Fehler_Abrechnung()
		UNION
		SELECT Fehler FROM dbo.Fehler_Anwesenheit()
		UNION
		SELECT Fehler FROM dbo.Fehler_Bescheid()
		UNION
		SELECT Fehler FROM dbo.Fehler_Bescheid_Typ()
		UNION
		SELECT Fehler FROM dbo.Fehler_Einheit()
		UNION
		SELECT Fehler FROM dbo.Fehler_Einrichtung()
		UNION
		SELECT Fehler FROM dbo.Fehler_Feiertag()
		UNION
		SELECT Fehler FROM dbo.Fehler_Kostensatz()
		UNION
		SELECT Fehler FROM dbo.Fehler_Leistungsart()
		UNION
		SELECT Fehler FROM dbo.Fehler_Planung()
		UNION
		SELECT Fehler FROM dbo.Fehler_Praktikum()
		UNION
		SELECT Fehler FROM dbo.Fehler_Praktikum_Kategorie()
		UNION
		SELECT Fehler FROM dbo.Fehler_Rechnung()
		UNION
		SELECT Fehler FROM dbo.Fehler_Standort()
		UNION
		SELECT Fehler FROM dbo.Fehler_Standort_Bereich()
		UNION
		SELECT Fehler FROM dbo.Fehler_Teilnehmer()
		UNION
		SELECT Fehler FROM dbo.Fehler_Verrechnungssatz()
		UNION
		SELECT Fehler FROM dbo.Fehler_Zeitspanne()
		UNION
		SELECT Fehler FROM dbo.Fehler_Zeitspanne_Austrittsgrund()
	) AS U
	EXEC dbo.WerfeFehler @Fehler

	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Abrechnung_Bescheid()
	EXEC dbo.WerfeFehler @Fehler
	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Abrechnung_Platzhalter()
	EXEC dbo.WerfeFehler @Fehler
	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Anwesenheit_Zeitspanne()
	EXEC dbo.WerfeFehler @Fehler
	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Bescheid_Maximum()
	EXEC dbo.WerfeFehler @Fehler
	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Bescheid_Typ()
	EXEC dbo.WerfeFehler @Fehler
	SELECT TOP(1) @Fehler = Fehler FROM dbo.Fehler__Verrechnungssatz_Platzhalter()
	EXEC dbo.WerfeFehler @Fehler
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteZeitspanneAustrittsgrund] ON [dbo].[Zeitspanne_Austrittsgrund] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Zeitspanne_Austrittsgrund() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Zeitspanne_Austrittsgrund')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Zeitspanne_Austrittsgrund')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TestePlanung] ON [dbo].[Planung] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Planung() AS F JOIN inserted ON F.ID = inserted.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist der User nicht privilegiert?
		IF NOT (IS_MEMBER('Rechnungswesen') = 1)
		BEGIN
			-- stimmt die Einrichtung?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(1,'Planung',DEFAULT)
			FROM
				(
					SELECT Einrichtung FROM inserted
					UNION
					SELECT Einrichtung FROM deleted
				) AS P
			WHERE
				P.Einrichtung NOT IN
				(
					SELECT E.ID
					FROM dbo.Einrichtung AS E
					WHERE IS_MEMBER(SUSER_SNAME(E.Leitung)) = 1
				)
			EXEC dbo.WerfeFehler @Fehler

			-- wurde ein altes Jahr geplant?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(47,'Planung',DEFAULT)
			FROM
				(
					SELECT Jahr FROM inserted
					UNION
					SELECT Jahr FROM deleted
				) AS P
			WHERE P.Jahr <= YEAR(GETDATE())
			EXEC dbo.WerfeFehler @Fehler
		END

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Planung')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Planung')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteEinrichtung] ON [dbo].[Einrichtung] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Einrichtung() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Einrichtung')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Einrichtung')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TestePraktikum] ON [dbo].[Praktikum] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Praktikum() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- stimmt die Einrichtung?
		SELECT TOP(1) @Fehler = dbo.ErstelleFehler(1,'Praktikum',DEFAULT)
		FROM
			(
				SELECT Einrichtung FROM inserted
				UNION
				SELECT Einrichtung FROM deleted
			) AS P
		WHERE
			P.Einrichtung NOT IN
			(
				SELECT E.ID
				FROM dbo.Einrichtung AS E
				WHERE IS_MEMBER(SUSER_SNAME(E.Integrationsassistenz)) = 1
			)
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Praktikum')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Praktikum')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteZeitspanne] ON [dbo].[Zeitspanne] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Zeitspanne() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist ein Anwesenheitstag nicht vollständig in einer Zeitspanne?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Anwesenheit_Zeitspanne() AS F JOIN inserted AS I ON F.Zeitspanne = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist der User nicht privilegiert?
		IF NOT (IS_MEMBER('Sekretariat') = 1)
		BEGIN
			-- stimmt die Einrichtung?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(1,'Anwesenheit',DEFAULT)
			FROM
				(
					SELECT Einrichtung FROM inserted
					UNION
					SELECT Einrichtung FROM deleted
				) AS Z
			WHERE
				Z.Einrichtung NOT IN
				(
					SELECT E.ID
					FROM dbo.Einrichtung AS E
					WHERE IS_MEMBER(SUSER_SNAME(E.Leitung)) = 1
				)
			EXEC dbo.WerfeFehler @Fehler

			-- wurde ein Überprüfungsdatum zurückgesetzt?
			SELECT TOP(1) @Fehler = dbo.ErstelleFehler(63,'Zeitspanne','Überprüft')
			FROM
				inserted AS I JOIN
				deleted AS D ON I.ID = D.ID
			WHERE
				D.Überprüft IS NOT NULL AND
				(I.Überprüft IS NULL OR I.Überprüft < D.Überprüft)
			EXEC dbo.WerfeFehler @Fehler
		END

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Zeitspanne')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Zeitspanne')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ErstelleRechnung]
	@Bezeichnung nvarchar(50),
	@Von datetime,
	@Bis datetime,
	@Strikt bit,
	@Rechnung int OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	-- deklariere die Variablen
	DECLARE @Datum datetime
	DECLARE @Jahr int
	DECLARE @Arbeitstag bit

	-- sichere den aktuellen Transaktionsstatus
	SAVE TRANSACTION ErstelleRechnung
	BEGIN TRY
		-- überprüfe die Datumswerte
		IF dbo.Time(@Von) <> 0 OR dbo.Time(@Bis) <> 0 EXEC dbo.WerfeFehler 67

		-- überprüfe den Zeitraum
		IF @Bis < @Von EXEC dbo.WerfeFehler 29

		-- erstelle die Rechnung
		INSERT INTO dbo.Rechnung(Datum, Bezeichnung)
		VALUES(DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0), @Bezeichnung)
		SET @Rechnung = SCOPE_IDENTITY()

		-- enumeriere alle Tage
		SET @Datum = @Von
		WHILE @Datum <= @Bis
		BEGIN
			-- ermittle das Verrechnungsjahr und ob es sich um einen Arbeitstag handelt
			SET @Jahr = YEAR(@Datum)
			IF MONTH(@Datum) = 1 SET @Jahr = @Jahr - 1
			SET @Arbeitstag = CASE WHEN DATEPART(dw, @Datum) < 6 AND NOT EXISTS(SELECT * FROM dbo.Feiertag WHERE Datum = @Datum) THEN 1 ELSE 0 END

			-- füge alle Abrechnungstage ein
			INSERT INTO dbo.Abrechnung (Rechnung, Bescheid, Datum, Preis, Menge, Kostensatz)
			SELECT
				@Rechnung,
				V.Bescheid,
				@Datum,
				V.Preis,
				V.Menge,
				V.Kostensatz
			FROM
			(
				SELECT
					V.*,
					ROW_NUMBER() OVER
					(
						PARTITION BY V.Bescheid
						ORDER BY Platzhalter, Preis * Menge
					) AS Reihung
				FROM
				(
					SELECT
						B.ID AS Bescheid,
						V.Preis,
						CASE WHEN B.Maximum IS NULL THEN NULL ELSE B.Maximum - ISNULL((SELECT SUM(Menge) FROM dbo.Abrechnung WHERE Bescheid = B.ID), 0) END AS Restmenge,
						CAST(CASE WHEN V.Zusatz = 1 THEN CAST(A.Zusatz AS float) * E.Faktor ELSE 1 END AS decimal(9,2)) AS Menge,
						V.Kostensatz,
						CASE WHEN V.Vormittags = 0 AND V.Nachmittags = 0 AND V.Nachts = 0 AND V.Zusatz = 0 AND V.Praktikum = 0 THEN 1 ELSE 0 END AS Platzhalter
					FROM
						dbo.Zeitspanne AS Z JOIN
						dbo.Bescheid AS B ON B.Einrichtung = Z.Einrichtung AND B.Teilnehmer = Z.Teilnehmer AND @Datum BETWEEN B.Beginn AND B.Ende JOIN
						dbo.Leistungsart AS L ON L.ID = B.Leistungsart JOIN
						dbo.Einheit AS E ON E.ID = L.Einheit LEFT JOIN
						dbo.Anwesenheit AS A ON A.Zeitspanne = Z.ID AND A.Datum = @Datum JOIN
						dbo.Verrechnungssatz AS V ON
						(
							V.Leistungsart = B.Leistungsart AND
							V.Jahr = @Jahr AND
							(
								(V.Vormittags = 1 AND V.Nachmittags = 1) AND (A.Vormittags = 1 AND A.Nachmittags = 1) OR
								(V.Vormittags = 1 AND V.Nachmittags = 0) AND A.Vormittags = 1 OR
								(V.Vormittags = 0 AND V.Nachmittags = 1) AND A.Nachmittags = 1 OR
								V.Nachts = 1 AND A.Nachts = 1 OR
								V.Zusatz = 1 AND A.Zusatz <> 0 OR
								V.Praktikum = 1 AND @Arbeitstag = 1 AND EXISTS(SELECT * FROM dbo.Praktikum WHERE Einrichtung = B.Einrichtung AND Teilnehmer = B.Teilnehmer AND @Datum BETWEEN Von AND Bis AND Begleitung = 1) OR
								(
									@Arbeitstag = 1 AND
									V.Vormittags = 0 AND
									V.Nachmittags = 0 AND
									V.Nachts = 0 AND
									V.Zusatz = 0 AND
									V.Praktikum = 0 AND
									(
										SELECT COUNT(*)
										FROM
											dbo.Abrechnung AS R JOIN
											dbo.Kostensatz AS K ON R.Kostensatz = K.ID
										WHERE
											R.Bescheid = B.ID AND
											K.Platzhalter = 1 AND
											dbo.YearDiff(B.Beginn,R.Datum) = dbo.YearDiff(B.Beginn,@Datum)
									) < CASE WHEN dbo.YearDiff(B.Beginn,B.Ende) > dbo.YearDiff(B.Beginn,@Datum) THEN L.Platzhalter ELSE ROUND(L.Platzhalter*(dbo.MonthDiff(DATEADD(year,dbo.YearDiff(B.Beginn,B.Ende),B.Beginn),B.Ende)+1)/12.0,0) END
								)
							)
						)
					WHERE
						@Datum >= Z.Eintritt AND
						(Z.Austritt IS NULL OR @Datum <= Z.Austritt) AND
						@Datum <= Z.Überprüft AND
						NOT EXISTS
						(
							SELECT *
							FROM dbo.Abrechnung
							WHERE
								Bescheid = B.ID AND
								Datum = @Datum
						)
				) AS V
				WHERE V.Restmenge IS NULL OR V.Menge <= V.Restmenge
			) AS V
			WHERE V.Reihung = 1

			-- erhöhe die Schleifenvariable
			SET @Datum = DATEADD(dd, 1, @Datum)
		END
	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		IF XACT_STATE() <> -1 ROLLBACK TRANSACTION ErstelleRechnung
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteFeiertag] ON [dbo].[Feiertag] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Feiertag() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Feiertag')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Feiertag')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteVerrechnungssatz] ON [dbo].[Verrechnungssatz] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Verrechnungssatz() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- stimmt die Platzhalteangabe des Kostensatzes nicht mit der Leistungsart zusammen?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Verrechnungssatz_Platzhalter() AS F JOIN inserted AS I ON F.Verrechnungssatz = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Verrechnungssatz')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Verrechnungssatz')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteBescheid] ON [dbo].[Bescheid] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Bescheid() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist der Bescheid mit dem Typ inkompatibel?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Bescheid_Typ() AS F JOIN inserted AS I ON F.Bescheid = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- liegt eine Abrechnung außerhalb des Bescheides?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Bescheid() AS F JOIN inserted AS I ON F.Bescheid = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- wurde das Maximum überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Bescheid_Maximum() AS F JOIN inserted AS I ON F.Bescheid = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- wurden die verfügbaren Platzhalte überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Platzhalter() AS F JOIN inserted AS I ON F.Bescheid = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Bescheid')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Bescheid')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TestePraktikumKategorie] ON [dbo].[Praktikum_Kategorie] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Praktikum_Kategorie() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Praktikum_Kategorie')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Praktikum_Kategorie')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteStandort] ON [dbo].[Standort] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Standort() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Standort')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Standort')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteTeilnehmer] ON [dbo].[Teilnehmer] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Teilnehmer() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Teilnehmer')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Teilnehmer')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteStandortBereich] ON [dbo].[Standort_Bereich] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Standort_Bereich() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Standort_Bereich')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Standort_Bereich')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteLeistungsart] ON [dbo].[Leistungsart] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Leistungsart() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- stimmt die Platzhalteangabe des Kostensatzes nicht mit der Leistungsart zusammen?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Verrechnungssatz_Platzhalter() AS F JOIN inserted AS I ON F.Leistungsart = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- wurden die verfügbaren Platzhalte überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Platzhalter() AS F JOIN inserted AS I ON F.Leistungsart = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Leistungsart')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Leistungsart')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteKostensatz] ON [dbo].[Kostensatz] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Kostensatz() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- stimmt die Platzhalteangabe des Kostensatzes nicht mit der Leistungsart zusammen?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Verrechnungssatz_Platzhalter() AS F JOIN inserted AS I ON F.Kostensatz = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- wurden die verfügbaren Platzhalte überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Platzhalter() AS F WHERE F.Bescheid IN (SELECT DISTINCT A.Bescheid FROM dbo.Abrechnung AS A JOIN inserted AS I ON A.Kostensatz = I.ID)
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Kostensatz')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Kostensatz')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteRechnung] ON [dbo].[Rechnung] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Rechnung() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Rechnung')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Rechnung')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteBescheidTyp] ON [dbo].[Bescheid_Typ] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Bescheid_Typ() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- ist der Bescheid mit dem Typ inkompatibel?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Bescheid_Typ() AS F JOIN inserted AS I ON F.Bescheid_Typ = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Bescheid_Typ')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Bescheid_Typ')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteAbrechnung] ON [dbo].[Abrechnung] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Abrechnung() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- liegt eine Abrechnung außerhalb des Bescheides?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Bescheid() AS F JOIN inserted AS I ON F.Abrechnung = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- wurde das Maximum überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Bescheid_Maximum() AS F JOIN inserted AS I ON F.Bescheid = I.Bescheid
		EXEC dbo.WerfeFehler @Fehler

		-- wurden die verfügbaren Platzhalte überschritten?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler__Abrechnung_Platzhalter() AS F JOIN inserted AS I ON F.Bescheid = I.Bescheid
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Abrechnung')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Abrechnung')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TesteEinheit] ON [dbo].[Einheit] AFTER INSERT, UPDATE, DELETE AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @Fehler bigint

		-- stimmt der Wert einer Spalte nicht?
		SELECT TOP(1) @Fehler = F.Fehler FROM dbo.Fehler_Einheit() AS F JOIN inserted AS I ON F.ID = I.ID
		EXEC dbo.WerfeFehler @Fehler

		-- archiviere die Änderung
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				CASE WHEN I1.ID IN (SELECT ID FROM deleted) THEN 'Geändert' ELSE 'Hinzugefügt' END AS [@Aktion],
				*
			FROM inserted AS I2
			WHERE I1.ID = I2.ID
			FOR XML PATH('Einheit')
		)
		FROM inserted AS I1
		INSERT INTO dbo.Version(Zeile)
		SELECT
		(
			SELECT
				'Gelöscht' AS [@Aktion],
				ID
			FROM deleted AS D2
			WHERE D1.ID = D2.ID
			FOR XML PATH('Einheit')
		)
		FROM deleted AS D1
		WHERE D1.ID NOT IN (SELECT ID FROM inserted)

	END TRY
	BEGIN CATCH
		EXEC dbo.BerichteFehler
		ROLLBACK TRANSACTION
	END CATCH
END
GO
ALTER TABLE [dbo].[Fehler]  WITH CHECK ADD  CONSTRAINT [CK_Fehler] CHECK  ((len(ltrim(rtrim([Meldung])))>(0)))
GO
ALTER TABLE [dbo].[Fehler] CHECK CONSTRAINT [CK_Fehler]
GO
ALTER TABLE [dbo].[Abrechnung]  WITH CHECK ADD  CONSTRAINT [FK_Abrechnung_Bescheid] FOREIGN KEY([Bescheid])
REFERENCES [dbo].[Bescheid] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Abrechnung] CHECK CONSTRAINT [FK_Abrechnung_Bescheid]
GO
ALTER TABLE [dbo].[Abrechnung]  WITH CHECK ADD  CONSTRAINT [FK_Abrechnung_Kostensatz] FOREIGN KEY([Kostensatz])
REFERENCES [dbo].[Kostensatz] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Abrechnung] CHECK CONSTRAINT [FK_Abrechnung_Kostensatz]
GO
ALTER TABLE [dbo].[Abrechnung]  WITH CHECK ADD  CONSTRAINT [FK_Abrechnung_Rechnung] FOREIGN KEY([Rechnung])
REFERENCES [dbo].[Rechnung] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Abrechnung] CHECK CONSTRAINT [FK_Abrechnung_Rechnung]
GO
ALTER TABLE [dbo].[Anwesenheit]  WITH CHECK ADD  CONSTRAINT [FK_Anwesenheit_Zeitspanne] FOREIGN KEY([Zeitspanne])
REFERENCES [dbo].[Zeitspanne] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Anwesenheit] CHECK CONSTRAINT [FK_Anwesenheit_Zeitspanne]
GO
ALTER TABLE [dbo].[Bescheid]  WITH CHECK ADD  CONSTRAINT [FK_Bescheid_Bescheid_Typ] FOREIGN KEY([Typ])
REFERENCES [dbo].[Bescheid_Typ] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Bescheid] CHECK CONSTRAINT [FK_Bescheid_Bescheid_Typ]
GO
ALTER TABLE [dbo].[Bescheid]  WITH CHECK ADD  CONSTRAINT [FK_Bescheid_Einrichtung] FOREIGN KEY([Einrichtung])
REFERENCES [dbo].[Einrichtung] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Bescheid] CHECK CONSTRAINT [FK_Bescheid_Einrichtung]
GO
ALTER TABLE [dbo].[Bescheid]  WITH CHECK ADD  CONSTRAINT [FK_Bescheid_Leistungsart] FOREIGN KEY([Leistungsart])
REFERENCES [dbo].[Leistungsart] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Bescheid] CHECK CONSTRAINT [FK_Bescheid_Leistungsart]
GO
ALTER TABLE [dbo].[Bescheid]  WITH CHECK ADD  CONSTRAINT [FK_Bescheid_Teilnehmer] FOREIGN KEY([Teilnehmer])
REFERENCES [dbo].[Teilnehmer] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Bescheid] CHECK CONSTRAINT [FK_Bescheid_Teilnehmer]
GO
ALTER TABLE [dbo].[Leistungsart]  WITH CHECK ADD  CONSTRAINT [FK_Leistungsart_Einheit] FOREIGN KEY([Einheit])
REFERENCES [dbo].[Einheit] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Leistungsart] CHECK CONSTRAINT [FK_Leistungsart_Einheit]
GO
ALTER TABLE [dbo].[Planung]  WITH CHECK ADD  CONSTRAINT [FK_Planung_Einrichtung] FOREIGN KEY([Einrichtung])
REFERENCES [dbo].[Einrichtung] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Planung] CHECK CONSTRAINT [FK_Planung_Einrichtung]
GO
ALTER TABLE [dbo].[Planung]  WITH CHECK ADD  CONSTRAINT [FK_Planung_Leistungsart] FOREIGN KEY([Leistungsart])
REFERENCES [dbo].[Leistungsart] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Planung] CHECK CONSTRAINT [FK_Planung_Leistungsart]
GO
ALTER TABLE [dbo].[Praktikum]  WITH CHECK ADD  CONSTRAINT [FK_Praktikum_Einrichtung] FOREIGN KEY([Einrichtung])
REFERENCES [dbo].[Einrichtung] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Praktikum] CHECK CONSTRAINT [FK_Praktikum_Einrichtung]
GO
ALTER TABLE [dbo].[Praktikum]  WITH CHECK ADD  CONSTRAINT [FK_Praktikum_Praktikum_Kategorie] FOREIGN KEY([Kategorie])
REFERENCES [dbo].[Praktikum_Kategorie] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Praktikum] CHECK CONSTRAINT [FK_Praktikum_Praktikum_Kategorie]
GO
ALTER TABLE [dbo].[Praktikum]  WITH CHECK ADD  CONSTRAINT [FK_Praktikum_Standort] FOREIGN KEY([Standort])
REFERENCES [dbo].[Standort] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Praktikum] CHECK CONSTRAINT [FK_Praktikum_Standort]
GO
ALTER TABLE [dbo].[Praktikum]  WITH CHECK ADD  CONSTRAINT [FK_Praktikum_Teilnehmer] FOREIGN KEY([Teilnehmer])
REFERENCES [dbo].[Teilnehmer] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Praktikum] CHECK CONSTRAINT [FK_Praktikum_Teilnehmer]
GO
ALTER TABLE [dbo].[Standort]  WITH CHECK ADD  CONSTRAINT [FK_Standort_Standort_Bereich] FOREIGN KEY([Bereich])
REFERENCES [dbo].[Standort_Bereich] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Standort] CHECK CONSTRAINT [FK_Standort_Standort_Bereich]
GO
ALTER TABLE [dbo].[Verrechnungssatz]  WITH CHECK ADD  CONSTRAINT [FK_Verrechnungssatz_Kostensatz] FOREIGN KEY([Kostensatz])
REFERENCES [dbo].[Kostensatz] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Verrechnungssatz] CHECK CONSTRAINT [FK_Verrechnungssatz_Kostensatz]
GO
ALTER TABLE [dbo].[Verrechnungssatz]  WITH CHECK ADD  CONSTRAINT [FK_Verrechnungssatz_Leistungsart] FOREIGN KEY([Leistungsart])
REFERENCES [dbo].[Leistungsart] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Verrechnungssatz] CHECK CONSTRAINT [FK_Verrechnungssatz_Leistungsart]
GO
ALTER TABLE [dbo].[Zeitspanne]  WITH CHECK ADD  CONSTRAINT [FK_Zeitspanne_Einrichtung] FOREIGN KEY([Einrichtung])
REFERENCES [dbo].[Einrichtung] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Zeitspanne] CHECK CONSTRAINT [FK_Zeitspanne_Einrichtung]
GO
ALTER TABLE [dbo].[Zeitspanne]  WITH CHECK ADD  CONSTRAINT [FK_Zeitspanne_Teilnehmer] FOREIGN KEY([Teilnehmer])
REFERENCES [dbo].[Teilnehmer] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Zeitspanne] CHECK CONSTRAINT [FK_Zeitspanne_Teilnehmer]
GO
ALTER TABLE [dbo].[Zeitspanne]  WITH CHECK ADD  CONSTRAINT [FK_Zeitspanne_Zeitspanne_Austrittsgrund] FOREIGN KEY([Austrittsgrund])
REFERENCES [dbo].[Zeitspanne_Austrittsgrund] ([ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Zeitspanne] CHECK CONSTRAINT [FK_Zeitspanne_Zeitspanne_Austrittsgrund]
GO
USE [master]
GO
GRANT CONNECT TO [app]
GO
GRANT SUBSCRIBE QUERY NOTIFICATIONS TO [app]
GO
GRANT CONNECT TO [Integrationsassistenz]
GO
GRANT CONNECT TO [Leitung]
GO
GRANT CONNECT TO [Rechnungswesen]
GO
GRANT CONNECT TO [Sekretariat]
GO
GRANT CONNECT TO [Training]
GO
USE [Teilnehmer_innen]
GO
GRANT DELETE ON [dbo].[Abrechnung] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Abrechnung] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Abrechnung] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Abrechnung] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Anwesenheit] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Anwesenheit] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Anwesenheit] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Anwesenheit] TO [Sekretariat]
GO
GRANT DELETE ON [dbo].[Anwesenheit] TO [Training]
GO
GRANT INSERT ON [dbo].[Anwesenheit] TO [Training]
GO
GRANT SELECT ON [dbo].[Anwesenheit] TO [Training]
GO
GRANT UPDATE ON [dbo].[Anwesenheit] TO [Training]
GO
GRANT SELECT ON [dbo].[Bescheid] TO [Leitung]
GO
GRANT SELECT ON [dbo].[Bescheid] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Bescheid] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Bescheid] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Bescheid] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Bescheid] TO [Sekretariat]
GO
GRANT DELETE ON [dbo].[Bescheid_Typ] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Bescheid_Typ] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Bescheid_Typ] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Bescheid_Typ] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Bescheid_Typ] ([ID]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Bescheid_Typ] ([Bezeichnung]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Bescheid_Typ] ([Version]) TO [Leitung]
GO
GRANT DELETE ON [dbo].[Einheit] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Einheit] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Einheit] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Einheit] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Einrichtung] TO [public]
GO
GRANT DELETE ON [dbo].[Feiertag] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Feiertag] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Feiertag] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Feiertag] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Feiertag] TO [Training]
GO
GRANT DELETE ON [dbo].[Kostensatz] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Kostensatz] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Kostensatz] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Kostensatz] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Leistungsart] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Leistungsart] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Leistungsart] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Leistungsart] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([ID]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([ID]) TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([Bezeichnung]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([Bezeichnung]) TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([Version]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Leistungsart] ([Version]) TO [Sekretariat]
GO
GRANT DELETE ON [dbo].[Planung] TO [Leitung]
GO
GRANT INSERT ON [dbo].[Planung] TO [Leitung]
GO
GRANT SELECT ON [dbo].[Planung] TO [Leitung]
GO
GRANT UPDATE ON [dbo].[Planung] TO [Leitung]
GO
GRANT DELETE ON [dbo].[Planung] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Planung] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Planung] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Planung] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Praktikum] TO [Integrationsassistenz]
GO
GRANT INSERT ON [dbo].[Praktikum] TO [Integrationsassistenz]
GO
GRANT SELECT ON [dbo].[Praktikum] TO [Integrationsassistenz]
GO
GRANT UPDATE ON [dbo].[Praktikum] TO [Integrationsassistenz]
GO
GRANT SELECT ON [dbo].[Praktikum_Kategorie] TO [Integrationsassistenz]
GO
GRANT DELETE ON [dbo].[Praktikum_Kategorie] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Praktikum_Kategorie] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Praktikum_Kategorie] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Praktikum_Kategorie] TO [Sekretariat]
GO
GRANT DELETE ON [dbo].[Rechnung] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Rechnung] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Rechnung] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Rechnung] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Standort] TO [Integrationsassistenz]
GO
GRANT INSERT ON [dbo].[Standort] TO [Integrationsassistenz]
GO
GRANT SELECT ON [dbo].[Standort] TO [Integrationsassistenz]
GO
GRANT UPDATE ON [dbo].[Standort] TO [Integrationsassistenz]
GO
GRANT SELECT ON [dbo].[Standort_Bereich] TO [Integrationsassistenz]
GO
GRANT DELETE ON [dbo].[Standort_Bereich] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Standort_Bereich] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Standort_Bereich] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Standort_Bereich] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Teilnehmer] TO [Integrationsassistenz]
GO
GRANT SELECT ON [dbo].[Teilnehmer] TO [Leitung]
GO
GRANT SELECT ON [dbo].[Teilnehmer] TO [Rechnungswesen]
GO
GRANT DELETE ON [dbo].[Teilnehmer] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Teilnehmer] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Teilnehmer] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Teilnehmer] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Teilnehmer] TO [Training]
GO
GRANT DELETE ON [dbo].[Verrechnungssatz] TO [Rechnungswesen]
GO
GRANT INSERT ON [dbo].[Verrechnungssatz] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Verrechnungssatz] TO [Rechnungswesen]
GO
GRANT UPDATE ON [dbo].[Verrechnungssatz] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Version] TO [app]
GO
GRANT SELECT ON [dbo].[Zeitspanne] TO [Leitung]
GO
GRANT DELETE ON [dbo].[Zeitspanne] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Zeitspanne] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Zeitspanne] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Zeitspanne] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([ID]) TO [Training]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Einrichtung]) TO [Training]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Teilnehmer]) TO [Training]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Eintritt]) TO [Training]
GO
GRANT UPDATE ON [dbo].[Zeitspanne] ([Überprüft]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Überprüft]) TO [Training]
GO
GRANT UPDATE ON [dbo].[Zeitspanne] ([Austritt]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Austritt]) TO [Training]
GO
GRANT UPDATE ON [dbo].[Zeitspanne] ([Austrittsgrund]) TO [Leitung]
GO
GRANT UPDATE ON [dbo].[Zeitspanne] ([Austrittsnotiz]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Zeitspanne] ([Version]) TO [Training]
GO
GRANT DELETE ON [dbo].[Zeitspanne_Austrittsgrund] TO [Sekretariat]
GO
GRANT INSERT ON [dbo].[Zeitspanne_Austrittsgrund] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Zeitspanne_Austrittsgrund] TO [Sekretariat]
GO
GRANT UPDATE ON [dbo].[Zeitspanne_Austrittsgrund] TO [Sekretariat]
GO
GRANT SELECT ON [dbo].[Zeitspanne_Austrittsgrund] ([ID]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Zeitspanne_Austrittsgrund] ([Bezeichnung]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Zeitspanne_Austrittsgrund] ([Version]) TO [Leitung]
GO
GRANT SELECT ON [dbo].[Druckform] TO [Rechnungswesen]
GO
GRANT SELECT ON [dbo].[Tagsatzplanung] TO [Rechnungswesen]
GO
GRANT EXECUTE ON [dbo].[DownloadRechnung] TO [Rechnungswesen]
GO
GRANT EXECUTE ON [dbo].[ErstelleRechnung] TO [Rechnungswesen]
GO
GRANT EXECUTE ON [dbo].[ÜberprüfeRechnung] TO [Rechnungswesen]
GO
