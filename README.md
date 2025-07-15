# DEX Router Documentation

This repository provides comprehensive documentation and example smart contracts for DEX Router products, supporting both EVM and Solana ecosystems.

## Project Structure

```
docs/
  docs/
    contracts/
      DEX-Router-EVM-V1/
        guides.md
        overview.md
        technical-reference.md
      DEX-Router-Solana-V1/
        guides.md
        overview.md
        technical-reference.md
  examples/
    DEX-Router-EVM-V1/
      foundry.toml
      interface/
        IDexRouter.sol
        IDexRouterExactOut.sol
      remappings.txt
      src/
        smartswap.sol
        smartswapByInvest.sol
        swapWrap.sol
        uniswapV3swap.sol
        uniswapV3SwapExactOutTo.sol
        unxswap.sol
        unxswapExactOutTo.sol
    DEX-Router-Solana-V1/
```

- **docs/contracts/DEX-Router-EVM-V1/**: Documentation for the EVM version of the DEX Router, including overview, guides, and technical reference.
- **docs/contracts/DEX-Router-Solana-V1/**: Documentation for the Solana version of the DEX Router, including overview, guides, and technical reference.
- **examples/DEX-Router-EVM-V1/**: Example Solidity contracts and interfaces for the EVM DEX Router.
- **examples/DEX-Router-Solana-V1/**: (Reserved for Solana contract examples.)

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (for documentation tooling, if needed)
- [Foundry](https://book.getfoundry.sh/) (for Solidity contract development)
- [Solana CLI](https://docs.solana.com/cli/install-solana-cli-tools) (for Solana development, if needed)

### Usage

- Browse documentation in `docs/docs/contracts/` for both EVM and Solana routers.
- Explore example smart contracts in the `docs/examples/` directory.

## Contributing

We welcome contributions! Please follow these steps:

1. Pick the appropriate section for your addition (EVM or Solana, docs or examples).
2. Add new documentation under the correct folder:
   - `overview.md` for product overviews
   - `guides.md` for step-by-step guides
   - `technical-reference.md` for API and contract references
3. Add example contracts in the `examples/` directory.
4. Open a Pull Request with a clear description of your changes.

## License

[MIT](./LICENSE)