CREATE OR REPLACE PROCEDURE sp_alterar_categoria_atividade_v2(
    p_cpf CHAR(11),
    p_nova_categoria INT,
    p_id_atividade_nova INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_inscricao INT;
    v_id_pagamento INT;
    v_valor_calculado NUMERIC(10, 2); -- Variável para guardar o valor definido pelo IF
BEGIN
    -- 1. Lógica de Preços (Regra de Negócio)
    -- Define o valor do pagamento baseado na categoria escolhida (1 a 5)
    IF p_nova_categoria = 1 THEN
        v_valor_calculado := 100.00; -- Ex: Estudante Graduação
    ELSIF p_nova_categoria = 2 THEN
        v_valor_calculado := 200.00; -- Ex: Pós-Graduando
    ELSIF p_nova_categoria = 3 THEN
        v_valor_calculado := 350.00; -- Ex: Professor
    ELSIF p_nova_categoria = 4 THEN
        v_valor_calculado := 500.00; -- Ex: Profissional
    ELSIF p_nova_categoria = 5 THEN
        v_valor_calculado := 800.00; -- Ex: VIP / Patrocinador
    ELSE
        -- Trava de segurança caso passem uma categoria que não existe
        RAISE EXCEPTION 'Categoria inválida: %. Escolha entre 1 e 5.', p_nova_categoria;
    END IF;

    -- 2. SELECT 1: Busca o ID da inscrição e valida se o participante existe
    SELECT ID_INSCRICAO INTO v_id_inscricao
    FROM TB_PARTICIPANTE 
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    IF v_id_inscricao IS NULL THEN
        RAISE EXCEPTION 'Erro: Participante com CPF % não encontrado.', p_cpf;
    END IF;

    -- 3. SELECT 2: Busca o Pagamento vinculado
    SELECT ID_PAGAMENTO INTO v_id_pagamento
    FROM TB_PAGAMENTO
    WHERE ID_INSCRICAO = v_id_inscricao;

    IF v_id_pagamento IS NULL THEN
        RAISE EXCEPTION 'Erro: Nenhum pagamento encontrado para a inscrição %.', v_id_inscricao;
    END IF;

    -- 4. UPDATE 1: Atualiza a categoria cadastral
    UPDATE TB_PARTICIPANTE 
    SET TP_CATEGORIA = p_nova_categoria 
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    -- 5. UPDATE 2: Atualiza o valor usando a variável CALCULADA (v_valor_calculado)
    UPDATE TB_PAGAMENTO 
    SET VL_PAGAMENTO = v_valor_calculado,
		    DT_PAGAMENTO = CURRENT_DATE
    WHERE ID_PAGAMENTO = v_id_pagamento;

    -- 6. DELETE: Remove agenda antiga
    DELETE FROM RL_PARTICIPANTE_ATIVIDADE 
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    -- 7. INSERT: Insere na nova atividade obrigatória
    INSERT INTO RL_PARTICIPANTE_ATIVIDADE (CD_CPF_PARTICIPANTE, ID_ATIVIDADE) 
    VALUES (p_cpf, p_id_atividade_nova);

    -- Efetiva tudo
    COMMIT;
END;
$$;
