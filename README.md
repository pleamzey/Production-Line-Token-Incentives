# 🏭 Production Line Token Incentives

A Clarity smart contract that rewards production line workers with tokens for hitting efficiency and quality KPIs, with automated verification.

## 🎯 Features

- **Worker Registration**: Register production line workers on-chain
- **KPI Management**: Create and manage Key Performance Indicators
- **Automated Rewards**: Workers earn efficiency tokens for meeting targets
- **Performance Tracking**: Daily stats tracking for efficiency, quality, and productivity
- **Achievement System**: Record and verify worker achievements
- **Token Economy**: Fungible token system for micro-rewards

## 🚀 Quick Start

### Prerequisites
- Clarinet installed
- Stacks wallet for testing

### Setup
```bash
git clone <repository-url>
cd Production-Line-Token-Incentives
clarinet check
```

## 📋 Contract Functions

### 👥 Worker Management
- `register-worker(worker-address)` - Register a new worker
- `deactivate-worker(worker-id)` - Deactivate a worker
- `get-worker(worker-id)` - Get worker details
- `get-worker-by-address(address)` - Find worker by address

### 📊 KPI Management  
- `create-kpi(name, reward-amount, verification-threshold)` - Create new KPI
- `deactivate-kpi(kpi-id)` - Deactivate a KPI
- `get-kpi(kpi-id)` - Get KPI details

### 🏆 Achievement System
- `record-achievement(worker-id, kpi-id, score)` - Record worker achievement
- `verify-achievement(worker-id, kpi-id, achievement-block)` - Verify achievement
- `claim-reward(worker-id, kpi-id, achievement-block)` - Claim token reward
- `batch-verify-achievements(achievements)` - Bulk verify achievements

### 📈 Performance Tracking
- `update-daily-stats(worker-id, efficiency-score, quality-score, tasks-completed)` - Update daily performance
- `get-daily-stats(worker-id, day)` - Get daily performance stats
- `calculate-worker-efficiency(worker-id, days-back)` - Calculate efficiency over time
- `get-worker-performance-summary(worker-id)` - Get comprehensive performance summary

### 💰 Token Operations
- `transfer-tokens(recipient, amount)` - Transfer efficiency tokens
- `fund-reward-pool(amount)` - Add funds to reward pool
- `get-token-balance(address)` - Check token balance

## 🔧 Usage Examples

### Register a Worker
```clarity
(contract-call? .Production-Line-Token-Incentives register-worker 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Create a KPI
```clarity
(contract-call? .Production-Line-Token-Incentives create-kpi "Daily Efficiency Target" u50 u75)
```

### Record Achievement
```clarity
(contract-call? .Production-Line-Token-Incentives record-achievement u1 u1 u85)
```

### Update Daily Stats
```clarity
(contract-call? .Production-Line-Token-Incentives update-daily-stats u1 u88 u92 u12)
```

## 💡 Reward System

### Automatic Daily Bonuses
- **Efficiency ≥ 80%**: 10 tokens
- **Quality ≥ 90%**: 15 tokens  
- **Tasks ≥ 10**: 5 tokens

### KPI Achievements
- Custom rewards based on KPI targets
- Manual verification required before claiming
- Prevents double-claiming

## 🛡️ Security Features

- Owner-only administrative functions
- Achievement verification system
- Reward pool management
- Worker deactivation capabilities
- Emergency pause functionality

## 📊 Data Structures

### Worker Profile
- Address and ID mapping
- Total tokens earned
- Active status
- Registration block

### KPI Definition
- Name and reward amount
- Verification threshold
- Creator and active status

### Achievement Record
- Score and verification status
- Block height timestamp
- Claim status tracking

## 🔍 Contract Info

Get contract statistics:
```clarity
(contract-call? .Production-Line-Token-Incentives get-contract-info)
```

Returns:
- Total registered workers
- Total active KPIs
- Current reward pool balance
- Contract owner address

## 🧪 Testing

Run contract tests:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📜 License

MIT License - see LICENSE file for details
