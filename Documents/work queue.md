Work queue: CarMesh3D and AnimateCar3D

Kept by Claude; edit or reorder freely. Last updated 2026-11-24 05:30. No batch running. Last question number used: Q42 (the next question is Q43). Last test number used: T44 (the next is T45).

The working rules (tags, communication, clock times, folders, git, licenses, running MATLAB, GUI rules, tests) are in claude/how_we_work.md, which is portable to other projects; a copy is in Desktop\Claude\Project_CarMesh3D\how_we_work.md. Project-specific rules:

No MATLAB pop-ups while Sean is in a GUI. Sean works in a MATLAB of his own; the agent-connected one is Claude's, and its windows stay hidden. GUI tests (hidden windows) run only while Sean is away or says OK.
No function edits while a batch runs.
Questions (Sean, 14:58, 01:51, 09:24): numbered Q1 to Q99, counting up across messages and wrapping to Q1 after Q99; lettered options, recommended first; self-contained; at most two at a time; reposted with context after 10 minutes when work depends on them. In design files: S2C / C2S, closed ones moved to the change log.
Test numbers are unique (Sean, 2026-11-24 03:43): T-steps count up across all design files and the chat (never restarting at T1 per file); a reset can be agreed if the numbers get too high.
The MD files are the record (Sean, 2026-11-24 01:40): review notes, test results, decisions and open questions go into the design files and docs first; the chat points to them. "We cannot rely on the chat to track details."
Discuss before large work (Sean, 01:12): re-list the tasks and agree on them before starting; do not tie up the computer with testing that is not needed.
Template changes are bundled: any template change redoes every vehicle's cache once.
Downloads: Sean works down Project_CarMesh3D\sketchfab\download_list.md. XXX trims are inferred by Claude and recorded as TrimStatus 'E', with TrimSource.
Git: Sean commits and pushes in GitHub Desktop (Summary and Description boxes: commit messages come as a ..._PASTE_THIS.txt file with the two parts). Claude may untrack files (git rm --cached, Sean 19:26) with GitHub Desktop's own git (%LOCALAPPDATA%\GitHubDesktop\app-3.6.11\resources\app\git\cmd\git.exe; not on the PATH).