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
  name VARCHAR (255) UNIQUE NOT NULL,
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

CREATE TABLE IF NOT EXISTS coromon_evolutions (
  coromon_evolution_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  coro_id INTEGER NOT NULL,
  pre_evo_coro_id INTEGER NULL,
  next_evo_coro_id INTEGER NULL,
  condition_to_evolve VARCHAR(255) NULL, -- Level / Item it will evolve, e.g. "Level 20", "Using Item X", etc... If Null means it cannot evolve, next_evo_coro_id should also be null

  CONSTRAINT fk_pre_evo_coro
    FOREIGN KEY (pre_evo_coro_id)
      REFERENCES coromon(coro_id),
  CONSTRAINT fk_next_evo_coro
    FOREIGN KEY (next_evo_coro_id)
      REFERENCES coromon(coro_id)
);

-- Add a B-Tree Index on coromon_evolutions.coro_id, coromon_evolutions.pre_evo_coro_id, coromon_evolutions.next_evo_coro_id
CREATE INDEX idx_coromon_evolutions_coro_id on coromon_evolutions (coro_id);
CREATE INDEX idx_coromon_evolutions_pre_evo_coro_id on coromon_evolutions (pre_evo_coro_id);
CREATE INDEX idx_coromon_evolutions_next_evo_coro_id on coromon_evolutions (next_evo_coro_id);

-- Create Enum for table traits
CREATE TYPE traits_type AS ENUM('Passive', 'Active');

CREATE TABLE IF NOT EXISTS traits (
  trait_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type TRAITS_TYPE NOT NULL,

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
  description TEXT NOT NULL
);

-- Add a B-Tree Index on trait_versions.trait_id
CREATE INDEX idx_trait_versions_trait_id ON trait_versions (trait_id);

CREATE TABLE IF NOT EXISTS coromon_traits (
  trait_id INTEGER NOT NULL,
  coro_id INTEGER NOT NULL,
  chance DECIMAL NOT NULL,

  -- Foreign Key to traits Table
  CONSTRAINT fk_traits
    FOREIGN KEY(trait_id)
      REFERENCES traits(trait_id),
  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id),

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

CREATE TABLE IF NOT EXISTS skills (
  skill_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  type_id INTEGER NOT NULL,
  skill_power INTEGER,
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

-- Add a GIN index on skills.name
CREATE INDEX idx_skills_name_search_vector ON skills USING gin(search_vector);

-- Add a B-Tree Index on skills.type_id and skills.skill_power
CREATE INDEX idx_skills_type_id ON skills (type_id);
CREATE INDEX idx_skills_skill_power ON skills (skill_power);

CREATE TABLE IF NOT EXISTS coromon_skills (
  coro_id INTEGER NOT NULL,
  skill_id INTEGER NOT NULL,
  learn_level INTEGER CHECK (learn_level BETWEEN 0 and 99),

  -- Foreign Key to coromon Table
  CONSTRAINT fk_coromon
    FOREIGN KEY(coro_id)
      REFERENCES coromon(coro_id),
  -- Foreign Key to skills Table
  CONSTRAINT fk_skills
    FOREIGN KEY(skill_id)
      REFERENCES skills(skill_id),

  PRIMARY KEY(coro_id, skill_id)
);

-- Add a B-Tree Index on coromon_skills.coro_id and coromon_skills.skill_id
CREATE INDEX idx_coromon_skills_coro_id ON coromon_skills (coro_id);
CREATE INDEX idx_coromon_skills_skill_id ON coromon_skills (skill_id);

-- Add a Composite Index on coromon_skills.coro_id and coromon_skills.skill_id
CREATE INDEX idx_coromon_skills_coro_id_skill_id ON coromon_skills (coro_id, skill_id);

-- Create Enum for table skill_effect_types
CREATE TYPE skill_effect_types_type AS ENUM('Status', 'Damage', 'Stat_Positive', 'Stat_Negative');

CREATE TABLE IF NOT EXISTS skill_effect_types (
  skill_effect_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type SKILL_EFFECT_TYPES_TYPE NOT NULL DEFAULT 'Damage',

  -- Add tsvector column for full-text search
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('simple', name)
  ) STORED
);

-- Add a GIN index on skill_effect_types.name
CREATE INDEX idx_skill_effect_types_name_search_vector ON skill_effect_types USING gin(search_vector);

