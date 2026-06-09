# Quick Planning Template

Copy this template and fill in the blanks. Keep it SHORT.

```markdown
## Task: [ONE LINE description]

### Files to Modify
- `path/to/file.ts` - [one line: what changes]
- `path/to/file.ts` - [one line: what changes]

### Steps
1. [action] in [file]
2. [action] in [file]
3. Verify: [command]

### Constraints
- [key constraint]
- [key constraint]
```

## Examples

### Example 1: Add feature
```markdown
## Task: Add user authentication

### Files to Modify
- `src/auth.ts` - create login function
- `src/routes.ts` - add auth middleware
- `src/components/Login.tsx` - create login form

### Steps
1. Create login function in auth.ts
2. Add auth middleware to routes
3. Build Login component
4. Verify: npm run build

### Constraints
- Use JWT tokens
- HTTP-only cookies
```

### Example 2: Fix bug
```markdown
## Task: Fix null pointer in user profile

### Files to Modify
- `src/components/Profile.tsx` - add null check

### Steps
1. Add optional chaining for user.name
2. Add fallback for missing data
3. Verify: npm run test

### Constraints
- Don't change API response
```

### Example 3: Refactor
```markdown
## Task: Extract API calls to service layer

### Files to Modify
- `src/services/api.ts` - create new file
- `src/components/UserList.tsx` - use service
- `src/components/PostList.tsx` - use service

### Steps
1. Create api.ts with fetch functions
2. Replace direct fetch calls in components
3. Verify: npm run build && npm run test

### Constraints
- Keep same function signatures
- No new dependencies
```

## Token Budget

- Header: ~5 tokens
- Files: ~20 tokens (3 files × ~7 tokens each)
- Steps: ~30 tokens (4 steps × ~7 tokens each)
- Constraints: ~20 tokens
- **Total: ~75 tokens per plan**

Compare to detailed analysis: ~2000-5000 tokens
