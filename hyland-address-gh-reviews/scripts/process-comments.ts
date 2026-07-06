#!/usr/bin/env tsx

/**
 * Process PR comments from GitHub API
 * Filters by reactions and formats for LLM consumption
 *
 * Usage: tsx process-comments.ts <raw-input.json> <processed-output.json> <formatted-output.txt>
 */
import * as fs from 'fs';
import * as path from 'path';

interface GitHubReactions {
  '+1': number;
  '-1': number;
  laugh: number;
  hooray: number;
  confused: number;
  heart: number;
  rocket: number;
  eyes: number;
}

interface GitHubUser {
  login: string;
  type: string;
}

interface GitHubComment {
  id: number;
  user: GitHubUser;
  path: string;
  position: number | null;
  original_position: number | null;
  line: number | null;
  original_line: number | null;
  commit_id: string;
  original_commit_id: string;
  body: string;
  created_at: string;
  updated_at: string;
  html_url: string;
  reactions: GitHubReactions;
  diff_hunk?: string;
  in_reply_to_id?: number;
}

interface CommentThread {
  author: string;
  body: string;
  createdAt: string;
}

interface ProcessedComment {
  id: number;
  author: string;
  authorType: string;
  file: string;
  line: number | null;
  position: number | null;
  body: string;
  diffHunk: string | null;
  thumbsUpCount: number;
  url: string;
  createdAt: string;
  thread?: CommentThread[];
}

interface ProcessedOutput {
  prNumber: string;
  totalComments: number;
  commentsWithThumbsUp: number;
  commentsSkipped: number;
  comments: ProcessedComment[];
}

// ANSI color codes
const colors = {
  red: '\x1b[0;31m',
  green: '\x1b[0;32m',
  yellow: '\x1b[1;33m',
  blue: '\x1b[0;34m',
  cyan: '\x1b[0;36m',
  reset: '\x1b[0m',
};

function extractCodeFromDiffHunk(diffHunk: string | undefined): string | null {
  if (!diffHunk) return null;

  // Remove the diff header (@@...@@) and extract the actual code
  const lines = diffHunk.split('\n');
  const codeLines = lines.slice(1).filter(line => !line.startsWith('@@'));

  return codeLines.join('\n').trim() || null;
}

function extractSuggestions(body: string): string[] {
  const suggestions: string[] = [];

  // Extract code blocks (```...```)
  const codeBlockRegex = /```[\s\S]*?```/g;
  const codeBlocks = body.match(codeBlockRegex);
  if (codeBlocks) {
    suggestions.push(...codeBlocks);
  }

  // Extract inline code (`...`)
  const inlineCodeRegex = /`[^`]+`/g;
  const inlineCodes = body.match(inlineCodeRegex);
  if (inlineCodes) {
    suggestions.push(...inlineCodes);
  }

  return suggestions;
}

function fetchCommentThread(commentId: number, allComments: GitHubComment[]): CommentThread[] {
  // Find all replies to this comment (comments with in_reply_to_id === commentId)
  const replies = allComments.filter(c => c.in_reply_to_id === commentId);

  return replies.map(reply => ({
    author: reply.user.login,
    body: reply.body,
    createdAt: reply.created_at,
  }));
}

function formatComment(comment: ProcessedComment, index: number): string {
  const lines: string[] = [];

  lines.push(`\n${'='.repeat(80)}`);
  lines.push(`COMMENT #${index + 1}`);
  lines.push(`${'='.repeat(80)}`);
  lines.push(`Author:        ${comment.author} (${comment.authorType})`);
  lines.push(`File:          ${comment.file}`);
  lines.push(`Line:          ${comment.line !== null ? comment.line : 'N/A'}`);
  lines.push(`Position:      ${comment.position !== null ? comment.position : 'N/A'}`);
  lines.push(`👍 Reactions:  ${comment.thumbsUpCount}`);
  lines.push(`URL:           ${comment.url}`);
  lines.push(`Created:       ${new Date(comment.createdAt).toLocaleString()}`);
  lines.push(`\n${'-'.repeat(80)}`);
  lines.push('COMMENT BODY:');
  lines.push(`${'-'.repeat(80)}`);
  lines.push(comment.body);

  if (comment.thread && comment.thread.length > 0) {
    lines.push(`\n${'-'.repeat(80)}`);
    lines.push(
      `THREAD (${comment.thread.length} ${comment.thread.length === 1 ? 'reply' : 'replies'}):`,
    );
    lines.push(`${'-'.repeat(80)}`);
    comment.thread.forEach((reply, idx) => {
      lines.push(
        `\n[Reply ${idx + 1}] ${reply.author} (${new Date(reply.createdAt).toLocaleString()}):`,
      );
      lines.push(reply.body);
    });
  }

  if (comment.diffHunk) {
    lines.push(`\n${'-'.repeat(80)}`);
    lines.push('CODE CONTEXT (diff hunk):');
    lines.push(`${'-'.repeat(80)}`);
    lines.push(comment.diffHunk);
  }

  const suggestions = extractSuggestions(comment.body);
  if (suggestions.length > 0) {
    lines.push(`\n${'-'.repeat(80)}`);
    lines.push('EXTRACTED SUGGESTIONS:');
    lines.push(`${'-'.repeat(80)}`);
    suggestions.forEach((suggestion, idx) => {
      lines.push(`[${idx + 1}] ${suggestion}`);
    });
  }

  return lines.join('\n');
}

