## Foundry Basics

- [Foundry Docs](https://book.getfoundry.sh)
- `anvil` runs the local blockchain network
- `forge script` is used to run the scripts in the script folder.
- `cast` is a command that comes with foundry, used to do a lot of things, including sending transactions from the terminal.
- Running `cast --to-base 0x714e1 dec`
  will convert the 0x714e1 to its decimal value, which is 464097. Run `cast --help` for more.
- `chisel` is a command line tool to execute solidity inline, like Python terminal execution. Run `chisel` and then type `!help` to get more.
- `forge snapshot` gives a snapshot file with the gas used for each of the test functions.

### Third Web

- Safe(ish) way to deploy from terminal without exposing your private keys and no additional installations:
  `npx thirdweb deploy`
- It gives you a good graphical UI with Metamask connectivity and everything.
- [Third Web Website](https://thirdweb.com)

### VS Code CheatCodes

- ^w deletes the last word in the terminal command
- ^u deletes the whole command in terminal

### Testing basics

- `Unit Testing` is when you're testing a specific part of the codebase, not caring about anything else. Limited and focused.
- `Integration Testing` is when you're testing how one part interacts and integrates with other parts of the code.
- `Forked Testing` is testing the (entire) code on simulated or real environment.
- `Staging Testing` is where you're testing the code in a real environment, but which is not production. Testnet Launch is an example.

### Miscellaneous

- Code Refactoring: making this modular and flexible, less hardcoded things. Easy maintenance.

### Arrange-Act-Assert Testing methodology

- `Arrange` or setup the test.
- `Act` the things you want. Do stuff.
- `Assert` the test.
