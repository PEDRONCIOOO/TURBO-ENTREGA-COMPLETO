-- Move todos os entregadores da zona "Brasil" para a zona "Dourados".
-- Pela tela atual: Brasil = id 2, Dourados = id 4.
-- Este script usa os nomes para reduzir risco caso IDs mudem entre ambientes.

START TRANSACTION;

-- Conferencia antes de alterar.
SELECT id, name, status FROM zones WHERE name IN ('Brasil', 'Dourados') ORDER BY id;

SELECT
  dm.zone_id,
  z.name AS zone_name,
  COUNT(*) AS delivery_men_count
FROM delivery_men dm
JOIN zones z ON z.id = dm.zone_id
WHERE z.name IN ('Brasil', 'Dourados')
GROUP BY dm.zone_id, z.name
ORDER BY dm.zone_id;

-- Move somente entregadores zone_wise da zona Brasil para Dourados.
UPDATE delivery_men
SET
  zone_id = (SELECT id FROM zones WHERE name = 'Dourados' LIMIT 1),
  updated_at = NOW()
WHERE
  type = 'zone_wise'
  AND zone_id = (SELECT id FROM zones WHERE name = 'Brasil' LIMIT 1);

-- Conferencia depois de alterar.
SELECT
  dm.zone_id,
  z.name AS zone_name,
  COUNT(*) AS delivery_men_count
FROM delivery_men dm
JOIN zones z ON z.id = dm.zone_id
WHERE z.name IN ('Brasil', 'Dourados')
GROUP BY dm.zone_id, z.name
ORDER BY dm.zone_id;

COMMIT;

-- Se notar algo errado antes do COMMIT, troque COMMIT por ROLLBACK.
--
-- Importante para notificacoes:
-- depois dessa mudanca, os entregadores precisam deslogar/logar ou atualizar o FCM token
-- para assinar o novo topico da zona Dourados.
