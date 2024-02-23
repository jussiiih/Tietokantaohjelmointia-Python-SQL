-- Creating table dim_country
CREATE TABLE "staging".dim_country
	(country_code TEXT,
	 short_name TEXT,
	 table_name TEXT,
	 currency_unit TEXT,
	 region TEXT,
	 income_group TEXT,
	 other_groups TEXT
	);


-- With this code you can import country_clean.csv file into table. You have to only change
-- the file path to the one where
-- you have country_clean.csv file on your computer


COPY "staging".dim_country
FROM 'C:\Code\Clean Data\country_clean.csv'
DELIMITER ','
CSV HEADER;


--Dropping and renaming columns according to schema
ALTER TABLE "staging".dim_country DROP COLUMN short_name;
ALTER TABLE "staging".dim_country DROP COLUMN other_groups;
ALTER TABLE "staging".dim_country RENAME COLUMN table_name TO country_name;
ALTER TABLE "staging".dim_country RENAME COLUMN region TO region_name;

-- Separating Country & Region dimensions

SELECT * INTO "staging".dim_region FROM "staging".dim_country
WHERE region_name IS NULL;

DELETE FROM "staging".dim_country
WHERE region_name IS NULL;

ALTER TABLE "staging".dim_region RENAME COLUMN country_name TO region;

-- Adding serial primary key
ALTER TABLE "staging".dim_country ADD COLUMN country_id SERIAL PRIMARY KEY;
ALTER TABLE "staging".dim_region ADD COLUMN region_id SERIAL PRIMARY KEY;

ALTER TABLE "staging".dim_region DROP COLUMN currency_unit;
ALTER TABLE "staging".dim_region DROP COLUMN region_name;
ALTER TABLE "staging".dim_region DROP COLUMN income_group;
ALTER TABLE "staging".dim_region RENAME COLUMN region TO region_name;
ALTER TABLE "staging".dim_region RENAME COLUMN country_code TO region_code;

--Copying table from staging into core
SELECT * INTO "core".dim_country FROM "staging".dim_country;

SELECT * INTO "core".dim_region FROM "staging".dim_region;


--Adding primary key to the table in core
ALTER TABLE "core".dim_country ADD PRIMARY KEY(country_id);
ALTER TABLE "core".dim_region ADD PRIMARY KEY(region_id);


-- DIM_INDICATOR

CREATE TABLE "staging".dim_indicator
	(indicator_code TEXT,
	 topic TEXT,
	 indicator_name TEXT,
	 short_definition TEXT,
	 long_definition TEXT,
	 periodicity TEXT
);

-- With this code you can import series_clean.csv file into table. You have to only change
-- the file path to the one where
-- you have series_clean.csv file on your computer 

COPY "staging".dim_indicator
FROM 'C:\Code\Clean Data\series_clean.csv'
DELIMITER ';'
CSV HEADER;


--Creating indicator_id primary keys
ALTER TABLE "staging".dim_indicator ADD COLUMN indicator_id SERIAL PRIMARY KEY;


--Copying table from staging into core
SELECT * INTO "core".dim_indicator FROM "staging".dim_indicator;

--Adding primary key to the table in core
ALTER TABLE "core".dim_indicator ADD PRIMARY KEY(indicator_id);



-- DIM_WHR_ATTRIBUTE, FACT_WHR


-- Creating a table for importing WHR data
--drop table if exists "staging".whr;

create table "staging".whr (
	country_name VARCHAR,
	year INT,
	attribute VARCHAR,
	value NUMERIC
);

	-- IMPORT 'WHR2023_clean.csv' into "staging".whr table
COPY "staging".whr
FROM 'C:\Code\Clean Data\WHR2023_clean.csv'
DELIMITER ','
CSV HEADER;


-- Creating fact table with an auto-generated log_id for each value input
create table "staging".whr_fact (
	log_id SERIAL PRIMARY KEY,
	country_name VARCHAR,
	year INT,
	attribute VARCHAR,
	value NUMERIC
);

