-- =============================================================
-- TURBO ENTREGAS — Entrega Adicional
-- Criado em: 07/05/2026
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

CREATE TABLE IF NOT EXISTS `order_additional_stops` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`              BIGINT UNSIGNED NOT NULL,
  `sequence`              TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `delivery_address`      JSON NOT NULL,
  `delivery_instruction`  VARCHAR(500) DEFAULT NULL,
  `distance_km`           DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
  `extra_delivery_charge` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status`                VARCHAR(20) NOT NULL DEFAULT 'pending',
  `delivered_at`          TIMESTAMP NULL DEFAULT NULL,
  `created_at`            TIMESTAMP NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  KEY `oas_order_id_idx` (`order_id`),
  KEY `oas_status_idx` (`status`),

  CONSTRAINT `fk_oas_order_id`
    FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
