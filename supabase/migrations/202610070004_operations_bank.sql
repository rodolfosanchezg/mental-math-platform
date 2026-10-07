-- T05: complete ordered pairs. Commuted operands are distinct exercises.
BEGIN;

INSERT INTO public.operations (type, operand_a, operand_b, result, level)
SELECT 'addition', a, b, a + b,
    CASE
        WHEN a < 10 AND b < 10 THEN 'S1'
        WHEN a < 10 OR b < 10 THEN CASE WHEN a % 10 + b % 10 <= 9 THEN 'S2' ELSE 'S3' END
        WHEN a % 10 + b % 10 <= 9 AND a / 10 + b / 10 <= 9 THEN 'S4'
        ELSE 'S5'
    END
FROM generate_series(1, 99) a CROSS JOIN generate_series(1, 99) b
WHERE a + b >= 4
ON CONFLICT (type, operand_a, operand_b, level) DO NOTHING;

INSERT INTO public.operations (type, operand_a, operand_b, result, level)
SELECT 'multiplication', a, b, a * b, 'M' || difficulty
FROM generate_series(1, 6) difficulty
CROSS JOIN generate_series(2, 16) a CROSS JOIN generate_series(2, 16) b
WHERE (difficulty = 1 AND a <= 10 AND b <= 10 AND (a IN (2, 5, 10) OR b IN (2, 5, 10)))
   OR (difficulty = 2 AND a <= 10 AND b <= 10 AND (a IN (2, 3, 4, 5, 10) OR b IN (2, 3, 4, 5, 10)))
   OR (difficulty = 3 AND a <= 10 AND b <= 10 AND (a IN (2, 3, 4, 5, 6, 7, 10) OR b IN (2, 3, 4, 5, 6, 7, 10)))
   OR (difficulty = 4 AND a <= 10 AND b <= 10)
   OR (difficulty = 5 AND a <= 12 AND b <= 12)
   OR difficulty = 6
ON CONFLICT (type, operand_a, operand_b, level) DO NOTHING;

COMMIT;
