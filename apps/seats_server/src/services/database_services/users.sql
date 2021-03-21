CREATE TABLE IF NOT EXISTS users (
  id SERIAL NOT NULL,
  email varchar (100) NOT NULL,
  password varchar (100) NOT NULL

  PRIMARY KEY (id)
);

-- Seed categories 
INSERT INTO users (email, password) VALUES
  ('adi@adi.com', '123456'),
  ('adi1@adi.com', '123456'),
  ('adi2@adi.com', '123456'),
  ('adi3@adi.com', '123456');
