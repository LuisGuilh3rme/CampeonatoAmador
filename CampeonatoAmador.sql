CREATE DATABASE CampeonatoAmador
GO
USE CampeonatoAmador
GO

-- Tabelas
CREATE TABLE [Time] (
    [Nome] VARCHAR(50) NOT NULL,
    [Apelido] VARCHAR(30) NOT NULL,
    [Data_Criacao] CHAR(10) NOT NULL,

    CONSTRAINT PK_Time PRIMARY KEY ([Nome])
)
GO

CREATE TABLE [Classificacao] (
    [Nome_Time] VARCHAR(50) NOT NULL,
    [Pontuacao] INT NOT NULL DEFAULT(0),
    [Total_Gols] INT NOT NULL DEFAULT (0),
    [Total_Gols_Sofridos] INT NOT NULL DEFAULT (0),
    [Saldo_Gols] INT NOT NULL DEFAULT(0),
    [Vitorias] INT NOT NULL DEFAULT (0),
    [Empates] INT NOT NULL DEFAULT(0),
    
    CONSTRAINT PK_Classificacao PRIMARY KEY ([Nome_Time]),
    CONSTRAINT FK_Classificacao_Time FOREIGN KEY ([Nome_Time]) REFERENCES [Time] ([Nome])
)
GO

CREATE TABLE [Partida] (
    [Numero_Partida] INT IDENTITY,
    [Time_Casa] VARCHAR(50) NOT NULL,
    [Time_Visitante] VARCHAR(50) NOT NULL,
    [Gols] INT NOT NULL,
    [Gols_Sofridos] INT NOT NULL

    CONSTRAINT PK_Partida PRIMARY KEY ([Time_Casa], [Time_Visitante]),
    CONSTRAINT FK_Partida_Time_Casa FOREIGN KEY ([Time_Casa]) REFERENCES [Time]([Nome]),
    CONSTRAINT FK_Partida_Time_Visitante FOREIGN KEY ([Time_Visitante]) REFERENCES [Time]([Nome])
)
GO

-- Triggers
CREATE TRIGGER TGR_Insercao_Time ON [Time] AFTER INSERT AS
    BEGIN
        DECLARE @Time VARCHAR(50)

        SELECT @Time = [Nome] FROM INSERTED

        INSERT INTO [Classificacao] ([Nome_Time]) VALUES (@Time)
    END
GO

CREATE OR ALTER TRIGGER TGR_Partida_Insert ON [Partida] AFTER INSERT AS 
    BEGIN
    
        DECLARE @Casa VARCHAR(50), @Visitante VARCHAR(50), @Gols_Casa INT, @Gols_Visitante INT

        SELECT @Casa = [Time_Casa], @Visitante = [Time_Visitante], @Gols_Casa = [Gols], @Gols_Visitante = [Gols_Sofridos] FROM INSERTED

        EXEC.Alterar_Classificacao @Casa, @Gols_Casa, @Gols_Visitante, 'Casa', 'Inserir'
        EXEC.Alterar_Classificacao @Visitante, @Gols_Visitante, @Gols_Casa, 'Visitante', 'Inserir'
    END
GO

CREATE OR ALTER TRIGGER TGR_Partida_Delete ON [Partida] AFTER DELETE AS 
    BEGIN
        DECLARE @Casa VARCHAR(50), @Visitante VARCHAR(50), @Gols_Casa INT, @Gols_Visitante INT

        SELECT @Casa = [Time_Casa], @Visitante = [Time_Visitante], @Gols_Casa = [Gols] * -1, @Gols_Visitante = [Gols_Sofridos] * -1 FROM DELETED
        
        IF ((SELECT COUNT(*) FROM [Partida]) = 0) EXEC.Zerar_Classificacao

        ELSE
            BEGIN
                EXEC.Alterar_Classificacao @Casa, @Gols_Casa, @Gols_Visitante, 'Casa', 'Remover'
                EXEC.Alterar_Classificacao @Visitante, @Gols_Visitante, @Gols_Casa, 'Visitante', 'Remover'
            END
    END
GO

