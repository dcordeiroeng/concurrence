DELIMITER //

CREATE PROCEDURE ExcluirCartoesElegibilidades_3Lotes()
BEGIN
    DECLARE v_lote_count INT DEFAULT 0;
    DECLARE v_max_lotes INT DEFAULT 3;
    DECLARE v_rows_affected INT DEFAULT 1;
    DECLARE v_total_elegibilidades INT DEFAULT 0;
    DECLARE v_total_cartoes INT DEFAULT 0;
    DECLARE v_batch_size INT DEFAULT 10000;
    DECLARE v_cartoes_afetados INT DEFAULT 0;
    
    SELECT 'INICIANDO PROCESSO DE EXCLUSÃO EM 3 LOTES' AS mensagem;
    
    WHILE v_lote_count < v_max_lotes AND v_rows_affected > 0 DO
        START TRANSACTION;
        
        SET v_lote_count = v_lote_count + 1;
        SELECT CONCAT('Processando lote ', v_lote_count, ' de ', v_max_lotes) AS mensagem_lote;
        
        -- 1. DELETE para elegibilidades usando EXISTS em vez de JOIN com subquery
        DELETE FROM tbvq037_elgd_funo_ccre_clie
        WHERE num_cpf_cnpj_titu_cccr IN (
            SELECT DISTINCT cartoes.num_cpf_cnpj_titu_cccr
            FROM tbvq036_info_ccre_clie cartoes
            JOIN tbvq037_elgd_funo_ccre_clie elegibilidades_sub
                ON cartoes.num_cpf_cnpj_titu_cccr = elegibilidades_sub.num_cpf_cnpj_titu_cccr
            WHERE cartoes.ind_titu_ccre = 'A'
              AND elegibilidades_sub.cod_funo_ccre = 11
        )
        LIMIT v_batch_size;
        
        SET v_rows_affected = ROW_COUNT();
        SET v_total_elegibilidades = v_total_elegibilidades + v_rows_affected;
        
        -- 2. DELETE para cartões sem elegibilidade
        DELETE FROM tbvq036_info_ccre_clie
        WHERE NOT EXISTS (
            SELECT 1 FROM tbvq037_elgd_funo_ccre_clie
            WHERE tbvq037_elgd_funo_ccre_clie.num_cpf_cnpj_titu_cccr = tbvq036_info_ccre_clie.num_cpf_cnpj_titu_cccr
        )
        LIMIT v_batch_size;
        
        SET v_cartoes_afetados = ROW_COUNT();
        SET v_total_cartoes = v_total_cartoes + v_cartoes_afetados;
        
        COMMIT;
        
        -- Relatório do lote
        SELECT CONCAT(
            'Lote ', v_lote_count, ' concluído: ',
            v_rows_affected, ' elegibilidades e ',
            v_cartoes_afetados, ' cartões excluídos. ',
            'Totais acumulados: ', v_total_elegibilidades, ' elegibilidades e ',
            v_total_cartoes, ' cartões'
        ) AS resultado_lote;
        
        -- Sleep entre lotes (exceto após o último lote)
        IF v_lote_count < v_max_lotes AND (v_rows_affected > 0 OR v_cartoes_afetados > 0) THEN
            DO SLEEP(1);
        END IF;
        
        -- Reset para próximo lote
        SET v_rows_affected = GREATEST(v_rows_affected, v_cartoes_afetados);
        SET v_cartoes_afetados = 0;
    END WHILE;
    
    SELECT CONCAT(
        'PROCESSO CONCLUÍDO. ',
        'Lotes executados: ', v_lote_count, '. ',
        'Totais finais: ', v_total_elegibilidades, ' elegibilidades e ',
        v_total_cartoes, ' cartões excluídos'
    ) AS mensagem_final;
END //

DELIMITER ;