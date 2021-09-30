CREATE TABLE IF NOT EXISTS users (
  id SERIAL NOT NULL PRIMARY KEY,
  email varchar (100) NOT NULL,
  password varchar (100) NOT NULL
);

CREATE TABLE IF NOT EXISTS venues (
  id SERIAL NOT NULL PRIMARY KEY,
  owner_id SERIAL REFERENCES users (id),
  canvas_height varchar (100) NOT NULL,
  canvas_width varchar (100) NOT NULL
);

CREATE TABLE IF NOT EXISTS seats (
  id SERIAL PRIMARY KEY,
  venue_id INTEGER REFERENCES venues (id),
  lon varchar (100) NOT NULL,
  lat varchar (100) NOT NULL
);
