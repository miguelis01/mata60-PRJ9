#Sistema de Controle de Eventos Acadêmicos

## 📘 Descrição
Este projeto implementa um **banco de dados relacional** em **PostgreSQL** para o gerenciamento de eventos acadêmicos, abrangendo controle de **participantes, inscrições, atividades, artigos, pagamentos e eventos**.  
---

## ⚙️ Requisitos
- **PostgreSQL 18+** instalado  
- **pgAdmin 4** (ou outro cliente compatível)  


---

## 🧩 Etapas de Configuração

### 1️⃣ Criação do Banco de Dados
1. Abra o **pgAdmin 4**.  
2. Clique com o botão direito em **Databases → Create → Database...**  
3. Nomeie o banco como `DB_EVENTOS_ACADEMICOS` ou outro nome da sua preferência.  
4. Confirme clicando em **Save**.  

---

### 2️⃣ Criação das Tabelas
1. No painel esquerdo, selecione o banco criado.  
2. Vá até a aba **Query Tool** (ícone do SQL).  
3. Copie e cole o conteúdo do arquivo:  sql/database.sql
4. Execute o script (botão ▶️ ou **F5**).  
5. Isso criará todas as relações do sistema.

---

### 3️⃣ População do Banco de Dados
1. Ainda na **Query Tool**, carregue e execute o script: sql/populate.sql
2. Esse script insere:
   - **4 eventos** (um sem atividades, para testes de integridade);
   - **10 atividades** distribuídas entre os eventos;
   - **7.000 inscrições** e **7.000 participantes**;
   - **5.000 vínculos entre participantes e atividades**;
   - **2.500 registros de pagamento**;
   - **2 participantes especiais** (com valores extremos de pagamento).  
   
   > O script utiliza funções do PostgreSQL (`generate_series`) para gerar grandes volumes de dados automaticamente.

---

### 4️⃣ Criação dos Índices
1. Após popular o banco, execute o script: sql/index.sql
2. Esse arquivo cria índices para otimizar as consultas SQL mais comuns, incluindo:
   - Índices por **chaves estrangeiras** (`ID_INSCRICAO`, `ID_EVENTO`, `ID_ATIVIDADE`);
   - Índices em **campos de busca textual** (`DS_NOME`, `DS_TITULO`);
   - Índices em **campos de filtro temporal e categórico** (`DT_PAGAMENTO`, `TP_CATEGORIA`).

---

## 🔍 Testes de Validação
Após a execução dos scripts:
1. Abra o **Query Tool** e teste as tabelas com as queries listadas dentro dos arquivos intermediate_queries.sql e advanced_queries.sql
