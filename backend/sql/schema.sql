-- Esquema de la base de datos (MySQL 5.7+ / 8.x)
-- NOTA: no se usan CHECK constraints a propósito: la validación vive en el backend (clases modelo),
-- y así se puede demostrar la prueba "insertar un registro inválido directo en la BD".

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('cliente','admin') NOT NULL DEFAULT 'cliente',
  age INT NOT NULL,
  monthly_income DECIMAL(12,2) NOT NULL DEFAULT 0,
  monthly_budget DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('gasto','ingreso') NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  category VARCHAR(40) NOT NULL,
  description VARCHAR(200) NOT NULL DEFAULT '',
  tx_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_date (user_id, tx_date),
  CONSTRAINT fk_tx_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ml_models (
  name VARCHAR(50) PRIMARY KEY,
  payload JSON NOT NULL,
  metrics JSON NOT NULL,
  trained_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