-- Inserting data into fact table from whr table
INSERT INTO "staging".whr_fact (country_name, year, attribute, value)
SELECT country_name, year, attribute, value FROM "staging".whr;


-- Creating dimension table for WHR attribute
create table "staging".dim_whr_attribute (
	attribute_id SERIAL PRIMARY KEY,
	attribute VARCHAR
);

-- Inserting distinct attribute from fact table
INSERT INTO "staging".dim_whr_attribute (attribute)
SELECT DISTINCT attribute FROM "staging".whr_fact;

-- Adding attribute_id column into fact table
ALTER TABLE "staging".whr_fact
ADD COLUMN attribute_id INT REFERENCES "staging".dim_whr_attribute (attribute_id);

-- Updating whr_product_fact table with attribute_id values from dim_whr_attribute
UPDATE "staging".whr_fact wf
SET attribute_id = dwa.attribute_id FROM "staging".dim_whr_attribute dwa
WHERE wf.attribute = dwa.attribute;

-- Dropping attribute column
ALTER TABLE "staging".whr_fact
DROP COLUMN attribute;


	-- ADD DIM_COUNTRY TABLE INTO STAGING AT THIS POINT


-- Adding country_id column into "Staging".fact table
ALTER TABLE "staging".whr_fact
ADD COLUMN country_id INT REFERENCES "staging".dim_country (country_id);

-- Updating "Staging".whr_fact table with country_id values from "Staging".dim_country
UPDATE "staging".whr_fact wf
SET country_id = dc.country_id FROM "staging".dim_country dc
WHERE wf.country_name = dc.country_name;

-- Dropping country_name column
ALTER TABLE "staging".whr_fact
DROP COLUMN country_name;


	-- AFTER COUNTRY ID SET


-- Creating "core".dim_whr_attribute table
SELECT * INTO "core".dim_whr_attribute
FROM "staging".dim_whr_attribute;

ALTER TABLE "core".dim_whr_attribute ADD PRIMARY KEY(attribute_id);


-- Creating "core".fact_whr
SELECT * INTO "core".fact_whr
FROM "staging".whr_fact;

ALTER TABLE "core".fact_whr ADD PRIMARY KEY(log_id);
ALTER TABLE "core".fact_whr ADD FOREIGN KEY (country_id) REFERENCES "core".dim_country(country_id);
ALTER TABLE "core".fact_whr ADD FOREIGN KEY (attribute_id) REFERENCES "core".dim_whr_attribute(attribute_id);


-- SCHEMA: staging

-- DROP SCHEMA IF EXISTS staging ;

/*CREATE SCHEMA IF NOT EXISTS staging
    AUTHORIZATION postgres;
*/	
	-- create FACT table country debt
	CREATE TABLE "staging".country_debt(
	debt_id SERIAL PRIMARY KEY,
	country_name TEXT,
	year INT NOT NULL,
	value NUMERIC
	);
	

	
	-- import csv 
	COPY "staging".country_debt (country_name, year, value)
	FROM 'C:\Code\Clean Data\imf-dm-export-20240205cleaned.csv'
	DELIMITER ';'
	CSV HEADER;
	
	-- add column country_id to table, update table
	ALTER TABLE "staging".country_debt
	ADD COLUMN country_id INT REFERENCES "staging".dim_country(country_id);
	
	UPDATE "staging".country_debt cd
	SET country_id = dc.country_id FROM "staging".dim_country dc
	WHERE cd.country_name = dc.country_name;
	
	-- drop country_name column from table, has been replaced by country_id
	ALTER TABLE "staging".country_debt
	DROP COLUMN country_name; 

-- Creating "core".country_debt
SELECT * INTO "core".fact_country_debt
FROM "staging".country_debt;

ALTER TABLE "core".fact_country_debt ADD PRIMARY KEY(debt_id);
ALTER TABLE "core".fact_country_debt ADD FOREIGN KEY (country_id) REFERENCES "core".dim_country(country_id);


