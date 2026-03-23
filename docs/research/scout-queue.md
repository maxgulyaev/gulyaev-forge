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
| `audit workflow pattern` | `ADOPT` | Сейчас | Взять как donor для investigation/audit mode: `sources -> facts -> analysis -> recommendations` |
| `Ruflo` | `TRIAL` | После стабилизации Behavior Contract migration | Брать natural-entry, navigator/help и operator UX patterns; не брать swarm/self-learning core |
| `TDD / proof-first loop` | `ADOPT` | Сейчас | Дожать proof-first implementation, stronger review/test barrier и behavior-first execution |
| `justdoit` | `ASSESS` | Если упрёмся в слабый Codex execution handoff или resumability для длинных runs | Брать milestone/status/stop-and-fix patterns, не копировать 3-file pack как core model |
| `NoClaw / UnixClaw` | `ADOPT` | Сейчас | Always-on Mac Mini M4 Pro: персональный ассистент + первая remote agent нода для forge |
| `ACP / A2A` | `TRIAL → ADOPT` | После поднятия Mac Mini как remote ноды | Transport layer для remote stage_agents; Mac Mini M4 Pro = первый реальный use case |
| `Agent Client Protocol` | `HOLD` | Только если сами начнём строить editor-native adapter/runtime вместо repo-level forge contract | Не путать с Agent Communication Protocol; для forge core сейчас вторично |
| `Chrome DevTools MCP` | `ADOPT` | Сейчас | QA + debugging: Lighthouse, network, console, memory, a11y — дополняет Playwright MCP |
| `CLI-Anything` | `ASSESS` | Только если упрёмся в реальный tooling pain point без MCP/API | Рассматривать как capability layer для внешних tools |
| `tmux` | `HOLD` | Вернуться только если multi-service local QA и long-running operator sessions станут регулярным bottleneck | Не делать частью forge core; максимум optional operator helper за thin script |

## Активная очередь

### 2026-03-23 — Chrome DevTools MCP

- Ссылка: https://developer.chrome.com/blog/new-in-devtools-146#mcp-server
- Репо: https://github.com/nicolo-ribaudo/chome-devtools-mcp
- Тип: MCP server
- Вердикт: ADOPT
- Тип вклада в forge:
  - donor for QA stage
  - donor for debugging
  - donor for tech monitoring
- Почему:
  - даёт агенту доступ к Chrome DevTools изнутри: Network, Console, Performance, Memory, Lighthouse, Accessibility
  - дополняет Playwright MCP: Playwright для journeys/clicks, DevTools для diagnostics/audit
  - Lighthouse аудиты автоматически в QA report
  - console errors и network failures видны агенту без ручного описания
  - видеозапись экрана, memory analysis, LCP diagnostics
- Как маппится на forge stages:
  - Stage 8 (QA): performance + a11y audit + console/network error check
  - Stage 7 (Test Coverage): memory leak detection, performance regression
  - Stage 12 (Tech Monitoring): Lighthouse scores как baseline
  - Bugfix: агент сам видит console errors и network failures
- Что делать:
  - Шаг 1: подключить MCP server в Claude settings
  - Шаг 2: обновить QA skill — использовать DevTools для diagnostics
  - Шаг 3: обновить forge-doctor — проверять наличие DevTools MCP
  - Шаг 4: обновить forge MCP bootstrap docs
- Решение: внедрять сейчас, дополняет существующий Playwright MCP

### 2026-03-20 — TDD / proof-first behavior loop

- Ссылки:
  - https://habr.com/ru/companies/ruvds/articles/450316/
- Тип: workflow-pattern
- Вердикт: ADOPT
- Тип вклада в forge:
  - donor for stages
  - donor for loops
- Почему:
  - усиливает главный forge pain point: drift между "что должна делать фича" и "как это доказать"
  - хорошо ложится на новый `Behavior Contract`: поведение и proof должны жить рядом
  - полезен не как догма "100% TDD everywhere", а как правило `proof-first` для implementation/test_coverage/qa
