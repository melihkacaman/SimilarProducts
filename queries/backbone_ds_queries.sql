/*
	17.10.2022 
	Backbone Dataset - For Similar Products 
	Created By Melih Kaçaman 

	Son bir yýl içerisinde performansý en yüksek olan 10 ÜG'den 1000 seçenek. 
*/ 

declare @today date = convert(date, getdate()) 
declare @lastOneYear date = dateadd(year,-1, @today) 

-- Ürün Grubu performansý hesaplama 

-- USPA Cinsiyet UG E-Ticarette satýþ sayýsý 
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
SELECT top 10 
	UG.SidMalzemeCinsiyet,
	UG.SidMalzemeUrunGrubu,
	cast(UG.UGSayisi / (C.CSayisi * 1.0) as decimal(15, 3)) UGPerformans 
INTO 
	 #UGPerformans 
FROM 
	#UGSatis UG INNER JOIN 
	#CSatis C ON UG.SidMalzemeCinsiyet = C.SidMalzemeCinsiyet
ORDER BY 
	UGPerformans DESC 

-- her iki 5 li UG'de kendi cinsiyetinin satýþlarýnýn %50 sini oluþturuyor. 

-- belirlenen ürün gruplarýna ait seçenekler altýnda seçenek ve renk performansý hesaplama 

SELECT 
	S.Tarih,
	M.SidMalzeme, 
	M.SidMalzemeCinsiyet, 
	M.SidMalzemeUrunGrubu, 
	M.SidSecenek, 
	M.Renk 
INTO 
	#SalesData 
FROM 
	MIX.dbo.vSatis S INNER JOIN 
	MIX.dim.vMalzeme M ON M.SidMalzeme = S.SidMalzeme INNER JOIN 
	#UGPerformans UGP ON UGP.SidMalzemeCinsiyet = M.SidMalzemeCinsiyet AND UGP.SidMalzemeUrunGrubu = M.SidMalzemeUrunGrubu 
WHERE 
	S.SidSatisKanali = 11 AND 
	S.Tarih > @lastOneYear AND 
	M.SidMalzemeMarka = 4
	
-- marka -> cinsiyet -> ürün grubu -> seçenek -> malzeme 

SELECT  
	S.SidMalzemeCinsiyet, 
	S.SidMalzemeUrunGrubu, 
	S.SidSecenek, 
	CAST(COUNT(S.SidSecenek) / (S2.UGSatisSayisi * 1.0) AS decimal(15, 3)) SecenekPerformans 
FROM 
	#SalesData S INNER JOIN 
	(SELECT SidMalzemeCinsiyet, SidMalzemeUrunGrubu, count(SidSecenek) UGSatisSayisi FROM #SalesData GROUP BY SidMalzemeCinsiyet, SidMalzemeUrunGrubu) S2 ON S2.SidMalzemeCinsiyet = S.SidMalzemeCinsiyet AND S2.SidMalzemeUrunGrubu = S.SidMalzemeUrunGrubu
GROUP BY	
	S.SidMalzemeCinsiyet, S.SidMalzemeUrunGrubu, SidSecenek, s2.UGSatisSayisi
ORDER BY 
	SecenekPerformans DESC 


