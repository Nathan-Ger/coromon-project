DROP TABLE IF EXISTS skill_effects;
DROP TABLE IF EXISTS skill_effect_types;
DROP TYPE IF EXISTS skill_effect_types_type;
DROP TABLE IF EXISTS coromon_skills;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS coromon_stats;
DROP TYPE IF EXISTS coromon_stats_stat_type;
DROP TABLE IF EXISTS trait_version_effects;
DROP TABLE IF EXISTS effect_types;
DROP TYPE IF EXISTS effect_types_type;
DROP TABLE IF EXISTS coromon_traits;
DROP TABLE IF EXISTS trait_versions;
DROP TABLE IF EXISTS traits;
DROP TYPE IF EXISTS traits_type;
DROP TABLE IF EXISTS type_effectiveness;
DROP TABLE IF EXISTS coromon_evolutions;
DROP TABLE IF EXISTS coromon;
DROP TABLE IF EXISTS types;

-- Display all evolution lines
WITH RECURSIVE EvolutionLine AS (
    -- Anchor: Start with Coromon that have no pre-evolution and coro_id <= 999
    SELECT 
        ce.coro_id AS base_coro_id,
        ce.coro_id,
        ce.pre_evo_coro_id,
        ce.next_evo_coro_id,
        ARRAY[c.name]::VARCHAR[] AS evolution_path -- Start the evolution path
    FROM coromon_evolutions ce
    JOIN coromon c ON ce.coro_id = c.coro_id
    WHERE ce.pre_evo_coro_id IS NULL AND ce.coro_id <= 999

    UNION ALL

    -- Recursive: Append the next stage of evolution while filtering out coro_id > 999
    SELECT 
        el.base_coro_id,
        ce.coro_id,
        ce.pre_evo_coro_id,
        ce.next_evo_coro_id,
        el.evolution_path || c.name::VARCHAR -- Append the current Coromon name to the path
    FROM coromon_evolutions ce
    JOIN EvolutionLine el ON ce.pre_evo_coro_id = el.coro_id
    JOIN coromon c ON ce.coro_id = c.coro_id
    WHERE ce.coro_id <= 999
)
-- Final Query: Aggregate the full evolution path into a single row
SELECT 
    el.base_coro_id,
    ARRAY_TO_STRING(MAX(el.evolution_path), ' -> ') AS evolution_line -- Convert the array to a string
FROM EvolutionLine el
GROUP BY el.base_coro_id
ORDER BY el.base_coro_id;
