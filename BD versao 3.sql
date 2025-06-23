CREATE DATABASE biblioteca;
USE biblioteca;

-- Tabela de Usuários (ampliada para dados acadêmicos)
CREATE TABLE Usuarios (
    usuario_id INT PRIMARY KEY AUTO_INCREMENT,
    nome_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    email_institucional VARCHAR(100) UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    cpf VARCHAR(14) UNIQUE,
    telefone VARCHAR(20),
    matricula VARCHAR(20) UNIQUE,
    tipo ENUM('admin', 'bibliotecario', 'aluno', 'professor') NOT NULL,
    curso VARCHAR(100),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_login DATETIME,
    ativo BOOLEAN DEFAULT TRUE,
    INDEX idx_usuario_email (email),
    INDEX idx_usuario_matricula (matricula)
);

-- Tabela de Sessões (controle de login)
CREATE TABLE Sessoes (
    sessao_id VARCHAR(255) PRIMARY KEY,
    usuario_id INT NOT NULL,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expiracao DATETIME NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    INDEX idx_sessao_expiracao (data_expiracao)
);

-- Tabela de Categorias (compatível com as categorias do site)
CREATE TABLE Categorias (
    categoria_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    slug VARCHAR(50) UNIQUE,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_categoria_slug (slug)
);

-- Tabela de Livros (com campos para venda e empréstimo)
CREATE TABLE Livros (
    livro_id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    ano_publicacao INT,
    editora VARCHAR(100),
    edicao VARCHAR(20),
    quantidade_estoque INT DEFAULT 0,
    quantidade_emprestimo INT DEFAULT 1,
    preco DECIMAL(10,2),
    capa_url VARCHAR(255),
    sinopse TEXT,
    disponivel_venda BOOLEAN DEFAULT FALSE,
    disponivel_emprestimo BOOLEAN DEFAULT TRUE,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_livro_titulo (titulo),
    INDEX idx_livro_autor (autor),
    INDEX idx_livro_disponivel (disponivel_venda, disponivel_emprestimo)
);

-- Tabela de Relacionamento Livro-Categoria (para múltiplas categorias)
CREATE TABLE LivroCategorias (
    livro_id INT NOT NULL,
    categoria_id INT NOT NULL,
    PRIMARY KEY (livro_id, categoria_id),
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES Categorias(categoria_id) ON DELETE CASCADE
);

-- Tabela de Empréstimos (com campos para o sistema do site)
CREATE TABLE Emprestimos (
    emprestimo_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    data_emprestimo DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_devolucao_prevista DATETIME NOT NULL,
    data_devolucao_real DATETIME,
    local_retirada ENUM('biblioteca-central', 'biblioteca-setorial-1', 'biblioteca-setorial-2') NOT NULL,
    status ENUM('pendente', 'ativo', 'devolvido', 'atrasado', 'renovado') DEFAULT 'pendente',
    multa DECIMAL(10,2) DEFAULT 0.00,
    observacoes TEXT,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    INDEX idx_emprestimo_status (status),
    INDEX idx_emprestimo_devolucao (data_devolucao_prevista)
);

-- Tabela de Pedidos (para compras)
CREATE TABLE Pedidos (
    pedido_id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(10,2) NOT NULL,
    status ENUM('pendente', 'processando', 'enviado', 'entregue', 'cancelado') DEFAULT 'pendente',
    metodo_pagamento ENUM('cartao', 'boleto', 'pix'),
    endereco_entrega TEXT,
    codigo_rastreio VARCHAR(100),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    INDEX idx_pedido_status (status),
    INDEX idx_pedido_data (data_pedido)
);

-- Tabela de Itens de Pedido (para compras)
CREATE TABLE ItensPedido (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    pedido_id INT NOT NULL,
    livro_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE RESTRICT
);

-- Tabela de Reservas (com campos para o fluxo do site)
CREATE TABLE Reservas (
    reserva_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    data_reserva DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expiracao DATETIME NOT NULL,
    status ENUM('pendente', 'ativa', 'cancelada', 'concluida') DEFAULT 'pendente',
    tipo ENUM('emprestimo', 'compra') NOT NULL,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    INDEX idx_reserva_status (status),
    INDEX idx_reserva_expiracao (data_expiracao)
);

-- Tabela de Avaliações 
CREATE TABLE Avaliacoes (
    avaliacao_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    nota INT NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    data_avaliacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    UNIQUE KEY (livro_id, usuario_id),
    INDEX idx_avaliacao_livro (livro_id)
);

-- Tabela de Termos de Empréstimo 
CREATE TABLE TermosAceitos (
    termo_id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    versao_termos VARCHAR(20) NOT NULL,
    data_aceite DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_aceite VARCHAR(45),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE
);