- Что уже забрали:
  - Stage 2 → `Behavior Contract`
  - Stage 5 → `Proof Hardening`
  - implementation ориентируется на contract slice + proof shape
- Что ещё осталось внедрить:
  - stronger review protocol
  - explicit proof-first check в implementation checkpoints
  - better contract → QA scenario ID traceability
- Решение для плана на сегодня:
  - считать это active adoption, а не scout backlog curiosity
  - использовать как один из главных источников для следующего refinement цикла

### 2026-03-20 — Ruflo

- Ссылка: https://github.com/ruvnet/ruflo
- Тип: framework
- Вердикт: TRIAL
- Тип вклада в forge:
  - donor for tooling
  - donor for workflow-patterns
  - donor for adapters
- Почему:
  - очень силён в operator UX: "just use the tool normally, routing happens under the hood"
  - подтверждает правильность нашего движения к одному естественному PRODUCT entrypoint
  - показывает полезный benchmark для navigator/help layer и complexity framing
- Что в нём ценно:
  - natural entry
  - helper/navigation layer
  - perception of "system product", not just docs + scripts
- Что не стоит брать:
  - swarm/queen hierarchy как core dependency
  - self-learning / RL / consensus layer
  - второй state-plane поверх issue + `.forge/pipeline-state.yaml`
- Решение для плана на сегодня:
  - trial only as donor
  - вернуться для navigator/help и operator UX work

### 2026-03-20 — audit workflow pattern

- Ссылка: https://gist.github.com/gsamat/d2aeb4eaa79260bc5f85ec9056296596
- Тип: workflow-pattern
- Вердикт: ADOPT
- Тип вклада в forge:
  - donor for stages
  - donor for loops
- Почему:
  - даёт аккуратную форму investigation work: `sources -> facts -> analysis -> recommendations`
  - хорошо подходит не только для code audit, но и для discovery, incident investigation, architecture review
  - помогает отделять доказанные факты от интерпретаций, чего forge сейчас местами не хватает
- Что брать:
  - compact investigation artifact format
  - strict separation between evidence and conclusions
  - reusable audit mode / investigation mode
- Решение для плана на сегодня:
  - поднять это в active roadmap как будущий `investigation/audit` mode
  - не плодить новый большой stage, а сделать reusable artifact/protocol

### 2026-03-20 — justdoit

- Ссылка: https://github.com/serejaris/justdoit
- Тип: skill-collection
- Вердикт: ASSESS
- Тип вклада в forge:
  - donor for workflow-patterns
  - donor for adapters
  - donor for tooling
- Почему:
  - repo-aware planning before execution, explicit confirmation, dependency-safe milestones и `stop-and-fix` rule хорошо попадают в реальные боли длинных Codex runs
  - `plans.md` + `status.md` дают хорошую resumability-модель для execution loops
  - но default shape (`plans.md`, `status.md`, `test-plan.md`) прямо конфликтует с нашим текущим направлением: меньше файлов, меньше воды, один основной contract file
- Что в нём ценно:
  - plan-first before long run
  - explicit `status` live log
  - validation-first milestones
  - короткий execution proposal вместо prompt dump
  - явное подтверждение перед стартом execution loop
- Что уже аккуратно забрали:
  - compact `Execution Proposal` block inside forge checkpoints for long runs
  - explicit stop-and-fix rule instead of silent multi-milestone drift
- Что не стоит брать напрямую:
  - three-file execution pack как новый forge default
  - `test-plan.md` как отдельный обязательный файл после перехода на `Behavior Contract`
  - plan file как новый source of truth поверх issue + `.forge/pipeline-state.yaml`
- Где может пригодиться:
  - Codex-specific long implementation loops
  - optional execution helper / resumable run pattern
  - future navigator/help or execution-handoff layer
- С чем сравнивать:
  - наш текущий `Behavior Contract` + issue trail + checkpoints
  - `big-project-orchestrator` как другой donor для long-running implementation
  - BMAD/Ruflo по operator UX, но не по state model
