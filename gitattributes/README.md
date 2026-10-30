# .gitattributes templates

| File | Use for |
|---|---|
| `firmware.gitattributes` | Firmware and FPGA projects |

Copy the file to the repository root as `.gitattributes`. Check what applies to a file with `git check-attr -a <path>`.

## Line endings

Text files are stored with LF. Build files and scripts (`Makefile`, `*.mk`, `*.sh`, `*.py`) are also checked out with LF on every OS, because CRLF breaks them. These lines change nothing on Linux, but they keep the build working for a client developer on Windows. Windows batch files (`*.bat`, `*.cmd`) are checked out with CRLF.

## Git LFS

The template stores PDFs, images, archives and FPGA output in Git LFS. Before using it on a project:

- **Everyone who clones the repository needs Git LFS installed**, including the client's developers and CI. Without it, a clone gets small placeholder files instead of the real ones, with no error. Run `git lfs install` once per machine.
- **Agree on it with the client at kickoff.** LFS storage and transfer count against the hosting account's quota (GitHub, GitLab, Bitbucket), which is usually the client's after handoff. Record the decision in the project README.
- **Patterns only apply to new commits.** Files committed before `.gitattributes` was added stay in normal Git until they're moved with `git lfs migrate import --include="<pattern>"`. That rewrites history, so coordinate with everyone using the repository first.

If a project doesn't use LFS, delete the LFS sections. Keep `*.bin binary` and add `binary` lines for any other binary files the project commits.