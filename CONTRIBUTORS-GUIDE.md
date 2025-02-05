# Contributing to the Split Elixir thin client SDK

Split SDK is an open source project and we welcome feedback and contribution. The information below describes how to build the project with your changes, run the tests, and send the Pull Request(PR).

## Development process

1. Fork the repository and create a topic branch from `development` branch. Please use a descriptive name for your branch.
2. Run `mix deps.get` to have the dependencies up to date.
3. While developing, use descriptive messages in your commits. Avoid short or meaningless sentences like: "fix bug".
4. Make sure to add tests for both positive and negative cases.
5. If your changes have any impact on the public API, make sure you update the type specification and documentation attributes (`@spec`, `@doc`, `@moduledoc`), as well as it's related test file.
6. Run the build script (`mix compile`) and make sure it runs with no errors.
7. Run all tests (`mix test`) and make sure there are no failures.
8. `git push` your changes to GitHub within your topic branch.
9. Open a Pull Request(PR) from your forked repo and into the `development` branch of the original repository.
10. When creating your PR, please fill out all the fields of the PR template, as applicable, for the project.
11. Check for conflicts once the pull request is created to make sure your PR can be merged cleanly into `development`.
12. Keep an eye out for any feedback or comments from Split's SDK team.

# Contact

If you have any other questions or need to contact us directly in a private manner send us a note at sdks@split.io
