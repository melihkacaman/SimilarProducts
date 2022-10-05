-- eticaret sto�u olan �r�n gruplar� 
SELECT 
	m.SidMagaza, 
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
	ml.SidMalzemeCinsiyet, 
	ml.SidMalzemeUrunGrubu, 
	s.SidSatisSezonDetay	
HAVING 
	SUM(s.KullanilabilirStok) > 0

-- e ticarette sto�u olan �r�n gruplar�ndaki se�eneklere ait �r�n g�rselleri 	
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
	INNER JOIN (SELECT DISTINCT SidMalzemeCinsiyet, SidMalzemeUrunGrubu FROM #GuncelStokEticaretUrunGruplari) GSUG 
		ON GSUG.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet AND GSUG.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu
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
/*
SELECT 
	K.*, 
	ROW_NUMBER() OVER() AS sira 
FROM 
	(SELECT * FROM #SecenekResim UNION SELECT * FROM #SecenekResim) K 

*/