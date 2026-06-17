-- =============================================================
-- TURBO ENTREGAS — Solicitação de Redefinição de Chave PIX
-- Migration: 2026_05_08_000001_add_pix_reset_requested_to_pix_accounts
-- Criado em: 08/05/2026
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================
--
-- Adiciona as colunas que controlam o fluxo de solicitação de
-- reset de chave PIX pelo entregador:
--   pix_reset_requested    → flag booleana (0/1)
--   pix_reset_requested_at → data/hora da solicitação
--

ALTER TABLE `delivery_man_pix_accounts`
    ADD COLUMN IF NOT EXISTS `pix_reset_requested`    TINYINT(1)  NOT NULL DEFAULT 0    AFTER `is_verified`,
    ADD COLUMN IF NOT EXISTS `pix_reset_requested_at` TIMESTAMP   NULL     DEFAULT NULL  AFTER `pix_reset_requested`;

-- Para desfazer:
-- ALTER TABLE `delivery_man_pix_accounts`
--     DROP COLUMN IF EXISTS `pix_reset_requested`,
--     DROP COLUMN IF EXISTS `pix_reset_requested_at`;
