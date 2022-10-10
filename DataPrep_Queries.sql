-- eticaret sto�u olan �r�n gruplar� 
SELECT 
	m.SidMagaza, 
	ml.SidMalzemeMarka,
	ml.SidMalzemeCinsiyet, 
	ml.SidMalzemeUrunGrubu, 
	s.SidSatisSezonDetay,
	SUM(KullanilabilirStok) stokMiktari 
INTO 
	#GuncelStokEticaretUrunGruplari 
FROM 
	MIX.dbo.E200StokTarihsel s
	INNER JOIN MIX.dim.vMagaza m on s.MagazaKodu=m.MagazaKodu
	INNER JOIN MIX.dim.vMalzeme ml on ml.MalzemeKodu=s.MalzemeKodu 
WHERE 
	Tarih = DATEADD(DAY,-1,convert(date,GETDATE())) AND 
	-- ml.EticaretMi = 1 
	ml.ResimAdresi is not null  
GROUP BY 
	m.SidMagaza, 
	ml.SidMalzemeMarka, 
	ml.SidMalzemeCinsiyet, 
	ml.SidMalzemeUrunGrubu, 
	s.SidSatisSezonDetay	
HAVING 
	SUM(s.KullanilabilirStok) > 0


-- e ticarette sto�u olan �r�n gruplar�ndaki se�eneklere ait �r�n g�rselleri 	
-- sto�u olan se�enek g�rselleri yetersiz kalmaktad�r. 
SELECT 
	M.WebSecenek, 
	MM.Kodu MarkaKodu, 
	MC.Kodu CinsiyetKodu, 
	MUG.UrunGrubu UrunGrubuKodu, 
	M.Renk,
	M.ResimAdresi ResimUrl 
INTO 
	#SecenekResim 
FROM 
	MIX.dim.vMalzeme M 
	INNER JOIN (SELECT DISTINCT SidMalzemeMarka,SidMalzemeCinsiyet, SidMalzemeUrunGrubu FROM #GuncelStokEticaretUrunGruplari) GSUG 
		ON GSUG.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet AND GSUG.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu and GSUG.SidMalzemeMarka = M.SidMalzemeMarka
	INNER JOIN MIX.dim.vMalzemeMarka MM on MM.SidMalzemeMarka = M.SidMalzemeMarka
	INNER JOIN MIX.dim.vMalzemeCinsiyet MC on MC.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet
	INNER JOIN MIX.dim.vMalzemeUrunGrubu MUG on MUG.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu
WHERE 
	-- M.EticaretMi = 1 
	M.ResimAdresi is not null 
GROUP BY 
	M.WebSecenek, 
	MM.Kodu, 
	MC.Kodu, 
	MUG.UrunGrubu, 
	M.Renk,
	M.ResimAdresi;  

select distinct CinsiyetKodu from #SecenekResim
select distinct SidMalzemeCinsiyet, SidMalzemeMarka, SidMalzemeUrunGrubu from MIX.dim.vSecenek

/*
select distinct 
	MarkaKodu, 
	UrunGrubuKodu, 
	Renk
INTO 
	#Classes  
from 
	#SecenekResim
*/ 

-- �kinci foto�raf i�in sat�rlar� duplicate et. 
INSERT INTO 
	#SecenekResim
SELECT 
	*
FROM
	#SecenekResim 

SELECT 
	K.WebSecenek, 
	K.MarkaKodu, 
	K.CinsiyetKodu, 
	K.UrunGrubuKodu, 
	K.Renk, 
	CASE 
		WHEN K.UrlNo % 2 != 0 THEN K.ResimUrl
		ELSE REPLACE(K.ResimUrl, '-1.jpg', '-2.jpg')
	END cURL, 
	K.UrlNo 
INTO 
	#Dataset1 
FROM 
	(SELECT 
		S.*,  
		ROW_NUMBER() OVER(PARTITION BY S.WebSecenek ORDER BY S.ResimUrl) UrlNo
	FROM 
		#SecenekResim S) K 

CREATE TABLE PROTO.Melih.Dataset1_SimilarProducts(
	WebSecenek varchar(50), --41 
	MarkaKodu varchar(50), 
	CinsiyetKodu nvarchar(50), 
	UrunGrubuKodu varchar(50), 
	Renk varchar(20), 
	cUrl varchar(200),
	UrlNo int 
)


-- truncate table PROTO.Melih.Dataset1_SimilarProducts 
-- drop table PROTO.Melih.Dataset1_SimilarProducts 
INSERT INTO PROTO.Melih.Dataset1_SimilarProducts 
SELECT * FROM #Dataset1  

select DISTINCT CinsiyetKodu from PROTO.Melih.Dataset1_SimilarProducts S WHERE S.MarkaKodu = '08'