CREATE TABLE IF NOT EXISTS skill_effects (
  skill_effect_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  skill_id INTEGER NOT NULL,
  skill_effect_type_id INTEGER NOT NULL,
  value DECIMAL NOT NULL,
  chance DECIMAL NOT NULL DEFAULT 1.00,
  is_primary BOOLEAN NOT NULL DEFAULT TRUE,

  -- Foreign Key to skills Table
  CONSTRAINT fk_skills
    FOREIGN KEY(skill_id)
      REFERENCES skills(skill_id),
  -- Foreign Key to skills Table
  CONSTRAINT fk_skill_effect_types
    FOREIGN KEY(skill_effect_type_id)
      REFERENCES skill_effect_types(skill_effect_type_id)
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
  (16, 'Slitherpin', (SELECT type_id FROM types WHERE name = 'Normal')),
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
  (42, 'Krypeek', (SELECT type_id FROM types WHERE name = 'Ice')),
  (43, 'Krybeest', (SELECT type_id FROM types WHERE name = 'Ice')),
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
  (111, 'Crimsonite Fiddly', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (112, 'Crimsonite Ucaclaw', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (113, 'Crimsonite Lumon', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (114, 'Crimsonite Lampyre', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (115, 'Crimsonite Lumasect', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (116, 'Crimsonite Decibite', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (117, 'Crimsonite Centilla', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (118, 'Crimsonite Millidont', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (119, 'Crimsonite Arcta', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (120, 'Crimsonite Arcturos', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (121, 'Crimsonite Otogy', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (122, 'Crimsonite Orotchy', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (123, 'Crimsonite Squidma', (SELECT type_id FROM types WHERE name = 'Crimsonite')),
  (124, 'Crimsonite Magmilus', (SELECT type_id FROM types WHERE name = 'Crimsonite'));

-- Inserting Titans Into Coromon Table
INSERT INTO coromon (coro_id, name, type_id, sp)
VALUES
  (1000, 'Voltgar', (SELECT type_id FROM types WHERE name = 'Electric'), 160),
  (1001, 'Illuginn', (SELECT type_id FROM types WHERE name = 'Ghost'), 160),
  (1002, 'Sart', (SELECT type_id FROM types WHERE name = 'Sand'), 160),
  (1003, 'Hozai', (SELECT type_id FROM types WHERE name = 'Fire'), 160),
  (1004, 'Vørst', (SELECT type_id FROM types WHERE name = 'Ice'), 160),
  (1005, 'Chalchiu', (SELECT type_id FROM types WHERE name = 'Water'), 160),
  (1006, 'Dark Form Chalchiu', (SELECT type_id FROM types WHERE name = 'Crimsonite'), 160);
  
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

-- Inserting All Coromon Evolutions Into Coromon Evolutions Table
INSERT INTO coromon_evolutions (coro_id, pre_evo_coro_id, next_evo_coro_id, condition_to_evolve)
VALUES
  ((SELECT coro_id FROM coromon WHERE name = 'Cubzero'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Aroara'), 'Level 16'),
  ((SELECT coro_id FROM coromon WHERE name = 'Aroara'), (SELECT coro_id FROM coromon WHERE name = 'Cubzero'), (SELECT coro_id FROM coromon WHERE name = 'Bearealis'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Bearealis'), (SELECT coro_id FROM coromon WHERE name = 'Aroara'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Toruga'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Embaval'), 'Level 16'),
  ((SELECT coro_id FROM coromon WHERE name = 'Embaval'), (SELECT coro_id FROM coromon WHERE name = 'Toruga'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), 'Level 36'),
  ((SELECT coro_id FROM coromon WHERE name = 'Volcadon'), (SELECT coro_id FROM coromon WHERE name = 'Embaval'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Nibblegar'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Sheartooth'), 'Level 17'),
  ((SELECT coro_id FROM coromon WHERE name = 'Sheartooth'), (SELECT coro_id FROM coromon WHERE name = 'Nibblegar'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), 'Level 35'),
  ((SELECT coro_id FROM coromon WHERE name = 'Megalobite'), (SELECT coro_id FROM coromon WHERE name = 'Sheartooth'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Swurmy'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Beezel'), 'Level 14, Attack is raised 6 stages in a single battle'),
  ((SELECT coro_id FROM coromon WHERE name = 'Beezel'), (SELECT coro_id FROM coromon WHERE name = 'Swurmy'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), 'Level 28'),
  ((SELECT coro_id FROM coromon WHERE name = 'Humbee'), (SELECT coro_id FROM coromon WHERE name = 'Beezel'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Silquill'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Gildwing'), 'Level 15'),
  ((SELECT coro_id FROM coromon WHERE name = 'Gildwing'), (SELECT coro_id FROM coromon WHERE name = 'Silquill'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), 'Level 41'),
  ((SELECT coro_id FROM coromon WHERE name = 'Golbeak'), (SELECT coro_id FROM coromon WHERE name = 'Gildwing'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Slitherpin'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Serpike'), 'Level 25'),
  ((SELECT coro_id FROM coromon WHERE name = 'Serpike'), (SELECT coro_id FROM coromon WHERE name = 'Slitherpin'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Houndos'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Hountrion'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Hountrion'), (SELECT coro_id FROM coromon WHERE name = 'Houndos'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Armado'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Armadil'), 'Level 18'),
  ((SELECT coro_id FROM coromon WHERE name = 'Armadil'), (SELECT coro_id FROM coromon WHERE name = 'Armado'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), 'Level 33'),
  ((SELECT coro_id FROM coromon WHERE name = 'Armadon'), (SELECT coro_id FROM coromon WHERE name = 'Armadil'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Sanscale'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Caradune'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Caradune'), (SELECT coro_id FROM coromon WHERE name = 'Sanscale'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Bittybolt'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Toravolt'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Toravolt'), (SELECT coro_id FROM coromon WHERE name = 'Bittybolt'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Bloby'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Molteye'), 'Level 23'),
  ((SELECT coro_id FROM coromon WHERE name = 'Molteye'), (SELECT coro_id FROM coromon WHERE name = 'Bloby'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), 'Level 44'),
  ((SELECT coro_id FROM coromon WHERE name = 'Ashclops'), (SELECT coro_id FROM coromon WHERE name = 'Molteye'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Fiddly'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), (SELECT coro_id FROM coromon WHERE name = 'Fiddly'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Moffel'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Digmow'), 'Level 17'),
  ((SELECT coro_id FROM coromon WHERE name = 'Digmow'), (SELECT coro_id FROM coromon WHERE name = 'Moffel'), (SELECT coro_id FROM coromon WHERE name = 'Dugterra'), 'Level 31'),
  ((SELECT coro_id FROM coromon WHERE name = 'Dugterra'), (SELECT coro_id FROM coromon WHERE name = 'Digmow'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Buzzlet'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Bazzer'), 'Level 17'),
  ((SELECT coro_id FROM coromon WHERE name = 'Bazzer'), (SELECT coro_id FROM coromon WHERE name = 'Buzzlet'), (SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), 'Level 36'),
  ((SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), (SELECT coro_id FROM coromon WHERE name = 'Bazzer'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Lunarpup'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Lunarwulf'), 'Level 21'),
  ((SELECT coro_id FROM coromon WHERE name = 'Lunarwulf'), (SELECT coro_id FROM coromon WHERE name = 'Lunarpup'), (SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), 'Level 39, Two Opponent Lunarwulfs use Howl in the same turn'),
  ((SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), (SELECT coro_id FROM coromon WHERE name = 'Lunarwulf'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Kryo'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Krypeek'), 'Level 18'),
  ((SELECT coro_id FROM coromon WHERE name = 'Krypeek'), (SELECT coro_id FROM coromon WHERE name = 'Kryo'), (SELECT coro_id FROM coromon WHERE name = 'Krybeest'), 'Level 39'),
  ((SELECT coro_id FROM coromon WHERE name = 'Krybeest'), (SELECT coro_id FROM coromon WHERE name = 'Krypeek'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Bren'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Pyrochick'), 'Level 12'),
  ((SELECT coro_id FROM coromon WHERE name = 'Pyrochick'), (SELECT coro_id FROM coromon WHERE name = 'Bren'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Infinix'), (SELECT coro_id FROM coromon WHERE name = 'Pyrochick'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Acie'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Deecie'), 'Level 35'),
  ((SELECT coro_id FROM coromon WHERE name = 'Deecie'), (SELECT coro_id FROM coromon WHERE name = 'Acie'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Kyreptil'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Kyraptor'), 'Level 37'),
  ((SELECT coro_id FROM coromon WHERE name = 'Kyraptor'), (SELECT coro_id FROM coromon WHERE name = 'Kyreptil'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Gella'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Gellish'), 'Level 21'),
  ((SELECT coro_id FROM coromon WHERE name = 'Gellish'), (SELECT coro_id FROM coromon WHERE name = 'Gella'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), (SELECT coro_id FROM coromon WHERE name = 'Gellish'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Skarbone'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Skuldra'), 'Level 18'),
  ((SELECT coro_id FROM coromon WHERE name = 'Skuldra'), (SELECT coro_id FROM coromon WHERE name = 'Skarbone'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), 'Level 37'),
  ((SELECT coro_id FROM coromon WHERE name = 'Skelatops'), (SELECT coro_id FROM coromon WHERE name = 'Skuldra'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Droople'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Mudma'), 'Level 28'),
  ((SELECT coro_id FROM coromon WHERE name = 'Mudma'), (SELECT coro_id FROM coromon WHERE name = 'Droople'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Arcta'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Arcturos'), 'Level 24'),
  ((SELECT coro_id FROM coromon WHERE name = 'Arcturos'), (SELECT coro_id FROM coromon WHERE name = 'Arcta'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Seraphace'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Grimmask'), 'Level 32'),
  ((SELECT coro_id FROM coromon WHERE name = 'Grimmask'), (SELECT coro_id FROM coromon WHERE name = 'Seraphace'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Squidma'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Magmilus'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Magmilus'), (SELECT coro_id FROM coromon WHERE name = 'Squidma'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Lumon'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Lampyre'), 'Level 16'),
  ((SELECT coro_id FROM coromon WHERE name = 'Lampyre'), (SELECT coro_id FROM coromon WHERE name = 'Lumon'), (SELECT coro_id FROM coromon WHERE name = 'Lumasect'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Lumasect'), (SELECT coro_id FROM coromon WHERE name = 'Lampyre'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Patterbit'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Pitterbyte'), 'Level 30, When a Pitterbyte Kernel is installed'),
  ((SELECT coro_id FROM coromon WHERE name = 'Pitterbyte'), (SELECT coro_id FROM coromon WHERE name = 'Patterbit'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), 'Level 50'),
  ((SELECT coro_id FROM coromon WHERE name = 'Cyberite'), (SELECT coro_id FROM coromon WHERE name = 'Pitterbyte'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Decibite'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Centilla'), 'Level 24'),
  ((SELECT coro_id FROM coromon WHERE name = 'Centilla'), (SELECT coro_id FROM coromon WHERE name = 'Decibite'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), 'Level 39'),
  ((SELECT coro_id FROM coromon WHERE name = 'Millidont'), (SELECT coro_id FROM coromon WHERE name = 'Centilla'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Taddle'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Fibio'), 'Level 18'),
  ((SELECT coro_id FROM coromon WHERE name = 'Fibio'), (SELECT coro_id FROM coromon WHERE name = 'Taddle'), (SELECT coro_id FROM coromon WHERE name = 'Chonktoad'), 'Level 38'),
  ((SELECT coro_id FROM coromon WHERE name = 'Chonktoad'), (SELECT coro_id FROM coromon WHERE name = 'Fibio'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Tinshel'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Dunpod'), 'Level 18'),
  ((SELECT coro_id FROM coromon WHERE name = 'Dunpod'), (SELECT coro_id FROM coromon WHERE name = 'Tinshel'), (SELECT coro_id FROM coromon WHERE name = 'Sandril'), 'Level 32'),
  ((SELECT coro_id FROM coromon WHERE name = 'Sandril'), (SELECT coro_id FROM coromon WHERE name = 'Dunpod'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Blizzburd'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Blizzian'), 'Level 40'),
  ((SELECT coro_id FROM coromon WHERE name = 'Blizzian'), (SELECT coro_id FROM coromon WHERE name = 'Blizzburd'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Purrgy'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Ghinx'), 'Level 38, Every Purrgy Nibbles eaten lowers level by 1'),
  ((SELECT coro_id FROM coromon WHERE name = 'Ghinx'), (SELECT coro_id FROM coromon WHERE name = 'Purrgy'), (SELECT coro_id FROM coromon WHERE name = 'Purrghast'), 'Level 50'),
  ((SELECT coro_id FROM coromon WHERE name = 'Purrghast'), (SELECT coro_id FROM coromon WHERE name = 'Ghinx'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Gauslime'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), 'Level 38'),
  ((SELECT coro_id FROM coromon WHERE name = 'Magnamire'), (SELECT coro_id FROM coromon WHERE name = 'Gauslime'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Quagoo'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Swampa'), 'Level 32'),
  ((SELECT coro_id FROM coromon WHERE name = 'Swampa'), (SELECT coro_id FROM coromon WHERE name = 'Quagoo'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Squidly'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Octotle'), 'Level 37, When its spinner is dipped into the Witchs Kettle'),
  ((SELECT coro_id FROM coromon WHERE name = 'Octotle'), (SELECT coro_id FROM coromon WHERE name = 'Squidly'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Ruptius'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), 'Level 42'),
  ((SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), (SELECT coro_id FROM coromon WHERE name = 'Ruptius'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Mooby'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Molbash'), 'Level 23'),
  ((SELECT coro_id FROM coromon WHERE name = 'Molbash'), (SELECT coro_id FROM coromon WHERE name = 'Mooby'), (SELECT coro_id FROM coromon WHERE name = 'Malavite'), 'Level 45'),
  ((SELECT coro_id FROM coromon WHERE name = 'Malavite'), (SELECT coro_id FROM coromon WHERE name = 'Molbash'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Flowish'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Daricara'), 'Level 39'),
  ((SELECT coro_id FROM coromon WHERE name = 'Daricara'), (SELECT coro_id FROM coromon WHERE name = 'Flowish'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Mino'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), 'Level 32'),
  ((SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), (SELECT coro_id FROM coromon WHERE name = 'Mino'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Frova'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Froshell'), 'Level 20'),
  ((SELECT coro_id FROM coromon WHERE name = 'Froshell'), (SELECT coro_id FROM coromon WHERE name = 'Frova'), (SELECT coro_id FROM coromon WHERE name = 'Glamoth'), 'Level 38'),
  ((SELECT coro_id FROM coromon WHERE name = 'Glamoth'), (SELECT coro_id FROM coromon WHERE name = 'Froshell'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Otogy'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Orotchy'), 'Level 40'),
  ((SELECT coro_id FROM coromon WHERE name = 'Orotchy'), (SELECT coro_id FROM coromon WHERE name = 'Otogy'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Shimshell'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Atlantern'), 'Level 38'),
  ((SELECT coro_id FROM coromon WHERE name = 'Atlantern'), (SELECT coro_id FROM coromon WHERE name = 'Shimshell'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Lemobi'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Makinja'), 'Level 33'),
  ((SELECT coro_id FROM coromon WHERE name = 'Makinja'), (SELECT coro_id FROM coromon WHERE name = 'Lemobi'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Glacikid'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), '38'),
  ((SELECT coro_id FROM coromon WHERE name = 'Arctiram'), (SELECT coro_id FROM coromon WHERE name = 'Glacikid'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Fiddly'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), 'Level 34'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Fiddly'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumon'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lampyre'), 'Level 16'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lampyre'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumon'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumasect'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumasect'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lampyre'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Decibite'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Centilla'), 'Level 24'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Centilla'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Decibite'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), 'Level 39'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Centilla'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcta'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), 'Level 24'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcta'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Otogy'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), 'Level 40'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Otogy'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Squidma'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), 'Level 30'),
  ((SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Squidma'), NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Voltgar'), NULL, NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Illuginn'), NULL, NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Sart'), NULL, NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Hozai'), NULL, NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Vørst'), NULL, NULL, NULL),
  ((SELECT coro_id FROM coromon WHERE name = 'Chalchiu'), NULL, (SELECT coro_id FROM coromon WHERE name = 'Dark Form Chalchiu'), 'Reach 50% Health'),
  ((SELECT coro_id FROM coromon WHERE name = 'Dark Form Chalchiu'), (SELECT coro_id FROM coromon WHERE name = 'Chalchiu'), NULL, NULL);

-- Inserting All Traits Into Traits Table
INSERT INTO traits (name, type)
VALUES
  ('Accurate', 'Passive'),
  ('Acupuncture', 'Active'),
  ('Afterburner', 'Passive'),
  ('Amplified', 'Passive'),
  ('Antarctic', 'Passive'),
  ('Antidote', 'Active'),
  ('Anti-fungal', 'Passive'),
  ('Backup Plan', 'Passive'),
  ('Brave', 'Passive'),
  ('Bright Light', 'Passive'),
  ('Caffeinated', 'Passive'),
  ('Cleanse', 'Passive'),
  ('Clean Retreat', 'Passive'),
  ('Clear Skies', 'Passive'),
  ('Comeback', 'Passive'),
  ('Conductor', 'Passive'),
  ('Conserver', 'Passive'),
  ('Contained Power', 'Passive'),
  ('Cool Body', 'Passive'),
  ('Cosmic', 'Passive'),
  ('Coward', 'Passive'),
  ('Creeping Stare', 'Passive'),
  ('Crippler', 'Passive'),
  ('Dark Atmosphere', 'Passive'),
  ('Dimensional Eye', 'Passive'),
  ('Dirt Coat', 'Passive'),
  ('Disrupting Aura', 'Passive'),
  ('Dry Wind', 'Passive'),
  ('Empathetic', 'Passive'),
  ('Escapist', 'Passive'),
  ('Fast Learner', 'Passive'),
  ('Fast Metabolism', 'Passive'),
  ('Fearless', 'Passive'),
  ('Flare Intake', 'Passive'),
  ('Frost Layer', 'Passive'),
  ('Fully Rested', 'Passive'),
  ('Glacial Affinity', 'Passive'),
  ('Good Aim', 'Passive'),
  ('Gourmand', 'Passive'),
  ('Gravity Pull', 'Passive'),
  ('Gullible', 'Passive'),
  ('Hardheaded', 'Passive'),
  ('Hoarder', 'Passive'),
  ('Hot Headed', 'Passive'),
  ('Humidifier', 'Passive'),
  ('Impatient', 'Passive'),
  ('Inner Fire', 'Passive'),
  ('Intelligent', 'Passive'),
  ('Inverse', 'Passive'),
  ('Kindred Soul', 'Passive'),
  ('Low Density', 'Passive'),
  ('Lucky', 'Passive'),
  ('Magic Layer', 'Passive'),
  ('Magnetic', 'Passive'),
  ('Menacing', 'Passive'),
  ('Molter', 'Passive'),
  ('Motivated', 'Passive'),
  ('Nano Skin', 'Passive'),
  ('Neutralizer', 'Passive'),
  ('Nimble', 'Passive'),
  ('Ninja Sense', 'Passive'),
  ('Nurse', 'Active'),
  ('Overclocker', 'Passive'),
  ('Patdown', 'Passive'),
  ('Pep Talk', 'Active'),
  ('Polished Body', 'Passive'),
  ('Polluter', 'Passive'),
  ('Prepared', 'Passive'),
  ('Radiator', 'Passive'),
  ('Rebirth', 'Passive'),
  ('Reconstitution', 'Active'),
  ('Regurgitator', 'Passive'),
  ('Reignite', 'Passive'),
  ('Resistant', 'Passive'),
  ('Restless', 'Passive'),
  ('Robber', 'Passive'),
  ('Scrapper', 'Passive'),
  ('Sharp Claws', 'Passive'),
  ('Shiny', 'Passive'),
  ('Shock Absorber', 'Passive'),
  ('Short Fused', 'Passive'),
  ('Slippery', 'Passive'),
  ('Snowman', 'Passive'),
  ('Soothing Aura', 'Active'),
  ('Soul Eater', 'Passive'),
  ('Specialist', 'Passive'),
  ('Spiked Body', 'Passive'),
  ('Static Body', 'Passive'),
  ('Steady', 'Passive'),
  ('Steam Layer', 'Passive'),
  ('Sticky Layer', 'Passive'),
  ('Stinky', 'Passive'),
  ('Stoic', 'Passive'),
  ('Strategist', 'Passive'),
  ('Sugar Rush', 'Passive'),
  ('Supersensory', 'Passive'),
  ('Tactical Retreat', 'Passive'),
  ('Thermogenesis', 'Passive'),
  ('Thick Skin', 'Passive'),
  ('Pure Essence Voltgar', 'Passive'),
  ('Pure Essence Hozai', 'Passive'),
  ('Pure Essence Illuginn', 'Passive'),
  ('Pure Essence Vørst', 'Passive'),
  ('Pure Essence Sart', 'Passive'),
  ('Pure Essence Chalchiu', 'Passive'),
  ('Tough Feet', 'Passive'),
  ('Toxic Skin', 'Passive'),
  ('Vaccinated', 'Passive'),
  ('Vegetarian', 'Passive'),
  ('Vengeful', 'Passive'),
  ('Vigilant', 'Passive'),
  ('Water Cooled', 'Passive'),
  ('Weatherproof', 'Passive'),
  ('Wet Coat', 'Passive'),
  ('Zealous', 'Passive');

-- Inserting all Traits into trait_versions table
INSERT INTO trait_versions (trait_id, plus, description)
VALUES
  -- Insertions for Traits that start with A
  ((SELECT trait_id FROM traits WHERE name = 'Accurate'), 0, 'The Coromon has such good aim that its Accuracy is always increase by 1 stage'),
  ((SELECT trait_id FROM traits WHERE name = 'Accurate'), 1, 'The Coromon has such good aim that its Accuracy and Critical hit chance is always increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Accurate'), 2, 'The Coromon has such good aim that its Accuracy is always increased by 1 stage and Critical hit change by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Acupuncture'), 0, 'The Coromon treats a member of the Squad to cure them of all status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Acupuncture'), 1, 'The Coromon treats a member of the Squad to cure them of all status problems. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Acupuncture'), 2, 'The Coromon treats all members of the Squad to cure them of all status problems after every battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Afterburner'), 0, 'When the Coromon is defeated in battle, inflict burn on the opposing team.'),
  ((SELECT trait_id FROM traits WHERE name = 'Afterburner'), 1, 'When the Coromon''s HP drops below 50%, inflict burn on the opposing team.'),
  ((SELECT trait_id FROM traits WHERE name = 'Afterburner'), 2, 'When the Coromon''s HP drops below 50%, increase its own Sp. Attack by 2 stages and inflict burn on the opposing team.'),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), 0, 'Very effective attacks against opponent deal 25% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), 1, 'Very effective attacks against the opponent deal 50% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), 2, 'Very effective attacks against the opponent deal 75% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antarctic'), 0, 'The Coromon makes it Snow for 5 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antarctic'), 1, 'The Coromon makes it Snow for 8 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antarctic'), 2, 'The Coromon makes it Snow for 8 rounds upon entering a battle and prevents it from changing.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antidote'), 0, 'The Coromon builds up an antidote over time which can cure a Squad member from poison.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antidote'), 1, 'The Coromon builds up an antidote over time which can cure a Squad member from poison. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Antidote'), 2, 'The Coromon builds up an antidote over time which can cure all Squad members from poison. Triggers after every battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Anti-fungal'), 0, 'By using Fungus, the Coromon can fully restore its HP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Anti-fungal'), 1, 'By using Fungus, the Coromon can fully restore its HP and SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Anti-fungal'), 2, 'By using Fungus, the Coromon can cure its status problems and fully restore its HP and SP.'),
  -- Insertions for Traits that start with B
  ((SELECT trait_id FROM traits WHERE name = 'Backup Plan'), 0, 'Once per battle, the Coromon will cling to life instead of fainting when hit by a very effective attack.'),
  ((SELECT trait_id FROM traits WHERE name = 'Backup Plan'), 1, 'Once per battle, the Coromon will cling to life and restore to 20% HP instead of fainting when hit by a very effective attack.'),
  ((SELECT trait_id FROM traits WHERE name = 'Backup Plan'), 2, 'Once per battle, the Coromon will cling to life and restore to 40% HP instead of fainting when hit by a very effective attack.'),
  ((SELECT trait_id FROM traits WHERE name = 'Brave'), 0, 'This Coromon is so brave that it can not be affected by curse.'),
  ((SELECT trait_id FROM traits WHERE name = 'Brave'), 1, 'This Coromon is so brave that it can not be affected by curse or poison.'),
  ((SELECT trait_id FROM traits WHERE name = 'Brave'), 2, 'This Coromon is so brave that it can not be affected by curse or poison, and upon entering a battle reduces the opponent''s Attack by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Bright Light'), 0, 'The Coromon emanates a bright light, blocking Twilight and lighting up caves.'),
  ((SELECT trait_id FROM traits WHERE name = 'Bright Light'), 1, 'The Coromon emanates a bright light, blocking Twilight and lighting up caves, and upon entering a battle reduces the opponent''s Sp. Defense by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Bright Light'), 2, 'The Coromon emanates a bright light, blocking Twilight and lighting up caves, and upon entering a battle reduces the opponent''s Sp. Defense by 2 stages.'),
  -- Insertions for Traits that start with C
  ((SELECT trait_id FROM traits WHERE name = 'Caffeinated'), 0, 'The Coromon is hyper and its max SP is increased by up to 18 points based on its level'),
  ((SELECT trait_id FROM traits WHERE name = 'Caffeinated'), 1, 'The Coromon is hyper and its max SP is increased by up to 18 points based on its level. Resting restores 100% SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Caffeinated'), 2, 'The Coromon is hyper its max SP is increased by up to 18 points based on its level. Resting restores 100% SP and the Coromon can''t become drowsy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cleanse'), 0, 'Rain has a soothing effect on this Coromon, curing all status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cleanse'), 1, 'Rain has a soothing effect on this Coromon, restoring 5% HP each round and curing all status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cleanse'), 2, 'Rain has a soothing effect on this Coromon, restoring 10% HP each round, and also curing all status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), 0, 'The Coromon is cured of all status problems when returned to its Spinner.'),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), 1, 'The Coromon is cured of all status problems and recovers 15% of its max HP when returned to its Spinner.'),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), 2, 'The Coromon is cured of all status problems and recovers 15% of its max HP and SP when returned to its Spinner.'),
  ((SELECT trait_id FROM traits WHERE name = 'Clear Skies'), 0, 'Clear the skies and removes all entry hazards upon entering a battle. The Coromon prevents weather from changing.'),
  ((SELECT trait_id FROM traits WHERE name = 'Clear Skies'), 1, 'Clear the skies and removes all entry hazards upon entering a battle. The Coromon prevents weather from changing and ignores the effects from entry hazards'),
  ((SELECT trait_id FROM traits WHERE name = 'Clear Skies'), 2, 'Clear the skies and removes nearby entry hazards upon entering a battle. The Coromon prevents weather from changing and ignores the effects from entry hazards.'),
  ((SELECT trait_id FROM traits WHERE name = 'Comeback'), 0, 'When its HP drops below 25%, the Coromon makes a comeback, increasing its Attack and Sp. Attack by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Comeback'), 1, 'When its HP drops below 35%, the Coromon makes a comeback, increasing its Attack and Sp. Attack by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Comeback'), 2, 'When its HP drops below 35%, the Coromon makes a comeback, increasing its Attack and Sp. Attack by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), 0, 'The Coromon charges when hit by an Electric attack, increasing its Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), 1, 'The Coromon charges when hit by an Electric attack, taking 50% less damage and increasing its Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), 2, 'The Coromon charges when hit by an Electric attack, taking no damage and increasing its Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), 0, 'The Coromon requires 1 less SP to use Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), 1, 'The Coromon has up to 15 more max SP based on its level and requires 1 less SP to use Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), 2, 'The Coromon has up to 15 more max SP based on its level and requires 2 less SP to use Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Contained Power'), 0, 'The Coromon contains its power. Once every three damaging Skills its power unleashes, dealing 20% more damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Contained Power'), 1, '???'),
  ((SELECT trait_id FROM traits WHERE name = 'Contained Power'), 2, '???'),
  ((SELECT trait_id FROM traits WHERE name = 'Cool Body'), 0, 'The Coromon embraces the cold, increasing its Defense by 20%. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cool Body'), 1, 'The Coromon embraces the cold, increasing its Defense by 20%, and an additional 40% in Snow. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cool Body'), 2, 'The Coromon embraces the cold, increasing its Defense by 20%, and an additional 60% in Snow. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cosmic'), 0, 'The Coromon draws power from the Twilight, causing all negative stat changes applied to it to become positive.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cosmic'), 1, 'The Coromon draws power from any active weather, causing all negative stat changes applied to it to become positive.'),
  ((SELECT trait_id FROM traits WHERE name = 'Cosmic'), 2, 'The Coromon draws power from any active weather, causing all negative stat changes applied to it to become positive and increased by 1 extra stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Coward'), 0, 'When the Coromon receives a critical hit, it cowers and increases its Defense 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Coward'), 1, 'When the Coromon receives a critical hit or very effective damage, it cowers and increases its Defense 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Coward'), 2, 'When the Coromon receives a critical hit or very effective damage, it cowers and increases its Defense and Speed 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Creeping Stare'), 0, 'The Coromon creeps out the opponent, lowering its Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Creeping Stare'), 1, 'The Coromon creeps out the opponent, lowering its Speed by 1 stage, the user can no longer have its speed lowered.'),
  ((SELECT trait_id FROM traits WHERE name = 'Creeping Stare'), 2, 'The Coromon creeps out the opponent, lowering its Speed by 2 stages, the user can no longer have its speed lowered.'),
  ((SELECT trait_id FROM traits WHERE name = 'Crippler'), 0, 'When the Coromon inflicts a status problem or stat change on an opponent, damage the target''s SP by 10% of their max SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Crippler'), 1, 'When the Coromon inflicts a status problem or stat change on an opponent, damage the target''s SP by 15% of their max SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Crippler'), 2, 'When the Coromon inflicts a status problem or stat change on an opponent, drain the target''s SP by 15% of their max SP.'),
  -- Insertions for Traits that start with D
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), 0, 'The Coromon calls forth the Twilight for 5 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), 1, 'The Coromon calls forth the Twilight for 8 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), 2, 'The Coromon calls forth the Twilight for 8 rounds upon entering a battle and prevents it from changing.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), 0, 'The Coromon excels at seeing weak points while in the Twilight, Critical hit chance is increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), 1, 'The Coromon excels at seeing weak points while in the Twilight, Critical hit chance is increased by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), 2, 'The Coromon excels while in the Twilight, Critical hit chance is increased by 2 stages while also being immune to critical hits.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dirt Coat'), 0, 'The Coromon covers itself in a sturdy dirt coat during a Sandstorm, increasing its Defense by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dirt Coat'), 1, 'The Coromon covers itself in a sturdy dirt coat during a Sandstorm, increasing its Defense and Sp. Defense by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dirt Coat'), 2, 'The Coromon covers itself in a sturdy dirt coat during a Sandstorm, increasing its Defense and Sp. Defense by 75%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Disrupting Aura'), 0, 'The Coromon''s aura depletes 2 SP of any attacker making contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Disrupting Aura'), 1, 'The Coromon''s aura depletes 5 SP of any attacker making contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Disrupting Aura'), 2, 'The Coromon''s aura depletes 5 SP and inflicts curse on any attacker making contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), 0, 'The Coromon summons a Sandstorm for 5 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), 1, 'The Coromon summons a Sandstorm for 8 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), 2, 'The Coromon summons a Sandstorm for 8 rounds upon entering a battle and prevents it from changing.'),
  -- Insertions for Traits that start with E
  ((SELECT trait_id FROM traits WHERE name = 'Empathetic'), 0, 'The Coromon is also affected by any stat changes the opponent is affected by.'),
  ((SELECT trait_id FROM traits WHERE name = 'Empathetic'), 1, 'The Coromon is also affected by any positive stat changes the opponent is affected by, and is healed 50% of any healing the opponent receives.'),
  ((SELECT trait_id FROM traits WHERE name = 'Empathetic'), 2, 'The Coromon is also affected by any positive stat changes the opponent is affected by, and is healed 100% of any healing the opponent receives.'),
  ((SELECT trait_id FROM traits WHERE name = 'Escapist'), 0, 'This Coromon is immune to being trapped, and in normal circumstances never fails to escape from a wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Escapist'), 1, 'This Coromon''s Speed is always increased by 1 stage and it can''t be trapped. In normal circumstances never fails to escape from a wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Escapist'), 2, 'This Coromon''s Speed is always increased by 2 stages and it can''t be trapped. In normal circumstances never fails to escape from a wild Coromon.'),
  -- Insertions for Traits that start with F
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), 0, 'The Coromon learns quickly, gaining 5% extra XP from battles.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), 1, 'The Coromon learns quickly, gaining 15% extra XP from battles.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), 2, 'The Coromon learns quickly, gaining 30% extra XP from battles.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Metabolism'), 0, 'The Coromon raises its Sp. Attack by 2 stages and restores 25% SP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Metabolism'), 1, 'The Coromon raises its Sp. Attack by 2 stages and restores 50% SP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Metabolism'), 2, 'The Coromon raises its Sp. Attack by 2 stages and restores 100% SP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fearless'), 0, 'The Coromon refuses to run from any fight, and its max HP is increased by up to 40 points based on its level.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fearless'), 1, 'The Coromon refuses to run from any fight, and its max HP is increased by up to 60 points based on its level.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fearless'), 2, 'The Coromon refuses to run from any fight, and its max HP is increased by up to 60 points based on its level. When its HP drops below 30% HP, the Coromon increases its Attack 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), 0, 'By absorbing flames, the Coromon raises its Sp. Attack when hit by a Fire move.'),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), 1, 'By absorbing flames, the Coromon takes 50% reduced damage and raises its Sp. Attack when hit by a Fire move.'),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), 2, 'By absorbing flames, the Coromon takes no damage and raises its Sp. Attack when hit by a Fire move.'),
  ((SELECT trait_id FROM traits WHERE name = 'Frost Layer'), 0, 'A frosty layer reduces the damage of the first incoming Fire attack by 75%. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Frost Layer'), 1, 'A frosty layer completely negates the damage of the first incoming Fire attack. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Frost Layer'), 2, 'A frosty layer completely negates the damage of the first two incoming Fire attack. Does not work in a Heatwave.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), 0, 'When the Coromon has full HP, any damage is reduced by 40%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), 1, 'When the Coromon has full HP, any damage is reduced by 60%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), 2, 'When the Coromon has full HP, any damage is reduced by 75%.'),
  -- Insertions for Traits that start with G
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), 0, 'For every other Ice type Coromon on their team, this Coromon Skills deal 10% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), 1, 'For every other Ice type Coromon on their team, this Coromon Skills deal 20% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), 2, 'For every other Ice type Coromon on their team or the opponent''s team, this Coromon Skills deal 20% extra damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Good Aim'), 0, 'Physical Skills hit the right spot, increasing critical hit damage by 35%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Good Aim'), 1, 'Physical Skills hit the right spot, increasing critical hit damage by 70%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Good Aim'), 2, 'Physical Skills hit the right spot, increasing critical hit damage by 70%. The Coromon''s Critical hit chance is always increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gourmand'), 0, 'The Coromon gains 50% additional HP and SP when consuming cakes.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gourmand'), 1, 'The Coromon gains 100% additional HP and SP when consuming cakes.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gourmand'), 2, 'The Coromon gains 150% additional HP and SP when consuming cakes.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gravity Pull'), 0, 'This Coromon has such a big mass that any attacker making contact will be prevented from switching out or escaping for 5 rounds.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gravity Pull'), 1, 'This Coromon has such a big mass that any attacker making contact will be prevented from switching out or escaping for 5 rounds and will lose 10% SP each round while trapped.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gravity Pull'), 2, 'This Coromon has such a big mass that any attacker making contact will be prevented from switching out or escaping for 5 rounds and will lose 20% SP each round while trapped.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gullible'), 0, 'The Coromon is very gullible, and every stat change is doubled.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gullible'), 1, 'The Coromon is selectively gullible, and every positive stat change is doubled.'),
  ((SELECT trait_id FROM traits WHERE name = 'Gullible'), 2, 'The Coromon is selectively gullible, positive stat changes are doubled, while negative ones are ignored.'),
  -- Insertions for Traits that start with H
  ((SELECT trait_id FROM traits WHERE name = 'Hardheaded'), 0, 'Because of its hard head, the Coromon suffers 50% less recoil damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hardheaded'), 1, 'Because of its hard head, the Coromon suffers 50% less recoil damage and always has its Defense increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hardheaded'), 2, 'Because of its hard head, the Coromon doesn''t suffer recoil damage and always has its Defense increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hoarder'), 0, 'After a battle, the Coromon has a 10% chance to hoard items it finds lying around the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hoarder'), 1, 'After a battle, the Coromon has a 10% chance to hoard valuable looking items it finds lying around the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hoarder'), 2, 'After a battle, the Coromon has a 10% chance to hoard very valuable looking items it finds lying around the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), 0, 'Fire Skills used by the Coromon deal 20% more damage. Does not work in Snow.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), 1, 'Fire Skills used by the Coromon deal 20% more damage, and an additional 40% in a Heatwave. Does not work in a Snow.'),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), 2, 'Fire Skills used by the Coromon deal 20% more damage, and an additional 60% in a Heatwave. Does not work in a Snow.'),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), 0, 'The Coromon makes it Rain for 5 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), 1, 'The Coromon makes it Rain for 8 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), 2, 'The Coromon makes it Rain for 8 rounds upon entering a battle and prevents it from changing.'),
  -- Insertions for Traits that start with I
  ((SELECT trait_id FROM traits WHERE name = 'Impatient'), 0, 'Upon defeating an opponent, the Coromon gets impatient and raises its Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Impatient'), 1, 'Upon defeating an opponent, the Coromon gets impatient and raises its Speed by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Impatient'), 2, 'Upon defeating an opponent, the Coromon gets impatient and raises its Speed by 3 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inner Fire'), 0, 'The Coromon has an inner fire burning so hot, that it cannot be frozen.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inner Fire'), 1, 'The Coromon has an inner fire burning so hot, that it cannot be frozen and takes 50% reduced damage from Ice Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inner Fire'), 2, 'The Coromon has an inner fire burning so hot, that it cannot be frozen, takes 50% reduced damage from Ice Skills, and burns opponents on contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Intelligent'), 0, 'The Coromon uses its knowledge to increase its Evasion by 25% when battling wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Intelligent'), 1, 'The Coromon uses its knowledge to increase its Evasion by 35% when battling wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Intelligent'), 2, 'The Coromon uses its knowledge to increase its Evasion by 45% when battling wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inverse'), 0, 'The Coromon doesn''t know left from right, so all stat changes are reversed.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inverse'), 1, 'The Coromon doesn''t know left from right, so all stat changes are reversed. When one of its stat decreases, it will decrease by 1 less stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Inverse'), 2, 'The Coromon doesn''t know left from right, so all stat changes are reversed. When one of its stat decreases, it will decrease by 2 less stages.'),
  -- Insertions for Traits that start with K
  ((SELECT trait_id FROM traits WHERE name = 'Kindred Soul'), 0, 'Upon entering a battle, if the opponent has higher max HP, the Coromon links their souls to match its HP until the battle ends.'),
  ((SELECT trait_id FROM traits WHERE name = 'Kindred Soul'), 1, 'Upon entering a battle, if the opponent has higher max HP, the Coromon links their souls to match its HP +10% until the battle ends.'),
  ((SELECT trait_id FROM traits WHERE name = 'Kindred Soul'), 2, 'Upon entering a battle, if the opponent has higher max HP, the Coromon links their souls to match its HP +20% until the battle ends.'),
  -- Insertions for Traits that start with L
  ((SELECT trait_id FROM traits WHERE name = 'Low Density'), 0, 'During a Sandstorm, the Coromon is immune to the contact effects of any opponent it attacks.'),
  ((SELECT trait_id FROM traits WHERE name = 'Low Density'), 1, 'During a Sandstorm, the Coromon is immune to the contact effects of any opponent it attacks, and takes 25% less damage from Skills that make contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Low Density'), 2, 'The Coromon is immune to the contact effects of any opponent it attacks, and takes 25% less damage from Skills that make contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), 0, 'The Coromon is so lucky that its Critical hit chance is always increased by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), 1, 'The Coromon is so lucky that its Critical hit chance is always increased by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), 2, 'The Coromon is so lucky that its Critical hit chance is always increased by 3 stages.'),
  -- Insertions for Traits that start with M
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), 0, 'Because of it''s aura of magic, the Coromon reduces special damage taken by 15%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), 1, 'Because of it''s aura of magic, the Coromon reduces special damage taken by 15% and increases special damage dealt by 5%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), 2, 'Because of it''s aura of magic, the Coromon reduces special damage taken by 15% and increases special damage dealt by 10%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Magnetic'), 0, 'When a Spinner fails to catch a wild Coromon, this Coromon tries to pull back the Spinner to the trainer with a 50% chance of success.'),
  ((SELECT trait_id FROM traits WHERE name = 'Magnetic'), 1, 'When a Spinner fails to catch a wild Coromon, this Coromon tries to pull back the Spinner to the trainer with a 65% chance of success.'),
  ((SELECT trait_id FROM traits WHERE name = 'Magnetic'), 2, 'When a Spinner fails to catch a wild Coromon, this Coromon tries to pull back the Spinner to the trainer with a 80% chance of success.'),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), 0, 'The Coromon intimidates its opponent, lowering its Attack by 1 stage. As the Squad leader outside of battle it has a chance to repel much weaker wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), 1, 'The Coromon intimidates its opponent and weaker wild Coromon. The opponent has its Attack reduced by 1 stage and requires 1 more SP to use skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), 2, 'The Coromon intimidates its opponent and weaker wild Coromon. The opponent has its Attack reduced by 1 stage and requires 1 more SP to use skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Molter'), 0, 'The Coromon sheds its skin after each round, giving it 30% chance to cure status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Molter'), 1, 'The Coromon sheds its skin after each round, giving it 55% chance to cure status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Molter'), 2, 'The Coromon sheds its skin after each round, giving it 80% chance to cure status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Motivated'), 0, 'Upon defeating an opponent, the Coromon gets motivated and raises its Attack and Sp. Attack by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Motivated'), 1, 'Upon defeating an opponent, the Coromon gets motivated and raises its Attack, Sp. Attack and Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Motivated'), 2, 'Upon defeating an opponent, the Coromon gets motivated and raises its Attack and Sp. Attack by 2 stages, and Speed by 1 stage.'),
  -- Insertions for Traits that start with N
  ((SELECT trait_id FROM traits WHERE name = 'Nano Skin'), 0, 'This Coromon''s regenerative exoskeleton makes it immune to bleeding.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nano Skin'), 1, 'This Coromon''s regenerative exoskeleton makes it immune to bleeding. Recovers from status problems two rounds after they are inflicted.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nano Skin'), 2, 'This Coromon''s regenerative exoskeleton makes it immune to bleeding and all status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Neutralizer'), 0, 'Upon entering a battle the Coromon disables the Trait of all opposing Coromon for 2 rounds while on the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Neutralizer'), 1, 'Upon entering a battle the Coromon disables the Trait of all opposing Coromon for 3 rounds while on the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Neutralizer'), 2, 'Upon entering a battle the Coromon disables the Trait of all opposing Coromon for 4 rounds while on the battlefield, and ignores their stat boosts.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nimble'), 0, 'When attacked, the Coromon steals any Fruit held by an attacker making contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nimble'), 1, 'When attacked, the Coromon steals any item held by an attacker making contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nimble'), 2, 'When attacked, the Coromon steals any item held by an attacker making contact and knocks them down after a successful steal.'),
  ((SELECT trait_id FROM traits WHERE name = 'Ninja Sense'), 0, 'Due to its sharp senses, the Coromon is able to evade any attack which hit in the previous round.'),
  ((SELECT trait_id FROM traits WHERE name = 'Ninja Sense'), 1, 'Due to its sharp senses, the Coromon is able to evade an attack which was used in the previous round.'),
  ((SELECT trait_id FROM traits WHERE name = 'Ninja Sense'), 2, 'Due to its sharp senses, the Coromon is able to evade an attack which was used in the previous round. Missing an attack makes the attacker hazy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nurse'), 0, 'The Coromon takes care of a member of the Squad, restoring them to full HP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nurse'), 1, 'The Coromon takes care of a member of the Squad, restoring them to full HP and overcharging their SP by 15 points.'),
  ((SELECT trait_id FROM traits WHERE name = 'Nurse'), 2, 'The Coromon takes care of a member of the Squad, restoring them to full HP and overcharging their SP by 15 points. Cooldown is reduced.'),
  -- Insertions for Traits that start with O
  ((SELECT trait_id FROM traits WHERE name = 'Overclocker'), 0, 'If the opponent has higher Attack, the Coromon overclocks its own Attack to match it.'),
  ((SELECT trait_id FROM traits WHERE name = 'Overclocker'), 1, 'If the opponent has higher Attack, the Coromon overclocks its own Attack to match it, plus an additional 10%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Overclocker'), 2, 'If the opponent has higher Attack, the Coromon overclocks its own Attack to match it, plus an additional 20%.'),
  -- Insertions for Traits that start with P
  ((SELECT trait_id FROM traits WHERE name = 'Patdown'), 0, 'Upon entering a battle, the Coromon pats the opponent down to detect any held items.'),
  ((SELECT trait_id FROM traits WHERE name = 'Patdown'), 1, 'Upon entering a battle, the Coromon pats the opponent down to detect any held items, and will steal an item once per battle if it''s not holding anything.'),
  ((SELECT trait_id FROM traits WHERE name = 'Patdown'), 2, 'Upon entering a battle, the Coromon pats the opponent down to detect any held items and will steal an item twice per battle if it''s not holding anything.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pep Talk'), 0, 'The Coromon gives a pep talk to a member of the Squad, overcharging their SP by 15 points.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pep Talk'), 1, 'The Coromon gives a pep talk to a member of the Squad, overcharging their SP by 15 points. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pep Talk'), 2, 'The Coromon gives a pep talk to all members of the Squad, overcharging their SP by 15 points. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), 0, 'The Coromon''s smooth body prevents any stat from lowering, unless caused by itself.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), 1, 'The Coromon''s smooth body reflects all negative stat changes used against it back onto the opponent.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), 2, 'The Coromon''s smooth body reflects all negative stat changes used against it back onto the opponent and increases their effect by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), 0, 'While on the battlefield, the Coromon pollutes the air on the opponent''s side, making any opponent unable to eat Fruits.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), 1, 'While on the battlefield, the Coromon pollutes the air on the opponent''s side, making any opponent unable to eat Fruits. The polluted air lingers for 1 round after the Coromon exits the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), 2, 'While on the battlefield, the Coromon pollutes the air on the opponent''s side, making any opponent unable to eat Fruits. The polluted air lingers for 2 rounds after the Coromon exits the battlefield.'),
  ((SELECT trait_id FROM traits WHERE name = 'Prepared'), 0, 'The Coromon is always prepared for a battle. The first turn after being sent out, the Coromon has double its Speed.'),
  ((SELECT trait_id FROM traits WHERE name = 'Prepared'), 1, 'The Coromon is always prepared for a battle. The first turn after being sent out, the Coromon has double its Speed and is immune to stat changes.'),
  ((SELECT trait_id FROM traits WHERE name = 'Prepared'), 2, 'The Coromon is always prepared for a battle. The first turn after being sent out, the Coromon has double its Speed, is immune to stat changes, and takes 50% less damage from attacks.'),
  -- Insertions for Traits that start with R
  ((SELECT trait_id FROM traits WHERE name = 'Radiator'), 0, 'The body of the Coromon is so hot that the first Skill making contact will burn the attacker, after which every fourth contact will.'),
  ((SELECT trait_id FROM traits WHERE name = 'Radiator'), 1, 'The body of the Coromon is so hot that the first Skill making contact will burn the attacker, after which every second contact will.'),
  ((SELECT trait_id FROM traits WHERE name = 'Radiator'), 2, 'The body of the Coromon is so hot that making contact will burn the attacker.'),
  ((SELECT trait_id FROM traits WHERE name = 'Rebirth'), 0, 'Upon fainting, the Coromon will be reborn as Bren. After 3 battles Bren will hatch.'),
  ((SELECT trait_id FROM traits WHERE name = 'Rebirth'), 1, 'Upon fainting, the Coromon will be reborn as Bren. After 3 battles Bren will hatch.'),
  ((SELECT trait_id FROM traits WHERE name = 'Rebirth'), 2, 'Upon fainting, the Coromon will be reborn as Bren. After 3 battles Bren will hatch.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reconstitution'), 0, 'The Coromon reconstitutes itself, restoring 20% of its HP and SP and curing itself of status problems.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reconstitution'), 1, 'The Coromon reconstitutes itself, restoring 50% of its HP and SP and curing itself of status problems. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reconstitution'), 2, 'The Coromon reconstitutes itself, restoring 80% of its HP and SP and curing itself of status problems. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Regurgitator'), 0, 'The Coromon regurgitates its Fruit after 4 rounds, after which the Fruit can be consumed again.'),
  ((SELECT trait_id FROM traits WHERE name = 'Regurgitator'), 1, 'The Coromon regurgitates its Fruit after 3 rounds, after which the Fruit can be consumed again.'),
  ((SELECT trait_id FROM traits WHERE name = 'Regurgitator'), 2, 'The Coromon regurgitates its Fruit after 2 rounds, after which the Fruit can be consumed again.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), 0, 'When falling below 25% HP, the Coromon reignites and raises its Fire Skill damage by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), 1, 'When falling below 35% HP, the Coromon reignites and raises its Fire Skill damage by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), 2, 'When falling below 35% HP, the Coromon reignites and raises its Fire Skill damage by 75%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Resistant'), 0, 'The Coromon doesn''t mind special attacks, and reduces damage from special attacks by 25%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Resistant'), 1, 'The Coromon doesn''t mind special attacks, and reduces damage from special attacks by 33%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Resistant'), 2, 'The Coromon doesn''t mind special attacks, and reduces damage from special attacks by 40%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Restless'), 0, 'The Coromon is too restless to feel drowsy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Restless'), 1, 'The Coromon is too restless to feel drowsy or become hazy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Restless'), 2, 'The Coromon is too restless to feel drowsy or become hazy. This restlessness helps regenerate 10% of its max SP per turn.'),
  ((SELECT trait_id FROM traits WHERE name = 'Robber'), 0, 'The spoils go to the victor. Steal 50% extra gold when defeating a trainer.'),
  ((SELECT trait_id FROM traits WHERE name = 'Robber'), 1, 'The spoils go to the victor. Steal 100% extra gold when defeating a trainer.'),
  ((SELECT trait_id FROM traits WHERE name = 'Robber'), 2, 'The spoils go to the victor. Steal 150% extra gold when defeating a trainer.'),
  -- Insertions for Traits that start with S
  ((SELECT trait_id FROM traits WHERE name = 'Scrapper'), 0, 'The Coromon doesn''t mind physical attacks, and reduces damage from physical attacks by 25%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Scrapper'), 1, 'The Coromon doesn''t mind physical attacks, and reduces damage from physical attacks by 33%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Scrapper'), 2, 'The Coromon doesn''t mind physical attacks, and reduces damage from physical attacks by 40%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sharp Claws'), 0, 'Its claws are so sharp that lowering its Attack is impossible, and its contact Skills deal 15% additional damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sharp Claws'), 1, 'Its claws are so sharp that lowering its Attack is impossible, and its contact Skills deal 30% additional damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sharp Claws'), 2, 'Its claws are so sharp that lowering its Attack is impossible, and its contact Skills deal 45% additional damage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shiny'), 0, 'Upon entering a battle the Coromon''s body shines bright and reduces the opponent''s Sp. Attack by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shiny'), 1, 'Upon entering a battle the Coromon''s body shines bright. The opponent has its Sp. Attack reduced by 1 stage and requires 1 more SP to use skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shiny'), 2, 'Upon entering a battle the Coromon''s body shines bright. The opponent has its Sp. Attack reduced by 1 stage and requires 2 more SP to use skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shock Absorber'), 0, 'The Coromon doesn''t mind critical hits, and reduces their damage by 25%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shock Absorber'), 1, 'The Coromon likes critical hits, and reduces their damage by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Shock Absorber'), 2, 'The Coromon likes critical hits, and reduces their damage by 50% while dealing 15% recoil damage to the opponent.'),
  ((SELECT trait_id FROM traits WHERE name = 'Short Fused'), 0, 'The Coromon gets angry upon receiving a critical hit, increasing its Attack by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Short Fused'), 1, 'The Coromon gets angry upon receiving a critical hit or very effective damage, increasing its Attack by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Short Fused'), 2, 'The Coromon gets angry upon receiving a critical hit or very effective damage, increasing its Attack by 2 stages and Speed by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), 0, 'This slippery Coromon will dodge the first of every four status changing moves it is hit by.'),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), 1, 'This slippery Coromon will dodge the first of every two status changing moves it is hit by.'),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), 2, 'This slippery Coromon will dodge every status changing move it is hit by and is immune to secondary effects of attacks.'),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), 0, 'The Coromon rebuilds itself using Snow, restoring 5% HP after every round when Snow is falling.'),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), 1, 'The Coromon rebuilds itself using Snow, restoring 8% HP and SP after every round when Snow is falling.'),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), 2, 'The Coromon rebuilds itself using Snow, restoring 12% HP and SP after every round when Snow is falling.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), 0, 'The Coromon can call down a soothing aura, restoring 20% HP to all Squad members.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), 1, 'The Coromon can call down a soothing aura, restoring 30% HP to all Squad members. Cooldown is slightly reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), 2, 'The Coromon can call down a soothing aura, restoring 40% HP to all Squad members. Cooldown is reduced.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soul Eater'), 0, 'When defeating an opponent the Coromon absorbs the soul, raising the stat in which the opponent was most proficient.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soul Eater'), 1, 'When defeating an opponent, the Coromon absorbs the soul to restore 15% of its max HP and raise the stat in which the opponent was most proficient by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Soul Eater'), 2, 'When defeating an opponent, the Coromon absorbs the soul to restore 15% of its max HP and raise the stat in which the opponent was most proficient by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Specialist'), 0, 'The Coromon restores 4% of its SP each turn, and 50% more SP than normal after each battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Specialist'), 1, 'The Coromon restores 6% of its SP each turn, and 100% more SP than normal after each battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Specialist'), 2, 'The Coromon restores 8% of its SP each turn, and fully recovers its SP after each battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Spiked Body'), 0, 'Sharp spikes or needles damage the attacker for 15% of its max HP upon contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Spiked Body'), 1, 'Sharp spikes or needles damage the attacker for 25% of its max HP upon contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Spiked Body'), 2, 'Sharp spikes or needles damage the attacker for 35% of its max HP upon contact.'),
  ((SELECT trait_id FROM traits WHERE name = 'Static Body'), 0, 'Because of its static body, the first Skill making contact will shock the attacker, after which every second contact will.'),
  ((SELECT trait_id FROM traits WHERE name = 'Static Body'), 1, 'Because of its static body, attackers making contact will get shocked.'),
  ((SELECT trait_id FROM traits WHERE name = 'Static Body'), 2, 'Because of its static body, attackers making contact will get shocked and lose 10 SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), 0, 'This Coromon''s strong stature prevents getting knocked down.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), 1, 'This Coromon''s strong stature prevents getting knocked down and makes it take 50% damage from Air Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), 2, 'This Coromon''s strong stature prevents getting knocked down and makes it immune to Air Skills.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steam Layer'), 0, 'The Coromon is protected by a layer of steam during a Heatwave, increasing its Sp. Defense by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steam Layer'), 1, 'The Coromon is protected by a layer of steam during a Heatwave, increasing its Sp. Defense by 100%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Steam Layer'), 2, 'The Coromon is protected by a layer of steam during a Heatwave, increasing its Sp. Defense by 150%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sticky Layer'), 0, 'The sticky layer of the Coromon lowers the Speed of an attacker making contact by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sticky Layer'), 1, 'The sticky layer of the Coromon lowers the Speed of an attacker making contact by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sticky Layer'), 2, 'The sticky layer of the Coromon lowers the Speed of an attacker making contact by 2 stages and traps them for 5 rounds.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stinky'), 0, 'Upon entering a battle, the Coromon''s stinky scent has a 20% chance to make the opponent hazy. As the Squad leader outside of battle it has a chance to repel wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stinky'), 1, 'Upon entering a battle, the Coromon''s stinky scent has a 35% chance to make the opponent hazy. As the Squad leader outside of battle it has a moderate chance to repel wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stinky'), 2, 'Upon entering a battle, the Coromon''s stinky scent has a 50% chance to make the opponent hazy. As the Squad leader outside of battle it has a good chance to repel wild Coromon.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stoic'), 0, 'After taking very effective damage, the Coromon''s Defense or Sp. Defense increases by 2 stages, countering the type of damage taken.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stoic'), 1, 'After taking very effective damage, the Coromon''s Defense and Sp. Defense increases by 2 stages.'),
  ((SELECT trait_id FROM traits WHERE name = 'Stoic'), 2, 'After taking very effective damage, the Coromon''s Defense and Sp. Defense increases by 2 stages. Once per battle, the Coromon can endure a very effective attack with 1 hp.'),
  ((SELECT trait_id FROM traits WHERE name = 'Strategist'), 0, 'When the Coromon moves later than its target, it strategically finds weak spots and attacks with 1 stage increased Critical hit chance.'),
  ((SELECT trait_id FROM traits WHERE name = 'Strategist'), 1, 'When the Coromon moves later than its target, it strategically finds weak spots and attacks with 2 stages Critical hit chance.'),
  ((SELECT trait_id FROM traits WHERE name = 'Strategist'), 2, 'When the Coromon moves later than its target, it strategically finds weak spots, inflicting heavy bleeding and attacking with 3 stages Critical hit chance.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sugar Rush'), 0, 'The Coromon raises its Speed by 1 stage when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sugar Rush'), 1, 'The Coromon raises its Speed by 1 stage and restores 50% SP when consuming fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Sugar Rush'), 2, 'The Coromon raises its Speed by 1 stage and restores all SP when consuming fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Supersensory'), 0, 'The Coromon raises its most proficient stat when one of its stats is lowered.'),
  ((SELECT trait_id FROM traits WHERE name = 'Supersensory'), 1, 'The Coromon raises its two most proficient stats when one of its stats is lowered.'),
  ((SELECT trait_id FROM traits WHERE name = 'Supersensory'), 2, 'The Coromon raises its two most proficient stats by two stages when one of its stats is lowered.'),
  -- Insertions for Traits that start with T
  ((SELECT trait_id FROM traits WHERE name = 'Tactical Retreat'), 0, 'When the Coromon retreats to its Spinner, it restores 25% of its HP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Tactical Retreat'), 1, 'When the Coromon retreats to its Spinner, it restores 25% of its HP and SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Tactical Retreat'), 2, 'When the Coromon retreats to its Spinner, it restores 45% of its HP and SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thermogenesis'), 0, 'The Coromon creates a Heatwave for 5 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thermogenesis'), 1, 'The Coromon creates a Heatwave for 8 rounds upon entering a battle.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thermogenesis'), 2, 'The Coromon creates a Heatwave for 8 rounds upon entering a battle and prevents it from changing.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), 0, 'Its thick skin makes the Coromon immune to critical hits.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), 1, 'Its thick skin makes the Coromon immune to critical hits and bleeding.'),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), 2, 'Its thick skin makes the Coromon immune to critical hits, Cut Skills and bleeding.'),
  ((SELECT trait_id FROM traits WHERE name = 'Tough Feet'), 0, 'Its tough feet ensure that this Coromon is not affected by damaging entry hazards.'),
  ((SELECT trait_id FROM traits WHERE name = 'Tough Feet'), 1, 'Its tough feet ensure that this Coromon is not affected by any entry hazards.'),
  ((SELECT trait_id FROM traits WHERE name = 'Tough Feet'), 2, 'Its tough feet ensure that this Coromon is not affected by any entry hazards.Existing entry hazards around the Coromon are removed.'),
  ((SELECT trait_id FROM traits WHERE name = 'Toxic Skin'), 0, 'The Coromon has a toxic skin. The first Skill making contact will poison the attacker, after which every second contact will.'),
  ((SELECT trait_id FROM traits WHERE name = 'Toxic Skin'), 1, 'The Coromon has a toxic skin. Any contact with it will poison the attacker.'),
  ((SELECT trait_id FROM traits WHERE name = 'Toxic Skin'), 2, 'The Coromon has a toxic skin and is immune to Poison Skills. Any contact with it will poison the attacker.'),
  -- Insertions for Traits that start with V
  ((SELECT trait_id FROM traits WHERE name = 'Vaccinated'), 0, 'The Coromon is vaccinated, which makes it immune to poison.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vaccinated'), 1, 'The Coromon is vaccinated, which makes it immune to poison and hazy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vaccinated'), 2, 'The Coromon is vaccinated, which makes it immune to poison, hazy and drowsy.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vegetarian'), 0, 'Fruit is healthy. The Coromon restores 30% HP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vegetarian'), 1, 'Fruit is healthy. The Coromon restores 30% HP and SP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vegetarian'), 2, 'Fruit is healthy. The Coromon restores 55% HP and SP when consuming Fruit.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vengeful'), 0, 'When an opponent returns to its Spinner or when the user goes last, its skill power will increase by 30%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vengeful'), 1, 'When an opponent returns to its Spinner or when the user goes last, its skill power will increase by 40%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vengeful'), 2, 'When an opponent returns to its Spinner or when the user goes last, its skill power will increase by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vigilant'), 0, 'When its HP drops below 25% the Coromon becomes vigilant, increasing its Speed and Accuracy by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vigilant'), 1, 'When its HP drops below 35% the Coromon becomes vigilant, increasing its Speed and Accuracy by 1 stage.'),
  ((SELECT trait_id FROM traits WHERE name = 'Vigilant'), 2, 'When its HP drops below 35% the Coromon becomes vigilant, increasing its Speed and Accuracy by 2 stages.'),
  -- Insertions for Traits that start with W
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), 0, 'The Coromon is water cooled, making it immune to burn.'),
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), 1, 'The Coromon is water cooled, reducing Fire Skill damage by 50% and making it immune to burn.'),
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), 2, 'The Coromon is water cooled, making it immune to Fire Skills and burn condition.'),
  ((SELECT trait_id FROM traits WHERE name = 'Weatherproof'), 0, 'The Coromon is not affected by any weather effect.'),
  ((SELECT trait_id FROM traits WHERE name = 'Weatherproof'), 1, 'The Coromon is not affected by any weather effect and gains 25% Speed while any weather is active.'),
  ((SELECT trait_id FROM traits WHERE name = 'Weatherproof'), 2, 'The Coromon adapts to the positive effects of any weather that is active.'),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), 0, 'The Coromon feels at home in Rain, increasing its Speed by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), 1, 'The Coromon feels at home in Rain, increasing its Speed and Accuracy by 50%.'),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), 2, 'The Coromon feels at home in Rain, increasing its Speed and Accuracy by 100%.'),
  -- Insertions for Traits that start with Z
  ((SELECT trait_id FROM traits WHERE name = 'Zealous'), 0, 'Skills used by the Coromon deal 20% more damage but cost 2 more SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Zealous'), 1, 'Skills used by the Coromon deal 30% more damage but cost 2 more SP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Zealous'), 2, 'Skills used by the Coromon deal 40% more damage but cost 2 more SP.'),
  -- Insertions related to Pure Essence (Titans abilities)
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Voltgar'), 0, 'Fills the air with static particles curing the Voltgar''s ailments and permanently increases SP cost for the Player''s Squad by 2 when HP falls below 50%'),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Hozai'), 0, 'Removes status changes and increases its Attack and Sp. Attack by one stage and summons a Heatwave when below 50% HP. 
                                                                        On the following turn it will increase its Attack and Sp. Attack again and deplete all SP for the entire squad.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Illuginn'), 0, 'Restores half of its max HP and removes status changes when reaching low HP, preventing itself from fainting once.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Vørst'), 0, 'Prevents it from fainting once. Freezes the entire Squad at low HP.'),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Sart'), 0, '???'),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Chalchiu'), 0, '???');

