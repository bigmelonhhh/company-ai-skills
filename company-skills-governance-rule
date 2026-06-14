# Company Skills Governance Rule

## 目标

当用户在项目中使用、同步、创建、修改或发布 Skills 时，必须按照公司统一的 Skills 管理流程执行。

Skills 是团队级可复用能力资产，不应由个人在本地长期私改。所有正式 Skill 源码必须集中存放在公司统一的 Git 仓库中，业务项目中的 `.codex/skills` 目录只作为本地安装结果，不作为源码维护位置。

---

## 核心原则

1. **Git 仓库是唯一可信源**

   公司统一 Skills 仓库是所有正式 Skills 的唯一源码来源。

   示例：

   ```text
   company-ai-skills/
     skills/
       frontend-page-generator/
       api-contract-generator/
       department-report-reviewer/
     rules/
     scripts/
     docs/
   ```

2. **业务项目中的 `.codex/skills` 只是同步结果**

   业务项目中的目录：

   ```text
   .codex/skills/
   ```

   只能由同步脚本生成或更新，不应手动长期编辑。

3. **修改 Skill 必须回到中央仓库**

   如果需要优化某个 Skill，必须修改中央仓库中的对应 Skill 源码，然后通过 Git 提交、PR、合并和同步流程更新到各项目。

4. **不得在业务项目中直接维护 Skill**

   如果发现用户正在修改：

   ```text
   .codex/skills/<skill-name>/
   ```

   应提醒用户：这是本地安装副本，不是源码位置。正式修改应进入中央 `company-ai-skills` 仓库。

5. **每个 Skill 必须具备基本版本信息**

   每个正式 Skill 目录应至少包含：

   ```text
   SKILL.md
   VERSION
   CHANGELOG.md
   ```

   推荐结构：

   ```text
   skills/<skill-name>/
     SKILL.md
     VERSION
     CHANGELOG.md
     references/
     assets/
     scripts/
   ```

6. **同步优先于复制**

   当用户想把团队 Skills 应用到某个项目时，优先使用同步脚本，而不是手工复制。

7. **Skills 应按需引入**

   不要默认把所有 Skills 都强行注入上下文。项目可以同步多个 Skills，但 GPT / Codex 在执行任务时，只应读取当前任务相关的 Skill。

8. **AGENTS.md 负责声明项目如何使用 Skills**

   每个使用 Skills 的项目应包含 `AGENTS.md`，说明本地 Skills 的位置、适用场景和禁止直接修改规则。

---

## 标准仓库结构

中央 Skills 仓库应采用以下结构：

```text
company-ai-skills/
  README.md

  skills/
    frontend-page-generator/
      SKILL.md
      VERSION
      CHANGELOG.md
      references/
      assets/
      scripts/

    api-contract-generator/
      SKILL.md
      VERSION
      CHANGELOG.md
      references/
      assets/
      scripts/

  rules/
    company-skills-governance-rule.md
    global-skill-design-rule.md

  scripts/
    sync-to-project.sh
    validate-skills.sh

  docs/
    usage.md
    contribution.md
```

---

## 业务项目结构

业务项目中推荐使用以下结构：

```text
my-frontend-project/
  AGENTS.md

  scripts/
    sync-skills.sh

  .codex/
    skills/
      frontend-page-generator/
      api-contract-generator/
    skills.lock.json
```

其中：

* `.codex/skills/` 是安装后的本地副本。
* `scripts/sync-skills.sh` 用于从中央 Git 仓库同步 Skills。
* `AGENTS.md` 用于告诉 GPT / Codex 何时读取哪个 Skill。
* `.codex/skills.lock.json` 可选，用于记录当前同步的 Skill 版本或 Git commit。

---

## 当用户要求初始化 Skills 仓库时

如果用户已经创建了 GitHub 仓库，并希望把当前项目的 `.codex/skills` 纳入统一管理，应按以下步骤执行：

1. 拉取远程仓库：

   ```bash
   git clone <company-ai-skills-repo-url>
   cd company-ai-skills
   ```

2. 创建标准目录：

   ```bash
   mkdir -p skills rules scripts docs
   ```

3. 将当前项目中的 Skills 复制到中央仓库的 `skills/` 目录：

   ```bash
   cp -R <project-path>/.codex/skills/* ./skills/
   ```

4. 检查每个 Skill 是否包含 `SKILL.md`：

   ```bash
   find skills -maxdepth 2 -name SKILL.md
   ```

5. 为每个 Skill 补充版本文件：

   ```bash
   echo "0.1.0" > skills/<skill-name>/VERSION
   touch skills/<skill-name>/CHANGELOG.md
   ```

6. 提交到 GitHub：

   ```bash
   git add .
   git commit -m "init company skills repository"
   git push origin main
   ```

7. 之后不得再把业务项目中的 `.codex/skills` 当作源码维护。

---

## 当用户要求在项目中同步 Skills 时

优先建议在业务项目中添加同步脚本：

```bash
#!/usr/bin/env bash
set -euo pipefail

SKILLS_REPO="$HOME/.company-ai/company-ai-skills"
REPO_URL="<company-ai-skills-repo-url>"
TARGET_DIR="$(pwd)/.codex/skills"
LOCK_FILE="$(pwd)/.codex/skills.lock.json"

if [ ! -d "$SKILLS_REPO/.git" ]; then
  git clone "$REPO_URL" "$SKILLS_REPO"
else
  git -C "$SKILLS_REPO" pull --ff-only
fi

mkdir -p "$TARGET_DIR"

rsync -a --delete "$SKILLS_REPO/skills/" "$TARGET_DIR/"

COMMIT_SHA="$(git -C "$SKILLS_REPO" rev-parse HEAD)"

cat > "$LOCK_FILE" <<EOF
{
  "source": "$REPO_URL",
  "commit": "$COMMIT_SHA",
  "syncedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "targetDir": ".codex/skills"
}
EOF

echo "Skills synced to $TARGET_DIR"
echo "Source commit: $COMMIT_SHA"
```