---creating tables for staging indicators 

CREATE TABLE "staging".indicators (
	country_name VARCHAR(100),
	country_code VARCHAR(20),
	indicator_name VARCHAR(500),
	indicator_code VARCHAR(100),
	year INT,
	value VARCHAR(100),
	value_numeric NUMERIC
);

COPY "staging".indicators
FROM 'C:\Code\Clean Data\indicators_with_numeric_values.csv'
DELIMITER ','
CSV HEADER;


create table "staging".indicators_country (like "staging".indicators including all);

create table "staging".fact_country_stat (like "staging".indicators including all);

---inserting COUNTRIES to table

INSERT INTO "staging".indicators_country
SELECT * FROM "staging".indicators
WHERE country_code NOT IN (
'AFE',
'AFW',
'ARB',
'CEB',
'CSS',
'EAP',
'EAR',
'EAS',
'ECA',
'ECS',
'EMU',
'EUU',
'FCS',
'HIC',
'HPC',
'IBD',
'IBT',
'IDA',
'IDB',
'IDX',
'LAC',
'LCN',
'LDC',
'LIC',
'LMC',
'LMY',
'LTE',
'MEA',
'MIC',
'MNA',
'NAC',
'OED',
'OSS',
'PRE',
'PSS',
'PST',
'SAS',
'SSA',
'SSF',
'SST',
'TEA',
'TEC',
'TLA',
'TMN',
'TSA',
'TSS',
'UMC',
'WLD'
);

---insering countries and selected indicators to fact table

