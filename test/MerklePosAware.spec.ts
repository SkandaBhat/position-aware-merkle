import hre from "hardhat";
import { MerklePosAwareTest } from "../typechain-types";
import { BytesLike, utils } from "ethers";

let tree: BytesLike[][] = [];

const createMerkle = async (values: number[]) => {
  tree = [];
  const leafs: string[] = [];
  // Hash all values
  for (let i = 0; i < values.length; i++) {
    leafs.push(utils.solidityKeccak256(["uint256"], [values[i]]));
  }

  let level: string[] = leafs;
  let nextLevel = [];
  tree.push(level);

  while (level.length !== 1) {
    for (let i = 0; i < level.length; i += 2) {
      if (i + 1 < level.length) {
        nextLevel.push(utils.solidityKeccak256(["bytes32", "bytes32"], [level[i], level[i + 1]]));
      } else nextLevel.push(level[i]);
    }
    level = nextLevel;
    tree.push(level);
    nextLevel = [];
  }
  tree = tree.reverse();
};

function getProofPath(assetId: number) {
  let index = assetId - 1;
  const compactProofPath: BytesLike[] = [];
  for (let currentLevel = tree.length - 1; currentLevel > 0; currentLevel--) {
    const currentLevelNodes = tree[currentLevel];
    const currentLevelCount = currentLevelNodes.length;

    // if this is an odd end node to be promoted up, skip to avoid proofs with null values
    if (index === currentLevelCount - 1 && currentLevelCount % 2 === 1) {
      index = Math.floor(index / 2);
      // eslint-disable-next-line no-continue
      continue;
    }

    const nodes: { left: BytesLike; right: BytesLike } = { left: "0", right: "0" };
    if (index % 2) {
      // the index is the right node
      nodes.left = currentLevelNodes[index - 1];
      nodes.right = currentLevelNodes[index];
      compactProofPath.push(nodes.left);
    } else {
      nodes.left = currentLevelNodes[index];
      nodes.right = currentLevelNodes[index + 1];
      compactProofPath.push(nodes.right);
    }

    index = Math.floor(index / 2); // set index to the parent index
  }
  return compactProofPath;
}

describe("Unit tests", function () {
  let Merkle: MerklePosAwareTest;

  before(async function () {
    Merkle = (await (
      await hre.ethers.getContractFactory("MerklePosAwareTest")
    ).deploy()) as unknown as MerklePosAwareTest;
  });

  describe("Merkle", function () {
    it("Tree from 2 nodes to 11 nodes", async function () {
      const votes = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 100];
      // passed for 9 how ?
      // edge case of asset being 1
      for (let i = 2; i <= 11; i++) {
        const votesThisItr = votes.slice(0, i);
        console.log("Tree of", i, votesThisItr);
        // const votesThisItr = votes.slice(0, i);
        await createMerkle(votesThisItr);

        const proofs: BytesLike[][] = [];
        const assetIds = [];
        const leaves = [];
        const depth = Math.log2(i) % 1 === 0 ? Math.log2(i) : Math.ceil(Math.log2(i));
        /// /console.log('depth', depth);
        /// /console.log(getProofPath(6, true, true));
        for (let j = 0; j < i; j++) {
          proofs.push(getProofPath(j + 1));
          leaves.push(utils.solidityKeccak256(["uint256"], [votes[j]]));
          assetIds.push(j + 1);
        }
        //console.log(proofs, leaves, assetIds);
        // console.log(proofs);
        // console.log('maxAssets', i);
        console.log(await Merkle.verifyMultiple(proofs, tree[0][0], leaves, assetIds, depth, i));
      }
    });
  });
});