DELIMITER //
CREATE PROCEDURE processar_emprestimo(
    IN p_livro_id INT,
    IN p_usuario_id INT,
    IN p_local_retirada VARCHAR(50)
)
BEGIN
    DECLARE v_disponivel BOOLEAN;
    DECLARE v_quantidade INT;
    DECLARE v_prazo_dias INT;
    
    -- Verificar se o livro está disponível para empréstimo
    SELECT disponivel_emprestimo, quantidade_emprestimo INTO v_disponivel, v_quantidade
    FROM Livros WHERE livro_id = p_livro_id;
    
    -- Definir prazo padrão de 15 dias 
    SET v_prazo_dias = 15;
    
    IF v_disponivel AND v_quantidade > 0 THEN
        -- Registrar o empréstimo
        INSERT INTO Emprestimos (
            livro_id, 
            usuario_id, 
            data_devolucao_prevista,
            local_retirada,
            status
        ) VALUES (
            p_livro_id,
            p_usuario_id,
            DATE_ADD(NOW(), INTERVAL v_prazo_dias DAY),
            p_local_retirada,
            'ativo'
        );
        
        -- Atualizar quantidade disponível
        UPDATE Livros 
        SET quantidade_emprestimo = quantidade_emprestimo - 1
        WHERE livro_id = p_livro_id;
        
        SELECT 'Empréstimo realizado com sucesso' AS message;
    ELSE
        SELECT 'Livro não disponível para empréstimo' AS error;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE calcular_multas()
BEGIN
    -- Atualizar status para atrasado e calcular multa
    UPDATE Emprestimos 
    SET 
        status = 'atrasado',
        multa = DATEDIFF(CURDATE(), data_devolucao_prevista) * 2.00 -- R$2,00 por dia como no seu site
    WHERE 
        status = 'ativo' 
        AND data_devolucao_prevista < CURDATE();
    
    SELECT CONCAT(ROW_COUNT(), ' empréstimos atualizados com multa') AS result;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE processar_devolucao(
    IN p_emprestimo_id INT
)
BEGIN
    DECLARE v_livro_id INT;
    DECLARE v_multa DECIMAL(10,2);
    
    -- Obter livro ID e multa
    SELECT livro_id, multa INTO v_livro_id, v_multa
    FROM Emprestimos 
    WHERE emprestimo_id = p_emprestimo_id;
    
    -- Registrar devolução
    UPDATE Emprestimos 
    SET 
        data_devolucao_real = NOW(),
        status = IF(multa > 0, 'atrasado', 'devolvido')
    WHERE emprestimo_id = p_emprestimo_id;
    
    -- Atualizar quantidade disponível
    UPDATE Livros 
    SET quantidade_emprestimo = quantidade_emprestimo + 1
    WHERE livro_id = v_livro_id;
    
    SELECT CONCAT('Devolução registrada. Multa: R$', v_multa) AS result;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_item_pedido_insert
AFTER INSERT ON ItensPedido
FOR EACH ROW
BEGIN
    UPDATE Livros 
    SET quantidade_estoque = quantidade_estoque - NEW.quantidade
    WHERE livro_id = NEW.livro_id;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER before_emprestimo_insert
BEFORE INSERT ON Emprestimos
FOR EACH ROW
BEGIN
    DECLARE v_disponivel BOOLEAN;
    DECLARE v_quantidade INT;
    
    SELECT disponivel_emprestimo, quantidade_emprestimo INTO v_disponivel, v_quantidade
    FROM Livros WHERE livro_id = NEW.livro_id;
    
    IF NOT v_disponivel OR v_quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Livro não disponível para empréstimo';
    END IF;
END //
DELIMITER ;

CREATE VIEW vw_livros_mais_emprestados AS
SELECT 
    l.livro_id,
    l.titulo,
    l.autor,
    COUNT(e.emprestimo_id) AS total_emprestimos,
    l.quantidade_emprestimo AS disponiveis
FROM 
    Livros l
LEFT JOIN 
    Emprestimos e ON l.livro_id = e.livro_id
GROUP BY 
    l.livro_id, l.titulo, l.autor, l.quantidade_emprestimo
ORDER BY 
    total_emprestimos DESC
LIMIT 10;

CREATE VIEW vw_historico_usuario AS
SELECT 
    u.usuario_id,
    u.nome_completo,
    u.matricula,
    COUNT(DISTINCT e.emprestimo_id) AS total_emprestimos,
    COUNT(DISTINCT p.pedido_id) AS total_compras,
    SUM(IF(e.status = 'atrasado', 1, 0)) AS atrasos,
    SUM(e.multa) AS total_multas
FROM 
    Usuarios u
LEFT JOIN 
    Emprestimos e ON u.usuario_id = e.usuario_id
LEFT JOIN 
    Pedidos p ON u.usuario_id = p.usuario_id
GROUP BY 
    u.usuario_id, u.nome_completo, u.matricula;
    
CREATE VIEW vw_controle_financeiro AS
SELECT 
    DATE_FORMAT(data_pedido, '%Y-%m') AS mes,
    COUNT(pedido_id) AS total_pedidos,
    SUM(valor_total) AS receita_vendas,
    (SELECT SUM(multa) FROM Emprestimos 
     WHERE status = 'atrasado' 
     AND DATE_FORMAT(data_devolucao_prevista, '%Y-%m') = mes) AS receita_multas
FROM 
    Pedidos
GROUP BY 
    DATE_FORMAT(data_pedido, '%Y-%m')
ORDER BY 
    mes DESC;
    
    
    
    
    
-- Ver livros mais emprestados
SELECT * FROM vw_livros_mais_emprestados;

-- Ver histórico de usuário
SELECT * FROM vw_historico_usuario WHERE usuario_id = 1;

-- Ver controle financeiro
SELECT * FROM vw_controle_financeiro;