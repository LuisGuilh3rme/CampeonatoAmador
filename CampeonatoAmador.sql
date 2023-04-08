CREATE DATABASE CampeonatoAmador
GO
USE CampeonatoAmador
GO

-- Tabelas
CREATE TABLE [Time] (
    [Nome] VARCHAR(50) NOT NULL,
    [Apelido] VARCHAR(30) NOT NULL,
    [Data_Criacao] DATETIME NOT NULL,

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

CREATE TRIGGER TGR_Partida_Insert ON [Partida] AFTER INSERT AS 
    BEGIN
        DECLARE @Casa VARCHAR(50), @Visitante VARCHAR(50), @Gols_Casa INT, @Gols_Visitante INT

        SELECT @Casa = [Time_Casa], @Visitante = [Time_Visitante], @Gols_Casa = [Gols], @Gols_Visitante = [Gols_Sofridos] FROM INSERTED

        EXEC.Alterar_Classificacao @Casa, @Gols_Casa, @Gols_Visitante, 'Casa'
        EXEC.Alterar_Classificacao @Visitante, @Gols_Visitante, @Gols_Casa, 'Visitante'
    END
GO

-- Procedures
CREATE OR ALTER PROC Alterar_Classificacao @Time VARCHAR(50), @Gols INT, @Gols_Sofridos INT, @Lado VARCHAR(9) AS
    BEGIN
        DECLARE @Pontuacao INT

        -- Contabilizando gols
        UPDATE [Classificacao] SET [Total_Gols] = [Total_Gols] + @Gols, [Total_Gols_Sofridos] = [Total_Gols_Sofridos] + @Gols_Sofridos, [Saldo_Gols] = [Saldo_Gols] + (@Gols - @Gols_Sofridos) WHERE [Nome_Time] = @Time

        -- Verificando empate ou vitoria
        IF (@Gols > @Gols_Sofridos)
            UPDATE [Classificacao] SET [Vitorias] = [Vitorias] + 1 WHERE [Nome_Time] = @Time
        IF (@Gols = @Gols_Sofridos)
            UPDATE [Classificacao] SET [Empates] = [Empates] + 1 WHERE [Nome_Time] = @Time

        -- Calculando Pontuacao
        SET @Pontuacao = CASE 
            WHEN @Gols = @Gols_Sofridos THEN 1
            WHEN @Gols > @Gols_Sofridos AND @Lado = 'Casa' THEN 3
            WHEN @Gols > @Gols_Sofridos AND @Lado = 'Visitante' THEN 5
            ELSE 0
        END

        UPDATE [Classificacao] SET [Pontuacao] = [Pontuacao] + @Pontuacao WHERE [Nome_Time] = @Time
    END
GO