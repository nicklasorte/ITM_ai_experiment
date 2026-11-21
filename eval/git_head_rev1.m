function h = git_head_rev1(repo_dir)
%GIT_HEAD_REV1 Short commit hash of a git checkout, read from .git without a shell.
%   h = GIT_HEAD_REV1(repo_dir) returns the first 7 characters of HEAD's
%   commit, or "unavailable". It reads .git/HEAD, the loose ref, or
%   packed-refs directly, so it never calls system() (shell calls from the
%   MATLAB MCP session can hang).
h = "unavailable";
g = fullfile(repo_dir, '.git');
if isfile(g)                                   % worktree or submodule: "gitdir: <path>"
    t = strtrim(string(fileread(g)));
    if startsWith(t, "gitdir:"), g = strtrim(extractAfter(t, "gitdir:")); end
end
hf = fullfile(g, 'HEAD');
if ~isfile(hf), return, end
t = strtrim(string(fileread(hf)));
if ~startsWith(t, "ref:")
    h = extractBefore(t + "       ", 8); return
end
ref = strtrim(extractAfter(t, "ref:"));
rf = fullfile(g, ref);
if isfile(rf)
    h = extractBefore(strtrim(string(fileread(rf))) + "       ", 8); return
end
pf = fullfile(g, 'packed-refs');
if isfile(pf)
    L = splitlines(string(fileread(pf)));
    k = find(endsWith(L, " " + ref), 1);
    if ~isempty(k), h = extractBefore(L(k), 8); end
end
end
