-- =============================================================
-- TURBO ENTREGAS — Entrega Adicional: % configurável por categoria
-- Criado em: 08/05/2026
-- Rodar no phpMyAdmin no banco de dados do Painel_API
-- =============================================================

ALTER TABLE `parcel_categories`
  ADD COLUMN `extra_stop_percentage` DECIMAL(5,2) NOT NULL DEFAULT 40.00
    COMMENT 'Percentual da taxa principal cobrado por parada adicional (ex: 40 = 40%)'
  AFTER `fractional_rounding`;