INSERT INTO "staging".fact_country_stat
SELECT * FROM "staging".indicators_country
WHERE indicator_code IN (
'BG.GSR.NFSV.GD.ZS',
'BM.GSR.CMCP.ZS',
'BM.GSR.GNFS.CD',
'BM.GSR.INSF.ZS',
'BM.GSR.MRCH.CD',
'BM.GSR.NFSV.CD',
'BM.GSR.TOTL.CD',
'BM.GSR.TRAN.ZS',
'BM.GSR.TRVL.ZS',
'BN.CAB.XOKA.CD',
'BN.CAB.XOKA.GD.ZS',
'BN.GSR.GNFS.CD',
'BN.GSR.MRCH.CD',
'BX.GSR.CCIS.CD',
'BX.GSR.CCIS.ZS',
'BX.GSR.CMCP.ZS',
'BX.GSR.GNFS.CD',
'BX.GSR.INSF.ZS',
'BX.GSR.MRCH.CD',
'BX.GSR.NFSV.CD',
'BX.GSR.TOTL.CD',
'BX.GSR.TRAN.ZS',
'BX.GSR.TRVL.ZS',
'DT.DOD.DSTC.XP.ZS',
'DT.DOD.PVLX.EX.ZS',
'DT.NFL.BLAT.CD',
'DT.NFL.FAOG.CD',
'DT.NFL.IAEA.CD',
'DT.NFL.IFAD.CD',
'DT.NFL.ILOG.CD',
'DT.NFL.OFFT.CD',
'DT.NFL.PROP.CD',
'DT.NFL.PRVT.CD',
'DT.NFL.UNAI.CD',
'DT.NFL.UNCF.CD',
'DT.NFL.UNCR.CD',
'DT.NFL.UNDP.CD',
'DT.NFL.UNEC.CD',
'DT.NFL.UNEP.CD',
'DT.NFL.UNFP.CD',
'DT.NFL.UNID.CD',
'DT.NFL.UNPB.CD',
'DT.NFL.UNRW.CD',
'DT.NFL.UNTA.CD',
'DT.NFL.UNWT.CD',
'DT.NFL.WFPG.CD',
'DT.NFL.WHOL.CD',
'DT.ODA.ODAT.MP.ZS',
'DT.TDS.DECT.EX.ZS',
'DT.TDS.DPPF.XP.ZS',
'DT.TDS.DPPG.XP.ZS',
'EG.IMP.CONS.ZS',
'EG.USE.COMM.GD.PP.KD',
'EG.USE.PCAP.KG.OE',
'FI.RES.TOTL.MO',
'FP.WPI.TOTL',
'GC.TAX.EXPT.CN',
'GC.TAX.EXPT.ZS',
'GC.TAX.IMPT.CN',
'GC.TAX.IMPT.ZS',
'GC.TAX.INTT.CN',
'GC.TAX.INTT.RV.ZS',
'IC.CUS.DURS.EX',
'IC.EXP.CSBC.CD',
'IC.EXP.CSDC.CD',
'IC.EXP.TMBC',
'IC.EXP.TMDC',
'IC.IMP.CSBC.CD',
'IC.IMP.CSDC.CD',
'IC.IMP.TMBC',
'IC.IMP.TMDC',
'LP.EXP.DURS.MD',
'LP.IMP.DURS.MD',
'LP.LPI.CUST.XQ',
'LP.LPI.INFR.XQ',
'LP.LPI.ITRN.XQ',
'LP.LPI.LOGS.XQ',
'LP.LPI.OVRL.XQ',
'LP.LPI.TIME.XQ',
'LP.LPI.TRAC.XQ',
'MS.MIL.MPRT.KD',
'MS.MIL.XPRT.KD',
'NE.EXP.GNFS.CD',
'NE.EXP.GNFS.CN',
'NE.EXP.GNFS.KD',
'NE.EXP.GNFS.KD.ZG',
'NE.EXP.GNFS.KN',
'NE.EXP.GNFS.ZS',
'NE.IMP.GNFS.CD',
'NE.IMP.GNFS.CN',
'NE.IMP.GNFS.KD',
'NE.IMP.GNFS.KD.ZG',
'NE.IMP.GNFS.KN',
'NE.IMP.GNFS.ZS',
'NE.RSB.GNFS.CD',
'NE.RSB.GNFS.CN',
'NE.RSB.GNFS.KN',
'NE.RSB.GNFS.ZS',
'NE.TRD.GNFS.ZS',
'NV.SRV.TOTL.CD',
'NV.SRV.TOTL.CN',
'NV.SRV.TOTL.KD',
'NV.SRV.TOTL.KD.ZG',
'NV.SRV.TOTL.KN',
'NV.SRV.TOTL.ZS',
'NY.EXP.CAPM.KN',
'NY.TTF.GNFS.KN',
'ST.INT.RCPT.CD',
'ST.INT.RCPT.XP.ZS',
'ST.INT.TVLR.CD',
'ST.INT.TVLX.CD',
'ST.INT.XPND.CD',
'ST.INT.XPND.MP.ZS',
'TG.VAL.TOTL.GD.ZS',
'TM.QTY.MRCH.XD.WD',
'TM.TAX.MANF.WM.AR.ZS',
'TM.TAX.MANF.WM.FN.ZS',
'TM.TAX.MRCH.WM.AR.ZS',
'TM.TAX.MRCH.WM.FN.ZS',
'TM.TAX.TCOM.WM.AR.ZS',
'TM.TAX.TCOM.WM.FN.ZS',
'TM.UVI.MRCH.XD.WD',
'TM.VAL.AGRI.ZS.UN',
'TM.VAL.FOOD.ZS.UN',
'TM.VAL.FUEL.ZS.UN',
'TM.VAL.ICTG.ZS.UN',
'TM.VAL.INSF.ZS.WT',
'TM.VAL.MANF.ZS.UN',
'TM.VAL.MMTL.ZS.UN',
'TM.VAL.MRCH.AL.ZS',
'TM.VAL.MRCH.CD.WT',
'TM.VAL.MRCH.HI.ZS',
'TM.VAL.MRCH.OR.ZS',
'TM.VAL.MRCH.R1.ZS',
'TM.VAL.MRCH.R2.ZS',
'TM.VAL.MRCH.R3.ZS',
'TM.VAL.MRCH.R4.ZS',
'TM.VAL.MRCH.R5.ZS',
'TM.VAL.MRCH.R6.ZS',
'TM.VAL.MRCH.RS.ZS',
'TM.VAL.MRCH.WL.CD',
'TM.VAL.MRCH.WR.ZS',
'TM.VAL.MRCH.XD.WD',
'TM.VAL.OTHR.ZS.WT',
'TM.VAL.SERV.CD.WT',
'TM.VAL.TRAN.ZS.WT',
'TM.VAL.TRVL.ZS.WT',
'TT.PRI.MRCH.XD.WD',
'TX.MNF.TECH.ZS.UN',
'TX.QTY.MRCH.XD.WD',
'TX.UVI.MRCH.XD.WD',
'TX.VAL.AGRI.ZS.UN',
'TX.VAL.FOOD.ZS.UN',
'TX.VAL.FUEL.ZS.UN',
'TX.VAL.ICTG.ZS.UN',
'TX.VAL.INSF.ZS.WT',
'TX.VAL.MANF.ZS.UN',
'TX.VAL.MMTL.ZS.UN',
'TX.VAL.MRCH.AL.ZS',
'TX.VAL.MRCH.CD.WT',
'TX.VAL.MRCH.HI.ZS',
'TX.VAL.MRCH.OR.ZS',
'TX.VAL.MRCH.R1.ZS',
'TX.VAL.MRCH.R2.ZS',
'TX.VAL.MRCH.R3.ZS',
'TX.VAL.MRCH.R4.ZS',
'TX.VAL.MRCH.R5.ZS',
'TX.VAL.MRCH.R6.ZS',
'TX.VAL.MRCH.RS.ZS',
'TX.VAL.MRCH.WL.CD',
'TX.VAL.MRCH.WR.ZS',
'TX.VAL.MRCH.XD.WD',
'TX.VAL.OTHR.ZS.WT',
'TX.VAL.SERV.CD.WT',
'TX.VAL.TECH.CD',
'TX.VAL.TECH.MF.ZS',
'TX.VAL.TRAN.ZS.WT',
'TX.VAL.TRVL.ZS.WT'
);


