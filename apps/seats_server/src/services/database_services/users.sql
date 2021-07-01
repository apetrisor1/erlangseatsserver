CREATE TABLE IF NOT EXISTS users (
  id SERIAL NOT NULL,
  email varchar (100) NOT NULL,
  password varchar (100) NOT NULL,

  PRIMARY KEY (id)
);
