-- ══════════════════════════════════════════════════════════════════════════════════
-- SCRIPT SQL: Criação das tabelas para API de Integração Externa
-- Data: 2026-05-15
-- Descrição: Cria tabelas e colunas necessárias para sistema de tokens de API
-- ══════════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────────
-- 1. Criar tabela user_api_tokens
-- ─────────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `user_api_tokens` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `token` VARCHAR(64) NOT NULL UNIQUE,
    `label` VARCHAR(255) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `reserved_balance` DECIMAL(20, 2) DEFAULT 0.00 COMMENT 'Saldo bloqueado por pedidos pendentes',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT `fk_user_api_tokens_user_id` 
        FOREIGN KEY (`user_id`) 
        REFERENCES `users`(`id`) 
        ON DELETE CASCADE,
    
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_token` (`token`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────────
-- 2. Adicionar colunas na tabela orders
-- ─────────────────────────────────────────────────────────────────────────────────

-- Compatibilidade com versões de MySQL/MariaDB sem suporte a IF NOT EXISTS em ALTER

-- Adiciona coluna external_reference_id se não existir
SET @has_external_reference_id := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'orders'
      AND COLUMN_NAME = 'external_reference_id'
);
SET @sql := IF(
    @has_external_reference_id = 0,
    'ALTER TABLE `orders` ADD COLUMN `external_reference_id` VARCHAR(100) NULL COMMENT ''ID do pedido gerado pelo sistema externo (remetente)''',
    'SELECT ''Coluna external_reference_id ja existe'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adiciona coluna api_token_id se não existir
SET @has_api_token_id := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'orders'
      AND COLUMN_NAME = 'api_token_id'
);
SET @sql := IF(
    @has_api_token_id = 0,
    'ALTER TABLE `orders` ADD COLUMN `api_token_id` BIGINT UNSIGNED NULL COMMENT ''Token de API usado para criar o pedido''',
    'SELECT ''Coluna api_token_id ja existe'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adiciona índice idx_external_reference_id se não existir
SET @has_idx_external_reference_id := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'orders'
      AND INDEX_NAME = 'idx_external_reference_id'
);
SET @sql := IF(
    @has_idx_external_reference_id = 0,
    'ALTER TABLE `orders` ADD INDEX `idx_external_reference_id` (`external_reference_id`)',
    'SELECT ''Indice idx_external_reference_id ja existe'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adiciona índice idx_api_token_id se não existir
SET @has_idx_api_token_id := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'orders'
      AND INDEX_NAME = 'idx_api_token_id'
);
SET @sql := IF(
    @has_idx_api_token_id = 0,
    'ALTER TABLE `orders` ADD INDEX `idx_api_token_id` (`api_token_id`)',
    'SELECT ''Indice idx_api_token_id ja existe'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Adiciona FK fk_orders_api_token_id se não existir
SET @has_fk_orders_api_token_id := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'orders'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
      AND CONSTRAINT_NAME = 'fk_orders_api_token_id'
);
SET @sql := IF(
    @has_fk_orders_api_token_id = 0,
    'ALTER TABLE `orders` ADD CONSTRAINT `fk_orders_api_token_id` FOREIGN KEY (`api_token_id`) REFERENCES `user_api_tokens`(`id`) ON DELETE SET NULL',
    'SELECT ''FK fk_orders_api_token_id ja existe'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ─────────────────────────────────────────────────────────────────────────────────
-- 3. Dados iniciais (exemplo de token de teste)
-- ─────────────────────────────────────────────────────────────────────────────────

-- Exemplo: Criar um token de teste para o usuário com ID 1
-- (Ajuste o user_id conforme necessário)
-- INSERT INTO `user_api_tokens` (`user_id`, `token`, `label`, `is_active`, `reserved_balance`)
-- VALUES (1, 'test_token_64_characters_abcdefghijklmnopqrstuvwxyz1234567890', 'Token de Teste', TRUE, 0.00);

-- ─────────────────────────────────────────────────────────────────────────────────
-- Fim do script
-- ─────────────────────────────────────────────────────────────────────────────────
