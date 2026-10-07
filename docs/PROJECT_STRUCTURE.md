# PROJECT_STRUCTURE.md

## Estructura inicial recomendada

```text
mental-math-platform/
├── README.md
├── .gitignore
├── docs/
│   ├── REQUIREMENTS.md
│   ├── DECISIONS.md
│   ├── ARCHITECTURE.md
│   ├── DATA_MODEL.md
│   ├── GAME_RULES.md
│   ├── UI_FLOW.md
│   ├── ACCEPTANCE_CRITERIA.md
│   ├── TEST_PLAN.md
│   ├── SUPABASE_SETUP.md
│   ├── ROADMAP.md
│   ├── CURRENT_STATE.md
│   └── PROJECT_STRUCTURE.md
├── supabase/
│   ├── migrations/
│   └── tests/
├── src/
│   ├── index.html
│   ├── css/
│   │   └── .gitkeep
│   └── js/
│       └── .gitkeep
├── assets/
│   └── .gitkeep
└── tests/
    └── .gitkeep
```

`src/index.html` puede crearse vacío/placeholder antes de Aurelio, pero no debe contener implementación funcional.

## Evolución probable durante implementación

Aurelio podrá crear, previa coherencia con `ARCHITECTURE.md`, archivos JS como:

```text
src/js/
├── config.js
├── supabase-client.js
├── auth.js
├── ui.js
├── game.js
├── timer.js
├── operations.js
├── progress.js
└── records.js
```

Estos nombres son una recomendación estructural, no un requisito contractual.