-- Inserting all Coromon Traits into coromon_traits table
INSERT INTO coromon_traits (trait_id, coro_id,  chance)
VALUES
  -- Insertions from 1-9
  ((SELECT trait_id FROM traits WHERE name = 'Stoic'), (SELECT coro_id FROM coromon WHERE name = 'Bearealis'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Sharp Claws'), (SELECT coro_id FROM coromon WHERE name = 'Bearealis'),  .25),
  ((SELECT trait_id FROM traits WHERE name = 'Contained Power'), (SELECT coro_id FROM coromon WHERE name = 'Bearealis'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Nimble'), (SELECT coro_id FROM coromon WHERE name = 'Bearealis'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Steam Layer'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Gourmand'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Metabolism'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), (SELECT coro_id FROM coromon WHERE name = 'Volcadon'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Vigilant'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Supersensory'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), (SELECT coro_id FROM coromon WHERE name = 'Megalobite'), .20),
  -- Insertions from 10-19
  ((SELECT trait_id FROM traits WHERE name = 'Gullible'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Inner Fire'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Antidote'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Resistant'), (SELECT coro_id FROM coromon WHERE name = 'Humbee'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Pep Talk'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Escapist'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Robber'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Weatherproof'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Tactical Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Golbeak'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Reconstitution'), (SELECT coro_id FROM coromon WHERE name = 'Serpike'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Good Aim'), (SELECT coro_id FROM coromon WHERE name = 'Serpike'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Molter'), (SELECT coro_id FROM coromon WHERE name = 'Serpike'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Spiked Body'), (SELECT coro_id FROM coromon WHERE name = 'Serpike'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Empathetic'), (SELECT coro_id FROM coromon WHERE name = 'Serpike'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), (SELECT coro_id FROM coromon WHERE name = 'Hountrion'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Coward'), (SELECT coro_id FROM coromon WHERE name = 'Hountrion'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Brave'), (SELECT coro_id FROM coromon WHERE name = 'Hountrion'), .45),
  -- Insertions from 20-29
  ((SELECT trait_id FROM traits WHERE name = 'Hoarder'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Vaccinated'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Patdown'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Strategist'), (SELECT coro_id FROM coromon WHERE name = 'Armadon'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Thick Skin'), (SELECT coro_id FROM coromon WHERE name = 'Caradune'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), (SELECT coro_id FROM coromon WHERE name = 'Caradune'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Dirt Coat'), (SELECT coro_id FROM coromon WHERE name = 'Caradune'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Zealous'), (SELECT coro_id FROM coromon WHERE name = 'Toravolt'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Static Body'), (SELECT coro_id FROM coromon WHERE name = 'Toravolt'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), (SELECT coro_id FROM coromon WHERE name = 'Toravolt'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Vengeful'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Gullible'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Radiator'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Thermogenesis'), (SELECT coro_id FROM coromon WHERE name = 'Ashclops'), .20),
  -- Insertions from 30-40
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), (SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), (SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), (SELECT coro_id FROM coromon WHERE name = 'Ucaclaw'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Vigilant'), (SELECT coro_id FROM coromon WHERE name = 'Dugterra'), .2143),
  ((SELECT trait_id FROM traits WHERE name = 'Escapist'), (SELECT coro_id FROM coromon WHERE name = 'Dugterra'), .3571),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), (SELECT coro_id FROM coromon WHERE name = 'Dugterra'), .4286),
  ((SELECT trait_id FROM traits WHERE name = 'Good Aim'), (SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Static Body'), (SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Impatient'), (SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Inner Fire'), (SELECT coro_id FROM coromon WHERE name = 'Rhynobuz'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), (SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), (SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), (SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), .10),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), (SELECT coro_id FROM coromon WHERE name = 'Eclyptor'), .20),
  -- Insertions from 41-50
  ((SELECT trait_id FROM traits WHERE name = 'Shiny'), (SELECT coro_id FROM coromon WHERE name = 'Krybeest'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Krybeest'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Cool Body'), (SELECT coro_id FROM coromon WHERE name = 'Krybeest'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), (SELECT coro_id FROM coromon WHERE name = 'Krybeest'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Afterburner'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Rebirth'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Thermogenesis'), (SELECT coro_id FROM coromon WHERE name = 'Infinix'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Specialist'), (SELECT coro_id FROM coromon WHERE name = 'Deecie'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), (SELECT coro_id FROM coromon WHERE name = 'Deecie'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), (SELECT coro_id FROM coromon WHERE name = 'Deecie'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Clear Skies'), (SELECT coro_id FROM coromon WHERE name = 'Deecie'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), (SELECT coro_id FROM coromon WHERE name = 'Deecie'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Prepared'), (SELECT coro_id FROM coromon WHERE name = 'Kyraptor'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Accurate'), (SELECT coro_id FROM coromon WHERE name = 'Kyraptor'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Sharp Claws'), (SELECT coro_id FROM coromon WHERE name = 'Kyraptor'), .40),
  -- Insertions from 51-60
  ((SELECT trait_id FROM traits WHERE name = 'Inverse'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Cleanse'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Vaccinated'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Kindred Soul'), (SELECT coro_id FROM coromon WHERE name = 'Gelaquad'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Crippler'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Scrapper'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Dirt Coat'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Polluter'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Impatient'), (SELECT coro_id FROM coromon WHERE name = 'Skelatops'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Gourmand'), (SELECT coro_id FROM coromon WHERE name = 'Mudma'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Regurgitator'), (SELECT coro_id FROM coromon WHERE name = 'Mudma'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), (SELECT coro_id FROM coromon WHERE name = 'Mudma'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Sticky Layer'), (SELECT coro_id FROM coromon WHERE name = 'Mudma'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Resistant'), (SELECT coro_id FROM coromon WHERE name = 'Mudma'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), (SELECT coro_id FROM coromon WHERE name = 'Arcturos'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Antarctic'), (SELECT coro_id FROM coromon WHERE name = 'Arcturos'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), (SELECT coro_id FROM coromon WHERE name = 'Arcturos'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), (SELECT coro_id FROM coromon WHERE name = 'Arcturos'), .25),
  -- Insertions from 61-70
  ((SELECT trait_id FROM traits WHERE name = 'Fearless'), (SELECT coro_id FROM coromon WHERE name = 'Grimmask'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Restless'), (SELECT coro_id FROM coromon WHERE name = 'Grimmask'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Soul Eater'), (SELECT coro_id FROM coromon WHERE name = 'Grimmask'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Pep Talk'), (SELECT coro_id FROM coromon WHERE name = 'Grimmask'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), (SELECT coro_id FROM coromon WHERE name = 'Magmilus'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), (SELECT coro_id FROM coromon WHERE name = 'Magmilus'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), (SELECT coro_id FROM coromon WHERE name = 'Magmilus'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), (SELECT coro_id FROM coromon WHERE name = 'Magmilus'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), (SELECT coro_id FROM coromon WHERE name = 'Lumasect'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), (SELECT coro_id FROM coromon WHERE name = 'Lumasect'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Bright Light'), (SELECT coro_id FROM coromon WHERE name = 'Lumasect'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Robber'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Overclocker'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Patdown'), (SELECT coro_id FROM coromon WHERE name = 'Cyberite'), .15),
  -- Insertions from 71-79
  ((SELECT trait_id FROM traits WHERE name = 'Neutralizer'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Vegetarian'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Nano Skin'), (SELECT coro_id FROM coromon WHERE name = 'Millidont'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), (SELECT coro_id FROM coromon WHERE name = 'Chonktoad'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Toxic Skin'), (SELECT coro_id FROM coromon WHERE name = 'Chonktoad'), .45),
  ((SELECT trait_id FROM traits WHERE name = 'Anti-fungal'), (SELECT coro_id FROM coromon WHERE name = 'Chonktoad'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), (SELECT coro_id FROM coromon WHERE name = 'Sandril'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), (SELECT coro_id FROM coromon WHERE name = 'Sandril'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Coward'), (SELECT coro_id FROM coromon WHERE name = 'Sandril'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), (SELECT coro_id FROM coromon WHERE name = 'Sandril'), .20),
  -- Insertions from 80-90
  ((SELECT trait_id FROM traits WHERE name = 'Intelligent'), (SELECT coro_id FROM coromon WHERE name = 'Blizzian'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), (SELECT coro_id FROM coromon WHERE name = 'Blizzian'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Cool Body'), (SELECT coro_id FROM coromon WHERE name = 'Blizzian'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), (SELECT coro_id FROM coromon WHERE name = 'Blizzian'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Kindred Soul'), (SELECT coro_id FROM coromon WHERE name = 'Purrghast'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Tactical Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Purrghast'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Backup Plan'), (SELECT coro_id FROM coromon WHERE name = 'Purrghast'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Sticky Layer'), (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Stinky'), (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Gravity Pull'), (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Magnetic'), (SELECT coro_id FROM coromon WHERE name = 'Magnamire'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), (SELECT coro_id FROM coromon WHERE name = 'Swampa'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Caffeinated'), (SELECT coro_id FROM coromon WHERE name = 'Swampa'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Water Cooled'), (SELECT coro_id FROM coromon WHERE name = 'Swampa'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Reconstitution'), (SELECT coro_id FROM coromon WHERE name = 'Swampa'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Cosmic'), (SELECT coro_id FROM coromon WHERE name = 'Octotle'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Motivated'), (SELECT coro_id FROM coromon WHERE name = 'Octotle'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Dark Atmosphere'), (SELECT coro_id FROM coromon WHERE name = 'Octotle'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Menacing'), (SELECT coro_id FROM coromon WHERE name = 'Octotle'), .20),
  -- Insertions from 91-99
  ((SELECT trait_id FROM traits WHERE name = 'Short Fused'), (SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), .45),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), (SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), (SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Steady'), (SELECT coro_id FROM coromon WHERE name = 'Vulbrute'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Low Density'), (SELECT coro_id FROM coromon WHERE name = 'Malavite'), .3333),
  ((SELECT trait_id FROM traits WHERE name = 'Shock Absorber'), (SELECT coro_id FROM coromon WHERE name = 'Malavite'), .3333),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), (SELECT coro_id FROM coromon WHERE name = 'Malavite'), .3333),
  ((SELECT trait_id FROM traits WHERE name = 'Creeping Stare'), (SELECT coro_id FROM coromon WHERE name = 'Daricara'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Acupuncture'), (SELECT coro_id FROM coromon WHERE name = 'Daricara'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), (SELECT coro_id FROM coromon WHERE name = 'Daricara'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Wet Coat'), (SELECT coro_id FROM coromon WHERE name = 'Daricara'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), (SELECT coro_id FROM coromon WHERE name = 'Daricara'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Comeback'), (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Hardheaded'), (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Motivated'), (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Tough Feet'), (SELECT coro_id FROM coromon WHERE name = 'Blazitaur'), .20),
  -- Insertions from 100-110
  ((SELECT trait_id FROM traits WHERE name = 'Crippler'), (SELECT coro_id FROM coromon WHERE name = 'Glamoth'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Caffeinated'), (SELECT coro_id FROM coromon WHERE name = 'Glamoth'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Glamoth'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), (SELECT coro_id FROM coromon WHERE name = 'Glamoth'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), (SELECT coro_id FROM coromon WHERE name = 'Orotchy'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Disrupting Aura'), (SELECT coro_id FROM coromon WHERE name = 'Orotchy'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Orotchy'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Orotchy'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Empathetic'), (SELECT coro_id FROM coromon WHERE name = 'Atlantern'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Nurse'), (SELECT coro_id FROM coromon WHERE name = 'Atlantern'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Hardheaded'), (SELECT coro_id FROM coromon WHERE name = 'Atlantern'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Shiny'), (SELECT coro_id FROM coromon WHERE name = 'Atlantern'), .10),
  ((SELECT trait_id FROM traits WHERE name = 'Ninja Sense'), (SELECT coro_id FROM coromon WHERE name = 'Makinja'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Sugar Rush'), (SELECT coro_id FROM coromon WHERE name = 'Makinja'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), (SELECT coro_id FROM coromon WHERE name = 'Makinja'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Soothing Aura'), (SELECT coro_id FROM coromon WHERE name = 'Makinja'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Fast Learner'), (SELECT coro_id FROM coromon WHERE name = 'Makinja'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Frost Layer'), (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Tough Feet'), (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Spiked Body'), (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Fearless'), (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Glacial Affinity'), (SELECT coro_id FROM coromon WHERE name = 'Arctiram'), .20),
  -- Insertions from 111-120
  ((SELECT trait_id FROM traits WHERE name = 'Conserver'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Polished Body'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Humidifier'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Ucaclaw'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Amplified'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumasect'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Conductor'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumasect'), .40),
  ((SELECT trait_id FROM traits WHERE name = 'Bright Light'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Lumasect'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Slippery'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Vegetarian'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Dry Wind'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Nano Skin'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Millidont'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Lucky'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Antarctic'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Snowman'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Arcturos'), .25),
  -- Insertions from 121-124
  ((SELECT trait_id FROM traits WHERE name = 'Dimensional Eye'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Disrupting Aura'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), .15),
  ((SELECT trait_id FROM traits WHERE name = 'Fully Rested'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), .35),
  ((SELECT trait_id FROM traits WHERE name = 'Clean Retreat'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Orotchy'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Flare Intake'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), .20),
  ((SELECT trait_id FROM traits WHERE name = 'Reignite'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), .30),
  ((SELECT trait_id FROM traits WHERE name = 'Hot Headed'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), .25),
  ((SELECT trait_id FROM traits WHERE name = 'Magic Layer'), (SELECT coro_id FROM coromon WHERE name = 'Crimsonite Magmilus'), .25),
  -- Insertions for Titans
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Voltgar'), (SELECT coro_id FROM coromon WHERE name = 'Voltgar'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Illuginn'), (SELECT coro_id FROM coromon WHERE name = 'Illuginn'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Sart'), (SELECT coro_id FROM coromon WHERE name = 'Sart'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Hozai'), (SELECT coro_id FROM coromon WHERE name = 'Hozai'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Vørst'), (SELECT coro_id FROM coromon WHERE name = 'Vørst'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Chalchiu'), (SELECT coro_id FROM coromon WHERE name = 'Chalchiu'), 1.00),
  ((SELECT trait_id FROM traits WHERE name = 'Pure Essence Chalchiu'), (SELECT coro_id FROM coromon WHERE name = 'Dark Form Chalchiu'), 1.00);