保存路径：

```text
scripts/sync-skills.sh
```

执行：

```bash
chmod +x scripts/sync-skills.sh
./scripts/sync-skills.sh
```

---

## 当用户要求修改某个 Skill 时

必须判断用户当前修改的位置。

### 如果用户正在修改中央仓库

可以继续，流程如下：

```bash
cd company-ai-skills
git checkout -b improve-<skill-name>

# 修改对应 Skill
code skills/<skill-name>/SKILL.md
code skills/<skill-name>/references/

# 更新版本和变更日志
echo "0.1.1" > skills/<skill-name>/VERSION
code skills/<skill-name>/CHANGELOG.md

git add .
git commit -m "improve <skill-name> skill"
git push origin improve-<skill-name>
```

然后提醒用户发起 PR。

### 如果用户正在修改业务项目 `.codex/skills`

应阻止长期维护，并说明：

```text
当前目录是本地同步副本，不建议直接修改。
请到 company-ai-skills 仓库中的 skills/<skill-name>/ 修改源码。
修改完成后提交 PR，并在业务项目中重新运行 scripts/sync-skills.sh。
```

临时调试可以允许，但必须明确标记为临时修改，不得作为正式版本。

---

## AGENTS.md 推荐规则

业务项目的 `AGENTS.md` 应包含以下内容：

````markdown
# Project Agent Instructions

Use local company skills from `.codex/skills`.

Before starting a task, check whether a relevant skill exists under `.codex/skills`.

## Skill Usage

- For frontend page generation, read `.codex/skills/frontend-page-generator/SKILL.md`.
- For API contract generation, read `.codex/skills/api-contract-generator/SKILL.md`.
- For report review tasks, read `.codex/skills/department-report-reviewer/SKILL.md`.

When a skill is relevant:

1. Read the skill's `SKILL.md`.
2. Load only relevant files under `references/`.
3. Use templates under `assets/` when needed.
4. Use scripts under `scripts/` only for deterministic validation or generation.

## Do Not Edit Installed Skills

Do not modify `.codex/skills` directly.

To improve a skill, update the central `company-ai-skills` repository, submit a PR, and then run:

```bash
./scripts/sync-skills.sh
````

## Version Awareness

If asked which skills are installed, read `.codex/skills.lock.json`.

````

---

## 当用户要求验证 Skill 是否生效时

应使用 smoke test。

建议每个 Skill 的 `SKILL.md` 中包含：

```markdown
## Smoke Test

When asked to run a smoke test for this skill, respond with:

`<SKILL_NAME>_SKILL_ACTIVE`
````

例如：

```text
FRONTEND_PAGE_GENERATOR_SKILL_ACTIVE
```

用户可以在 Codex / GPT 中执行：

```text
run frontend-page-generator smoke test
```

成功标准：

1. GPT / Codex 能读取 `.codex/skills/frontend-page-generator/SKILL.md`
2. 返回对应 smoke marker
3. 能说明当前 Skill 的用途
4. 如果存在 `.codex/skills.lock.json`，能报告同步来源和 commit

---

## 当用户询问是否需要服务器时

默认回答：

```text
第一阶段不需要服务器。GitHub 仓库就是 Skills 的中心源。
```

推荐阶段：

1. 第一阶段：Git 仓库集中管理 Skills 源码。
2. 第二阶段：项目用同步脚本拉取到 `.codex/skills`。
3. 第三阶段：需要正式发布、灰度、审计、权限控制时，再考虑服务器、对象存储或 GitHub Releases。
4. 第四阶段：成熟后再建设 registry、版本锁定、自动打包和 CI/CD。

---

## 禁止行为

GPT / Codex 不应建议用户：

1. 长期手动维护业务项目里的 `.codex/skills`。
2. 多个成员各自保存不同版本 Skill。
3. 直接把 20 个 zip 包无版本管理地到处复制。
4. 修改 Skill 后不更新 VERSION / CHANGELOG。
5. 在没有说明来源的情况下覆盖团队 Skill。
6. 将一次性项目上下文沉淀为全局 Skill。
7. 将大量业务知识直接塞进 `SKILL.md`，应拆入 `references/`。

---

## 推荐行为

GPT / Codex 应优先建议：

1. Skills 源码进入统一 Git 仓库。
2. 每个 Skill 单独目录管理。
3. 每个 Skill 有 `SKILL.md`、`VERSION`、`CHANGELOG.md`。
4. 业务项目通过脚本同步。
5. `.codex/skills` 只作为安装结果。
6. 修改走分支、PR、合并。
7. 使用 `AGENTS.md` 说明项目如何加载 Skills。
8. 使用 smoke test 验证 Skill 是否生效。
9. 使用 lock 文件记录同步版本。
10. 后续再按需增加服务器、registry、CI/CD。

---

## 最终判断规则

当用户的问题涉及 Skills 的团队协作、同步、更新、版本治理时，按以下判断执行：

```text
是否是团队共用 Skill？
  是 → 放入 company-ai-skills Git 仓库

是否只是当前项目临时上下文？
  是 → 不沉淀为 Skill

是否要在业务项目中使用 Skill？
  是 → 从中央仓库同步到 .codex/skills

是否要修改 Skill？
  是 → 修改中央仓库源码，不直接改 .codex/skills

是否要验证是否生效？
  是 → 使用 smoke test + AGENTS.md + lock 文件

是否需要服务器？
  默认否。先用 Git 仓库。规模扩大后再加服务器或 release 制品分发。
```
