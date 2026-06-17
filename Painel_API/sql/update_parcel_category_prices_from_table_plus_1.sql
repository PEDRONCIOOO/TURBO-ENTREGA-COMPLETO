-- Atualiza TODAS as categorias de encomenda com a tabela enviada + R$ 1,00.
--
-- Como o sistema calcula:
--   valor final = parcel_minimum_shipping_charge + soma das faixas em distance_pricing_rules
--
-- A imagem informa valores finais por distancia. Por isso, abaixo:
--   0 a 1 km  -> parcel_minimum_shipping_charge = 8.10
--   1 a 2 km  -> diferenca entre 9.20 e 8.10 = 1.10 por km
--   ...
--
-- Conferir colunas antes de executar:
-- SHOW COLUMNS FROM parcel_categories
-- WHERE Field IN (
--   'parcel_minimum_shipping_charge',
--   'minimum_shipping_distance_km',
--   'parcel_per_km_shipping_charge',
--   'parcel_per_km_return_shipping_charge',
--   'distance_pricing_rules',
--   'charge_fractional_km',
--   'fractional_rounding'
-- );

START TRANSACTION;

UPDATE parcel_categories
SET
  -- 0 a 1 Km na tabela original: S/Volta 7.10, C/Volta 7.50.
  -- Com +1.00: S/Volta 8.10, C/Volta 8.50.
  parcel_minimum_shipping_charge = 8.10,
  minimum_shipping_distance_km = 1.00,

  -- Default usado se passar da ultima faixa cadastrada.
  -- Mantido no mesmo incremento final da tabela.
  parcel_per_km_shipping_charge = 1.10,
  parcel_per_km_return_shipping_charge = 1.50,

  -- Faixas convertidas para incremento por km, para o calculo bater com os totais da imagem + R$ 1,00.
  distance_pricing_rules = JSON_ARRAY(
    JSON_OBJECT('from', 1,  'to', 2,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 2,  'to', 3,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 3,  'to', 4,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 4,  'to', 5,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 5,  'to', 6,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 6,  'to', 7,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 7,  'to', 8,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 8,  'to', 9,  'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 9,  'to', 10, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 10, 'to', 11, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 11, 'to', 12, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 12, 'to', 13, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 13, 'to', 14, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 14, 'to', 15, 'price_per_km', 9.10, 'return_price_per_km', 9.50),
    JSON_OBJECT('from', 15, 'to', 16, 'price_per_km', 4.10, 'return_price_per_km', 4.50),
    JSON_OBJECT('from', 16, 'to', 17, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 17, 'to', 18, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 18, 'to', 19, 'price_per_km', 1.10, 'return_price_per_km', 1.50),
    JSON_OBJECT('from', 19, 'to', 20, 'price_per_km', 1.10, 'return_price_per_km', 1.50)
  ),

  -- Mantem comportamento inteiro por km, coerente com a tabela 0-1, 1-2, etc.
  charge_fractional_km = 0,
  fractional_rounding = 'ceil',
  updated_at = NOW();

-- Conferencia rapida depois do update:
SELECT
  id,
  name,
  parcel_minimum_shipping_charge,
  minimum_shipping_distance_km,
  parcel_per_km_shipping_charge,
  parcel_per_km_return_shipping_charge,
  distance_pricing_rules
FROM parcel_categories
ORDER BY id;

-- Se a conferencia estiver correta:
COMMIT;

-- Se algo estiver errado antes do COMMIT, rode:
-- ROLLBACK;
