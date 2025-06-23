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

-- Tabela de Avaliações (compatível com o sistema de estrelas do site)
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

-- Tabela de Termos de Empréstimo (para registro de aceite)
CREATE TABLE TermosAceitos (
    termo_id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    versao_termos VARCHAR(20) NOT NULL,
    data_aceite DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_aceite VARCHAR(45),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE
);