-- ===================================================================
-- 1. POPULAÇÃO: Eventos (4 eventos; o 4º ficará sem atividades)
-- ===================================================================
INSERT INTO TB_EVENTO (ID_EVENTO, DT_EVENTO, DS_LOCAL)
VALUES
(1, DATE '2025-04-20', 'Centro de Convenções de São Paulo'),
(2, DATE '2025-09-10', 'Auditório da Universidade Federal do Rio de Janeiro'),
(3, DATE '2025-11-15', 'Expo Minas, Belo Horizonte'),
(4, DATE '2026-02-10', 'Evento Sem Atividades - Local a definir');  -- evento 4 ficará sem atividades

-- ===================================================================
-- 2. POPULAÇÃO: Atividades
-- ===================================================================
INSERT INTO TB_ATIVIDADE (ID_ATIVIDADE, DS_NOME_ATIVIDADE, TP_CATEGORIA)
VALUES
(201, 'Palestra: Inovações Tecnológicas', 1),
(202, 'Workshop: Machine Learning', 2),
(203, 'Mesa Redonda: Ética na IA', 3),
(204, 'Apresentação de Artigos', 4),
(205, 'Laboratório de Dados', 2),
(206, 'Painel de Startups', 1),
(207, 'Hackathon de IA', 2),
(208, 'Sessão de Posters', 4),
(209, 'Debate: Sustentabilidade', 3),
(210, 'Workshop: Blockchain', 2);

-- ===================================================================
-- 3. POPULAÇÃO: Artigos (serão associados a atividades que pertencem a eventos diferentes)
-- ===================================================================
INSERT INTO TB_ARTIGO (ID_ARTIGO, DS_TITULO, DS_RESUMO, DS_PATH_DOCUMENTO)
VALUES
(10, 'Inteligência Artificial na Educação', 'Estudo sobre o uso de IA em plataformas de ensino.', '/docs/artigos/ia_educacao.pdf'),
(11, 'Sustentabilidade e Inovação', 'Análise de práticas sustentáveis no setor tecnológico.', '/docs/artigos/sustentabilidade.pdf'),
(12, 'Blockchain no Setor Público', 'Aplicações de blockchain em transparência governamental.', '/docs/artigos/blockchain_publico.pdf');

-- ===================================================================
-- 4. POPULAÇÃO: Inscrições (7.000 registros)
-- ===================================================================
INSERT INTO TB_INSCRICAO (ID_INSCRICAO)
SELECT generate_series(1001, 8000);

-- ===================================================================
-- 5. POPULAÇÃO: Participantes (7.000 registros)
--    - CD_CPF_PARTICIPANTE como CHAR(11) com zeros à esquerda
--    - ID_INSCRICAO = 1000 + gs  (corresponde a 1001..6000)
-- ===================================================================
INSERT INTO TB_PARTICIPANTE (
    CD_CPF_PARTICIPANTE,
    DS_NOME,
    DS_EMAIL,
    TP_CATEGORIA,
    ID_INSCRICAO
)
SELECT
    LPAD(gs::text, 11, '0') AS CD_CPF_PARTICIPANTE,     -- ex: '00000000001'
    'Participante ' || gs AS DS_NOME,
    'participante' || gs || '@email.com' AS DS_EMAIL,
    (gs % 4) + 1 AS TP_CATEGORIA,    -- categorias 1..4
    1000 + gs AS ID_INSCRICAO
FROM generate_series(1, 7000) AS gs;

-- ===================================================================
-- 6. POPULAÇÃO: RL_ATIVIDADE_EVENTO
--    - associamos atividades aos eventos 1..3 de forma cíclica (como antes)
--    - notamos que o evento 4 ficará sem atividades (nenhuma atividade apontada para 4)
-- ===================================================================
INSERT INTO RL_ATIVIDADE_EVENTO (ID_ATIVIDADE, ID_EVENTO)
SELECT
    ID_ATIVIDADE,
    (ID_ATIVIDADE % 3) + 1 AS ID_EVENTO
FROM TB_ATIVIDADE;

-- ===================================================================
-- 7. POPULAÇÃO: RL_ARTIGO_ATIVIDADE
--    - Agora cada artigo é associado a uma atividade que pertence a um evento diferente:
--      artigo 10 -> atividade 202 (evento 1)
--      artigo 11 -> atividade 203 (evento 2)
--      artigo 12 -> atividade 204 (evento 3)
-- ===================================================================
INSERT INTO RL_ARTIGO_ATIVIDADE (ID_ARTIGO, ID_ATIVIDADE)
VALUES
(10, 202),  -- atividade 202 -> (202 % 3) +1 = 1  => evento 1
(11, 203),  -- atividade 203 -> event 2
(12, 204);  -- atividade 204 -> event 3

