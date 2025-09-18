
# Dexrouter - Aptos DEX Aggregator

Dexrouter is a decentralized exchange aggregator built on Aptos blockchain that provides optimal trading routes across multiple DEXs, ensuring users get the best prices for their trades.

## 🏗️ Project Architecture

### Core Components

- **Aggregator (`sources/aggregator.move`)** - Main aggregation logic and routing
- **Router (`sources/router.move`)** - DEX routing management and swap execution  
- **Proxy (`sources/proxy.move`)** - Security proxy and access control

### Supported DEX Adapters

**Currently Active:**
- ✅ Pontem Liquidswap (V1 & V2)
- ✅ PancakeSwap
- ✅ Cellana
- ✅ Hyperion

## 🚀 Quick Start

### 1. Initialize Account
```bash
aptos init --profile test_account
```

### 2. Compile Project
```bash
aptos move compile
```

### 3. Deploy Package
```bash
aptos move publish --package-dir . --profile test_account     
```

### 4. Initialize Router
```bash
aptos move run --function-id package_address::proxy::init  --profile test_account    
```

## 🔧 Configuration

### Package Configuration
Key settings in `Move.toml`:
- Package name: `dexrouter`
- Version: `2.0.0`
- Main address: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`
