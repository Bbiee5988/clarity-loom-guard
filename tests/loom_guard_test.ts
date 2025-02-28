// [Previous test content remains, adding new tests]

Clarinet.test({
  name: "Contract pause functionality works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user = accounts.get('wallet_1')!;
    
    // Test pausing
    let block = chain.mineBlock([
      Tx.contractCall('loom-guard', 'toggle-contract-pause', [], deployer.address)
    ]);
    block.receipts[0].result.expectOk();
    
    // Try to register innovation while paused
    let pausedBlock = chain.mineBlock([
      Tx.contractCall('loom-guard', 'register-innovation', [
        types.utf8("Test Pattern"),
        types.utf8("Description"),
        types.buff('0x1234567890123456789012345678901234567890123456789012345678901234'),
        types.uint(500)
      ], user.address)
    ]);
    pausedBlock.receipts[0].result.expectErr(106); // err-contract-paused
  }
});

// [Additional tests for new functionality]
