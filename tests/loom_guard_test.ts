import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can register new innovation with royalty rate",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
    
    let block = chain.mineBlock([
      Tx.contractCall('loom-guard', 'register-innovation', [
        types.utf8("Test Pattern"),
        types.utf8("A unique textile pattern"),
        types.buff(testHash),
        types.uint(500) // 5% royalty rate
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Can pay royalties for licensed innovation",
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
        types.uint(100),
        types.utf8("Standard usage terms")
      ], deployer.address),
      Tx.contractCall('loom-guard', 'pay-royalty', [
        types.uint(1),
        types.uint(1000)
      ], licensee.address)
    ]);
    
    block.receipts[2].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Can transfer ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const testHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
    
    let block = chain.mineBlock([
      Tx.contractCall('loom-guard', 'register-innovation', [
        types.utf8("Test Pattern"),
        types.utf8("A unique textile pattern"),
        types.buff(testHash),
        types.uint(500)
      ], deployer.address),
      Tx.contractCall('loom-guard', 'transfer-ownership', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk().expectBool(true);
    
    let verifyBlock = chain.mineBlock([
      Tx.contractCall('loom-guard', 'verify-ownership', [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    verifyBlock.receipts[0].result.expectOk().expectBool(true);
  }
});
