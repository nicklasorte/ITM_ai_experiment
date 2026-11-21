function P = itm_exp_paths_rev1(options)
%ITM_EXP_PATHS_REV1 Put the harness, the ITM variant, and the pinned matlab_itm on the path.
%   P = ITM_EXP_PATHS_REV1() returns a struct of folders and adds to the
%   MATLAB path: eval/, itm_variant/, and the matlab_itm root (public
%   functions only: itm_p2p_rev1, itm_terrain_profile_rev1, the climate and
%   refractivity lookups). matlab_itm must be at the commit pinned in
%   P.itm_commit, so the baseline can't drift.
%
%   Folders default to siblings of this repository and can be overridden
%   with the environment variables ITM_EXP_MATLAB_ITM, ITM_EXP_P452, and
%   ITM_EXP_P2001. Set ITM_EXP_ALLOW_ANY_COMMIT=1 only for debugging.
%
%   Options: References (false) also adds matlab_itu_p452 and itu_p2001,
%   which only data/build_links_rev1 needs.

arguments
    options.References (1,1) logical = false
end
P.root = string(fileparts(fileparts(mfilename('fullpath'))));
P.itm_commit = "9bd6a4e";
parent = fileparts(P.root);
P.matlab_itm = env_or("ITM_EXP_MATLAB_ITM", fullfile(parent, "matlab_itm"));
P.p452 = env_or("ITM_EXP_P452", fullfile(parent, "matlab_itu_p452"));
P.p2001 = env_or("ITM_EXP_P2001", fullfile(parent, "itu_p2001"));

if ~isfolder(P.matlab_itm)
    error('itmexp:path', 'matlab_itm not found at %s. Clone it or set ITM_EXP_MATLAB_ITM.', P.matlab_itm);
end
head = git_head_rev1(P.matlab_itm);
if head == "unavailable"
    error('itmexp:git', 'Could not read the matlab_itm commit from %s/.git.', P.matlab_itm);
end
if head ~= P.itm_commit && getenv('ITM_EXP_ALLOW_ANY_COMMIT') ~= "1"
    error('itmexp:commit', ['matlab_itm is at %s; the baseline is pinned to %s. ', ...
        'Run git -C "%s" checkout %s.'], head, P.itm_commit, P.matlab_itm, P.itm_commit);
end
P.itm_head = head;

addpath(char(P.matlab_itm));
addpath(char(fullfile(P.root, "itm_variant")));
addpath(char(fullfile(P.root, "eval")));
if options.References
    for d = [P.p452, P.p2001]
        if ~isfolder(d)
            error('itmexp:path', 'Reference model folder not found: %s', d);
        end
        addpath(char(d));
    end
    if exist('p452_addpath_rev1', 'file')
        old = getenv('MATLAB_P452_ITM_DIR');
        setenv('MATLAB_P452_ITM_DIR', char(P.matlab_itm));
        p452_addpath_rev1();
        setenv('MATLAB_P452_ITM_DIR', old);
    end
end
warning('off', 'itm:validity:Caution');
warning('off', 'p2001:profile:spacing');
end

function v = env_or(name, default)
v = string(getenv(name));
if strlength(v) == 0
    v = string(default);
end
end
