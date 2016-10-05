-- Importare T_Tempi e T_Atleti

/* ContradaAtletaPartecipazioni */

DROP VIEW IF EXISTS ContradaAtletaPartecipazioniView;

CREATE VIEW ContradaAtletaPartecipazioniView
AS
SELECT T.Contrada,
	A.Cognome,
	A.Nome,
	COUNT(DISTINCT T.Anno) AS NumeroPartecipazioni,
	MIN(T.TempoDescrizione) AS MigliorTempo
FROM T_Tempi T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
LEFT JOIN T_Tempi T2 ON T.Anno = T2.Anno AND T.PKAtleta = T2.PKAtleta AND T.Contrada > T2.Contrada
WHERE T2.PKAtleta IS NULL
GROUP BY T.Contrada,
	A.Cognome,
	A.Nome
ORDER BY T.Contrada,
	NumeroPartecipazioni DESC,
	A.Cognome,
	A.Nome;

SELECT * FROM ContradaAtletaPartecipazioniView WHERE Contrada = 'MOLINO';

/* SessoTempi */

DROP VIEW IF EXISTS SessoTempiView;

CREATE VIEW SessoTempiView
AS
SELECT
	A.Sesso,
	T.Anno,
	T.Contrada,
	T.Pettorale,
	A.Cognome,
	A.Nome,
	T.TempoDescrizione AS Tempo
FROM T_Tempi T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
ORDER BY A.Sesso,
	T.TempoSecondi,
	T.Anno,
	T.Pettorale;

SELECT * FROM SessoTempiView WHERE Sesso = 'M' LIMIT 100;

/* Tempi */

DROP VIEW IF EXISTS TempiView;

CREATE VIEW TempiView
AS
SELECT T.Anno,
	T.Contrada,
	T.Pettorale,
	A.Cognome,
	A.Nome,
	A.Sesso,
	T.TempoSecondi,
	T.TempoDescrizione
FROM T_Tempi T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
ORDER BY T.Anno,
	T.Contrada,
	T.Pettorale;

SELECT * FROM TempiView;

/* TempiFull */

DROP VIEW IF EXISTS TempiFullView;

CREATE VIEW TempiFullView
AS
SELECT TV.Anno,
	TV.Contrada,
	TV.Pettorale,
	TV.Cognome,
	TV.Nome,
	TV.Sesso,
	TV.TempoDescrizione AS Tempo,
	CONCAT(
		CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
	) AS TempoCumulato
FROM TempiView TV
INNER JOIN T_Tempi T ON TV.Anno = T.Anno AND TV.Contrada = T.Contrada AND TV.Pettorale >= T.Pettorale
GROUP BY TV.Anno,
	TV.Contrada,
	TV.Pettorale,
	TV.Cognome,
	TV.Nome,
	TV.Sesso,
	TV.TempoSecondi,
	TV.TempoDescrizione
ORDER BY TV.Anno,
	TV.Contrada,
	TV.Pettorale;

SELECT * FROM TempiFullView WHERE Anno = 2016;

/* AnnoContradaTempoTotale */

DROP VIEW IF EXISTS AnnoContradaTempoTotaleView;

