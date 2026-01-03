CREATE OR REPLACE PROCEDURE sp_cadastrar_participante_auto(
    p_cpf CHAR(11),
    p_nome VARCHAR(150),
    p_email VARCHAR(100),
    p_categoria INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cpf_existente CHAR(11); -- Pra validar se já não tem esse CPF no banco
    v_id_inscricao INT; -- Pra pegar o ID da inscrição que será criada
BEGIN
    -- SELECT Valida se o CPF já existe antes de começar
    SELECT CD_CPF_PARTICIPANTE INTO v_cpf_existente
    FROM TB_PARTICIPANTE
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    IF v_cpf_existente IS NOT NULL THEN
        RAISE EXCEPTION 'Erro: O CPF % já está cadastrado.', p_cpf;
    END IF;

    -- INSERT 1 Cria a Inscrição e CAPTURA o ID gerado
    -- Como a tabela só tem o ID usamos DEFAULT VALUE
    INSERT INTO TB_INSCRICAO DEFAULT VALUES
    RETURNING ID_INSCRICAO INTO v_id_inscricao;

    -- INSERT 2 Cria o Participante usando o ID capturado acima
    INSERT INTO TB_PARTICIPANTE (CD_CPF_PARTICIPANTE, DS_NOME, DS_EMAIL, TP_CATEGORIA, ID_INSCRICAO)
    VALUES (p_cpf, p_nome, p_email, p_categoria, v_id_inscricao);

    -- UPDATE 1 Sanitização do Nome (Maiúsculo)
    UPDATE TB_PARTICIPANTE 
    SET DS_NOME = UPPER(DS_NOME) 
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    -- UPDATE 2 Sanitização do Email (Minúsculo)
    UPDATE TB_PARTICIPANTE 
    SET DS_EMAIL = LOWER(DS_EMAIL) 
    WHERE CD_CPF_PARTICIPANTE = p_cpf;

    COMMIT;
END;
$$;
