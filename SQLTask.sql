CREATE DATABASE BankDb
GO

USE BankDb
GO

CREATE TABLE Bank
(
	Id INT PRIMARY KEY IDENTITY,
	BankName NVARCHAR(32) UNIQUE NOT NULL
)
CREATE TABLE City
(
	Id INT PRIMARY KEY IDENTITY,
	CityName NVARCHAR(32) NOT NULL
)
CREATE TABLE BranchOffice
(
	Id INT PRIMARY KEY IDENTITY,
	BranchOfficeName NVARCHAR(32) UNIQUE NOT NULL,
	BankId INT REFERENCES Bank (Id) NOT NULL,
	CityId INT REFERENCES City (Id) NOT NULL
)
CREATE TABLE SocialStatus
(
	Id INT PRIMARY KEY IDENTITY,
	SocialStatusName NVARCHAR(32) UNIQUE NOT NULL,
)
CREATE TABLE Person
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(32) NOT NULL,
	LastName NVARCHAR(32) NOT NULL,
	SocialStatusId INT REFERENCES SocialStatus (Id) NOT NULL
)
CREATE TABLE Account
(
	Id INT PRIMARY KEY IDENTITY,
	AccountName NVARCHAR(32) UNIQUE NOT NULL,
	Balance Money NOT NULL DEFAULT 0,
	PersonId INT REFERENCES Person (Id) NOT NULL,
	BankId INT REFERENCES Bank (Id) NOT NULL
)
CREATE TABLE Cards
(
	Id INT PRIMARY KEY IDENTITY,
	CardName NVARCHAR(32) NOT NULL,
	Balance Money NOT NULL DEFAULT 0,
	AccountId INT REFERENCES Account (Id) NOT NULL
)


INSERT Bank
VALUES
('Priorbank'),
('MTB'),
('Alphabank'),
('Belinvestbank'),
('BNB'),
('VTB')


INSERT City
VALUES
('Minsk'),
('Vitebsk'),
('Mogilev'),
('Gomel'),
('Brest'),
('Grodno')


INSERT BranchOffice
VALUES
('PriorMinsk',1,1),
('MTBMinsk',2,1),
('AlphaMinsk',3,1),
('BelinvestMinsk',4,1),
('BNBMinsk',5,1),
('VTBMinsk',6,1),
('MTBGomel',2,4),
('BelinvestGomel',4,4),
('BNBVitebsk',5,2),
('VTBMogilev',6,3),
('PriorBrest',1,5)


INSERT SocialStatus
VALUES
('Student'),
('Worker'),
('Pensioner'),
('Invalid'),
('Businessman')


INSERT Person
VALUES
('Ivan','Ivanov',3),
('John','Johnson',5),
('Vasiliy','Smirnov',2),
('Stepan','Fedorovich',1),
('Vladislav','Kuznetsov',1)


INSERT Account
VALUES
('Ivan1950',50,1,2),
('JONH5',400,2,1),
('VasSmir',100,3,6),
('SF2',200,4,3),
('Vlad2002',80,5,4)


INSERT Cards
VALUES
('Simple VISA',20,1),
('Simple Mastercard',15,1),
('Premium VISA',400,2),
('Gold Mastercard',70,3),
('Classic VISA',190,4),
('Classic Mastercard',30,5)

--TASKS
--1
DECLARE @CityName NVARCHAR(32) = 'Minsk'

SELECT DISTINCT BankName
FROM BranchOffice 
	INNER JOIN Bank ON BranchOffice.BankId=Bank.Id 
	INNER JOIN City ON City.Id=BranchOffice.CityId
WHERE City.CityName=@CityName
--2
SELECT Person.FirstName,Cards.Balance,Bank.BankName,Cards.CardName
FROM Person 
	INNER JOIN Account ON Person.Id=Account.Id
	INNER JOIN Cards ON Cards.AccountId=Account.Id
	INNER JOIN Bank ON Bank.Id=Account.BankId
--3
SELECT Account.AccountName,Account.Balance-SUM(Cards.Balance) AS 'Difference'
FROM Cards 
	INNER JOIN Account ON Cards.AccountId=Account.Id
GROUP BY Account.AccountName,Account.Balance
HAVING Account.Balance-SUM(Cards.Balance)!=0
--4

--GROUP BY
SELECT SocialStatus.SocialStatusName,COUNT(Person.SocialStatusId) AS 'Number of cards'
FROM Account 
	INNER JOIN Person ON Account.PersonId=Person.Id
	INNER JOIN Cards ON Cards.AccountId=Account.Id
	RIGHT JOIN SocialStatus ON SocialStatus.Id=Person.SocialStatusId
GROUP BY SocialStatus.SocialStatusName


--Subquery
SELECT SocialStatus.SocialStatusName,
(SELECT COUNT(*)
FROM Person,Account,Cards 
WHERE Person.SocialStatusId = SocialStatus.Id 
	AND Cards.AccountId=Account.Id 
	AND Account.PersonId=Person.Id) AS 'Number of cards'
FROM SocialStatus


--5
GO
CREATE PROCEDURE Add10$
    @SocialStatusId INT
AS
IF EXISTS 
(SELECT * 
FROM Account,Person 
WHERE Account.PersonId=Person.Id 
	AND Person.SocialStatusId=@SocialStatusId)
BEGIN
	UPDATE Account
	SET Balance=Balance+10
	FROM Account,Person
	WHERE Account.PersonId=Person.Id 
		AND @SocialStatusId=Person.SocialStatusId
