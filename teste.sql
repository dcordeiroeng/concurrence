-- Cria o banco de dados
CREATE DATABASE IF NOT EXISTS cartoes;

-- Seleciona o banco de dados para uso
USE cartoes;

-- Criação da tabela tb036 (original)
CREATE TABLE tb036 (
    CPF VARCHAR(15),
    hash_do_cartao VARCHAR(19),
    nome VARCHAR(36),
    PRIMARY KEY (CPF, hash_do_cartao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Criação da tabela tb037 (original)
CREATE TABLE tb037 (
    CPF VARCHAR(15),
    hash_do_cartao VARCHAR(19),
    funcionalidade TINYINT(2),
    PRIMARY KEY (CPF, hash_do_cartao),
    FOREIGN KEY (CPF, hash_do_cartao) REFERENCES tb036(CPF, hash_do_cartao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Verifica os dados inseridos na tb036
SELECT COUNT(*) FROM tb036_old;

-- Verifica os dados inseridos na tb037
SELECT COUNT(*) FROM tb037_old;

SELECT * FROM tb037 ORDER BY CPF;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE tb037;
TRUNCATE TABLE tb036;

SET FOREIGN_KEY_CHECKS = 1;

SET autocommit = 0;
-- Suas inserções
COMMIT;

-- Configurações para performance
SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;

-- Limpa tabelas se existirem
TRUNCATE TABLE tb037;
TRUNCATE TABLE tb036;

-- Configurações para performance
SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;

-- Limpa tabelas se existirem
TRUNCATE TABLE tb037;
TRUNCATE TABLE tb036;

-- 1. Cria tabela temporária para gerar os números
CREATE TEMPORARY TABLE temp_numbers (
    n INT PRIMARY KEY
);

-- 2. Popula a tabela temporária com 1 milhão de números
-- Usando técnica de multiplicação cruzada para MySQL 5.7
INSERT INTO temp_numbers
SELECT a.n + b.n*10 + c.n*100 + d.n*1000 + e.n*10000 + f.n*100000
FROM 
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) e,
    (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) f
WHERE a.n + b.n*10 + c.n*100 + d.n*1000 + e.n*10000 + f.n*100000 BETWEEN 1 AND 1000000;

-- 3. Inserção na tb036 (1 milhão de registros)
INSERT INTO tb036 (CPF, hash_do_cartao, nome)
SELECT 
    LPAD(FLOOR(RAND()*90000000000)+10000000000, 11, '0') AS CPF,
    CONCAT('HASH', LPAD(n, 15, '0')) AS hash_do_cartao,
    CONCAT('Cliente ', n) AS nome
FROM temp_numbers;

-- 4. Inserção na tb037 (80% dos registros com 20% de funcionalidade 11)
INSERT INTO tb037 (CPF, hash_do_cartao, funcionalidade)
SELECT 
    t36.CPF,
    t36.hash_do_cartao,
    CASE 
        WHEN RAND() <= 0.2 THEN 11  -- 20% chance de ser 11
        ELSE FLOOR(1 + RAND()*99)   -- 80% chance de ser 1-99
    END AS funcionalidade
FROM tb036 t36
WHERE RAND() <= 0.8;  -- Inclui apenas 80% dos registros da tb036

-- Limpeza
DROP TEMPORARY TABLE temp_numbers;

-- Atualiza configurações
COMMIT;
SET autocommit = 1;
SET unique_checks = 1;
SET foreign_key_checks = 1;

-- Verificação
SELECT 
    COUNT(*) AS total_tb036,
    (SELECT COUNT(*) FROM tb037) AS total_tb037,
    (SELECT COUNT(*) FROM tb037 WHERE funcionalidade = 11) AS total_func_11,
    ROUND((SELECT COUNT(*) FROM tb037 WHERE funcionalidade = 11) / 
          (SELECT COUNT(*) FROM tb037) * 100, 2) AS percentual_func_11;
          
SELECT 
    COUNT(DISTINCT CPF) AS total_cpfs_com_func_11
FROM 
    tb037_old
WHERE 
    funcionalidade = 11;
    
SELECT COUNT(DISTINCT t36.CPF) AS total_cpfs_com_func_11
FROM tb036_old t36
WHERE EXISTS (
    SELECT 1
    FROM tb037_old t37
    WHERE t37.CPF = t36.CPF
    AND t37.funcionalidade = 11
);

SHOW TABLES;

-- 1. Renomear tabelas originais
RENAME TABLE tb036 TO tb036_old, tb037 TO tb037_old;

DROP TABLE tb036_old;
DROP TABLE tb037_old;

-- 2. Criar nova tb036 (apenas CPFs sem funcionalidade 11)
CREATE TABLE tb036 AS
SELECT t36.*
FROM tb036_old t36
LEFT JOIN (
    SELECT DISTINCT CPF
    FROM tb037_old
    WHERE funcionalidade = 11
) t37_excluir ON t36.CPF = t37_excluir.CPF
WHERE t37_excluir.CPF IS NULL;

-- 3. Criar nova tb037 (mesmo critério)
CREATE TABLE tb037 AS
SELECT t37.*
FROM tb037_old t37
LEFT JOIN (
    SELECT DISTINCT CPF
    FROM tb037_old
    WHERE funcionalidade = 11
) t37_excluir ON t37.CPF = t37_excluir.CPF
WHERE t37_excluir.CPF IS NULL;

-- 4. Recriar chaves primárias
ALTER TABLE tb036 ADD PRIMARY KEY (CPF, hash_do_cartao);
ALTER TABLE tb037 ADD PRIMARY KEY (CPF, hash_do_cartao);

-- 5. Recriar chave estrangeira
ALTER TABLE tb037 ADD CONSTRAINT fk_tb037_tb036
FOREIGN KEY (CPF, hash_do_cartao) REFERENCES tb036(CPF, hash_do_cartao);

DROP TABLE tb037_old;
DROP TABLE tb036_old;

-- Configurações para performance
SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;
SET GLOBAL innodb_buffer_pool_size = 12G;  -- Ajuste conforme sua memória

-- Limpa tabelas se existirem
TRUNCATE TABLE tb037_old;
TRUNCATE TABLE tb036_old;

DELIMITER //
CREATE PROCEDURE inserir_massa_dados()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 100000;  -- Tamanho do lote (100k)
    DECLARE max_records INT DEFAULT 100000000;  -- 100 milhões
    DECLARE commit_interval INT DEFAULT 1000000; -- Commit a cada 1M
    
    -- Variável para controle de transação
    DECLARE in_transaction BOOL DEFAULT FALSE;
    
    WHILE i < max_records DO
        -- Inicia transação se não estiver em uma
        IF NOT in_transaction THEN
            START TRANSACTION;
            SET in_transaction = TRUE;
        END IF;
        
        -- Inserção na tb036
        INSERT INTO tb036 (CPF, hash_do_cartao, nome)
        SELECT 
            LPAD(FLOOR(RAND()*90000000000)+10000000000, 11, '0'),
            CONCAT('HASH', LPAD(i + n, 15, '0')),
            CONCAT('Cliente ', i + n)
        FROM (
            SELECT a.n + b.n*10 + c.n*100 + d.n*1000 + e.n*10000 AS n
            FROM 
                (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
                (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
                (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
                (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d,
                (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) e
            LIMIT batch_size
        ) AS numbers;
        
        -- Inserção correspondente na tb037
        INSERT INTO tb037 (CPF, hash_do_cartao, funcionalidade)
        SELECT 
            t36.CPF,
            t36.hash_do_cartao,
            CASE 
                WHEN RAND() <= 0.2 THEN 11
                ELSE FLOOR(1 + RAND()*99)
            END
        FROM tb036 t36
        WHERE t36.hash_do_cartao BETWEEN CONCAT('HASH', LPAD(i, 15, '0')) 
                                AND CONCAT('HASH', LPAD(i + batch_size - 1, 15, '0'))
        AND RAND() <= 0.8;
        
        SET i = i + batch_size;
        
        -- Verifica se é hora de fazer commit
        IF MOD(i, commit_interval) = 0 THEN
            COMMIT;
            SET in_transaction = FALSE;
            SELECT CONCAT('Commit realizado: ', i, ' registros inseridos') AS progresso;
        END IF;
    END WHILE;
    
    -- Commit final se houver transação pendente
    IF in_transaction THEN
        COMMIT;
    END IF;
END //
DELIMITER ;

-- 2. Executar o procedimento
CALL inserir_massa_dados();

-- 3. Limpar o procedimento
DROP PROCEDURE inserir_massa_dados;

-- 4. Recriar índices (opcional, se necessário)
ALTER TABLE tb036 ADD PRIMARY KEY (CPF, hash_do_cartao);
ALTER TABLE tb037 ADD PRIMARY KEY (CPF, hash_do_cartao);
ALTER TABLE tb037 ADD FOREIGN KEY (CPF, hash_do_cartao) REFERENCES tb036(CPF, hash_do_cartao);

-- 5. Verificação final
SELECT 
    COUNT(*) AS total_tb036,
    (SELECT COUNT(*) FROM tb037) AS total_tb037,
    (SELECT COUNT(*) FROM tb037 WHERE funcionalidade = 11) AS total_func_11,
    ROUND((SELECT COUNT(*) FROM tb037 WHERE funcionalidade = 11) / 
          (SELECT COUNT(*) FROM tb037) * 100, 2) AS percentual_func_11;

-- Configurações para performance
SET autocommit = 0;
SET unique_checks = 0;
SET foreign_key_checks = 0;
SET GLOBAL innodb_buffer_pool_size = 6442450944;  -- 6GB

-- Limpa tabelas se existirem
TRUNCATE TABLE tb037;
TRUNCATE TABLE tb036;

-- Restante do seu script continua aqui...
