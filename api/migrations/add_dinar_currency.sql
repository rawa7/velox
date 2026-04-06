-- Add Iraqi Dinar to currency table (run once on database dasroor_velox)
-- Skip if you already have a row with currencycode = 'IQD'
INSERT INTO `currency` (`currencyname`, `currencysign`, `currencycode`, `currencyconvert`)
SELECT * FROM (SELECT 'Dinar' AS currencyname, 'د.ع' AS currencysign, 'IQD' AS currencycode, 1 AS currencyconvert) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `currency` WHERE `currencycode` = 'IQD' LIMIT 1);
