-- MV para gráfico 1
-- Esta view armazena a contagem total de participantes e a contagem de pagantes por categoria,
-- facilitando o cálculo da taxa de conversão (pagantes vs. não pagantes).

CREATE MATERIALIZED VIEW MV_PARTICIPANTES_PAGAMENTOS_CATEGORIA AS
WITH TotalParticipantes AS (
    -- Total de participantes por categoria (base)
    SELECT
        TP_CATEGORIA,
        COUNT(CD_CPF_PARTICIPANTE) AS QT_PARTICIPANTES
    FROM
        TB_PARTICIPANTE
    GROUP BY
        TP_CATEGORIA
),
PagantesPorCategoria AS (
    -- Contagem de pagantes únicos por categoria
    SELECT
        P.TP_CATEGORIA,
        COUNT(DISTINCT P.CD_CPF_PARTICIPANTE) AS QT_PAGANTES
    FROM
        TB_PARTICIPANTE P
    INNER JOIN
        TB_PAGAMENTO G ON P.ID_INSCRICAO = G.ID_INSCRICAO
    GROUP BY
        P.TP_CATEGORIA
)
SELECT
    T.TP_CATEGORIA,
    T.QT_PARTICIPANTES,
    COALESCE(P.QT_PAGANTES, 0) AS QT_PAGANTES,
    (T.QT_PARTICIPANTES - COALESCE(P.QT_PAGANTES, 0)) AS QT_NAO_PAGANTES
FROM
    TotalParticipantes T
LEFT JOIN
    PagantesPorCategoria P ON T.TP_CATEGORIA = P.TP_CATEGORIA;

-- Exemplos de uso:
SELECT
    TP_CATEGORIA,
    (QT_PAGANTES * 100.0 / QT_PARTICIPANTES) AS PCT_PAGANTES
FROM
    MV_PARTICIPANTES_PAGAMENTOS_CATEGORIA
WHERE
    TP_CATEGORIA = 5; -- Filtro

-- MV para gráfico 2
-- Esta view armazena o ranking dos eventos com base no número de artigos vinculados.
CREATE MATERIALIZED VIEW MV_RANK_EVENTOS_POR_ARTIGOS AS
WITH EventoArtigoContagem AS (
    SELECT
        E.ID_EVENTO,
        E.DS_LOCAL,
        COUNT(DISTINCT RA.ID_ARTIGO) AS QT_ARTIGOS
    FROM
        TB_EVENTO E
    INNER JOIN
        RL_ATIVIDADE_EVENTO RAE ON E.ID_EVENTO = RAE.ID_EVENTO
    INNER JOIN
        RL_ARTIGO_ATIVIDADE RA ON RAE.ID_ATIVIDADE = RA.ID_ATIVIDADE
    GROUP BY
        E.ID_EVENTO, E.DS_LOCAL
)
SELECT
    ID_EVENTO,
    DS_LOCAL,
    QT_ARTIGOS,
    -- Função WINDOW para rankear
    RANK() OVER (ORDER BY QT_ARTIGOS DESC) AS RANK_EVENTO
FROM
    EventoArtigoContagem;

-- Exemplos de uso:
SELECT
    DS_LOCAL,
    QT_ARTIGOS
FROM
    MV_RANK_EVENTOS_POR_ARTIGOS
WHERE
    RANK_EVENTO <= 5; -- Filtra os 5 melhores ranks

-- MV para gráfico 3
-- Esta view calcula o volume financeiro total por evento e a porcentagem que este volume
-- representa do total geral, usando uma função de Janela (WINDOW)
CREATE MATERIALIZED VIEW MV_DISTRIBUICAO_FINANCEIRA_EVENTO AS
WITH EventoPagamentoTotal AS (
    SELECT
        E.ID_EVENTO,
        E.DS_LOCAL,
        -- Soma de pagamentos via complexo JOIN
        SUM(P.VL_PAGAMENTO) AS VL_TOTAL_EVENTO
    FROM
        TB_EVENTO E
    INNER JOIN
        RL_ATIVIDADE_EVENTO RAE ON E.ID_EVENTO = RAE.ID_EVENTO
    INNER JOIN
        RL_PARTICIPANTE_ATIVIDADE RPA ON RAE.ID_ATIVIDADE = RPA.ID_ATIVIDADE
    INNER JOIN
        TB_PARTICIPANTE PART ON RPA.CD_CPF_PARTICIPANTE = PART.CD_CPF_PARTICIPANTE
    INNER JOIN
        TB_PAGAMENTO P ON PART.ID_INSCRICAO = P.ID_INSCRICAO
    GROUP BY
        E.ID_EVENTO, E.DS_LOCAL
)
SELECT
    ID_EVENTO,
    DS_LOCAL,
    VL_TOTAL_EVENTO,
    -- Calcula a porcentagem do total geral usando SUM() OVER ()
    (VL_TOTAL_EVENTO / SUM(VL_TOTAL_EVENTO) OVER ()) * 100 AS PCT_DO_TOTAL_GERAL
FROM
    EventoPagamentoTotal;
-- Exemplos de uso:

SELECT
    DS_LOCAL,
    VL_TOTAL_EVENTO,
    PCT_DO_TOTAL_GERAL
FROM
    MV_DISTRIBUICAO_FINANCEIRA_EVENTO
WHERE
    PCT_DO_TOTAL_GERAL > 5.0 -- Filtra eventos que representam mais de 5% do total
ORDER BY
    PCT_DO_TOTAL_GERAL DESC;

-- MV para gráfico 4
-- Esta view calcula o nível de engajamento médio (atividades por participante) para cada categoria.
CREATE MATERIALIZED VIEW MV_MEDIA_ATIVIDADES_CATEGORIA AS
WITH TotalParticipantes AS (
    -- Total de participantes por categoria (base)
    SELECT
        TP_CATEGORIA,
        COUNT(CD_CPF_PARTICIPANTE) AS QT_PARTICIPANTES
    FROM
        TB_PARTICIPANTE
    GROUP BY
        TP_CATEGORIA
),
InscricoesTotais AS (
    -- Soma o total de inscrições em atividades (linhas em RL_PARTICIPANTE_ATIVIDADE)
    SELECT
        P.TP_CATEGORIA,
        COUNT(RPA.ID_ATIVIDADE) AS QT_INSCRICOES_TOTAIS
    FROM
        TB_PARTICIPANTE P
    INNER JOIN
        RL_PARTICIPANTE_ATIVIDADE RPA ON P.CD_CPF_PARTICIPANTE = RPA.CD_CPF_PARTICIPANTE
    GROUP BY
        P.TP_CATEGORIA
)
SELECT
    T.TP_CATEGORIA,
    -- CORREÇÃO: Multiplica por 1.0 para forçar o cálculo decimal
    ROUND((COALESCE(I.QT_INSCRICOES_TOTAIS, 0) * 1.0 / T.QT_PARTICIPANTES), 2) AS MEDIA_ATIVIDADES_POR_PARTICIPANTE
FROM
    TotalParticipantes T
LEFT JOIN
    InscricoesTotais I ON T.TP_CATEGORIA = I.TP_CATEGORIA;

-- Exemplos de uso:

SELECT
    TP_CATEGORIA,
    MEDIA_ATIVIDADES_POR_PARTICIPANTE
FROM
    MV_MEDIA_ATIVIDADES_CATEGORIA
ORDER BY
    MEDIA_ATIVIDADES_POR_PARTICIPANTE DESC
LIMIT 1;