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
  trait_version_id INTEGER NOT NULL,
  chance DECIMAL NOT NULL,

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
  ('Gullibile', 'Passive'),
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
  ('Pure Essense Sart', 'Passive'),
  ('Pure Essense Chalchiu', 'Passive'),
  ('Pure Essense Dark Form Chalchiu', 'Passive'),
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







































