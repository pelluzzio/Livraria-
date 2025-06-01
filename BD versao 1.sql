create database biblioteca;
use biblioteca;

-- Tabela de Usuários (autenticação)
CREATE TABLE Usuarios (
    usuario_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    tipo ENUM('admin', 'bibliotecario', 'membro') NOT NULL DEFAULT 'membro',
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_login DATETIME,
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela de Sessões (controle de login)
CREATE TABLE Sessoes (
    sessao_id VARCHAR(255) PRIMARY KEY,
    usuario_id INT NOT NULL,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expiracao DATETIME NOT NULL,
    ip_address VARCHAR(45),
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE
);

-- Tabela de Categorias 
CREATE TABLE Categorias (
    categoria_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao TEXT,
    slug VARCHAR(50) UNIQUE, -- Para URLs amigáveis
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Livros 
CREATE TABLE Livros (
    livro_id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    ano_publicacao INT,
    editora VARCHAR(100),
    quantidade_disponivel INT DEFAULT 1,
    capa_url VARCHAR(255), -- URL da imagem da capa
    sinopse TEXT,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    categoria_id INT,
    FOREIGN KEY (categoria_id) REFERENCES Categorias(categoria_id) ON DELETE SET NULL
);

-- Tabela de Relacionamento Livro-Categoria (para múltiplas categorias)
CREATE TABLE LivroCategorias (
    livro_id INT NOT NULL,
    categoria_id INT NOT NULL,
    PRIMARY KEY (livro_id, categoria_id),
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES Categorias(categoria_id) ON DELETE CASCADE
);

-- Tabela de Empréstimos
CREATE TABLE Emprestimos (
    emprestimo_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    data_emprestimo DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_devolucao_prevista DATETIME NOT NULL,
    data_devolucao_real DATETIME,
    status ENUM('ativo', 'devolvido', 'atrasado') DEFAULT 'ativo',
    multa DECIMAL(10,2) DEFAULT 0.00,
    observacoes TEXT,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE
);

-- Tabela de Reservas
CREATE TABLE Reservas (
    reserva_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    data_reserva DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expiracao DATETIME NOT NULL,
    status ENUM('ativa', 'cancelada', 'concluida') DEFAULT 'ativa',
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE
);

-- Tabela de Avaliações (opcional)
CREATE TABLE Avaliacoes (
    avaliacao_id INT PRIMARY KEY AUTO_INCREMENT,
    livro_id INT NOT NULL,
    usuario_id INT NOT NULL,
    nota DECIMAL(2,1) NOT NULL CHECK (nota BETWEEN 0 AND 5),
    comentario TEXT,
    data_avaliacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (livro_id) REFERENCES Livros(livro_id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    UNIQUE KEY (livro_id, usuario_id) -- Cada usuário pode avaliar um livro apenas uma vez
);