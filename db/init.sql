CREATE TABLE IF NOT EXISTS types (
  type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on types.name
CREATE INDEX idx_types_name_search_vector ON types USING gin(search_vector);

CREATE TABLE IF NOT EXISTS coromon (
  coro_id INTEGER PRIMARY KEY,
  name VARCHAR (255) NOT NULL,
  type_id INTEGER NOT NULL,
  sp INT DEFAULT 34, -- Every coromon has 54 SP as their stat, but it is a stat that can be edited

  -- Foreign Key to types Table
  CONSTRAINT fk_types
    FOREIGN KEY(type_id)
      REFERENCES types(type_id),

  -- Add a generated column for the tsvector (PostgreSQL 12+)
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on coromon.name
CREATE INDEX idx_coromon_name_search_vector ON coromon USING gin(search_vector);

-- Add a B-Tree Index on cormon.type_id
CREATE INDEX idx_coromon_type_id ON coromon (type_id);

CREATE TABLE IF NOT EXISTS type_effectiveness (
  attacking_type_id INTEGER NOT NULL,
  defending_type_id INTEGER NOT NULL,
  multiplier DECIMAL NOT NULL DEFAULT 1,

  -- Foreign Key to types Table for both attacking and defending
  CONSTRAINT fk_attacking_type
    FOREIGN KEY(attacking_type_id)
      REFERENCES types(type_id),
  CONSTRAINT fk_defending_type
    FOREIGN KEY(defending_type_id)
      REFERENCES types(type_id),

  PRIMARY KEY(attacking_type_id, defending_type_id)
);

-- Add a Composite Index on defending_type_id and attacking_type_id
CREATE INDEX idx_type_effectiveness_defending_attacking ON type_effectiveness (defending_type_id, attacking_type_id);

CREATE TABLE IF NOT EXISTS evolution_stage (
  evolution_stage_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  coro_id INTEGER NOT NULL,
  stage_level INTEGER NOT NULL DEFAULT 1,

  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id)
);

-- Add a B-Tree Index on evolution_stage.coro_id
CREATE INDEX idx_evolution_stage_coro_id ON evolution_stage (coro_id);

-- Add a B-Tree Index on evolution_stage.stage_level
CREATE INDEX idx_evolution_stage_stage_level ON evolution_stage (stage_level);

-- Create Enum for table traits
CREATE TYPE traits_type AS ENUM('Passive', 'Active');

CREATE TABLE IF NOT EXISTS traits (
  trait_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type TRAITS_TYPE NOT NULL,
  effect_desc TEXT NOT NULL,

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on traits.name
CREATE INDEX idx_traits_name_search_vector ON traits USING gin(search_vector);

CREATE TABLE trait_versions (
  trait_version_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  trait_id INTEGER NOT NULL,
  plus INTEGER NOT NULL DEFAULT 0,
  version_description TEXT NOT NULL
);

-- Add a B-Tree Index on trait_versions.trait_id
CREATE INDEX idx_trait_versions_trait_id ON trait_versions (trait_id);

CREATE TABLE IF NOT EXISTS coromon_traits (
  trait_id INTEGER NOT NULL,
  coro_id INTEGER NOT NULL,
  trait_version_id INTEGER NOT NULL,

  -- Foreign Key to traits Table
  CONSTRAINT fk_traits
    FOREIGN KEY(trait_id)
      REFERENCES traits(trait_id),
  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id),
  -- Foreign Key to trait_versions Table
  CONSTRAINT fk_trait_versions
    FOREIGN KEY(trait_version_id)
      REFERENCES trait_versions(trait_version_id),

  PRIMARY KEY(trait_id, coro_id)
);

-- Add a B-Tree Index on coromon_traits.coro_id and coromon_traits.trait_id
CREATE INDEX idx_coromon_traits_coro_id ON coromon_traits (coro_id);
CREATE INDEX idx_coromon_traits_trait_id ON coromon_traits (trait_id);

-- Add a Composite Index on trait_id and coro_id
CREATE INDEX idx_coromon_traits_trait_coro_id ON coromon_traits (trait_id, coro_id);

-- Create Enum for table effect_types
CREATE TYPE effect_types_type AS ENUM('Status', 'Stat_Positive', 'Stat_Negative'); -- more to be added

CREATE TABLE IF NOT EXISTS effect_types (
  effect_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type EFFECT_TYPES_TYPE NOT NULL,
  self_inflicted BOOLEAN NOT NULL DEFAULT FALSE,

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on effect_types.name
CREATE INDEX idx_effect_types_name_search_vector ON effect_types USING gin(search_vector);

CREATE TABLE IF NOT EXISTS trait_version_effects (
  trait_version_effect_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  trait_version_id INTEGER NOT NULL,
  effect_type_id INTEGER NOT NULL,
  value DECIMAL NOT NULL,

  -- Foreign Key to trait_versions Table
  CONSTRAINT fk_trait_versions
    FOREIGN KEY(trait_version_id)
      REFERENCES trait_versions(trait_version_id),
  -- Foreign Key to effect_types Table
  CONSTRAINT fk_effect_types
    FOREIGN KEY(effect_type_id)
      REFERENCES effect_types(effect_type_id)
);

-- Create Enum for table coromon_stats
CREATE TYPE coromon_stats_stat_type AS ENUM('HP', 'Speed', 'Defense', 'Special_Attack', 'Special_Defense');

CREATE TABLE IF NOT EXISTS coromon_stats (
  coro_id INTEGER NOT NULL,
  stat_type COROMON_STATS_STAT_TYPE NOT NULL,
  value INTEGER NOT NULL,

  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id),

  PRIMARY KEY(coro_id, stat_type)
);

-- Add a B-Tree Index on coromon_stats.coro_id and coromon_stats.stat_type
CREATE INDEX idx_coromon_stats_coro_id ON coromon_stats (coro_id);
CREATE INDEX idx_coromon_stats_stat_type ON coromon_stats (stat_type);

-- Add a Composite Index on coromon_stats.coro_id and coromon_stats.stat_type
CREATE INDEX idx_coromon_stats_coro_id_stat_type ON coromon_stats (coro_id, stat_type);

CREATE TABLE IF NOT EXISTS moves (
  move_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  type_id INTEGER NOT NULL,
  move_power INTEGER,
  accuracy DECIMAL DEFAULT 100,

  -- Foreign Key to coromon Table
  CONSTRAINT fk_types
    FOREIGN KEY(type_id)
      REFERENCES types(type_id),

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on moves.name
CREATE INDEX idx_moves_name_search_vector ON moves USING gin(search_vector);

-- Add a B-Tree Index on moves.type_id and moves.move_power
CREATE INDEX idx_moves_type_id ON moves (type_id);
CREATE INDEX idx_moves_move_power ON moves (move_power);

CREATE TABLE IF NOT EXISTS coromon_moves (
  coro_id INTEGER NOT NULL,
  move_id INTEGER NOT NULL,
  learn_level INTEGER CHECK (learn_level BETWEEN 0 and 99),

  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id),
  -- Foreign Key to moves Table
  CONSTRAINT fk_moves
    FOREIGN KEY(move_id)
      REFERENCES moves(move_id),

  PRIMARY KEY(coro_id, move_id)
);

-- Add a B-Tree Index on coromon_moves.coro_id and coromon_moves.move_id
CREATE INDEX idx_coromon_moves_coro_id ON coromon_moves (coro_id);
CREATE INDEX idx_coromon_moves_move_id ON coromon_moves (move_id);

-- Add a Composite Index on coromon_moves.coro_id and coromon_moves.move_id
CREATE INDEX idx_coromon_moves_coro_id_move_id ON coromon_moves (coro_id, move_id);

-- Create Enum for table move_effect_types
CREATE TYPE move_effect_types_type AS ENUM('Status', 'Damage', 'Stat_Positive', 'Stat_Negative');

CREATE TABLE IF NOT EXISTS move_effect_types (
  move_effect_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type MOVE_EFFECT_TYPES_TYPE NOT NULL DEFAULT 'Damage',

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on move_effect_types.name
CREATE INDEX idx_move_effect_types_name_search_vector ON move_effect_types USING gin(search_vector);

CREATE TABLE IF NOT EXISTS move_effects (
  move_effect_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  move_id INTEGER NOT NULL,
  move_effect_type_id INTEGER NOT NULL,
  value DECIMAL NOT NULL,
  chance DECIMAL NOT NULL DEFAULT 1.00,
  is_primary BOOLEAN NOT NULL DEFAULT TRUE,

  -- Foreign Key to moves Table
  CONSTRAINT fk_moves
    FOREIGN KEY(move_id)
      REFERENCES moves(move_id),
  -- Foreign Key to moves Table
  CONSTRAINT fk_move_effect_types
    FOREIGN KEY(move_effect_type_id)
      REFERENCES move_effect_types(move_effect_type_id)
);

-- Inserting All Types Into Types Table
INSERT INTO types (name)
VALUES
  ('Normal'),
  ('Electric'),
  ('Ghost'),
  ('Sand'),
  ('Fire'),
  ('Ice'),
  ('Water'),
  ('Magic'),
  ('Foul'),
  ('Heavy'),
  ('Air'),
  ('Poison'),
  ('Cut'),
  ('Crimsonite');

-- Inserting All Coromon, 124 total, Into Coromon Table
INSERT INTO coromon (coro_id, name, type_id)
VALUES
  (1, 'Cubzero', (SELECT type_id FROM types WHERE name = 'Ice')),
  (2, 'Aroara', (SELECT type_id FROM types WHERE name = 'Ice')),
  (3, 'Bearealis', (SELECT type_id FROM types WHERE name = 'Ice')),
  (4, 'Toruga', (SELECT type_id FROM types WHERE name = 'Fire')),
  (5, 'Embaval', (SELECT type_id FROM types WHERE name = 'Fire')),
  (6, 'Volcadon', (SELECT type_id FROM types WHERE name = 'Fire')),
  (7, 'Nibblegar', (SELECT type_id FROM types WHERE name = 'Water')),
  (8, 'Sheartooth', (SELECT type_id FROM types WHERE name = 'Water')),
  (9, 'Megalobite', (SELECT type_id FROM types WHERE name = 'Water')),
  (10, 'Swurmy', (SELECT type_id FROM types WHERE name = 'Normal')),
  (11, 'Beezel', (SELECT type_id FROM types WHERE name = 'Normal')),
  (12, 'Humbee', (SELECT type_id FROM types WHERE name = 'Normal')),
  (13, 'Silquill', (SELECT type_id FROM types WHERE name = 'Normal')),
  (14, 'Gildwing', (SELECT type_id FROM types WHERE name = 'Normal')),
  (15, 'Golbeak', (SELECT type_id FROM types WHERE name = 'Normal')),
  (16, 'Sliterpin', (SELECT type_id FROM types WHERE name = 'Normal')),
  (17, 'Serpike', (SELECT type_id FROM types WHERE name = 'Normal')),
  (18, 'Houndos', (SELECT type_id FROM types WHERE name = 'Electric')),
  (19, 'Hountrion', (SELECT type_id FROM types WHERE name = 'Electric')),
  (20, 'Armado', (SELECT type_id FROM types WHERE name = 'Normal')),
  (21, 'Armadil', (SELECT type_id FROM types WHERE name = 'Normal')),
  (22, 'Armadon', (SELECT type_id FROM types WHERE name = 'Normal')),
  (23, 'Sanscale', (SELECT type_id FROM types WHERE name = 'Sand')),
  (24, 'Caradune', (SELECT type_id FROM types WHERE name = 'Sand')),
  (25, 'Bittybolt', (SELECT type_id FROM types WHERE name = 'Electric')),
  (26, 'Toravolt', (SELECT type_id FROM types WHERE name = 'Electric')),
  (27, 'Bloby', (SELECT type_id FROM types WHERE name = 'Fire')),
  (28, 'Molteye', (SELECT type_id FROM types WHERE name = 'Fire')),
  (29, 'Ashclops', (SELECT type_id FROM types WHERE name = 'Fire')),
  (30, 'Fiddly', (SELECT type_id FROM types WHERE name = 'Water')),
  (31, 'Ucaclaw', (SELECT type_id FROM types WHERE name = 'Water')),
  (32, 'Moffel', (SELECT type_id FROM types WHERE name = 'Sand')),
  (33, 'Digmow', (SELECT type_id FROM types WHERE name = 'Sand')),
  (34, 'Dugterra', (SELECT type_id FROM types WHERE name = 'Sand')),
  (35, 'Buzzlet', (SELECT type_id FROM types WHERE name = 'Electric')),
  (36, 'Bazzer', (SELECT type_id FROM types WHERE name = 'Electric')),
  (37, 'Rhynobuz', (SELECT type_id FROM types WHERE name = 'Electric')),
  (38, 'Lunarpup', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (39, 'Lunarwulf', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (40, 'Eclyptor', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (41, 'Kryo', (SELECT type_id FROM types WHERE name = 'Ice')),
  (42, 'Krypeak', (SELECT type_id FROM types WHERE name = 'Ice')),
  (43, 'Krybeast', (SELECT type_id FROM types WHERE name = 'Ice')),
  (44, 'Bren', (SELECT type_id FROM types WHERE name = 'Fire')),
  (45, 'Pyrochick', (SELECT type_id FROM types WHERE name = 'Fire')),
  (46, 'Infinix', (SELECT type_id FROM types WHERE name = 'Fire')),
  (47, 'Acie', (SELECT type_id FROM types WHERE name = 'Electric')),
  (48, 'Deecie', (SELECT type_id FROM types WHERE name = 'Electric')),
  (49, 'Kyreptil', (SELECT type_id FROM types WHERE name = 'Sand')),
  (50, 'Kyraptor', (SELECT type_id FROM types WHERE name = 'Sand')),
  (51, 'Gella', (SELECT type_id FROM types WHERE name = 'Water')),
  (52, 'Gellish', (SELECT type_id FROM types WHERE name = 'Water')),
  (53, 'Gelaquad', (SELECT type_id FROM types WHERE name = 'Water')),
  (54, 'Skarbone', (SELECT type_id FROM types WHERE name = 'Sand')),
  (55, 'Skuldra', (SELECT type_id FROM types WHERE name = 'Sand')),
  (56, 'Skelatops', (SELECT type_id FROM types WHERE name = 'Sand')),
  (57, 'Droople', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (58, 'Mudma', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (59, 'Arcta', (SELECT type_id FROM types WHERE name = 'Ice')),
  (60, 'Arcturos', (SELECT type_id FROM types WHERE name = 'Ice')),
  (61, 'Seraphace', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (62, 'Grimmask', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (63, 'Squidma', (SELECT type_id FROM types WHERE name = 'Fire')),
  (64, 'Magmilus', (SELECT type_id FROM types WHERE name = 'Fire')),
  (65, 'Lumon', (SELECT type_id FROM types WHERE name = 'Electric')),
  (66, 'Lampyre', (SELECT type_id FROM types WHERE name = 'Electric')),
  (67, 'Lumasect', (SELECT type_id FROM types WHERE name = 'Electric')),
  (68, 'Patterbit', (SELECT type_id FROM types WHERE name = 'Normal')),
  (69, 'Pitterbyte', (SELECT type_id FROM types WHERE name = 'Normal')),
  (70, 'Cyberite', (SELECT type_id FROM types WHERE name = 'Normal')),
  (71, 'Decibite', (SELECT type_id FROM types WHERE name = 'Sand')),
  (72, 'Centilla', (SELECT type_id FROM types WHERE name = 'Sand')),
  (73, 'Millidont', (SELECT type_id FROM types WHERE name = 'Sand')),
  (74, 'Taddle', (SELECT type_id FROM types WHERE name = 'Water')),
  (75, 'Fibio', (SELECT type_id FROM types WHERE name = 'Water')),
  (76, 'Chonktoad', (SELECT type_id FROM types WHERE name = 'Water')),
  (77, 'Tinshel', (SELECT type_id FROM types WHERE name = 'Sand')),
  (78, 'Dunpod', (SELECT type_id FROM types WHERE name = 'Sand')),
  (79, 'Sandril', (SELECT type_id FROM types WHERE name = 'Sand')),
  (80, 'Blizzburd', (SELECT type_id FROM types WHERE name = 'Ice')),
  (81, 'Blizzian', (SELECT type_id FROM types WHERE name = 'Ice')),
  (82, 'Purrgy', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (83, 'Ghinx', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (84, 'Purrghast', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (85, 'Gauslime', (SELECT type_id FROM types WHERE name = 'Electric')),
  (86, 'Magnamire', (SELECT type_id FROM types WHERE name = 'Electric')),
  (87, 'Quagoo', (SELECT type_id FROM types WHERE name = 'Water')),
  (88, 'Swampa', (SELECT type_id FROM types WHERE name = 'Water')),
  (89, 'Squidly', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (90, 'Octotle', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (91, 'Ruptius', (SELECT type_id FROM types WHERE name = 'Fire')),
  (92, 'Vulbrute', (SELECT type_id FROM types WHERE name = 'Fire')),
  (93, 'Mooby', (SELECT type_id FROM types WHERE name = 'Sand')),
  (94, 'Molbash', (SELECT type_id FROM types WHERE name = 'Sand')),
  (95, 'Malavite', (SELECT type_id FROM types WHERE name = 'Sand')),
  (96, 'Flowish', (SELECT type_id FROM types WHERE name = 'Water')),
  (97, 'Daricara', (SELECT type_id FROM types WHERE name = 'Water')),
  (98, 'Mino', (SELECT type_id FROM types WHERE name = 'Fire')),
  (99, 'Blazitaur', (SELECT type_id FROM types WHERE name = 'Fire')),
  (100, 'Frova', (SELECT type_id FROM types WHERE name = 'Ice')),
  (101, 'Froshell', (SELECT type_id FROM types WHERE name = 'Ice')),
  (102, 'Glamoth', (SELECT type_id FROM types WHERE name = 'Ice')),
  (103, 'Otogy', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (104, 'Orotchy', (SELECT type_id FROM types WHERE name = 'Ghost')),
  (105, 'Shimshell', (SELECT type_id FROM types WHERE name = 'Water')),
  (106, 'Atlantern', (SELECT type_id FROM types WHERE name = 'Water')),
  (107, 'Lemobi', (SELECT type_id FROM types WHERE name = 'Normal')),
  (108, 'Makinja', (SELECT type_id FROM types WHERE name = 'Normal')),
  (109, 'Glacikid', (SELECT type_id FROM types WHERE name = 'Ice')),
  (110, 'Arctiram', (SELECT type_id FROM types WHERE name = 'Ice')),
  (111, 'Fiddly', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (112, 'Ucaclaw', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (113, 'Lumon', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (114, 'Lampyre', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (115, 'Lumasect', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (116, 'Decibite', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (117, 'Centilla', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (118, 'Millidont', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (119, 'Arcta', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (120, 'Arcturos', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (121, 'Otogy', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (122, 'Orotchy', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (123, 'Squidma', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (124, 'Magmilus', (SELECT type_id FROM types WHERE name = 'Crimsonite'));

-- Inserting Titans Into Coromon Table
INSERT INTO coromon (coro_id, name, type_id, sp)
VALUES
  (1000, 'Voltgar', (SELECT type_id FROM types WHERE name = 'Electric'), 160),
  (1001, 'Illuginn', (SELECT type_id FROM types WHERE name = 'Ghost'), 160),
  (1002, 'Sart', (SELECT type_id FROM types WHERE name = 'Sand'), 160),
  (1003, 'Hozai', (SELECT type_id FROM types WHERE name = 'Fire'), 160),
  (1004, 'Vørst', (SELECT type_id FROM types WHERE name = 'Ice'), 160),
  (1005, 'Chalchiu', (SELECT type_id FROM types WHERE name = 'Water'), 160),
  (1006, 'Chalchiu Dark Form', (SELECT type_id FROM types WHERE name = 'Crimsonite'), 160);
  
-- Inserting Into The Type Effectiveness Table
INSERT INTO type_effectiveness (attacking_type_id, defending_type_id, multiplier)
VALUES
  -- Normal Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Ghost'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Normal'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Electric Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Electric'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Sand'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Water'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Electric'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Ghost Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Normal'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Ghost'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ghost'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Sand Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Electric'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Sand'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Water'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Sand'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Fire Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Fire'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Ice'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Water'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Fire'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Ice Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Fire'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Ice'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Water'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Ice'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Water Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Electric'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Sand'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Fire'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Ice'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Water'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Water'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Magic Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Ghost'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Magic'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Foul Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Sand'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Water'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Foul'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Heavy Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Fire'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Ice'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Heavy'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Air Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Fire'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Ice'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Air'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Poison Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Normal'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Ice'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Poison'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Cut Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Electric'), 2.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Ghost'), 0.5),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Cut'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 0.5),
  -- Crimsonite Attacking Types
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Normal'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Electric'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Ghost'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Sand'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Fire'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Ice'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Water'), 1.0),
  ((SELECT type_id FROM types WHERE name = 'Crimsonite'), (SELECT type_id FROM types WHERE name = 'Crimsonite'), 1.0);















































































  