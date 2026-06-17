-- =============================================================
-- TURBO ENTREGAS — Fix: payment_method nullable em disbursement_details
-- Migration: 2026_05_08_000004_fix_payment_method_nullable_in_disbursement_details
-- Criado em: 08/05/2026
-- Motivo: payment_method era NOT NULL, mas entregadores PIX não possuem
--         método de saque cadastrado — o INSERT falhava silenciosamente
--         retornando "unable to create disbursement request".
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

ALTER TABLE `disbursement_details`
  MODIFY COLUMN `payment_method` BIGINT UNSIGNED NULL DEFAULT NULL;

-- Para desfazer (restaura NOT NULL, só se todos os registros tiverem valor):
-- ALTER TABLE `disbursement_details`
--   MODIFY COLUMN `payment_method` BIGINT UNSIGNED NOT NULL;
