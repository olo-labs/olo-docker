# Contributing to OLO Docker

Thanks for helping improve the OLO Docker stack. This repository is most useful when the docs make it easy for visitors to find a path in, understand ownership, and make a safe change without guessing.

## What belongs here

- Docker Compose changes for `dev/`, `demo/`, and `prod/`
- Documentation that helps operators, module owners, and contributors
- Scenario notes under `dev/configuration/olo-configuration/`
- Fixes for pathing, refresh behavior, ports, and local developer experience

## Before you open a change

1. Read the top-level [README](README.md) and the [docs index](docs/README.md).
2. Check the relevant scenario README under `dev/configuration/olo-configuration/<scenario>/`.
3. Keep changes narrow when the issue is specific to one environment.
4. Update the docs in the same change if behavior, ports, or activation flow changes.

## Review checklist

- Does the README tell a new visitor what to run first?
- Does the relevant scenario README explain activation, worker scanning, and test/demo data?
- If the change affects a scenario, is the owning team or module credit visible?
- Are links, ports, and container names still accurate?

## Ownership and credit

Each scenario folder should be treated as a module with a clear owner. When you update a scenario, please add or keep a short credit note in that scenario README naming the maintainer or owning team.

If a repository-wide ownership file is added later, link it from here and from the main README so contributors can find it quickly.

## Good contribution shape

- Small fix: update the relevant doc and compose file together.
- Behavioral fix: include a short verification note in the PR description or commit message.
- New scenario or module: add a README, a quick activation path, and a credit line for the owner.
