/*
	17.10.2022 
	Backbone Dataset - For Similar Products 
	Created By Melih Kaçaman 

	Son bir yýl içerisinde performansý en yüksek olan 
	
	10 ÜG'den 1000 seçenek. 
*/ 

declare @today date = convert(date, getdate()) 
declare @lastOneYear date = dateadd(year,-1, @today) 

-- Ürün Grubu performansý hesaplama 

-- USPA Cinsiyet UG E-Ticarette satýþ sayýsý 
-- Belki maðazada almayý tercih ettiðim þeyi eticarette almayý daha az tercih edebilirim.  

SELECT 
	M.SidMalzemeCinsiyet,
	M.SidMalzemeUrunGrubu, 
	COUNT(M.SidMalzeme) UGSayisi 
INTO 
	#UGSatis 
FROM 
	MIX.dbo.vSatis S INNER JOIN 
	MIX.dim.vMalzeme M on S.SidMalzeme = M.SidMalzeme 
WHERE 
	S.SidSatisKanali = 11 AND 
	S.Tarih > @lastOneYear AND 
	M.SidMalzemeMarka = 4
GROUP BY 
	M.SidMalzemeCinsiyet,
	M.SidMalzemeUrunGrubu

SELECT TOP 2 
	SidMalzemeCinsiyet,
	SUM(UGSayisi) CSayisi 
INTO 
	#CSatis 
FROM 
	#UGSatis 
GROUP BY 
	SidMalzemeCinsiyet
ORDER BY
	2 DESC 
	
-- UG Performansý
SELECT 
	UG.SidMalzemeCinsiyet,
	UG.SidMalzemeUrunGrubu,
	cast(UG.UGSayisi / (C.CSayisi * 1.0) as decimal(15, 3)) UGPerformans 
INTO 
	 #UGPerformans -- drop table #UGPerformans
FROM 
	#UGSatis UG INNER JOIN 
	#CSatis C ON UG.SidMalzemeCinsiyet = C.SidMalzemeCinsiyet
ORDER BY 
	UGPerformans DESC 


select SidMalzemeCinsiyet, count(distinct SidMalzemeUrunGrubu) say from #UGPerformans group by SidMalzemeCinsiyet

select * into #SecilenUG from (
		select * from #UGPerformans WHERE SidMalzemeCinsiyet = 3 
		UNION 
		SELECT TOP 42 * FROM #UGPerformans WHERE SidMalzemeCinsiyet = 4 ORDER BY UGPerformans DESC
	) K 





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
	INNER JOIN (SELECT DISTINCT SidMalzemeCinsiyet, SidMalzemeUrunGrubu FROM #SecilenUG) GSUG 
		ON GSUG.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet AND GSUG.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu 
	INNER JOIN MIX.dim.vMalzemeMarka MM on MM.SidMalzemeMarka = M.SidMalzemeMarka
	INNER JOIN MIX.dim.vMalzemeCinsiyet MC on MC.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet
	INNER JOIN MIX.dim.vMalzemeUrunGrubu MUG on MUG.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu
WHERE 
	M.ResimAdresi is not null and M.ResimAdresi not like '%tedarik%' AND 
	M.SidMalzemeMarka = 4 
GROUP BY 
	M.WebSecenek, 
	MM.Kodu, 
	MC.Kodu, 
	MUG.UrunGrubu, 
	M.Renk,
	M.ResimAdresi;  


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
	#Dataset2 
FROM 
	(SELECT 
		S.*,  
		ROW_NUMBER() OVER(PARTITION BY S.WebSecenek ORDER BY S.ResimUrl) UrlNo
	FROM 
		#SecenekResim S) K 


CREATE TABLE PROTO.Melih.Dataset2_SimilarProducts(
	WebSecenek varchar(50), --41 
	MarkaKodu varchar(50), 
	CinsiyetKodu nvarchar(50), 
	UrunGrubuKodu varchar(50), 
	Renk varchar(20), 
	cUrl varchar(200),
	UrlNo int 
)
-- truncate table PROTO.Melih.Dataset2_SimilarProducts 
-- drop table PROTO.Melih.Dataset2_SimilarProducts 
-- INSERT INTO PROTO.Melih.Dataset2_SimilarProducts 

select DISTINCT  
	C.Kodu,
	C.CinsiyetKisaAdi,
	UG.UrunGrubu, 
	count(*) as classnum 
INTO 
	#prep2 -- drop table #prep2 
from #Dataset2 S 
INNER JOIN MIX.dim.vMalzemeCinsiyet C on C.Kodu = s.CinsiyetKodu 
INNER JOIN MIX.dim.vMalzemeUrunGrubu UG ON UG.UrunGrubu = S.UrunGrubuKodu 
WHERE S.MarkaKodu = '08' 
group by C.Kodu, C.CinsiyetKisaAdi, UG.UrunGrubu
having count(*) > 500 -- bu sayýnýn doðru tespit edilmesi gerek. 
order by classnum desc  



-- drop table #prep3 
select S.* INTO #prep3 from #Dataset2 s INNER JOIN #prep2 P on P.Kodu = S.CinsiyetKodu and P.UrunGrubu = S.UrunGrubuKodu 
where s.MarkaKodu = '08' 


select p.CinsiyetKodu, p.UrunGrubuKodu, count(WebSecenek) as seceneksay from #prep3 p
group by p.CinsiyetKodu, p.UrunGrubuKodu
order by seceneksay desc  


select CinsiyetKodu, count(UrunGrubuKodu) from #prep3 group by CinsiyetKodu 

-- dataset2 125 bin img içeriyor. 
-- bir classta en az 526 fotoðraf var. 
-- bir classta en fazla 10170 fotoðraf var. 
-- bu durum modelin kurulum esnasýnda deðerlendirilecek. 

INSERT INTO PROTO.Melih.Dataset2_SimilarProducts 
SELECT * FROM #prep3