- Решение для плана на сегодня:
  - частично adopted как donor для compact execution-loop discipline
  - дальше держать как donor, если позже будем усиливать Codex execution loops или resumable status layer

### 2026-03-21 — NoClaw / UnixClaw

- Ссылки:
  - https://habr.com/ru/news/1012466/
  - https://linuxtoaster.com/blog/noclaw.html
- Тип: tool + framework
- Вердикт: ADOPT
- Тип вклада в forge:
  - donor for infrastructure
  - donor for stage-agent transport
  - первый always-on remote agent node
- Почему:
  - минималистичный AI-ассистент для Mac Mini на Apple Silicon — C + Unix pipes + plain text config
  - бесхозный Mac Mini M4 Pro = идеальная always-on нода
  - три роли одновременно:
    1. персональный ассистент (iMessage, calendar, reminders, email)
    2. первый remote stage_agent node для forge (review, investigation, draft generation)
    3. local inference hub (Ollama / Toast, ~100+ tok/s на M4 Pro)
  - по духу совпадает с forge: Unix-pipe модель, plain text, composable tools, предсказуемое поведение
- Почему не OpenClaw:
  - 400K+ строк кода, npm dependency hell, security concerns
  - слишком opinionated для интеграции с forge
  - для always-on ноды нужна простота и предсказуемость, не feature richness
  - OpenClaw остаётся как концепт для visual orchestration UI в будущем
- Что делать:
  - Шаг 1: поставить NoClaw как персонального ассистента на Mac Mini
  - Шаг 2: поднять Ollama для локального инференса
  - Шаг 3: перенести Codex review adapter на Mac Mini как первый remote stage_agent
  - Шаг 4: когда remote handoff станет болью → ACP как transport layer
- Критерий успеха шага 1:
  - Mac Mini стабильно always-on
  - NoClaw отвечает в iMessage
  - базовый calendar/reminders работает
- Что уже забрали:
  - `.crumbs` как рабочая память бота — текстовый файл с контекстом, подкладывается в каждый промпт
  - классификатор сообщений через LLM вместо хардкода
  - `ask_yes_no` через LLM для natural-language confirmation
- Решение:
  - начинать сейчас, шаг 1 не блокирует forge work
  - каждый следующий шаг — отдельное решение после стабилизации предыдущего

### 2026-03-20 — ACP / A2A

- Ссылки:
  - https://agentcommunicationprotocol.dev/introduction/welcome
  - https://agentcommunicationprotocol.dev/about/mcp-and-a2a
  - https://developers.googleblog.com/google-cloud-donates-a2a-to-linux-foundation/
  - https://research.ibm.com/blog/agent-communication-protocol-ai
- Тип: protocol
- Вердикт: TRIAL
- Тип вклада в forge:
  - donor for orchestration
  - donor for stage-agent transport
  - donor for future multi-agent topology
- Почему:
  - это уже не `agent -> tools`, а `agent -> agent` слой; именно туда упрётся forge, если stage_agents вырастут из текущего reviewer-only режима
  - ACP/A2A решают реальные боли interoperability, discovery, async/long-running tasks и peer-to-peer delegation между независимыми агентами
  - MCP остаётся релевантным и не заменяется: ACP docs прямо фиксируют, что MCP работает внутри single-agent границ, а ACP/A2A — между агентами
- Что в этом особенно ценно:
  - стандартный transport для remote/long-running stage agents
  - discoverability и capability metadata
  - async-first model вместо синхронного "позвал сабагента и ждёшь"
  - возможность вынести часть agent fleet за пределы текущего chat runtime
- Что не стоит делать сейчас:
  - переписывать forge core вокруг ACP/A2A до стабилизации текущих gates/artifacts/stage discipline
  - заменять issue trail, `.forge/pipeline-state.yaml`, stage gates или approved artifacts сетевым agent mesh state
  - превращать каждую stage handoff в peer mesh communication просто потому, что это "интереснее"
