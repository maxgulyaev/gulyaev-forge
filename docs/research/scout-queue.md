# Очередь Scout

Входящие инструменты и фреймворки, которые нужно оценить или просто не потерять до следующего цикла развития forge.

Используй этот файл как человекочитаемый backlog для запросов в стиле `смотри че`.
Реестр в `core/registry/mcp-servers.yaml` остаётся компактным техническим каталогом.

## Сводка на сегодня

| Штука | Вердикт | Когда возвращаться | Как использовать в forge |
|------|---------|--------------------|--------------------------|
| `pm-skills` | `TRIAL` | Ближайший цикл refinement для `strategy` / `discovery` / `prd` | Выборочно забирать stage-patterns и role intelligence |
| `BMAD Method` | `TRIAL` | Когда улучшаем onboarding, helper-layer, docs IA и ранние stage-skills | Держать как donor/benchmark, не как новый core dependency |
| `big-project-orchestrator` | `TRIAL` | Когда будем усиливать большие `implementation` loops и Codex-specific orchestration | Брать milestone/repair/worktree patterns, не второй source of truth |
| `CLI-Anything` | `ASSESS` | Только если упрёмся в реальный tooling pain point без MCP/API | Рассматривать как capability layer для внешних tools |

## Активная очередь

### 2026-03-14 — CLI-Anything

- Ссылка: https://github.com/HKUDS/CLI-Anything
- Тип: tool
- Вердикт: ASSESS
- Почему:
  - хорошо ложится в философию agent-native tooling
  - может помочь там, где полезный внешний инструмент не имеет нормального MCP или API
  - не закрывает текущие приоритеты forge на сегодня: adapters, `/init`, MCP setup, completion пилота
- Где может пригодиться в pipeline:
  - как вспомогательный слой для `design`, `architecture` или implementation-сценариев, где нужно управлять внешними desktop tools
- С чем сравнивать:
  - сначала MCP/API
  - потом native CLI, если он уже существует
  - GUI automation только если детерминированного CLI-доступа нет
- Решение для плана на сегодня:
  - не добавлять в активный roadmap сегодня
  - держать как элемент scout backlog
  - возвращаться только если конкретный workflow упрётся в отсутствие agent-native доступа к нужному инструменту

### 2026-03-14 — PM Skills Marketplace

- Ссылка: https://github.com/phuryn/pm-skills
- Тип: skill-collection
- Вердикт: TRIAL
- Тип вклада в forge:
  - donor for roles
  - donor for stages
  - donor for loops
- Почему:
  - прямой overlap с нашими `strategy`, `discovery`, `prd` и частично `product_analytics`
  - `skills/*/SKILL.md` заявлены как переносимые и могут жить вне Claude plugin layer
  - это скорее источник stage-экспертизы и workflow-идей, чем новая архитектурная зависимость
- Что особенно ценно по текущей карте:
  - `Product Discovery` усиливает `discovery` и ранний feature loop
  - `Product Strategy` усиливает `strategy`
  - `Execution` пересекается с `prd`, planning, retros, release communication
  - `Market Research` может стать отдельным более узким подслоем внутри `discovery`
  - `Data Analytics` усиливает `product_analytics`
  - `Go-to-Market` и `Marketing & Growth` указывают на возможные будущие skill packs или post-ship loops, которых у forge пока почти нет
- Риски:
  - repo Claude-first по entry surface и slash-командам
  - очень широкий охват, легко притащить в forge лишнее и раздуть base skills
  - много пересечения с уже существующими stage-skills, нужен отбор, а не wholesale merge
- Где может пригодиться в pipeline:
  - `strategy`
  - `discovery`
  - `prd`
  - частично `product_analytics`
- С чем сравнивать:
  - с нашими текущими `core/skills/strategy`, `core/skills/discovery`, `core/skills/prd`
  - с уже используемыми `superpowers`, `everything-claude-code`, `bmad-method`
  - по критерию `усиливает stage rigor без слома forge contract`
- Решение для плана на сегодня:
  - записать как trial-кандидат
  - не тащить целиком в active roadmap сегодня
  - вернуться при следующем цикле refinement для stages 0-2 и выбрать 2-3 конкретных паттерна на импорт

### 2026-03-14 — big-project-orchestrator

- Ссылка: https://github.com/HBTCFO/big-project-orchestrator
- Тип: workflow-pattern
- Вердикт: TRIAL
- Тип вклада в forge:
  - donor for loops
  - donor for tooling
  - donor for stages
- Почему:
  - сильный operating model для длинных implementation-задач: milestones, verify, repair, handoff, archive
  - хорошо упаковывает long-running Codex work в файловый state, а не в историю чата
  - даёт полезные паттерны для крупных refactor / maintenance / migration сценариев
- Что из него потенциально брать:
  - implementation loop по milestone-based delivery
  - repair loop после failed verification
  - report-first maintenance workflow
  - worktree lanes для параллельных потоков реализации
- Как это раскладывается по forge:
  - роли: отдельной новой product-роли не даёт, но усиливает implementation-orchestrator posture
  - stages: сильнее всего ложится в `implementation`, частично в `test_coverage` и `qa`
  - loops: даёт кандидат на future long-running implementation loop внутри PRODUCT-контура
  - tooling: полезен как Codex-specific operational layer, не как общий forge control plane
- Риски:
  - Codex-native и плохо переносим как universal adapter layer
  - вводит второй state-plane (`.codex/orchestrator/`), что конфликтует с нашим issue + `.forge/pipeline-state.yaml`
  - сейчас выглядит ранним и узким по зрелости
- С чем сравнивать:
  - с текущим forge contract для `implementation`
  - с будущим Codex adapter path
  - с идеей selective skill pack, а не замены core orchestrator
- Решение для плана на сегодня:
  - не добавлять в active roadmap сегодня
  - держать как trial-кандидат на будущее
  - вернуться, когда будем усиливать большие implementation loops или Codex-specific orchestration

### 2026-03-14 — BMAD Method

- Ссылка: https://github.com/bmad-code-org/BMAD-METHOD
- Тип: framework
- Вердикт: TRIAL
- Тип вклада в forge:
  - donor for roles
  - donor for stages
  - donor for loops
- Почему:
  - зрелее forge по packaging, install flow, helper layer и workflow framing
  - уже дал нам полезные паттерны: story sharding и readiness framing
  - остаётся хорошим benchmark для operator experience, но не шаблоном для полного копирования
- Что из него потенциально брать:
  - structured elicitation patterns
  - clearer complexity tracks
  - better onboarding / navigator / helper layer
  - modular pack mindset без отказа от forge core
- Как это раскладывается по forge:
  - роли: может усиливать ранние продуктовые роли, но не должен замещать forge role model wholesale
  - stages: сильнее всего влияет на `strategy`, `discovery`, `prd`, частично `implementation`
  - loops: полезен как donor для planning-to-implementation loops, но не покрывает наш полный lifecycle
  - tooling: слабее влияет на tooling напрямую, сильнее на packaging и operator flow
- Риски:
  - monolithic project-local shape против нашего centralized forge core
  - personality-first and Claude-first delivery не совпадает с forge architecture
  - если тащить без отбора, легко размыть наши инварианты
- С чем сравнивать:
  - с `pm-skills` по early product stages
  - с текущими forge base skills и `bmad-comparison.md`
  - по критерию "улучшает operator experience без слома forge contract"
- Решение для плана на сегодня:
  - не добавлять как новый framework dependency
  - держать как постоянный donor/benchmark
  - возвращаться при refinement stage-skills, onboarding, docs IA и helper-layer work
