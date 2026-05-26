---
marp: true
theme: default
paginate: true
header: 'agentic-sdlc'
---

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&family=Fira+Code:wght@400;500;700&display=swap');

:root {
  --color-background: #0d1117;
  --color-foreground: #c9d1d9;
  --color-heading: #58a6ff;
  --color-accent: #7ee787;
  --color-muted: #8b949e;
  --color-code-bg: #161b22;
  --color-border: #30363d;
  --color-warn: #f0883e;
  --font-default: 'Inter', system-ui, sans-serif;
  --font-code: 'Fira Code', 'Consolas', 'Monaco', monospace;
}

section {
  background-color: var(--color-background);
  color: var(--color-foreground);
  font-family: var(--font-default);
  font-weight: 400;
  box-sizing: border-box;
  border-left: 4px solid var(--color-accent);
  position: relative;
  line-height: 1.6;
  font-size: 22px;
  padding: 56px 64px;
}

h1, h2, h3, h4, h5, h6 {
  font-weight: 700;
  color: var(--color-heading);
  margin: 0;
  padding: 0;
  font-family: var(--font-code);
}

h1 { font-size: 52px; line-height: 1.25; text-align: left; }
h1::before { content: '# '; color: var(--color-accent); }

h2 {
  font-size: 36px;
  margin-bottom: 28px;
  padding-bottom: 10px;
  border-bottom: 2px solid var(--color-border);
}
h2::before { content: '## '; color: var(--color-accent); }

h3 {
  color: var(--color-foreground);
  font-size: 24px;
  margin-top: 24px;
  margin-bottom: 8px;
}
h3::before { content: '### '; color: var(--color-accent); }

ul, ol { padding-left: 28px; }
li { margin-bottom: 8px; }
li::marker { color: var(--color-accent); }

pre {
  background-color: var(--color-code-bg);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 16px 20px;
  overflow-x: auto;
  font-family: var(--font-code);
  font-size: 16px;
  line-height: 1.5;
}

code {
  background-color: var(--color-code-bg);
  color: var(--color-accent);
  padding: 2px 6px;
  border-radius: 3px;
  font-family: var(--font-code);
  font-size: 0.88em;
}
pre code { background-color: transparent; padding: 0; color: var(--color-foreground); }

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 18px;
  margin-top: 12px;
}
th, td {
  border: 1px solid var(--color-border);
  padding: 8px 12px;
  text-align: left;
  color: var(--color-foreground);
  background-color: var(--color-background);
}
th {
  background-color: var(--color-code-bg);
  color: var(--color-heading);
  font-family: var(--font-code);
}
tr:nth-child(even) td { background-color: rgba(21, 29, 24, 0.9); }

blockquote {
  border-left: 3px solid var(--color-accent);
  padding-left: 16px;
  color: var(--color-muted);
  font-style: italic;
  margin: 16px 0;
}

strong { color: var(--color-accent); font-weight: 700; }
em { color: var(--color-warn); font-style: normal; }

header {
  position: absolute;
  top: 20px;
  left: 64px;
  font-size: 14px;
  color: var(--color-muted);
  font-family: var(--font-code);
}
header::before { content: '// '; color: var(--color-accent); }

footer {
  font-size: 14px;
  color: var(--color-muted);
  font-family: var(--font-code);
  position: absolute;
  left: 64px;
  right: 64px;
  bottom: 28px;
  text-align: left;
}
footer::before { content: '// '; color: var(--color-accent); }

section::after {
  font-family: var(--font-code);
  color: var(--color-muted);
  font-size: 14px;
}

section.lead {
  display: flex;
  flex-direction: column;
  justify-content: center;
}
section.lead h1 { margin-bottom: 24px; font-size: 60px; }
section.lead p {
  font-size: 24px;
  color: var(--color-foreground);
  font-family: var(--font-code);
}
section.lead p strong { color: var(--color-accent); }
</style>

<!-- _class: lead -->
<!-- _paginate: false -->

# /agentic-sdlc

Плагін Claude Code. Сім фаз, кожен перехід з перевіркою.

**Специфікація та тікет** → *готовий PR із записаним демо-відео.*

---

## Проблема

> "ми довіряємо Claude, але він робить дивні речі. потім ми забуваємо перетестувати — відповідно отримуємо 13 зауважень від QA."

- Claude робить хибні припущення, а ми пропускаємо його питання.
- Ми повторюємо одні й ті ж промпти знову і знову.
- Claude може мати «деструктивні наміри» і намагатися видалити багато всього просто так.
- Ми хочемо бути впевнені, що застосунок реально працює після змін Claude.

**Нам потрібні перевірки, через які сам цикл відмовляється переходити.**

---

## Цикл

```
ticket, requirements, specs, context
  │
  ▼
intake ──────── взяти в роботу та вирішити питання
  │             кожен AC → перевірювані вимоги
  ▼
implement ───── пише код
  │             перевіряє автоматичні перевірки
  ▼
validate ────── Playwright відео доказ ──► 🎬 narrated .webm
  │             
  ▼
review ──────── три ревʼювери: code · security · standards
  │             користувач вирішує які пропозиції застосувати
  ▼
 pr ─────────── пуш гілки · відкрити PR
  │             опрацювати коментарі · запостити відповіді
  ▼
revalidate ──── повторна перевірка після ревʼю
  │             оновлене відео після всього
  ▼
merge
```

