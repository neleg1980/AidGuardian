# AidGuardian

A decentralized aid distribution protocol built on Stacks blockchain using Clarity smart contracts.

## Overview

AidGuardian is a transparent and equitable platform designed to streamline crisis response and aid distribution through blockchain technology. The protocol enables secure fund management, democratic decision-making, and verified aid distribution to beneficiaries.

## Key Features

- **Decentralized Aid Pool**: Secure collection and management of contributions
- **Crisis Management**: Systematic registration and tracking of crisis events
- **Beneficiary Verification**: Multi-step validation process for aid recipients
- **Democratic Aid Distribution**: Community-driven aid plan proposals and voting
- **Guardian NFTs**: Proof of contribution and governance rights
- **Transparent Fund Allocation**: Trackable aid distribution and usage

## Smart Contract Architecture

### Core Components

1. **Contribution System**
   - Minimum contribution threshold
   - Automatic Guardian NFT minting
   - Transparent fund pooling

2. **Crisis Registry**
   - Crisis event registration
   - Urgency level tracking
   - Aid requirement assessment
   - Status monitoring

3. **Beneficiary Management**
   - Secure registration process
   - Multi-validator verification system
   - Impact assessment scoring
   - Encrypted personal data handling

4. **Aid Distribution**
   - Community-proposed aid plans
   - Democratic voting system
   - Weighted voting based on contribution
   - Execution tracking

5. **Guardian NFT System**
   - Proof of contribution
   - Voting power allocation
   - Transferable governance rights

## Getting Started

### Prerequisites

- Stacks blockchain environment
- Clarity smart contract deployment tools
- Web3 wallet compatible with Stacks

### Contract Deployment

1. Clone the repository
2. Configure deployment parameters in `constants`
3. Deploy using Stacks CLI:
```bash
stacks deploy aid-guardian.clar
```

### Initialization

After deployment, the contract requires:
1. Setting up initial admin address
2. Configuring minimum contribution amounts
3. Establishing validation requirements
4. Registering initial trusted validators

## Usage

### For Contributors

```clarity
;; Make a contribution
(contract-call? .aid-guardian contribute)

;; Support an aid plan
(contract-call? .aid-guardian support-aid-plan crisis-id)
```

### For Administrators

```clarity
;; Register new crisis
(contract-call? .aid-guardian register-crisis "Crisis Name" urgency-level aid-needed)

;; Authorize validators
(contract-call? .aid-guardian authorize-validator validator-address)
```

### For Beneficiaries

```clarity
;; Register as beneficiary
(contract-call? .aid-guardian register-beneficiary crisis-id region-data impact-score secure-data validation-data)
```

### For Validators

```clarity
;; Validate beneficiary
(contract-call? .aid-guardian validate-beneficiary beneficiary-id)
```

## Security Considerations

- Multi-validator requirement for beneficiary verification
- Encrypted storage of sensitive information
- Admin-only access for critical functions
- Threshold-based voting system
- Guardian token transfer restrictions

## Error Handling

The contract includes comprehensive error handling for:
- Unauthorized access attempts
- Insufficient funds
- Invalid operations
- Duplicate registrations
- Verification failures

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Testing

Run the test suite:
```bash
clarity-cli test aid-guardian-tests.clar
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions and support, please open an issue in the repository.

## Acknowledgments

- Stacks blockchain community
- Clarity smart contract developers
- Humanitarian aid organizations for requirements consultation

## Roadmap

### Phase 1: Core Implementation
- [x] Basic contract deployment
- [x] Contribution system
- [x] Guardian NFT implementation

### Phase 2: Enhancement
- [ ] Advanced validation mechanisms
- [ ] Integration with external oracles
- [ ] Enhanced reporting system

### Phase 3: Scaling
- [ ] Cross-chain compatibility
- [ ] Advanced governance features
- [ ] Mobile app integration