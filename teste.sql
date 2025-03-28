DELIMITER //

CREATE PROCEDURE Excluir_e_c_3Lotes()
BEGIN
    DECLARE v_lote INT DEFAULT 0;
    DECLARE v_max_lotes INT DEFAULT 3;
    DECLARE v_rows INT DEFAULT 1;
    DECLARE v_total_e INT DEFAULT 0;
    DECLARE v_total_c INT DEFAULT 0;
    DECLARE v_batch INT DEFAULT 10000;
    DECLARE v_c_afetados INT DEFAULT 0;
    
    SELECT 'INICIANDO PROCESSO EM 3 LOTES' AS msg;
    
    WHILE v_lote < v_max_lotes AND v_rows > 0 DO
        START TRANSACTION;
        
        SET v_lote = v_lote + 1;
        SELECT CONCAT('Lote ', v_lote, '/', v_max_lotes) AS lote_atual;
        
        -- 1. DELETE para 'e' (antigas elegibilidades)
        DELETE FROM te -- tbvq037_elgd_funo_ccre_clie
        WHERE num_cpf_cnpj_titu_cccr IN (
            SELECT DISTINCT tc.num_cpf_cnpj_titu_cccr
            FROM tc -- tbvq036_info_ccre_clie
            JOIN te e_sub
                ON tc.num_cpf_cnpj_titu_cccr = e_sub.num_cpf_cnpj_titu_cccr
            WHERE tc.ind_titu_ccre = 'A'
              AND e_sub.cod_funo_ccre = 11
        )
        LIMIT v_batch;
        
        SET v_rows = ROW_COUNT();
        SET v_total_e = v_total_e + v_rows;
        
        -- 2. DELETE para 'c' sem 'e' (antigos cartões sem elegibilidade)
        DELETE FROM tc -- tbvq036_info_ccre_clie
        WHERE NOT EXISTS (
            SELECT 1 FROM te
            WHERE te.num_cpf_cnpj_titu_cccr = tc.num_cpf_cnpj_titu_cccr
        )
        LIMIT v_batch;
        
        SET v_c_afetados = ROW_COUNT();
        SET v_total_c = v_total_c + v_c_afetados;
        
        COMMIT;
        
        -- Relatório
        SELECT CONCAT(
            'Lote ', v_lote, ': ',
            v_rows, ' e, ',
            v_c_afetados, ' c. ',
            'Total: ', v_total_e, ' e, ',
            v_total_c, ' c'
        ) AS resultado;
        
        -- Pausa entre lotes (exceto último)
        IF v_lote < v_max_lotes AND (v_rows > 0 OR v_c_afetados > 0) THEN
            DO SLEEP(1);
        END IF;
        
        -- Reset
        SET v_rows = GREATEST(v_rows, v_c_afetados);
        SET v_c_afetados = 0;
    END WHILE;
    
    SELECT CONCAT(
        'FIM. Lotes: ', v_lote, '. ',
        'Totais: ', v_total_e, ' e, ',
        v_total_c, ' c'
    ) AS final;
END //

DELIMITER ;