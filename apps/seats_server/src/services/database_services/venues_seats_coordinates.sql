CREATE TABLE IF NOT EXISTS venues (
  venue_id SERIAL NOT NULL PRIMARY KEY,
  owner_id SERIAL REFERENCES users (id),
  canvas_height varchar (100) NOT NULL,
  canvas_width varchar (100) NOT NULL
);

CREATE TABLE IF NOT EXISTS seats (
  seat_id INTEGER UNIQUE NOT NULL PRIMARY KEY,
  venue_id SERIAL REFERENCES venues (venue_id)
);

CREATE TABLE IF NOT EXISTS coordinates (
  coordinate_id SERIAL NOT NULL PRIMARY KEY,
  lon varchar (100) NOT NULL,
  lat varchar (100) NOT NULL
);

ALTER TABLE seats
ADD COLUMN coordinate_id SERIAL REFERENCES coordinates (coordinate_id);

ALTER TABLE coordinates
ADD COLUMN seat_id SERIAL REFERENCES seats (seat_id);