---Adding columns indicator_id and country_id
ALTER TABLE "staging".fact_country_stat
ADD COLUMN indicator_id INT REFERENCES "staging".dim_indicator (indicator_id);

ALTER TABLE "staging".fact_country_stat
ADD COLUMN country_id INT REFERENCES "staging".dim_country (country_id);


--Updating columns to match with dim_country and dim_indicators
UPDATE "staging".fact_country_stat cs
SET country_id = dc.country_id FROM "staging".dim_country dc
WHERE cs.country_name = dc.country_name;

UPDATE "staging".fact_country_stat cs
SET indicator_id = di.indicator_id FROM "staging".dim_indicator di
WHERE cs.indicator_code = di.indicator_code; 
 
-- Dropping column country_name, country_code, indicator_name and indicator_code
ALTER TABLE "staging".fact_country_stat
DROP COLUMN country_name;

ALTER TABLE "staging".fact_country_stat
DROP COLUMN indicator_code;

ALTER TABLE "staging".fact_country_stat
DROP COLUMN country_code;

ALTER TABLE "staging".fact_country_stat
DROP COLUMN indicator_name;

-- Adding primary key serial into fact_country_stat
ALTER TABLE "staging".fact_country_stat ADD COLUMN stat_id SERIAL PRIMARY KEY;

-- Creating country_stat table into core
SELECT * INTO "core".fact_country_stat FROM "staging".fact_country_stat;

ALTER TABLE "core".fact_country_stat ADD PRIMARY KEY(stat_id);
ALTER TABLE "core".fact_country_stat ADD FOREIGN KEY (country_id) REFERENCES "core".dim_country(country_id);
ALTER TABLE "core".fact_country_stat ADD FOREIGN KEY (indicator_id) REFERENCES "core".dim_indicator(indicator_id);




