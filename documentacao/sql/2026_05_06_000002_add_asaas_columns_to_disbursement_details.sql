-- =============================================================
-- TURBO ENTREGAS — Colunas Asaas em disbursement_details
-- Migration: 2026_05_06_000002_add_asaas_columns_to_disbursement_details_table
-- Criado em: 06/05/2026
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

ALTER TABLE `disbursement_details`
  ADD COLUMN `payout_provider`     VARCHAR(30)  DEFAULT NULL AFTER `payment_method`,
  ADD COLUMN `payout_status`       VARCHAR(30)  DEFAULT NULL AFTER `payout_provider`,
  ADD COLUMN `asaas_transfer_id`   VARCHAR(191) DEFAULT NULL AFTER `payout_status`,
  ADD COLUMN `payout_error`        TEXT         DEFAULT NULL AFTER `asaas_transfer_id`,
  ADD COLUMN `payout_processed_at` TIMESTAMP    NULL DEFAULT NULL AFTER `payout_error`;

-- Para desfazer:
-- ALTER TABLE `disbursement_details`
--   DROP COLUMN `payout_provider`,
--   DROP COLUMN `payout_status`,
--   DROP COLUMN `asaas_transfer_id`,
--   DROP COLUMN `payout_error`,
--   DROP COLUMN `payout_processed_at`;
