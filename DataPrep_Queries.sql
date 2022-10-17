/*
	DATASET: 1 
	- Cinsiyet, 
	- Ürün Grubu,
	- Renk 

	- Tedarik uzantýlý olmayanlar. 
	- Güncel en az bir stoðu olan Ürün Gruplarýnda 
	- Bebek Cinsiyetleri çýkartýldý. 
*/

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


-- e ticarette stoðu olan ürün gruplarýndaki seçeneklere ait ürün görselleri 	
-- stoðu olan seçenek görselleri yetersiz kalmaktadýr. 
-- tedarik uzantýlýlarý sil. 
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
	M.ResimAdresi is not null and M.ResimAdresi not like '%tedarik%'
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
-- INSERT INTO PROTO.Melih.Dataset1_SimilarProducts 

----- 
select DISTINCT CinsiyetKodu, UrunGrubuKodu, Renk from #Dataset1
WHERE MarkaKodu = '08'
-- 9453 class 

select DISTINCT  C.Kodu,C.CinsiyetKisaAdi,UG.UrunGrubu,S.Renk, count(*) as classnum INTO #prep1 
from #Dataset1 S 
INNER JOIN MIX.dim.vMalzemeCinsiyet C on C.Kodu = s.CinsiyetKodu 
INNER JOIN MIX.dim.vMalzemeUrunGrubu UG ON UG.UrunGrubu = S.UrunGrubuKodu 
WHERE S.MarkaKodu = '08' 
group by C.Kodu, C.CinsiyetKisaAdi, UG.UrunGrubu, S.Renk
having count(*) > 200 -- bu sayýnýn doðru tespit edilmesi gerek. 
order by classnum desc 

-- drop table #prep1

select count(distinct CinsiyetKisaAdi), count(distinct  UrunGrubu), count(distinct Renk) from #prep1 

select S.* INTO #prep2 from #Dataset1 s INNER JOIN #prep1 P on P.Kodu = S.CinsiyetKodu and P.UrunGrubu = S.UrunGrubuKodu and P.Renk = S.Renk 

select p.CinsiyetKodu, p.UrunGrubuKodu, p.Renk, count(WebSecenek) as seceneksay from #prep2 p
group by p.CinsiyetKodu, p.UrunGrubuKodu, p.Renk
order by seceneksay desc 

-- dataset1 60 bin img içeriyor. 
-- bir classta en az 200 fotoðraf var. 
-- bir classta en fazla 3500 fotoðraf var. 
-- bu durum modelin kurukum esnasýnda deðerlendirilecek. 

INSERT INTO PROTO.Melih.Dataset1_SimilarProducts 
SELECT * FROM #prep2


