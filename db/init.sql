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

INSERT INTO coromon_evolutions (coro_id, pre_evo_coro_id, next_evo_coro_id, condition_to_evolve)
VALUES
  (1, NULL, 2, 'Level 16'),
  (2, 1, 3, 'Level 34'),
  (3, 2, NULL, NULL),
  (4, NULL, 5, 'Level 16'),
  (5, 4, 6, 'Level 36'),
  (6, 5, NULL, NULL),
  (7, NULL, 8, 'Level 17'),
  (8, 7, 9, 'Level 35'),
  (9, 8, NULL, NULL),
  (10, NULL, 11, 'Level 14, Attack is raised 6 stages in a single battle'),
  (11, 10, 12, 'Level 28'),
  (12, 11, NULL, NULL),
  (13, NULL, 14, 'Level 15'),
  (14, 13, 15, 'Level 41'),
  (15, 14, NULL, NULL),
  (16, NULL, 17, 'Level 25'),
  (17, 16, NULL, NULL),
  (18, NULL, 19, 'Level 34'),
  (19, 18, NULL, NULL),
  (20, NULL, 21, 'Level 18'),
  (21, 20, 22, 'Level 33'),
  (22, 21, NULL, NULL),
  (23, NULL, 24, 'Level 30'),
  (24, 23, NULL, NULL),
  (25, NULL, 26, 'Level 30'),
  (26, 25, NULL, NULL),
  (27, NULL, 28, 'Level 23'),
  (28, 27, 29, 'Level 44'),
  (29, 28, NULL, NULL),
  (30, NULL, 31, 'Level 34'),
  (31, 30, NULL, NULL),
  (32, NULL, 33, 'Level 17'),
  (33, 32, 34, 'Level 31'),
  (34, 33, NULL, NULL),
  (35, NULL, 36, 'Level 17'),
  (36, 35, 37, 'Level 36'),
  (37, 36, NULL, NULL),
  (38, NULL, 39, 'Level 21'),
  (39, 38, 40, 'Level 39, Two Opponent Lunarwulfs use Howl in the same turn'),
  (40, 39, NULL, NULL),
  (41, NULL, 42, 'Level 18'),
  (42, 41, 43, 'Level 39'),
  (43, 42, NULL, NULL),
  (44, NULL, 45, 'Level 12'),
  (45, 44, 46, 'Level 34'),
  (46, 45, NULL, NULL),
  (47, NULL, 48, 'Level 35'),
  (48, 47, NULL, NULL),
  (49, NULL, 50, 'Level 37'),
  (50, 49, NULL, NULL),
  (51, NULL, 52, 'Level 21'),
  (52, 51, 53, 'Level 34'),
  (53, 52, NULL, NULL),
  (54, NULL, 55, 'Level 18'),
  (55, 54, 56, 'Level 37'),
  (56, 55, NULL, NULL),
  (57, NULL, 58, 'Level 28'),
  (58, 57, NULL, NULL),
  (59, NULL, 60, 'Level 24'),
  (60, 59, NULL, NULL),
  (61, NULL, 62, 'Level 32'),
  (62, 61, NULL, NULL),
  (63, NULL, 64, 'Level 30'),
  (64, 63, NULL, NULL),
  (65, NULL, 66, 'Level 16'),
  (66, 65, 67, 'Level 30'),
  (67, 66, NULL, NULL),
  (68, NULL, 69, 'Level 30, When a Pitterbyte Kernel is installed'),
  (69, 68, 70, 'Level 50'),
  (70, 69, NULL, NULL),
  (71, NULL, 72, 'Level 24'),
  (72, 71, 73, 'Level 39'),
  (73, 72, NULL, NULL),
  (74, NULL, 75, 'Level 18'),
  (75, 74, 76, 'Level 38'),
  (76, 75, NULL, NULL),
  (77, NULL, 78, 'Level 18'),
  (78, 77, 79, 'Level 32'),
  (79, 78, NULL, NULL),
  (80, NULL, 81, 'Level 40'),
  (81, 80, NULL, NULL),
  (82, NULL, 83, 'Level 38, Every Purrgy Nibbles eaten lowers level by 1'),
  (83, 82, 84, 'Level 50'),
  (84, 83, NULL, NULL),
  (85, NULL, 86, 'Level 38'),
  (86, 85, NULL, NULL),
  (87, NULL, 88, 'Level 32'),
  (88, 87, NULL, NULL),
  (89, NULL, 90, 'Level 37, When its spinner is dipped into the Witchs Kettle'),
  (90, 89, NULL, NULL),
  (91, NULL, 92, 'Level 42'),
  (92, 91, NULL, NULL),
  (93, NULL, 94, 'Level 23'),
  (94, 93, 95, 'Level 45'),
  (95, 94, NULL, NULL),
  (96, NULL, 97, 'Level 39'),
  (97, 96, NULL, NULL),
  (98, NULL, 99, 'Level 32'),
  (99, 98, NULL, NULL),
  (100, NULL, 101, 'Level 20'),
  (101, 100, 102, 'Level 38'),
  (102, 101, NULL, NULL),
  (103, NULL, 104, 'Level 40'),
  (104, 103, NULL, NULL),
  (105, NULL, 106, 'Level 38'),
  (106, 105, NULL, NULL),
  (107, NULL, 108, 'Level 33'),
  (108, 107, NULL, NULL),
  (109, NULL, 110, '38'),
  (110, 109, NULL, NULL),
  (111, NULL, 112, 'Level 34'),
  (112, 111, NULL, NULL),
  (113, NULL, 114, 'Level 16'),
  (114, 113, 115, 'Level 30'),
  (115, 114, NULL, NULL),
  (116, NULL, 117, 'Level 24'),
  (117, 116, 118, 'Level 39'),
  (118, 117, NULL, NULL),
  (119, NULL, 120, 'Level 24'),
  (120, 119, NULL, NULL),
  (121, NULL, 122, 'Level 40'),
  (122, 121, NULL, NULL),
  (123, NULL, 124, 'Level 30'),
  (124, 123, NULL, NULL),
  (1000, NULL, NULL, NULL),
  (1001, NULL, NULL, NULL),
  (1002, NULL, NULL, NULL),
  (1003, NULL, NULL, NULL),
  (1004, NULL, NULL, NULL),
  (1005, NULL, NULL, NULL),
  (1006, NULL, NULL, NULL);










