-- ===================================================================
-- 8. POPULAÇÃO: RL_PARTICIPANTE_ATIVIDADE
--    - Vamos inscrever 5.000 participantes em atividades (para garantir
--      que existam participantes inscritos e NÃO inscritos)
--    - Os restantes 2.000 participantes ficarão sem registros aqui
-- ===================================================================
INSERT INTO RL_PARTICIPANTE_ATIVIDADE (CD_CPF_PARTICIPANTE, ID_ATIVIDADE)
SELECT
    LPAD(gs::text, 11, '0') AS CD_CPF_PARTICIPANTE,
    201 + (gs % 10) AS ID_ATIVIDADE    -- distribui entre 201..210
FROM generate_series(1, 5000) AS gs;

-- ===================================================================
-- 9. POPULAÇÃO: TB_PAGAMENTO
--    - Metade das inscrições (2.500) terão pagamento; metade NÃO (sem linhas em TB_PAGAMENT        O)
--    - Pagamentos com valores diferentes por categoria:
--        categoria 1 -> 200.00
--        categoria 2 -> 300.00
--        categoria 4 -> 400.00
--        categoria 3 -> será atualizada depois para ser igual à média (excluindo categoria 3)
--    - Para garantir vínculo entre inscrição e categoria consultamos TB_PARTICIPANTE
-- ===================================================================
-- Inserimos pagamentos iniciais para as primeiras 2.500 inscrições (1001..3500)
INSERT INTO TB_PAGAMENTO (ID_PAGAMENTO, CD_BOLETO, DT_PAGAMENTO, VL_PAGAMENTO, ID_INSCRICAO)
SELECT
    5000 + ROW_NUMBER() OVER (ORDER BY i.ID_INSCRICAO) AS ID_PAGAMENTO,
    'BOL-' || to_char(ROW_NUMBER() OVER (ORDER BY i.ID_INSCRICAO), 'FM00000') AS CD_BOLETO,
    current_date - (((ROW_NUMBER() OVER (ORDER BY i.ID_INSCRICAO)) % 30) * INTERVAL '1 day') AS DT_PAGAMENTO,
    CASE par.TP_CATEGORIA
        WHEN 1 THEN 200.00
        WHEN 2 THEN 300.00
        WHEN 4 THEN 400.00
        WHEN 3 THEN 300.00  
        ELSE 250.00
    END AS VL_PAGAMENTO,
    i.ID_INSCRICAO
FROM (
    SELECT ID_INSCRICAO FROM TB_INSCRICAO WHERE ID_INSCRICAO BETWEEN 1001 AND 4500
) i
JOIN TB_PARTICIPANTE par ON par.ID_INSCRICAO = i.ID_INSCRICAO
ORDER BY i.ID_INSCRICAO;

---------------------------------------------------------------------------------------
-- Incrições extras para facilitar consultas

-- 1️⃣ Criar novas inscrições (fora do intervalo 1001..8000 já usado)
INSERT INTO TB_INSCRICAO (ID_INSCRICAO)
VALUES (9001), (9002);

-- 2️⃣ Inserir os novos participantes
INSERT INTO TB_PARTICIPANTE (
    CD_CPF_PARTICIPANTE,
    DS_NOME,
    DS_EMAIL,
    TP_CATEGORIA,
    ID_INSCRICAO
)
VALUES
('99999999999', 'Participante Alto Pagamento', 'alto@email.com', 2, 9001),
('88888888888', 'Participante Baixo Pagamento', 'baixo@email.com', 3, 9002);

-- 3️⃣ Vincular esses participantes a múltiplas atividades
-- (escolhemos 3 atividades por participante, diferentes entre si)
INSERT INTO RL_PARTICIPANTE_ATIVIDADE (CD_CPF_PARTICIPANTE, ID_ATIVIDADE)
VALUES
('99999999999', 201),
('99999999999', 202),
('99999999999', 203),
('88888888888', 204),
('88888888888', 205),
('88888888888', 206);

-- 4️⃣ Criar pagamentos — um muito alto e outro muito baixo
-- (respeitando FK -> TB_INSCRICAO)
INSERT INTO TB_PAGAMENTO (
    ID_PAGAMENTO,
    CD_BOLETO,
    DT_PAGAMENTO,
    VL_PAGAMENTO,
    ID_INSCRICAO
)
VALUES
(9991, 'BOL-ALTISSIMO', CURRENT_DATE, 599.00, 9001),  -- Pagamento extremamente alto
(9992, 'BOL-BAIXISSIMO', CURRENT_DATE, 1.00, 9002);   -- Pagamento extremamente baixo
