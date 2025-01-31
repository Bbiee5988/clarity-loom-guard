# LoomGuard

A secure blockchain-based system for managing and protecting textile innovations. LoomGuard provides a way to register, track, and verify textile designs, patterns, and technical innovations on the Stacks blockchain.

## Features
- Register new textile innovations with proof of ownership
- Track innovation history and modifications 
- Manage licensing and usage rights
- Verify authenticity of registered designs
- Transfer ownership of innovations
- Set and track royalty payments for licensed innovations
- Automated royalty payment tracking and history
- License expiration enforcement for royalty payments

## Getting Started
1. Clone the repository
2. Install dependencies with `clarinet install`
3. Run tests with `clarinet test`

## Royalty System
The royalty tracking system allows innovation owners to:
- Set royalty rates during innovation registration
- Track royalty payments from licensees
- View payment history and total royalties received
- Automatically record all royalty transactions on-chain
- Prevent royalty payments for expired licenses

## License Management
The system now includes automatic license expiration checks:
- Licenses have a specified expiration date in block height
- Royalty payments are automatically rejected for expired licenses
- Active license status is verified before processing payments
