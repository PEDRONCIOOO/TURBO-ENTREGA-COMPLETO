-- =============================================================
-- TURBO ENTREGAS — Conta PIX do Entregador (Asaas)
-- Migration: 2026_05_06_000001_create_delivery_man_pix_accounts_table
-- Criado em: 06/05/2026
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

CREATE TABLE IF NOT EXISTS `delivery_man_pix_accounts` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_man_id`  BIGINT UNSIGNED NOT NULL,
  `pix_key`          VARCHAR(191)    NOT NULL,
  `pix_key_type`     VARCHAR(20)     DEFAULT NULL,  -- CPF | CNPJ | EMAIL | PHONE | EVP
  `holder_name`      VARCHAR(191)    DEFAULT NULL,
  `holder_document`  VARCHAR(30)     DEFAULT NULL,
  `is_verified`      TINYINT(1)      NOT NULL DEFAULT 0,
  `created_at`       TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP       NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `delivery_man_pix_accounts_delivery_man_id_unique` (`delivery_man_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Para desfazer:
-- DROP TABLE IF EXISTS `delivery_man_pix_accounts`;