-- Procedures
CREATE OR ALTER PROC Alterar_Classificacao @Time VARCHAR(50), @Gols INT, @Gols_Sofridos INT, @Lado VARCHAR(9), @Situacao CHAR(7) AS
    BEGIN
        DECLARE @Pontuacao INT, @Saldo_Gols INT

        SET @Saldo_Gols = @Gols - @Gols_Sofridos
        
        -- Contabilizando gols
        UPDATE [Classificacao] SET [Total_Gols] = [Total_Gols] + @Gols, [Total_Gols_Sofridos] = [Total_Gols_Sofridos] + @Gols_Sofridos, [Saldo_Gols] = [Saldo_Gols] + @Saldo_Gols WHERE [Nome_Time] = @Time

        -- Verificando empate ou vitoria
        IF (@Gols > @Gols_Sofridos AND @Situacao = 'Inserir')
            UPDATE [Classificacao] SET [Vitorias] = [Vitorias] + 1 WHERE [Nome_Time] = @Time
        ELSE IF (@Gols = @Gols_Sofridos AND @Situacao = 'Inserir')
            UPDATE [Classificacao] SET [Empates] = [Empates] + 1 WHERE [Nome_Time] = @Time

        ELSE IF (@Gols < @Gols_Sofridos AND @Situacao = 'Remover')
            UPDATE [Classificacao] SET [Vitorias] = [Vitorias] - 1 WHERE [Nome_Time] = @Time
        ELSE IF (@Gols = @Gols_Sofridos AND @Situacao = 'Remover')
            UPDATE [Classificacao] SET [Empates] = [Empates] - 1 WHERE [Nome_Time] = @Time

        -- Calculando Pontuacao
        SET @Pontuacao = CASE
            WHEN @Saldo_Gols = 0 THEN 1
            WHEN @Gols > @Gols_Sofridos AND @Lado = 'Casa' THEN 3
            WHEN @Gols > @Gols_Sofridos AND @Lado = 'Visitante' THEN 5
            ELSE 0
        END

        IF (@Situacao = 'Remover') SET @Pontuacao = CASE
            WHEN @Gols < @Gols_Sofridos AND @Lado = 'Casa' THEN -3
            WHEN @Gols < @Gols_Sofridos AND @Lado = 'Visitante' THEN -5
            ELSE @Pontuacao * -1
        END  

        UPDATE [Classificacao] SET [Pontuacao] = [Pontuacao] + @Pontuacao WHERE [Nome_Time] = @Time
    END
GO

CREATE OR ALTER PROC Criar_Time @Nome VARCHAR(50), @Apelido VARCHAR(30), @Data_Criacao char(10) AS
    BEGIN
        INSERT INTO [Time] ([Nome], [Apelido], [Data_Criacao]) VALUES (@Nome, @Apelido, @Data_Criacao)
    END
GO

CREATE OR ALTER PROC Criar_Partida @Casa VARCHAR(50), @Visitante VARCHAR(50), @Gols INT, @Gols_Sofridos INT AS
    BEGIN
    DECLARE @Count INT
    SET @Count = (SELECT COUNT(*) FROM [Partida]) + 1

    SET IDENTITY_INSERT [Partida] ON
    INSERT INTO [Partida] ([Numero_Partida], [Time_Casa], [Time_Visitante], [Gols], [Gols_Sofridos]) VALUES (@Count, @Casa, @Visitante, @Gols, @Gols_Sofridos)
    SET IDENTITY_INSERT [Partida] OFF

    END
GO

CREATE OR ALTER PROC Zerar_Classificacao AS
    BEGIN
        UPDATE [Classificacao] SET [Pontuacao] = 0, [Total_Gols] = 0, [Total_Gols_Sofridos] = 0, [Saldo_Gols] = 0, [Vitorias] = 0, [Empates] = 0
    END
GO


CREATE OR ALTER PROC Partida_Maior_Gols_Times AS
    BEGIN
        WITH Max_Gols_Visitantes AS (
            SELECT [Time_Visitante] AS 'Time', MAX([Gols_Sofridos]) AS 'Gols' FROM [Partida] GROUP BY [Time_Visitante]
        ), Max_Gols_Casa AS
        (
            SELECT [Time_Casa] AS 'Time', MAX(Gols) AS 'Gols' FROM [Partida] GROUP BY [Time_Casa]
        ), Max_Gols_Duplicados AS (
            SELECT * FROM Max_Gols_Casa UNION ALL SELECT * FROM Max_Gols_Visitantes
        ) SELECT [Time], MAX([Gols]) AS 'Máximo de Gols' FROM Max_Gols_Duplicados GROUP BY [Time] ORDER BY 'Máximo de Gols' DESC
    END
GO