---

## Команди

| #   | Команда                     | Ідея фази                                                  |
| --- | --------------------------- | ---------------------------------------------------------- |
| 0   | `/agentic-sdlc:init`        | Налаштування SDLC під проєкт                               |
| 1   | `/agentic-sdlc:intake`      | Формування track file. Уточнюючі питання                   |
| 2   | `/agentic-sdlc:implement`   | Написання коду, та перевірки                               |
| 3   | `/agentic-sdlc:validate`    | Playwright-тести  → запис відео 🎬 демо                     |
| 4   | `/agentic-sdlc:review`      | Три ревʼюери: безпека, стандарти, загальне                 |
| 5   | `/agentic-sdlc:pr`          | Пуш гілки та  відкрити PR                                  |
| 5b  | `/agentic-sdlc:pr-comments` | Відповіді на коментарі з вердиктом (застосовано/відхилено) |
| 6   | `/agentic-sdlc:revalidate`  | Повторна перевірка всього перед мержем                     |
| ∗   | `/agentic-sdlc:cycle`       | Оркестрація фаз 1→6, пауза між кожною                      |

---

## INTAKE: Єдине джерело треку

- **Спочатку ставить уточнюючі питання** — припущення агента стають видимими і коригованими ще до написання коду.
- Один трек-файл на тікет — `_/tracks/<TICKET>.md`.
— це YAML контракт та тіло файлу — контекст для агентів і людей.
- Головний акцент на специфікаціях, вимогах і критеріях прийняття

```
_/
├── sdlc-config.md                профіль проєкту
├── tracks/PROJ-123.md            вимоги, статус, журнал
├── demo/PROJ-123.spec.mjs        згенерований Playwright-скрипт
└── recordings/
    ├── PROJ-123.validation.md    звіт про тести
    ├── PROJ-123.review.md        зведені знахідки ревʼю
    ├── PROJ-123.latest.webm      демо для стейкхолдерів
    └── …
```

---

## VALIDATE: Playwright-скрипт → assertions → 🎬 демо

**Як будується скрипт:** Playwright MCP навігує живий застосунок (`browser_navigate`, `browser_snapshot`) і знаходить реальні селектори з accessibility tree — без жодного вгадування.

**Два проходи згенерованого скрипту:**

**Прохід 1** — запуск та відлагодження перевірок без видимого браузера

**Прохід 2** — запис відео демо
- Оверлеї + фейковий курсор + бейджики секцій, уповільнений режим, запис у `.webm`
- Відразу готово для Slack, коментаря в Jira або листа стейкхолдеру

> "Я зашипив фічу. Ось 40-секундне відео, як вона працює."

---

## REVIEW: три паралельні субагенти

```
            ┌──► code reviewer       ┐
intake ────►├──► security reviewer   ├──► consolidator ──► звіт
            └──► standards reviewer  ┘
```

Знахідки зводяться до *CRITICAL / HIGH / MEDIUM / LOW*
Після цього буде запропоновано запустити суб-агент щоб застосувати ці зауваження.

---

## /agentic-sdlc:cycle

```bash
/agentic-sdlc:cycle PROJ-123
```

- Запускає фази 1 → 6 у **виділених субагентах** (чистий контекст на кожну фазу)
- Робить паузу між фазами для людського погляду
- Зупиняється на **першій неуспішній перевірці**
- Відновлювальний — трек-файл памʼятає, де зупинився

Можна просуватися вручну, якщо так зручніше:

```bash
/agentic-sdlc:intake     PROJ-123 path/to/spec.md
/agentic-sdlc:implement  PROJ-123
/agentic-sdlc:validate   PROJ-123
```

---

## Встановлення та перший запуск

```bash
# встановлення
/plugin marketplace add /path/to/sdlc
/plugin install agentic-sdlc@agentic-sdlc

# одноразове налаштування — визначає pkg manager, скрипти, префікс тікетів,
# перевіряє доступні MCP та скіли, запитає: про gitignore та інше
/agentic-sdlc:init

# повний цикл, з перевірками, від і до
/agentic-sdlc:cycle PROJ-123
```

**Вимоги:** Claude Code v2.1+, Node 18+, `gh` CLI з авторизацією. Atlassian / Linear MCP — опційно.

---

## Чому це краще ніж вайбкодинг


- Відновлення наступного дня не втрачає контекст — трек-файл є контрактом
- Narrated `.webm` робить те можна *подивитися*
- Оригінальні специфікації та вимоги завжди в контектсі агента

> Змусити цикл відмовитися брехати. Тоді йому можна довіряти.

---

<!-- _class: lead -->
<!-- _paginate: false -->

# Спробуй

**`/agentic-sdlc:cycle PROJ-123`**


