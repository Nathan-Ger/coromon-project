DROP TABLE IF EXISTS coromon_skills;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS coromon_stats;
DROP TYPE IF EXISTS coromon_stats_stat_type;
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






-- Display all Coromon with their traits
WITH RECURSIVE EvolutionChain AS (
    -- Start from Coromon with no pre-evolution
    SELECT 
        c.coro_id AS original_coro_id,
        c.coro_id AS current_coro_id,
        1 AS chain_position
    FROM 
        coromon c
    LEFT JOIN 
        coromon_evolutions ce ON c.coro_id = ce.coro_id
    WHERE 
        ce.pre_evo_coro_id IS NULL -- Base case: No pre-evolution

    UNION ALL

    -- Traverse the evolution chain
    SELECT DISTINCT
        ec.original_coro_id,
        ce.next_evo_coro_id AS current_coro_id,
        ec.chain_position + 1 AS chain_position
    FROM 
        EvolutionChain ec
    JOIN 
        coromon_evolutions ce ON ec.current_coro_id = ce.coro_id
    WHERE 
        ce.next_evo_coro_id IS NOT NULL -- Continue while there is a next evolution
),
ChainLength AS (
    -- Calculate the total length of each chain
    SELECT 
        original_coro_id,
        MAX(chain_position) AS total_length
    FROM 
        EvolutionChain
    GROUP BY 
        original_coro_id
),
CoromonPlus AS (
    -- Assign `plus` values based on position and total length
    SELECT 
        ec.original_coro_id AS coromon_id,
        ec.current_coro_id,
        ec.chain_position,
        cl.total_length,
        CASE
            WHEN cl.total_length = 3 AND ec.chain_position = 1 THEN 2 -- First in 3-stage
            WHEN cl.total_length = 3 AND ec.chain_position = 2 THEN 1 -- Middle in 3-stage
            WHEN cl.total_length = 3 AND ec.chain_position = 3 THEN 0 -- Final in 3-stage
            WHEN cl.total_length = 2 AND ec.chain_position = 1 THEN 2 -- First in 2-stage
            WHEN cl.total_length = 2 AND ec.chain_position = 2 THEN 0 -- Final in 2-stage
            WHEN cl.total_length = 1 THEN 0 -- Single-stage Coromon
            ELSE NULL -- Catch unexpected cases
        END AS plus
    FROM 
        EvolutionChain ec
    JOIN 
        ChainLength cl ON ec.original_coro_id = cl.original_coro_id
),
FinalEvolution AS (
    -- Identify the final evolution in each chain
    SELECT 
        ec.original_coro_id,
        MAX(ec.current_coro_id) AS final_coro_id
    FROM 
        EvolutionChain ec
    LEFT JOIN 
        coromon_evolutions ce ON ec.current_coro_id = ce.coro_id
    WHERE 
        ce.next_evo_coro_id IS NULL
    GROUP BY 
        ec.original_coro_id
),
FinalEvolutionTraits AS (
    -- Traits for the final evolution Coromon
    SELECT 
        fe.original_coro_id AS coromon_id,
        t.name AS trait_name,
        ct.chance
    FROM 
        FinalEvolution fe
    JOIN 
        coromon_traits ct ON fe.final_coro_id = ct.coro_id
    JOIN 
        traits t ON ct.trait_id = t.trait_id
),
CoromonTraits AS (
    -- Traits for the original Coromon
    SELECT 
        ct.coro_id AS coromon_id,
        t.name AS trait_name,
        ct.chance
    FROM 
        coromon_traits ct
    JOIN 
        traits t ON ct.trait_id = t.trait_id
),
CombinedTraits AS (
    -- Combine traits for Coromon and their final evolutions
    SELECT 
        c.coro_id AS coromon_id,
        c.name AS coromon_name,
        cp.plus,
        -- Ensure fallback to final evolution traits
        COALESCE(ct.trait_name, fet.trait_name) AS trait_name,
        COALESCE(ct.chance, fet.chance) AS chance
    FROM 
        coromon c
    LEFT JOIN 
        CoromonPlus cp ON c.coro_id = cp.current_coro_id
    LEFT JOIN 
        CoromonTraits ct ON c.coro_id = ct.coromon_id
    LEFT JOIN 
        FinalEvolutionTraits fet ON cp.coromon_id = fet.coromon_id -- Ensure fallback to original Coromon's final evolution traits
)
-- Aggregate traits and ensure no duplicates
SELECT 
    ct.coromon_id,
    ct.coromon_name,
    MAX(ct.plus) AS plus,
    COALESCE(
        STRING_AGG(DISTINCT ct.trait_name || ' (' || ROUND(ct.chance * 100, 0) || '%)', ', '),
        'No Traits Available'
    ) AS traits
FROM 
    CombinedTraits ct
GROUP BY 
    ct.coromon_id, ct.coromon_name
ORDER BY 
    ct.coromon_id;