-- Adding region table into staging

---creating tables

create table "staging".indicators_region (like "staging".indicators including all);

create table "staging".fact_region_stat (like "staging".indicators including all);


---inserting REGIONS to table
INSERT INTO "staging".indicators_region
SELECT * FROM "staging".indicators
WHERE country_code IN (
'AFE',
'AFW',
'ARB',
'CEB',
'CSS',
'EAP',
'EAR',
'EAS',
'ECA',
'ECS',
'EMU',
'EUU',
'FCS',
'HIC',
'HPC',
'IBD',
'IBT',
'IDA',
'IDB',
'IDX',
'LAC',
'LCN',
'LDC',
'LIC',
'LMC',
'LMY',
'LTE',
'MEA',
'MIC',
'MNA',
'NAC',
'OED',
'OSS',
'PRE',
'PSS',
'PST',
'SAS',
'SSA',
'SSF',
'SST',
'TEA',
'TEC',
'TLA',
'TMN',
'TSA',
'TSS',
'UMC',
'WLD'
);



---inseting REGIONS WTIH WANTED INDICATORS to FACT table

INSERT INTO "staging".fact_region_stat
SELECT * FROM "staging".indicators_region
WHERE indicator_code IN (
'BG.GSR.NFSV.GD.ZS',
'BM.GSR.CMCP.ZS',
'BM.GSR.GNFS.CD',
'BM.GSR.INSF.ZS',
'BM.GSR.MRCH.CD',
'BM.GSR.NFSV.CD',
'BM.GSR.TOTL.CD',
'BM.GSR.TRAN.ZS',
'BM.GSR.TRVL.ZS',
'BN.CAB.XOKA.CD',
'BN.CAB.XOKA.GD.ZS',
'BN.GSR.GNFS.CD',
'BN.GSR.MRCH.CD',
'BX.GSR.CCIS.CD',
'BX.GSR.CCIS.ZS',
'BX.GSR.CMCP.ZS',
'BX.GSR.GNFS.CD',
'BX.GSR.INSF.ZS',
'BX.GSR.MRCH.CD',
'BX.GSR.NFSV.CD',
'BX.GSR.TOTL.CD',
'BX.GSR.TRAN.ZS',
'BX.GSR.TRVL.ZS',
'DT.DOD.DSTC.XP.ZS',
'DT.DOD.PVLX.EX.ZS',
'DT.NFL.BLAT.CD',
'DT.NFL.FAOG.CD',
'DT.NFL.IAEA.CD',
'DT.NFL.IFAD.CD',
'DT.NFL.ILOG.CD',
'DT.NFL.OFFT.CD',
'DT.NFL.PROP.CD',
'DT.NFL.PRVT.CD',
'DT.NFL.UNAI.CD',
'DT.NFL.UNCF.CD',
'DT.NFL.UNCR.CD',
'DT.NFL.UNDP.CD',
'DT.NFL.UNEC.CD',
'DT.NFL.UNEP.CD',
'DT.NFL.UNFP.CD',
'DT.NFL.UNID.CD',
'DT.NFL.UNPB.CD',
'DT.NFL.UNRW.CD',
'DT.NFL.UNTA.CD',
'DT.NFL.UNWT.CD',
'DT.NFL.WFPG.CD',
'DT.NFL.WHOL.CD',
'DT.ODA.ODAT.MP.ZS',
'DT.TDS.DECT.EX.ZS',
'DT.TDS.DPPF.XP.ZS',
'DT.TDS.DPPG.XP.ZS',
'EG.IMP.CONS.ZS',
'EG.USE.COMM.GD.PP.KD',
'EG.USE.PCAP.KG.OE',
'FI.RES.TOTL.MO',
'FP.WPI.TOTL',
'GC.TAX.EXPT.CN',
'GC.TAX.EXPT.ZS',
'GC.TAX.IMPT.CN',
'GC.TAX.IMPT.ZS',
'GC.TAX.INTT.CN',
'GC.TAX.INTT.RV.ZS',
'IC.CUS.DURS.EX',
'IC.EXP.CSBC.CD',
'IC.EXP.CSDC.CD',
'IC.EXP.TMBC',
'IC.EXP.TMDC',
'IC.IMP.CSBC.CD',
'IC.IMP.CSDC.CD',
'IC.IMP.TMBC',
'IC.IMP.TMDC',
'LP.EXP.DURS.MD',
'LP.IMP.DURS.MD',
'LP.LPI.CUST.XQ',
'LP.LPI.INFR.XQ',
'LP.LPI.ITRN.XQ',
'LP.LPI.LOGS.XQ',
'LP.LPI.OVRL.XQ',
'LP.LPI.TIME.XQ',
'LP.LPI.TRAC.XQ',
'MS.MIL.MPRT.KD',
'MS.MIL.XPRT.KD',
'NE.EXP.GNFS.CD',
'NE.EXP.GNFS.CN',
'NE.EXP.GNFS.KD',
'NE.EXP.GNFS.KD.ZG',
'NE.EXP.GNFS.KN',
'NE.EXP.GNFS.ZS',
'NE.IMP.GNFS.CD',
'NE.IMP.GNFS.CN',
'NE.IMP.GNFS.KD',
'NE.IMP.GNFS.KD.ZG',
'NE.IMP.GNFS.KN',
'NE.IMP.GNFS.ZS',
'NE.RSB.GNFS.CD',
'NE.RSB.GNFS.CN',
'NE.RSB.GNFS.KN',
'NE.RSB.GNFS.ZS',
'NE.TRD.GNFS.ZS',
'NV.SRV.TOTL.CD',
'NV.SRV.TOTL.CN',
'NV.SRV.TOTL.KD',
'NV.SRV.TOTL.KD.ZG',
'NV.SRV.TOTL.KN',
'NV.SRV.TOTL.ZS',
'NY.EXP.CAPM.KN',
'NY.TTF.GNFS.KN',
'ST.INT.RCPT.CD',
'ST.INT.RCPT.XP.ZS',
'ST.INT.TVLR.CD',
'ST.INT.TVLX.CD',
'ST.INT.XPND.CD',
'ST.INT.XPND.MP.ZS',
'TG.VAL.TOTL.GD.ZS',
'TM.QTY.MRCH.XD.WD',
'TM.TAX.MANF.WM.AR.ZS',
'TM.TAX.MANF.WM.FN.ZS',
'TM.TAX.MRCH.WM.AR.ZS',
'TM.TAX.MRCH.WM.FN.ZS',
'TM.TAX.TCOM.WM.AR.ZS',
'TM.TAX.TCOM.WM.FN.ZS',
'TM.UVI.MRCH.XD.WD',
'TM.VAL.AGRI.ZS.UN',
'TM.VAL.FOOD.ZS.UN',
'TM.VAL.FUEL.ZS.UN',
'TM.VAL.ICTG.ZS.UN',
'TM.VAL.INSF.ZS.WT',
'TM.VAL.MANF.ZS.UN',
'TM.VAL.MMTL.ZS.UN',
'TM.VAL.MRCH.AL.ZS',
'TM.VAL.MRCH.CD.WT',
'TM.VAL.MRCH.HI.ZS',
'TM.VAL.MRCH.OR.ZS',
'TM.VAL.MRCH.R1.ZS',
'TM.VAL.MRCH.R2.ZS',
'TM.VAL.MRCH.R3.ZS',
'TM.VAL.MRCH.R4.ZS',
'TM.VAL.MRCH.R5.ZS',
'TM.VAL.MRCH.R6.ZS',
'TM.VAL.MRCH.RS.ZS',
'TM.VAL.MRCH.WL.CD',
'TM.VAL.MRCH.WR.ZS',
'TM.VAL.MRCH.XD.WD',
'TM.VAL.OTHR.ZS.WT',
'TM.VAL.SERV.CD.WT',
'TM.VAL.TRAN.ZS.WT',
'TM.VAL.TRVL.ZS.WT',
'TT.PRI.MRCH.XD.WD',
'TX.MNF.TECH.ZS.UN',
'TX.QTY.MRCH.XD.WD',
'TX.UVI.MRCH.XD.WD',
'TX.VAL.AGRI.ZS.UN',
'TX.VAL.FOOD.ZS.UN',
'TX.VAL.FUEL.ZS.UN',
'TX.VAL.ICTG.ZS.UN',
'TX.VAL.INSF.ZS.WT',
'TX.VAL.MANF.ZS.UN',
'TX.VAL.MMTL.ZS.UN',
'TX.VAL.MRCH.AL.ZS',
'TX.VAL.MRCH.CD.WT',
'TX.VAL.MRCH.HI.ZS',
'TX.VAL.MRCH.OR.ZS',
'TX.VAL.MRCH.R1.ZS',
'TX.VAL.MRCH.R2.ZS',
'TX.VAL.MRCH.R3.ZS',
'TX.VAL.MRCH.R4.ZS',
'TX.VAL.MRCH.R5.ZS',
'TX.VAL.MRCH.R6.ZS',
'TX.VAL.MRCH.RS.ZS',
'TX.VAL.MRCH.WL.CD',
'TX.VAL.MRCH.WR.ZS',
'TX.VAL.MRCH.XD.WD',
'TX.VAL.OTHR.ZS.WT',
'TX.VAL.SERV.CD.WT',
'TX.VAL.TECH.CD',
'TX.VAL.TECH.MF.ZS',
'TX.VAL.TRAN.ZS.WT',
'TX.VAL.TRVL.ZS.WT'
);


