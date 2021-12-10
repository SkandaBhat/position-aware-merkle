import hre from "hardhat";
import { MerklePosAwareTest } from "../typechain-types";
import { BytesLike, utils } from "ethers";
import { expect } from "chai";
import { createMerkle, getProofPath } from "../utils/MerklePosAware";

describe("Unit tests", function () {
  let Merkle: MerklePosAwareTest;

  before(async function () {
    Merkle = (await (
      await hre.ethers.getContractFactory("MerklePosAwareTest")
    ).deploy()) as unknown as MerklePosAwareTest;
  });

  describe("MerklePosAware", function () {
    it("Tree from 1 nodes to 11 nodes", async function () {
      const maxNodes = 11;
      const votes = [];
      for (let i = 1; i <= maxNodes; i++) {
        votes.push(i * 100);
      }
      // passed for 9 how ?
      // edge case of asset being 1
      for (let i = 1; i <= maxNodes; i++) {
        console.log(i);
        const votesThisItr = votes.slice(0, i);
        const tree = await createMerkle(votesThisItr);
        const proofs: BytesLike[][] = [];
        const assetIds = [];
        const leaves = [];
        const depth = Math.log2(i) % 1 === 0 ? Math.log2(i) : Math.ceil(Math.log2(i));
        for (let j = 0; j < i; j++) {
          const tree = await createMerkle(votesThisItr);
          proofs.push(getProofPath(tree, j + 1));
          leaves.push(utils.solidityKeccak256(["uint256"], [votes[j]]));
          assetIds.push(j + 1);
        }
        expect(await Merkle.verifyMultiple(proofs, tree[0][0], leaves, assetIds, depth, i)).to.be.true;
      }
    });
  });
});
