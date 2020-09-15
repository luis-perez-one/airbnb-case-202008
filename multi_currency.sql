CREATE TABLE moneda (
    id VARCHAR(4) PRIMARY KEY
);

INSERT INTO moneda(id) VALUES 
    ('MXN'), ('BRL'), ('CLP'), ('USD');

CREATE TABLE tipo_cambio (
    id SERIAL PRIMARY KEY,
    moneda_origen VARCHAR(4),
    moneda_destino VARCHAR(4),
    valor NUMERIC

    CONSTRAINT postivie_ex_rates 
        CHECK (valor > 0),

    CONSTRAINT moneda_origen_fk
        FOREIGN KEY (moneda_origen)
        REFERENCES moneda(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT moneda_destino_fk
        FOREIGN KEY (moneda_destino)
        REFERENCES moneda(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

);

INSERT INTO tipo_cambio
            (moneda_origen,
            moneda_destino,
            valor)
            VALUES
            ('MXN','USD', 21.91),
            ('CLP','USD', 768.40),
            ('BRL','USD', 5.14)
        ;

ALTER TABLE listing ADD COLUMN moneda_id VARCHAR(4);
ALTER TABLE listing ADD COLUMN price_usd NUMERIC;
ALTER TABLE listing ADD COLUMN weekly_price_usd NUMERIC;
ALTER TABLE listing ADD COLUMN monthly_price_usd NUMERIC;
ALTER TABLE listing ADD COLUMN security_deposit_usd NUMERIC;
ALTER TABLE listing ADD COLUMN cleaning_fee_usd NUMERIC;
ALTER TABLE listing ADD COLUMN extra_people_usd NUMERIC;
ALTER TABLE listing ADD COLUMN price_per_people NUMERIC;
ALTER TABLE listing ADD COLUMN price_per_people_full_cap NUMERIC;
ALTER TABLE listing ADD COLUMN price_per_people_usd NUMERIC;
ALTER TABLE listing ADD COLUMN price_per_people_full_cap_usd NUMERIC;

UPDATE listing SET price_per_people = price / guests_included;
UPDATE listing SET price_per_people_full_cap =(price + ((accommodates-guests_included)*extra_people))/accommodates;

UPDATE listing SET price_per_people_

ALTER TABLE listing ADD CONSTRAINT
    moneda_id_fk FOREIGN KEY (moneda_id)
        REFERENCES moneda(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
    ;

UPDATE listing SET
    moneda_id = 'MXN'
    WHERE city_id = 'CDMX'
;

UPDATE listing SET
    moneda_id = 'CLP'
    WHERE city_id = 'STGO'
;

UPDATE listing SET
    moneda_id = 'BRL'
    WHERE city_id = 'RIO'
;

CREATE OR REPLACE FUNCTION 
    convertir_a_usd
        (_moneda_origen VARCHAR(4), _importe_origen NUMERIC)
        RETURNS NUMERIC
        LANGUAGE plpgsql
        SECURITY DEFINER
    
    AS
    $$
    DECLARE
        _importe_usd NUMERIC;
        _valor_tipo_cambio NUMERIC;
        _importe_destino NUMERIC;
    
    BEGIN
        SELECT valor INTO _valor_tipo_cambio
            FROM tipo_cambio
            WHERE (
                    moneda_origen = _moneda_origen AND
                    moneda_destino = 'USD'
            );
            _importe_destino = _importe_origen / _valor_tipo_cambio ;
        

        RETURN _importe_destino;
    
    END;
    $$
    ;

CREATE OR REPLACE FUNCTION public.actualizar_montos_usd_listings()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    
    AS $BODY$

    DECLARE
    valor_tipo_cambio NUMERIC;

    BEGIN
        SELECT valor INTO valor_tipo_cambio FROM
        public.tipo_cambio WHERE (
            tipo_cambio.moneda_origen = NEW.moneda_origen AND
            tipo_cambio.moneda_Destino = 'USA');

        UPDATE public.listing SET price_usd =
            convertir_a_usd(moneda_id, price) 
            WHERE moneda_id = NEW.moneda_origen;
        
        UPDATE public.listing SET weekly_price_usd =
            convertir_a_usd(moneda_id, weekly_price) 
            WHERE moneda_id = NEW.moneda_origen;
        
        UPDATE public.listing SET monthly_price_usd =
            convertir_a_usd(moneda_id, monthly_price) 
            WHERE moneda_id = NEW.moneda_origen;

        UPDATE public.listing SET security_deposit_usd =
            convertir_a_usd(moneda_id, security_deposit) 
            WHERE moneda_id = NEW.moneda_origen;

        UPDATE public.listing SET cleaning_fee_usd =
            convertir_a_usd(moneda_id, cleaning_fee) 
            WHERE moneda_id = NEW.moneda_origen;
        
        UPDATE public.listing SET extra_people_usd =
            convertir_a_usd(moneda_id, extra_people) 
            WHERE moneda_id = NEW.moneda_origen;

        UPDATE public.listing SET price_per_people_usd =
            convertir_a_usd(moneda_id, price_per_people) 
            WHERE moneda_id = NEW.moneda_origen;    

        UPDATE public.listing SET price_per_people_full_cap_usd =
            convertir_a_usd(moneda_id, price_per_people_full_cap) 
            WHERE moneda_id = NEW.moneda_origen;  

    RETURN NEW;
    
    END;
    $BODY$
    ;


CREATE TRIGGER tr_cal_usd_amounts
    AFTER INSERT OR UPDATE
    ON public.tipo_cambio
    FOR EACH ROW
    EXECUTE PROCEDURE public.actualizar_montos_usd_listings()
    ;