function main() {
  const args = process.argv.slice(2);

  if (args.length < 3) {
    console.error(
      'Usage: tsx process-comments.ts <raw-input.json> <processed-output.json> <formatted-output.txt>',
    );
    process.exit(1);
  }

  const [rawInputFile, processedOutputFile, formattedOutputFile] = args;

  // Read raw comments
  let rawComments: GitHubComment[];
  try {
    const rawData = fs.readFileSync(rawInputFile, 'utf-8');
    rawComments = JSON.parse(rawData);
  } catch (error) {
    console.error(`${colors.red}Error reading or parsing input file: ${error}${colors.reset}`);
    process.exit(1);
  }

  console.log(`${colors.cyan}Total comments fetched: ${rawComments.length}${colors.reset}`);

  // Filter comments by thumbs up reactions
  const commentsWithThumbsUp = rawComments.filter(
    comment => comment.reactions && comment.reactions['+1'] > 0,
  );

  console.log(
    `${colors.cyan}Comments with 👍 reactions: ${commentsWithThumbsUp.length}${colors.reset}`,
  );
  console.log(
    `${colors.yellow}Comments skipped (no 👍): ${rawComments.length - commentsWithThumbsUp.length}${colors.reset}`,
  );

  // Process comments and fetch threads
  const processedComments: ProcessedComment[] = commentsWithThumbsUp.map(comment => {
    const thread = fetchCommentThread(comment.id, rawComments);

    return {
      id: comment.id,
      author: comment.user.login,
      authorType: comment.user.type,
      file: comment.path,
      line: comment.line || comment.original_line,
      position: comment.position || comment.original_position,
      body: comment.body,
      diffHunk: extractCodeFromDiffHunk(comment.diff_hunk),
      thumbsUpCount: comment.reactions['+1'],
      url: comment.html_url,
      createdAt: comment.created_at,
      thread: thread.length > 0 ? thread : undefined,
    };
  });

  // Group by file for summary
  const fileGroups = processedComments.reduce(
    (acc, comment) => {
      if (!acc[comment.file]) {
        acc[comment.file] = [];
      }
      acc[comment.file].push(comment);
      return acc;
    },
    {} as Record<string, ProcessedComment[]>,
  );

  // Create processed output
  const output: ProcessedOutput = {
    prNumber: path.basename(rawInputFile).split('-')[0],
    totalComments: rawComments.length,
    commentsWithThumbsUp: commentsWithThumbsUp.length,
    commentsSkipped: rawComments.length - commentsWithThumbsUp.length,
    comments: processedComments,
  };

  // Write processed JSON
  fs.writeFileSync(processedOutputFile, JSON.stringify(output, null, 2), 'utf-8');

  // Create formatted text output for LLM
  const formattedLines: string[] = [];

  formattedLines.push('PR COMMENTS REVIEW SUMMARY');
  formattedLines.push('='.repeat(80));
  formattedLines.push(`Total comments: ${output.totalComments}`);
  formattedLines.push(`Comments with 👍 reactions: ${output.commentsWithThumbsUp}`);
  formattedLines.push(`Comments skipped: ${output.commentsSkipped}`);
  formattedLines.push('');

  if (output.commentsWithThumbsUp > 0) {
    formattedLines.push('FILES WITH COMMENTS:');
    formattedLines.push('-'.repeat(80));
    Object.entries(fileGroups)
      .sort(([a], [b]) => a.localeCompare(b))
      .forEach(([file, comments]) => {
        formattedLines.push(
          `📁 ${file} (${comments.length} comment${comments.length > 1 ? 's' : ''})`,
        );
        comments.forEach(comment => {
          const lineInfo = comment.line !== null ? `Line ${comment.line}` : 'Unknown line';
          const preview = comment.body.split('\n')[0].substring(0, 80);
          const threadInfo = comment.thread
            ? ` [${comment.thread.length} ${comment.thread.length === 1 ? 'reply' : 'replies'}]`
            : '';
          formattedLines.push(
            `   [👍 ${comment.thumbsUpCount}]${threadInfo} ${lineInfo}: ${preview}${comment.body.length > 80 ? '...' : ''}`,
          );
        });
      });

    // Add detailed comments
    formattedLines.push('\n\n');
    formattedLines.push('DETAILED COMMENTS FOR LLM PROCESSING');
    formattedLines.push('='.repeat(80));

    processedComments.forEach((comment, index) => {
      formattedLines.push(formatComment(comment, index));
    });
  } else {
    formattedLines.push(
      '⚠️  No comments with 👍 reactions found. Please add reactions on GitHub to indicate which comments should be addressed.',
    );
  }

  // Write formatted output
  fs.writeFileSync(formattedOutputFile, formattedLines.join('\n'), 'utf-8');

  console.log(`${colors.green}✓ Processing complete${colors.reset}`);

  // Print summary
  console.log('');
  console.log(`${colors.blue}Summary by file:${colors.reset}`);
  Object.entries(fileGroups)
    .sort(([a], [b]) => a.localeCompare(b))
    .forEach(([file, comments]) => {
      console.log(
        `  ${colors.cyan}📁 ${file}${colors.reset} (${comments.length} comment${comments.length > 1 ? 's' : ''})`,
      );
    });
}

main();