- Как это маппится на forge:
  - сегодня: `stage_agents.<stage>.<role>` + explicit adapter invocation
  - позже: optional transport layer for stage agents (`local-cli`, `mcp`, `acp/a2a`)
  - ещё позже: remote specialized agents for review, investigation, analytics, release ops
- Критерий возвращения:
  - минимум 2-3 реальных agent roles beyond reviewer
  - хотя бы один long-running or remote agent case
  - явная боль от current explicit adapter model
- Конкретный trigger (2026-03-21):
  - Mac Mini M4 Pro поднят как always-on нода
  - первый remote stage_agent (review) работает через ssh/http
  - боль от ручного transport → время для ACP
- Решение:
  - вердикт повышен до `TRIAL → ADOPT` (условный, после Mac Mini шага 3)
  - не брать в active core roadmap до реальной remote agent боли
  - Mac Mini — конкретный путь к этой боли, а не теоретический аргумент

### 2026-03-20 — Agent Client Protocol

- Ссылки:
  - https://acpserver.org/
- Тип: protocol
- Вердикт: HOLD
- Тип вклада в forge:
  - donor for adapters
  - donor for editor integrations
- Почему:
  - это другой `ACP`: Agent Client Protocol стандартизует `editor <-> coding agent`, а не `agent <-> agent`
  - для forge core это вторично, потому что forge держит repo/process contract above editor runtime
  - может стать полезным только если мы сами захотим richer editor-native adapters beyond current `CLAUDE.md` / `AGENTS.md` / command shims
- Что в нём ценно:
  - общий transport для editor integrations
  - снижение adapter-specific glue между editor и coding agent
- Почему не сейчас:
  - forge не строит свой editor runtime
  - текущий bottleneck не в editor-agent transport, а в process rigor / stage orchestration / artifact quality
- Решение для плана на сегодня:
  - зафиксировать терминологически, чтобы не путать с Agent Communication Protocol
  - не включать в active roadmap, пока сами не упрёмся в adapter/runtime layer

### 2026-03-16 — tmux

- Ссылка: https://github.com/tmux/tmux
- Тип: tool
- Вердикт: HOLD
- Тип вклада в forge:
  - donor for tooling
  - donor for workflow-patterns
- Почему:
  - может помочь локально держать несколько длинноживущих процессов: API, web, logs, simulator-oriented QA helpers
  - потенциально полезен для ручного sync QA и multi-service local setup, где сейчас оператор вручную собирает стек
  - при этом не решает forge-level боли вокруг issue trail, gate discipline, artifacts, adapter maturity или source-of-truth state
  - добавляет ещё один локальный state-plane вне repo и вне agent contract; для hosted/cloud agents вообще бесполезен
- Что в нём потенциально ценно:
  - persistent local sessions для manual QA
  - panes/windows для API + web + log tail + helper commands
  - удобство для оператора при длинных local verification loops
- Почему не берём сейчас:
  - forge должен оставаться agent-agnostic и script-first, а не зависеть от terminal multiplexer
  - текущая боль точечная: в основном manual iOS/sync QA для одного пилота, а не системный bottleneck по всем продуктам
  - на текущей машине `tmux` даже не установлен, то есть это пока не базовый operational primitive команды
  - если нам понадобится local QA launcher, правильнее сначала описать его как `forge` workflow, а уже потом при желании реализовать backend через tmux как optional enhancement
- Где может пригодиться позже:
  - optional operator helper для `qa`, `staging-deploy`, локальных sync-smoke и long-running implementation loops
  - возможно как внутренняя реализация будущего `forge dev-session` / `forge local-qa` helper, но не как обязательная зависимость
- С чем сравнивать:
  - обычные shell scripts + несколько терминалов
  - docker compose / xcodebuild / playwright / simctl, запускаемые явно
  - будущий thin forge helper, который может работать и без tmux
- Решение для плана на сегодня:
  - не добавлять tmux в forge core, docs requirements или bootstrap
  - не строить process around tmux sessions
  - вернуться только если multi-service local orchestration повторится как bottleneck минимум в нескольких сценариях/проектах

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
