#!/usr/bin/env bash
set +e  # Continue on error

echo "🔍 이전 Claude 리뷰 검색 중..."

# 1. PR 코멘트(요약) 삭제 - github-actions[bot]이 작성한 코멘트
gh api "repos/$REPO/issues/$PR_NUMBER/comments" \
  --jq '.[] | select(.user.login == "github-actions[bot]") | .id' \
  | while read comment_id; do
      if [ -n "$comment_id" ]; then
        echo "🗑️  PR 코멘트 삭제: $comment_id"
        gh api -X DELETE "repos/$REPO/issues/comments/$comment_id" 2>/dev/null || echo "⚠️  삭제 실패 (무시)"
        sleep "$DELETE_DELAY"
      fi
    done

# 2. 인라인 리뷰 코멘트 삭제
# - 미해결 스레드 중 bot 코멘트만 있는 스레드만 삭제
# - 사용자 답글이 있는 스레드는 삭제하지 않음 (코드만 덩그러니 남는 문제 방지)
OWNER=${REPO%/*}
NAME=${REPO#*/}

gh api graphql -F owner="$OWNER" -F name="$NAME" -F number="$PR_NUMBER" -f query='
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(last: 100) {
          nodes {
            isResolved
            comments(first: 50) {
              nodes {
                databaseId
                author {
                  login
                }
              }
            }
          }
        }
      }
    }
  }' \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | select([.comments.nodes[].author.login] | all(. == "github-actions")) | .comments.nodes[].databaseId' \
  | while read comment_id; do
      if [ -n "$comment_id" ]; then
        echo "🗑️  인라인 코멘트 삭제: $comment_id"
        gh api -X DELETE "repos/$REPO/pulls/comments/$comment_id" 2>/dev/null || echo "⚠️  삭제 실패 (무시)"
        sleep "$DELETE_DELAY"
      fi
    done

echo "✅ 이전 리뷰 삭제 완료"
