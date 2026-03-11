# OGQ Claude Code Reviewer

Claude Code를 사용한 PR 자동 리뷰 Composite GitHub Action.

## 사용법

```yaml
name: "Claude Code Review"
on:
  pull_request:
    branches:
      - main
    types: [opened, reopened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    concurrency:
      group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
      cancel-in-progress: true
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: ogq-bobby/ogq-code-reviewer@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

## Inputs

| Input | Required | Default | 설명 |
|---|---|---|---|
| `github_token` | **yes** | - | GitHub API 토큰 |
| `claude_code_oauth_token` | **yes** | - | Claude Code OAuth 토큰 |
| `prompt` | no | 한국어 리뷰 프롬프트 | Claude에게 전달할 프롬프트 |
| `claude_args` | no | allowedTools 설정 | Claude CLI 추가 인자 |
| `show_full_output` | no | `"true"` | Claude 출력 전체 표시 여부 |
| `delete_previous_reviews` | no | `"true"` | synchronize 시 이전 리뷰 삭제 여부 |
| `delete_delay_seconds` | no | `"0.3"` | API 호출 간 딜레이 (rate limit 방지) |

## 커스터마이징 예시

```yaml
- uses: ogq-bobby/ogq-code-reviewer@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
    prompt: |
      REPO: ${{ github.repository }}
      PR NUMBER: ${{ github.event.pull_request.number }}
      Review this PR in English.
    delete_previous_reviews: "false"
```

## 동작 방식

1. **이전 리뷰 삭제** (`synchronize` 이벤트 시) — `github-actions[bot]`이 작성한 PR 코멘트와 bot 전용 인라인 리뷰 스레드를 삭제합니다. 사용자 답글이 있는 스레드는 보존됩니다.
2. **Claude Code 리뷰 실행** — `anthropics/claude-code-action@v1`을 호출하여 PR 리뷰를 수행합니다.

> **참고**: `actions/checkout@v4`는 action 내부에 포함되지 않으므로, 소비 워크플로우에서 직접 호출해야 합니다.
