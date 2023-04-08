CREATE DATABASE CampeonatoAmador
GO
USE CampeonatoAmador
GO

CREATE TABLE [Time] (
    [Nome] VARCHAR(50) NOT NULL,
    [Apelido] VARCHAR(30) NOT NULL,
    [Data_Criacao] DATETIME NOT NULL,

    CONSTRAINT PK_Time PRIMARY KEY ([Nome])
)

CREATE TABLE [Classificacao] (
    [Nome_Time] VARCHAR(50) NOT NULL,
    [Pontuacao] INT NOT NULL DEFAULT(0),
    [Total_Gols] INT NOT NULL DEFAULT (0),
    [Total_Gols_Sofridos] INT NOT NULL DEFAULT (0),
    [Saldo_Gols] INT NOT NULL DEFAULT(0),
    [Vitorias] INT NOT NULL DEFAULT (0),
    [Derrotas] INT NOT NULL DEFAULT(0),
    [Empates] INT NOT NULL DEFAULT(0),
    
    CONSTRAINT PK_Classificacao PRIMARY KEY ([Nome_Time]),
    CONSTRAINT FK_Classificacao_Time FOREIGN KEY ([Nome_Time]) REFERENCES [Time] ([Nome])
)

CREATE TABLE [Partida] (
    [Time_Casa] VARCHAR(50) NOT NULL,
    [Time_Visitante] VARCHAR(50) NOT NULL,
    [Gols] INT NOT NULL,
    [Gols_Sofridos] INT NOT NULL

    CONSTRAINT PK_Partida PRIMARY KEY ([Time_Casa], [Time_Visitante]),
    CONSTRAINT FK_Partida_Time_Casa FOREIGN KEY ([Time_Casa]) REFERENCES [Time]([Nome]),
    CONSTRAINT FK_Partida_Time_Visitante FOREIGN KEY ([Time_Visitante]) REFERENCES [Time]([Nome])
)