--Changing column_name

ALTER TABLE "staging".fact_region_stat
RENAME COLUMN country_name TO region_name;

ALTER TABLE "staging".fact_region_stat
RENAME COLUMN country_code TO region_code;


---Adding indicator_id and country_id columns into staging fact_region_stat table
ALTER TABLE "staging".fact_region_stat
ADD COLUMN indicator_id INT REFERENCES "staging".dim_indicator (indicator_id);

ALTER TABLE "staging".fact_region_stat
ADD COLUMN region_id INT REFERENCES "staging".dim_region (region_id);


---Updating columns compared to dim_region.region_id
UPDATE "staging".fact_region_stat rs
SET region_id = dr.region_id FROM "staging".dim_region dr
WHERE rs.region_name = dr.region_name;


---Updating columns compared to dim_indicator.indicator_id
UPDATE "staging".fact_region_stat rs
SET indicator_id = di.indicator_id FROM "staging".dim_indicator di
WHERE rs.indicator_code = di.indicator_code; 
 
-- Dropping column region_name, region_code, indicator_name and indicator_code
ALTER TABLE "staging".fact_region_stat
DROP COLUMN indicator_code;

ALTER TABLE "staging".fact_region_stat
DROP COLUMN region_name;

ALTER TABLE "staging".fact_region_stat
DROP COLUMN region_code;

ALTER TABLE "staging".fact_region_stat
DROP COLUMN indicator_name;

-- Adding primary key serial into fact_region_stat
ALTER TABLE "staging".fact_region_stat ADD COLUMN stat_id SERIAL PRIMARY KEY;

-- Creating country_stat table into core
SELECT * INTO "core".fact_region_stat FROM "staging".fact_region_stat;

ALTER TABLE "core".fact_region_stat ADD PRIMARY KEY(stat_id);

ALTER TABLE "core".fact_region_stat ADD FOREIGN KEY (region_id) REFERENCES "core".dim_region(region_id);

ALTER TABLE "core".fact_region_stat ADD FOREIGN KEY (indicator_id) REFERENCES "core".dim_indicator(indicator_id);