CREATE VIEW AnnoContradaTempoTotaleView
AS
SELECT TV.Anno,
	TV.Contrada,
	SUM(TV.TempoSecondi) AS TempoTotaleSecondi,
	CONCAT(
		CASE WHEN SUM(TV.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(TV.TempoSecondi) / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN SUM(TV.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(TV.TempoSecondi) / 60) - 60 * FLOOR(SUM(TV.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(SUM(TV.TempoSecondi)) - 60 * FLOOR(SUM(TV.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((SUM(TV.TempoSecondi) - FLOOR(SUM(TV.TempoSecondi))) * 100)), 2)
	) AS TempoDescrizione
FROM TempiView TV
GROUP BY TV.Anno,
	TV.Contrada
ORDER BY TV.Anno,
	SUM(TV.TempoSecondi);

SELECT * FROM AnnoContradaTempoTotaleView;

/* AnnoContradaPiazzamentoTempo */

DROP TABLE IF EXISTS AnnoContradaPiazzamentoTempo;

SET @anno := 0;
SET @num := 1;

CREATE TABLE AnnoContradaPiazzamentoTempo
AS
SELECT Anno,
	Contrada,
	@num := if (@anno = Anno, @num + 1, 1) AS Piazzamento,
	@anno := Anno AS dummy,
	TempoTotaleSecondi,
	CONCAT(
		CASE WHEN TempoTotaleSecondi >= 3600 THEN CONCAT(FLOOR(TempoTotaleSecondi / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN TempoTotaleSecondi >= 600 THEN "0" ELSE "" END, FLOOR(TempoTotaleSecondi / 60) - 60 * FLOOR(TempoTotaleSecondi / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(TempoTotaleSecondi) - 60 * FLOOR(TempoTotaleSecondi / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((TempoTotaleSecondi - FLOOR(TempoTotaleSecondi)) * 100)), 2)
	) AS TempoTotaleDescrizione
FROM AnnoContradaTempoTotaleView
ORDER BY Anno,
	Piazzamento;

SELECT * FROM AnnoContradaPiazzamentoTempo;

/* SessoMiglioriTempi */

DROP TABLE IF EXISTS SessoMiglioriTempi;

CREATE TABLE SessoMiglioriTempi
AS
SELECT
	A.Sesso,
	A.Cognome,
	A.Nome,
	T.Anno,
	T.Contrada,
	T.Pettorale,
	T.TempoDescrizione
FROM (
	SELECT PKAtleta,
		@num := if(@num IS NULL, 1, if(@pkatleta = PKAtleta, @num + 1, 1)) AS rank,
		@pkatleta := PKAtleta AS dummy,
		Anno,
		Contrada,
		Pettorale,
		TempoSecondi,
		TempoDescrizione
	FROM T_Tempi
	ORDER BY PKAtleta,
		TempoSecondi
) T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
WHERE T.rank = 1
ORDER BY A.Sesso,
	T.TempoSecondi;

SELECT * FROM SessoMiglioriTempi;

/* AtletaTotalePartecipazioni */

DROP VIEW IF EXISTS AtletaTotalePartecipazioniView;

CREATE VIEW AtletaTotalePartecipazioniView
AS
SELECT
	CASE WHEN TCVMo.NumeroPartecipazioni IS NULL THEN 0 ELSE TCVMo.NumeroPartecipazioni END
		+ CASE WHEN TCVPi.NumeroPartecipazioni IS NULL THEN 0 ELSE TCVPi.NumeroPartecipazioni END
		+ CASE WHEN TCVPo.NumeroPartecipazioni IS NULL THEN 0 ELSE TCVPo.NumeroPartecipazioni END
		+ CASE WHEN TCVTo.NumeroPartecipazioni IS NULL THEN 0 ELSE TCVTo.NumeroPartecipazioni END
	AS NumeroPartecipazioni,
	A.Cognome,
	A.Nome,
	CONCAT(
	CASE WHEN TCVMo.NumeroPartecipazioni IS NULL THEN "" ELSE CONCAT(TCVMo.NumeroPartecipazioni, " Mo ") END
		, CASE WHEN TCVPi.NumeroPartecipazioni IS NULL THEN "" ELSE CONCAT(TCVPi.NumeroPartecipazioni, " Pi ") END
		, CASE WHEN TCVPo.NumeroPartecipazioni IS NULL THEN "" ELSE CONCAT(TCVPo.NumeroPartecipazioni, " Po ") END
		, CASE WHEN TCVTo.NumeroPartecipazioni IS NULL THEN "" ELSE CONCAT(TCVTo.NumeroPartecipazioni, " To ") END
	) AS DistribuzioneContrade
FROM T_Atleti A
LEFT JOIN ContradaAtletaPartecipazioniView TCVMo ON A.Cognome = TCVMo.Cognome AND A.Nome = TCVMo.Nome AND TCVMo.Contrada = 'MOLINO'
LEFT JOIN ContradaAtletaPartecipazioniView TCVPi ON A.Cognome = TCVPi.Cognome AND A.Nome = TCVPi.Nome AND TCVPi.Contrada = 'PIAZZETTA'
LEFT JOIN ContradaAtletaPartecipazioniView TCVPo ON A.Cognome = TCVPo.Cognome AND A.Nome = TCVPo.Nome AND TCVPo.Contrada = 'PORTE'
LEFT JOIN ContradaAtletaPartecipazioniView TCVTo ON A.Cognome = TCVTo.Cognome AND A.Nome = TCVTo.Nome AND TCVTo.Contrada = 'TORRE'
ORDER BY NumeroPartecipazioni DESC,
	A.Cognome,
	A.Nome;

SELECT * FROM AtletaTotalePartecipazioniView;

/* Piazzamenti */

DROP TABLE IF EXISTS Piazzamenti;

SET @piazzamento := 1;
SET @last_anno := 0;

CREATE TABLE Piazzamenti
AS
SELECT
	TT.Anno,
	@piazzamento := CASE WHEN TT.Anno = @last_anno THEN @piazzamento + 1 ELSE 1 END AS Piazzamento,
	TT.Contrada,
	TT.TempoSecondi,
	TT.TempoDescrizione,
	@last_anno := TT.Anno AS dummy
FROM (
	SELECT
		T.Anno,
		T.Contrada,
		SUM(T.TempoSecondi) AS TempoSecondi,
		CONCAT(
			CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
			RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
			RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), """",
			RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
		) AS TempoDescrizione
	FROM T_Tempi T
	GROUP BY T.Anno,
		T.Contrada
) TT
ORDER BY TT.Anno,
	TT.TempoSecondi;

SELECT * FROM Piazzamenti;

/* PiazzamentiTotali */

DROP VIEW IF EXISTS PiazzamentiTotaliView;

CREATE VIEW PiazzamentiTotaliView
AS
SELECT Contrada,
	SUM(CASE WHEN Piazzamento = 1 THEN 1 ELSE 0 END) AS 1o,
	SUM(CASE WHEN Piazzamento = 2 THEN 1 ELSE 0 END) AS 2o,
	SUM(CASE WHEN Piazzamento = 3 THEN 1 ELSE 0 END) AS 3o,
	SUM(CASE WHEN Piazzamento = 4 THEN 1 ELSE 0 END) AS 4o
FROM Piazzamenti
GROUP BY Contrada
ORDER BY 1o DESC, 2o DESC, 3o DESC, 4o DESC;

SELECT * FROM PiazzamentiTotaliView;

/* Punteggi */

DROP VIEW IF EXISTS PunteggiView;

CREATE VIEW PunteggiView
AS
SELECT Contrada,
	SUM(5 - Piazzamento) AS Punti
FROM Piazzamenti
GROUP BY Contrada
ORDER BY Punti DESC, Contrada;

SELECT * FROM PunteggiView;

/* ContradaTempoTotale */

DROP VIEW IF EXISTS ContradaTempoTotaleView;

CREATE VIEW ContradaTempoTotaleView
AS
SELECT
	Contrada,
	SUM(T.TempoSecondi) AS TempoSecondi,
	CONCAT(
			CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
			RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
			RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), """",
			RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
	) AS TempoDescrizione
FROM T_Tempi T
GROUP BY Contrada
ORDER BY TempoSecondi;

SELECT * FROM ContradaTempoTotaleView;

/* TempoTotale */

DROP VIEW IF EXISTS TempoTotaleView;

CREATE VIEW TempoTotaleView
AS
SELECT
	80 * COUNT(DISTINCT Anno) AS KmTotali,
	SUM(T.TempoSecondi) AS TempoSecondi,
	CONCAT(
			CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
			RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
			RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), """",
			RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
	) AS TempoDescrizione
FROM T_Tempi T;

SELECT * FROM TempoTotaleView;

/* ContradaMigliorTempo */

DROP TABLE IF EXISTS ContradaMigliorTempo;

CREATE TABLE ContradaMigliorTempo
AS
SELECT
	P.Contrada,
	P.Anno,
	P.TempoDescrizione,
	P.Piazzamento
FROM (
	SELECT Contrada,
		@num := if(@num IS NULL, 1, if(@contrada = Contrada, @num + 1, 1)) AS rank,
		@contrada := Contrada AS dummy,
		Anno,
		TempoSecondi,
		TempoDescrizione,
		Piazzamento
	FROM Piazzamenti
	ORDER BY Contrada, TempoSecondi
) P
WHERE P.rank = 1
ORDER BY P.TempoSecondi;

SELECT * FROM ContradaMigliorTempo;

/* PiazzamentiUomini */

DROP TABLE IF EXISTS PiazzamentiUomini;

SET @piazzamento := 1;
SET @last_anno := 0;

CREATE TABLE PiazzamentiUomini
AS
SELECT
	TT.Anno,
	@piazzamento := CASE WHEN TT.Anno = @last_anno THEN @piazzamento + 1 ELSE 1 END AS Piazzamento,
	TT.Contrada,
	TT.TempoSecondi,
	TT.TempoDescrizione,
	@last_anno := TT.Anno AS dummy
FROM (
	SELECT
		T.Anno,
		T.Contrada,
		SUM(T.TempoSecondi) AS TempoSecondi,
		CONCAT(
			CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
			RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
			RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), """",
			RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
		) AS TempoDescrizione
	FROM T_Tempi T
	INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta AND A.Sesso = 'M'
	GROUP BY T.Anno,
		T.Contrada
) TT
ORDER BY TT.Anno,
	TT.TempoSecondi;

SELECT * FROM PiazzamentiUomini;

/* ContradaMigliorPiazzamentoUomini */

DROP TABLE IF EXISTS ContradaMigliorPiazzamentoUomini;

CREATE TABLE ContradaMigliorPiazzamentoUomini
AS
SELECT
	P.Contrada,
	P.Anno,
	P.TempoDescrizione,
	P.Piazzamento
FROM (
	SELECT PU.Contrada,
		@num := if(@num IS NULL, 1, if(@contrada = PU.Contrada, @num + 1, 1)) AS rank,
		@contrada := PU.Contrada AS dummy,
		PU.Anno,
		PU.TempoSecondi,
		PU.TempoDescrizione,
		PU.Piazzamento
	FROM PiazzamentiUomini PU
	LEFT JOIN (
		SELECT
			T.Contrada,
			T.Anno
		
		FROM T_Tempi T
		INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
		GROUP BY T.Contrada,
			T.Anno
		HAVING SUM(CASE WHEN A.Sesso = 'M' THEN 1 ELSE 0 END) != 15
	) Anomalie ON PU.Contrada = Anomalie.Contrada AND PU.Anno = Anomalie.Anno
	WHERE Anomalie.Contrada IS NULL
	ORDER BY PU.Contrada, PU.TempoSecondi
) P
LEFT JOIN (
	SELECT
		T.Contrada,
		T.Anno
	
	FROM T_Tempi T
	INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
	GROUP BY T.Contrada,
		T.Anno
	HAVING SUM(CASE WHEN A.Sesso = 'M' THEN 1 ELSE 0 END) != 15
) Anomalie ON P.Contrada = Anomalie.Contrada AND P.Anno = Anomalie.Anno
WHERE P.rank = 1
ORDER BY P.TempoSecondi;

SELECT * FROM ContradaMigliorPiazzamentoUomini;

/* PiazzamentiDonne */

DROP TABLE IF EXISTS PiazzamentiDonne;

SET @piazzamento := 1;
SET @last_anno := 0;

CREATE TABLE PiazzamentiDonne
AS
SELECT
	TT.Anno,
	@piazzamento := CASE WHEN TT.Anno = @last_anno THEN @piazzamento + 1 ELSE 1 END AS Piazzamento,
	TT.Contrada,
	TT.TempoSecondi,
	TT.TempoDescrizione,
	@last_anno := TT.Anno AS dummy
FROM (
	SELECT
		T.Anno,
		T.Contrada,
		SUM(T.TempoSecondi) AS TempoSecondi,
		CONCAT(
			CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
			RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
			RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), """",
			RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
		) AS TempoDescrizione
	FROM T_Tempi T
	INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta AND A.Sesso = 'F'
	GROUP BY T.Anno,
		T.Contrada
) TT
ORDER BY TT.Anno,
	TT.TempoSecondi;

SELECT * FROM PiazzamentiDonne;

/* ContradaMigliorPiazzamentoDonne */

DROP TABLE IF EXISTS ContradaMigliorPiazzamentoDonne;

CREATE TABLE ContradaMigliorPiazzamentoDonne
AS
SELECT
	P.Contrada,
	P.Anno,
	P.TempoDescrizione,
	P.Piazzamento
FROM (
	SELECT PD.Contrada,
		@num := if(@num IS NULL, 1, if(@contrada = PD.Contrada, @num + 1, 1)) AS rank,
		@contrada := PD.Contrada AS dummy,
		PD.Anno,
		PD.TempoSecondi,
		PD.TempoDescrizione,
		PD.Piazzamento
	FROM PiazzamentiDonne PD
	LEFT JOIN (
		SELECT
			T.Contrada,
			T.Anno
		
		FROM T_Tempi T
		INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
		GROUP BY T.Contrada,
			T.Anno
		HAVING SUM(CASE WHEN A.Sesso = 'M' THEN 1 ELSE 0 END) != 15
	) Anomalie ON PD.Contrada = Anomalie.Contrada AND PD.Anno = Anomalie.Anno
	WHERE Anomalie.Contrada IS NULL
	ORDER BY PD.Contrada, PD.TempoSecondi
) P
WHERE P.rank = 1
ORDER BY P.TempoSecondi;

SELECT * FROM ContradaMigliorPiazzamentoDonne;

/* SessoTotaleTempi */

DROP VIEW IF EXISTS SessoTotaleTempiView;

CREATE VIEW SessoTotaleTempiView
AS
SELECT A.Sesso,
	CONCAT(
		CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
	) AS TempoTotale
FROM T_Tempi T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
GROUP BY A.Sesso;

/* ContradaSessoTotaleTempi */

DROP VIEW IF EXISTS ContradaSessoTotaleTempiView;

CREATE VIEW ContradaSessoTotaleTempiView
AS
SELECT T.Contrada, A.Sesso,
	CONCAT(
		CASE WHEN SUM(T.TempoSecondi) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi) / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi) / 60) - 60 * FLOOR(SUM(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)) - 60 * FLOOR(SUM(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi) - FLOOR(SUM(T.TempoSecondi))) * 100)), 2)
	) AS TempoTotale,
	COUNT(*) AS TotaleFrazioni,
	CONCAT(
		CASE WHEN SUM(T.TempoSecondi)/COUNT(*) >= 3600 THEN CONCAT(FLOOR(SUM(T.TempoSecondi)/COUNT(*) / 3600), "h") ELSE "" END,
		RIGHT(CONCAT(CASE WHEN SUM(T.TempoSecondi)/COUNT(*) >= 600 THEN "0" ELSE "" END, FLOOR(SUM(T.TempoSecondi)/COUNT(*) / 60) - 60 * FLOOR(SUM(T.TempoSecondi)/COUNT(*) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(SUM(T.TempoSecondi)/COUNT(*)) - 60 * FLOOR(SUM(T.TempoSecondi)/COUNT(*) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((SUM(T.TempoSecondi)/COUNT(*) - FLOOR(SUM(T.TempoSecondi)/COUNT(*))) * 100)), 2)
	) AS TempoMedio
FROM T_Tempi T
INNER JOIN T_Atleti A ON T.PKAtleta = A.PKAtleta
GROUP BY T.Contrada, A.Sesso
ORDER BY A.Sesso, SUM(T.TempoSecondi);

DROP VIEW IF EXISTS v_50MiglioriAtlete;

CREATE VIEW v_50MiglioriAtlete AS SELECT * FROM SessoMiglioriTempi WHERE Sesso = 'F' LIMIT 50;

DROP VIEW IF EXISTS v_50MiglioriAtleti;

CREATE VIEW v_50MiglioriAtleti AS SELECT * FROM SessoMiglioriTempi WHERE Sesso = 'M' LIMIT 100;

DROP VIEW IF EXISTS v_100MiglioriAtlete;

CREATE VIEW v_100MiglioriAtlete AS SELECT * FROM SessoMiglioriTempi WHERE Sesso = 'F' LIMIT 100;

DROP VIEW IF EXISTS v_100MiglioriAtleti;

CREATE VIEW v_100MiglioriAtleti AS SELECT * FROM SessoMiglioriTempi WHERE Sesso = 'M' LIMIT 100;

DROP VIEW IF EXISTS v_PiazzamentiPerAnno;

CREATE VIEW v_PiazzamentiPerAnno
AS
SELECT
	P1.Anno,
	P1.Contrada AS Prima,
	P2.Contrada AS Seconda,
	P3.Contrada AS Terza,
	P4.Contrada AS Quarta
FROM Piazzamenti P1
INNER JOIN Piazzamenti P2 ON P1.Anno = P2.Anno AND P2.Piazzamento = 2
INNER JOIN Piazzamenti P3 ON P1.Anno = P3.Anno AND P3.Piazzamento = 3
INNER JOIN Piazzamenti P4 ON P1.Anno = P4.Anno AND P4.Piazzamento = 4
WHERE P1.Piazzamento = 1
ORDER BY P1.Anno;

DROP VIEW IF EXISTS RiepilogoPartecipazioniDettaglioView;

CREATE VIEW RiepilogoPartecipazioniDettaglioView
AS
SELECT DISTINCT
	A.PKAtleta,
	T.Anno,
	CASE WHEN P.Piazzamento = 1 THEN 1 ELSE 0 END AS NumeroPrimiPosti,
	CASE WHEN P.Piazzamento = 2 THEN 1 ELSE 0 END AS NumeroSecondiPosti,
	CASE WHEN P.Piazzamento = 3 THEN 1 ELSE 0 END AS NumeroTerziPosti,
	CASE WHEN P.Piazzamento = 4 THEN 1 ELSE 0 END AS NumeroQuartiPosti

FROM T_Tempi T
INNER JOIN T_Atleti A ON A.PKAtleta = T.PKAtleta
INNER JOIN Piazzamenti P ON P.Anno = T.Anno AND P.Contrada = T.Contrada;

DROP VIEW IF EXISTS RiepilogoPartecipazioniView;

CREATE VIEW RiepilogoPartecipazioniView
AS
SELECT
	A.Cognome,
	A.Nome,
	A.Sesso,
	COUNT(1) AS NumeroPartecipazioni,
	MIN(RPD.Anno) AS AnnoPrimaPartecipazione,
	MAX(RPD.Anno) AS AnnoUltimaPartecipazione,
	SUM(NumeroPrimiPosti) AS NumeroPrimiPosti,
	SUM(NumeroSecondiPosti) AS NumeroSecondiPosti,
	SUM(NumeroTerziPosti) AS NumeroTerziPosti,
	SUM(NumeroQuartiPosti) AS NumeroQuartiPosti

FROM RiepilogoPartecipazioniDettaglioView RPD
INNER JOIN T_Atleti A ON A.PKAtleta = RPD.PKAtleta
GROUP BY A.Cognome,
	A.Nome,
	A.Sesso
ORDER BY NumeroPrimiPosti DESC,
	NumeroSecondiPosti DESC,
	NumeroTerziPosti DESC,
	NumeroQuartiPosti DESC,
	A.Cognome,
	A.Nome;

DROP VIEW IF EXISTS UniformitaTempiView;

CREATE VIEW UniformitaTempiView
AS
SELECT
	T.PKAtleta,
	COUNT(DISTINCT T.Anno) AS NumeroPartecipazioni,
	COUNT(1) AS NumeroFrazioni,
	CONCAT(
		RIGHT(CONCAT(CASE WHEN MIN(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(MIN(T.TempoSecondi) / 60) - 60 * FLOOR(MIN(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(MIN(T.TempoSecondi)) - 60 * FLOOR(MIN(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((MIN(T.TempoSecondi) - FLOOR(MIN(T.TempoSecondi))) * 100)), 2)
	) AS MigliorTempo,
	CONCAT(
		RIGHT(CONCAT(CASE WHEN MAX(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(MAX(T.TempoSecondi) / 60) - 60 * FLOOR(MAX(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(MAX(T.TempoSecondi)) - 60 * FLOOR(MAX(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((MAX(T.TempoSecondi) - FLOOR(MAX(T.TempoSecondi))) * 100)), 2)
	) AS PeggiorTempo,
	CONCAT(
		RIGHT(CONCAT(CASE WHEN AVG(T.TempoSecondi) >= 600 THEN "0" ELSE "" END, FLOOR(AVG(T.TempoSecondi) / 60) - 60 * FLOOR(AVG(T.TempoSecondi) / 3600)), 2), "'",
		RIGHT(CONCAT("0", FLOOR(AVG(T.TempoSecondi)) - 60 * FLOOR(AVG(T.TempoSecondi) / 60)), 2), "\"",
		RIGHT(CONCAT("0", FLOOR((AVG(T.TempoSecondi) - FLOOR(AVG(T.TempoSecondi))) * 100)), 2)
	) AS TempoMedio,
	ROUND(STD(T.TempoSecondi) / COUNT(1), 2) AS IndiceDiVariabilita

FROM T_Tempi T
INNER JOIN T_Atleti A ON A.PKAtleta = T.PKAtleta
GROUP BY T.PKAtleta
HAVING COUNT(1) >= 5
ORDER BY STD(T.TempoSecondi) / COUNT(1),
	NumeroPartecipazioni DESC;
