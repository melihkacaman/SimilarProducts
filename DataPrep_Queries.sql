-- eticaret stoðu olan ürün gruplarý 
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
	ml.EticaretMi = 1 
GROUP BY 
	m.SidMagaza, 
	ml.SidMalzemeMarka, 
	ml.SidMalzemeCinsiyet, 
	ml.SidMalzemeUrunGrubu, 
	s.SidSatisSezonDetay	
HAVING 
	SUM(s.KullanilabilirStok) > 0

-- e ticarette stoðu olan ürün gruplarýndaki seçeneklere ait ürün görselleri 	
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
	M.EticaretMi = 1
GROUP BY 
	M.WebSecenek, 
	MM.Kodu, 
	MC.Kodu, 
	MUG.UrunGrubu, 
	M.Renk,
	M.ResimAdresi;  

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

-- Ýkinci fotoðraf için satýrlarý duplicate et. 
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
