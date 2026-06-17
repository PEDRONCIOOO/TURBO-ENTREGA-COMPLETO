-- =============================================================
-- TURBO ENTREGAS — Criação da tabela dm_cash_logs
-- Migration: 2026_05_08_000005_create_dm_cash_logs_table
-- Criado em: 08/05/2026
-- Motivo: Rastrear todas as transações de dinheiro em mãos dos
--         entregadores: atribuição de cash ao completar pedido
--         e ajustes de carteira (parcial/completo).
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

-- 1) Nova tabela de logs de caixa
CREATE TABLE IF NOT EXISTS `dm_cash_logs` (
    `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_man_id`       BIGINT UNSIGNED NOT NULL,
    `order_id`              BIGINT UNSIGNED NULL DEFAULT NULL,
    `type`                  ENUM('cash_assigned','adjustment_partial','adjustment_full') NOT NULL,
    `amount`                DECIMAL(24,2) NOT NULL DEFAULT 0.00
                                COMMENT 'Valor desta transação: comissão atribuída (cash_assigned) ou valor abatido (adjustment)',
    `order_amount`          DECIMAL(24,2) NOT NULL DEFAULT 0.00
                                COMMENT 'Valor total do pedido (somente para cash_assigned; 0 nos ajustes)',
    `collected_cash_after`  DECIMAL(24,2) NOT NULL DEFAULT 0.00
                                COMMENT 'Saldo de dinheiro em mãos APÓS esta transação',
    `digital_balance_after` DECIMAL(24,2) NOT NULL DEFAULT 0.00
                                COMMENT 'Saldo digital (PIX) APÓS esta transação',
    `note`                  VARCHAR(500) NULL DEFAULT NULL,
    `created_at`            TIMESTAMP NULL DEFAULT NULL,
    `updated_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `dm_cash_logs_dm_id_idx`      (`delivery_man_id`),
    INDEX `dm_cash_logs_order_id_idx`   (`order_id`),
    INDEX `dm_cash_logs_type_idx`       (`type`),
    INDEX `dm_cash_logs_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2) Nova coluna na tabela delivery_man_wallets
--    Guarda os ganhos físicos de parcel em dinheiro (não entram no saldo digital)
--    para exibição correta do "Total Ganho Acumulado" no app do entregador.
ALTER TABLE `delivery_man_wallets`
    ADD COLUMN IF NOT EXISTS `total_cash_parcel_earned`
        DECIMAL(24,8) NOT NULL DEFAULT 0
        COMMENT 'Soma dos ganhos físicos de pedidos parcel pagos em dinheiro';