END
ELSE
BEGIN
	IF EXISTS (SELECT * 
	FROM SocialStatus 
	WHERE SocialStatus.Id=@SocialStatusId)
	BEGIN
		PRINT 'Social status Id'+CONVERT(NVARCHAR,@SocialStatusId)+' not use'
	END
	ELSE
	BEGIN
		PRINT 'Social status Id'+CONVERT(NVARCHAR,@SocialStatusId)+' not found'
	END
END
GO


DECLARE @SocialStatusId INT = 1

SELECT Person.FirstName,SocialStatus.SocialStatusName,Account.Balance
FROM Account,Person,SocialStatus
WHERE Person.SocialStatusId = SocialStatus.Id 
	AND Account.PersonId=Person.Id 
	AND @SocialStatusId=SocialStatus.Id

EXEC Add10$ @SocialStatusId

SELECT Person.FirstName,SocialStatus.SocialStatusName,Account.Balance
FROM Account,Person,SocialStatus
WHERE Person.SocialStatusId = SocialStatus.Id 
	AND Account.PersonId=Person.Id 
	AND @SocialStatusId=SocialStatus.Id

--6
SELECT Person.FirstName,Account.Balance-SUM(Cards.Balance) AS 'Available money'
FROM Cards 
	INNER JOIN Account ON Cards.AccountId=Account.Id 
	INNER JOIN Person ON Person.Id=Account.PersonId
GROUP BY Account.AccountName,Person.FirstName,Account.Balance
--7
GO
CREATE PROCEDURE AddMoneyCard
@AccountId INT,
@CardId INT,
@Money MONEY
AS
BEGIN TRANSACTION
	UPDATE Cards
	SET Balance=Cards.Balance+@Money
	FROM Account,Cards
	WHERE Account.Id=Cards.AccountId 
		AND Account.Id=@AccountId 
		AND Cards.Id=@CardId
	IF 0 > (SELECT Account.Balance-SUM(Cards.Balance)
	FROM Cards
		INNER JOIN Account ON Cards.AccountId=Account.Id
	WHERE Account.Id=@AccountId
	GROUP BY Account.AccountName,Account.Balance)
	BEGIN
		ROLLBACK TRANSACTION
	END
	ELSE
COMMIT TRANSACTION
GO


DECLARE @AccountId INT = 1
DECLARE @CardId INT = 1
DECLARE @Money MONEY = 15


SELECT Person.FirstName,Cards.Balance AS 'Card balance',CardName,Account.Balance AS 'Account Balance'
FROM Person 
	INNER JOIN Account ON Person.Id=Account.Id 
	INNER JOIN Cards ON Cards.AccountId=Account.Id 
	INNER JOIN Bank ON Bank.Id=Account.BankId
WHERE Account.Id=@AccountId

EXEC AddMoneyCard @AccountId,@CardId,@Money

SELECT Person.FirstName,Cards.Balance AS 'Card balance',CardName,Account.Balance AS 'Account Balance'
FROM Person 
	INNER JOIN Account ON Person.Id=Account.Id 
	INNER JOIN Cards ON Cards.AccountId=Account.Id 
	INNER JOIN Bank ON Bank.Id=Account.BankId
WHERE Account.Id=@AccountId

EXEC AddMoneyCard @AccountId,@CardId,@Money

SELECT Person.FirstName,Cards.Balance AS 'Card balance',CardName,Account.Balance AS 'Account Balance'
FROM Person 
	INNER JOIN Account ON Person.Id=Account.Id 
	INNER JOIN Cards ON Cards.AccountId=Account.Id 
	INNER JOIN Bank ON Bank.Id=Account.BankId
WHERE Account.Id=@AccountId

--8
GO
CREATE TRIGGER Account_Balance_Update
ON Account
AFTER UPDATE
AS IF UPDATE (Balance)
BEGIN
	IF 0 > (SELECT Account.Balance-SUM(Cards.Balance)
		FROM Cards 
			INNER JOIN Account ON Cards.AccountId=Account.Id
		WHERE Account.Id=(SELECT Id 
			FROM deleted)
		GROUP BY Account.AccountName,Account.Balance
	)
	BEGIN
		PRINT('Balance cards more than balance account')
		ROLLBACK TRANSACTION
	END
END
GO

CREATE TRIGGER Cards_Balance_Update
ON Cards
AFTER UPDATE
AS IF UPDATE (Balance)
BEGIN
	IF 0 > (SELECT Account.Balance-SUM(Cards.Balance)
		FROM Cards 
			INNER JOIN Account ON Cards.AccountId=Account.Id
		WHERE Account.Id=(SELECT AccountId 
			FROM deleted)
		GROUP BY Account.AccountName,Account.Balance
	)
	BEGIN
		PRINT('Balance cards more than balance account')
		ROLLBACK TRANSACTION
	END
END
GO



--DECLARE @AccountId INT = 1
--DECLARE @CardId INT = 1
--DEClARE @Money MONEY = 100


--SELECT *
--FROM Account
--WHERE Account.Id=@AccountId

--SELECT *
--FROM Cards
--WHERE Cards.AccountId=@AccountId

--UPDATE Account
--SET Balance=Balance-@Money
--WHERE Id = @AccountId

--UPDATE Cards
--SET Balance=Balance+@Money
--WHERE Id = @CardId


--SELECT *
--FROM Account
--WHERE Account.Id=@AccountId

--SELECT *
--FROM Cards
--WHERE Cards.AccountId=@AccountId