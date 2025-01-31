[previous test content]

Clarinet.test({
  name: "Cannot pay royalties with expired license",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const licensee = accounts.get('wallet_1')!;
    const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
    
    let block = chain.mineBlock([
      Tx.contractCall('loom-guard', 'register-innovation', [
        types.utf8("Test Pattern"),
        types.utf8("A unique textile pattern"),
        types.buff(testHash),
        types.uint(500)
      ], deployer.address),
      Tx.contractCall('loom-guard', 'grant-license', [
        types.uint(1),
        types.principal(licensee.address),
        types.uint(10), // License expires after 10 blocks
        types.utf8("Standard usage terms")
      ], deployer.address)
    ]);

    // Mine 11 blocks to ensure license expires
    chain.mineEmptyBlockUntil(12);
    
    let paymentBlock = chain.mineBlock([
      Tx.contractCall('loom-guard', 'pay-royalty', [
        types.uint(1),
        types.uint(1000)
      ], licensee.address)
    ]);
    
    paymentBlock.receipts[0].result.expectErr(104); // err-expired-license
  }
});
