-- Adiciona coluna que define a base de cálculo da taxa da parada extra:
--   'main_fee'       → percentual sobre a taxa da ENTREGA PRINCIPAL (padrão)
--   'extra_distance' → percentual sobre o valor calculado para a DISTÂNCIA DA PARADA EXTRA
ALTER TABLE parcel_categories
    ADD COLUMN extra_stop_fee_basis ENUM('main_fee', 'extra_distance')
        NOT NULL DEFAULT 'main_fee'
    AFTER extra_stop_percentage;