CREATE OR ALTER PROC Verificar_Campeao AS
    BEGIN
        DECLARE @Pontuacao INT, @Vitorias INT, @Saldo_Gols INT

        SELECT @Pontuacao = MAX([Pontuacao]) FROM [Classificacao]
        -- SELECT * FROM [Classificacao] WHERE [Pontuacao] = @Pontuacao
        SELECT @Vitorias = MAX([Vitorias]) FROM [Classificacao] WHERE [Pontuacao] = @Pontuacao
        -- SELECT * FROM [Classificacao] WHERE [Pontuacao] = @Pontuacao AND [Vitorias] = @Vitorias
        SELECT @Saldo_Gols = MAX([Saldo_Gols]) FROM [Classificacao] WHERE [Vitorias] = @Vitorias AND [Pontuacao] = @Pontuacao


        SELECT TOP 1 * FROM [Classificacao] WHERE [Pontuacao] = @Pontuacao AND [Vitorias] = @Vitorias AND [Saldo_Gols] = @Saldo_Gols
    END
GO

-- Inserts
EXEC.Criar_Time 'Galaticos', 'GL', '2023'
EXEC.Criar_Time 'Bunda Moles', 'Bundoes', '1990'
EXEC.Criar_Time 'Mafia Japonesa', 'Yakuza', '1903'
EXEC.Criar_Time 'Palmeiras', 'Mundial', '1914'
EXEC.Criar_Time 'Lorem Ipsum', 'Lorem', '1900'
GO

EXEC.Criar_Partida 'Galaticos', 'Bunda Moles', 1, 0
EXEC.Criar_Partida 'Galaticos', 'Mafia Japonesa', 1, 0
EXEC.Criar_Partida 'Galaticos', 'Palmeiras', 2, 0
EXEC.Criar_Partida 'Galaticos', 'Lorem Ipsum', 1, 0

EXEC.Criar_Partida 'Bunda Moles', 'Galaticos', 1, 0
EXEC.Criar_Partida 'Bunda Moles', 'Mafia Japonesa', 1, 0
EXEC.Criar_Partida 'Bunda Moles', 'Palmeiras', 1, 0
EXEC.Criar_Partida 'Bunda Moles', 'Lorem Ipsum', 1, 0

EXEC.Criar_Partida 'Mafia Japonesa', 'Galaticos', 1, 0
EXEC.Criar_Partida 'Mafia Japonesa', 'Bunda Moles', 1, 0
EXEC.Criar_Partida 'Mafia Japonesa', 'Palmeiras', 1, 0
EXEC.Criar_Partida 'Mafia Japonesa', 'Lorem Ipsum', 1, 0

EXEC.Criar_Partida 'Palmeiras', 'Galaticos', 0, 1
EXEC.Criar_Partida 'Palmeiras', 'Bunda Moles', 1, 0
EXEC.Criar_Partida 'Palmeiras', 'Mafia Japonesa', 1, 0
EXEC.Criar_Partida 'Palmeiras', 'Lorem Ipsum', 1, 0

EXEC.Criar_Partida 'Lorem Ipsum', 'Galaticos', 1, 1
EXEC.Criar_Partida 'Lorem Ipsum', 'Bunda Moles', 2, 2
EXEC.Criar_Partida 'Lorem Ipsum', 'Mafia Japonesa', 3, 4
EXEC.Criar_Partida 'Lorem Ipsum', 'Palmeiras', 1, 1
GO

-- Visualizacao
SELECT * FROM [Time]
SELECT * FROM [Classificacao] ORDER BY [Pontuacao] DESC
SELECT * FROM [Partida] ORDER BY [Numero_Partida] ASC
DELETE FROM [Partida]

-- Quem é o campeão no final do campeonato?
EXEC.Verificar_Campeao

-- Como faremos para verificar os 5 primeiros times do campeonato?
SELECT TOP 5 * FROM [Classificacao] ORDER BY [Pontuacao] DESC
SELECT TOP 5 * FROM [Partida] ORDER BY [Numero_Partida] ASC

-- Quem é o time que mais fez gols no campeonato?
SELECT TOP 1 [Nome_Time], Total_Gols AS 'Gols' FROM [Classificacao] ORDER BY [Total_Gols] DESC

-- Quem é que tomou mais gols no campeonato?
SELECT TOP 1 [Nome_Time], Total_Gols_Sofridos AS 'Gols Sofridos' FROM [Classificacao] ORDER BY [Total_Gols_Sofridos] DESC

-- Qual é o jogo que teve mais gols?
SELECT TOP 1 Numero_Partida, Time_Casa, Time_Visitante, MAX(Gols + Gols_Sofridos) AS 'Total Gols' FROM [Partida] GROUP BY Numero_Partida, Time_Casa, Time_Visitante ORDER BY 4 DESC

-- Qual é o maior número de gols que cada time fez em um único jogo?
EXEC.Partida_Maior_Gols_Times