import {loadFixture,} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";
import { IBenchmark, PrimeBenchmark__factory } from "../typechain-types";

interface BenchmarkTests {
  desc: string;
  contractName: string;
  deployArgs: any[];
  tableTests: Array<PromptTestCase | EvaluateTestCase | IdTestCase | DescriptionTestCase>;
}
interface PromptTestCase {
  desc: string;
  expectedPrompt: string;
}
interface DescriptionTestCase {
  desc: string;
  expectedDescription: string;
}
interface IdTestCase {
  desc: string;
  expectedId: string;
}
interface EvaluateTestCase {
  desc: string;
  prompt: string;
  response: string;
  expectedScore: number;
}



const tests: BenchmarkTests[] = [
  {
    desc: "Test a prime number",
    contractName: "PrimeBenchmark",
    deployArgs: [11, true],
    tableTests: [
      {
        desc: "prompt correct",

        expectedPrompt: `Is ${11} a prime number? Think step by step and then answer "[Yes]" or "[No]".`
      },
      {
        desc: "description correct",

        expectedDescription: `Evaluates the LLM to check that ${11} is prime.`
      },
      {
        desc: "id correct",

        expectedId: `PrimeBenchmark${11}IsPrime`
      },
      {
        desc: "Exact [Yes] gives 100",

        prompt: "",
        response: "[Yes]",

        expectedScore: 100,
      },
      {
        desc: "Exact [No] gives 0",

        prompt: "",
        response: "[No]",

        expectedScore: 0,
      },
      {
        desc: "Both [Yes] and [No] gives 0",

        prompt: "",
        response: "[Yes] [No]",

        expectedScore: 0,
      },
      {
        desc: "Empty string gives 0",

        prompt: "",
        response: "",

        expectedScore: 0,
      },
      {
        desc: "Gibberish gives 0",

        prompt: "",
        response: "[gibberish][]",

        expectedScore: 0,
      },
    ]
  },
  {
    desc: "Test a prime number",
    contractName: "CountingHappyNumbersBenchmark",
    deployArgs: [3904, 3912, 2],
    tableTests: [
      {
        desc: "prompt correct",

        expectedPrompt: `How many happy numbers are there between ${3904} and ${3912}? Think step by step and then answer within "\\boxed" (e.g, \\boxed{10}).`
      },
      {
        desc: "description correct",

        expectedDescription: `Evaluates the LLM to count the number of happy numbers between ${3904} and ${3912}.`
      },
      {
        desc: "id correct",

        expectedId: `CountingHappyNumbersBenchmark${3904}To${3912}Is${2}`
      },
      {
        desc: "Correct answer with \\boxed gives score 100",

        prompt: "",
        response: "\\boxed{2}",

        expectedScore: 100,
      },
      {
        desc: "Correct \\boxed with other stuff around it gives score 100",

        prompt: "",
        response: "dwajsi\\boxed{2}fjsdkljfkdslj2 h u21j ",

        expectedScore: 100,
      },
      {
        desc: "Incorrect answer with \\boxed gives score 0",

        prompt: "",
        response: "\\boxed{23}",

        expectedScore: 0,
      },
      {
        desc: "Empty string gives 0",

        prompt: "",
        response: "",

        expectedScore: 0,
      },
      {
        desc: "Gibberish gives 0",

        prompt: "",
        response: "[gibberish]\\box\\boxed{[]",

        expectedScore: 0,
      },
    ]
  }
]

describe("LLMDrift", () => {

  for (const t of tests) {
    const { desc, contractName, deployArgs, tableTests } = t;
    describe(`[Contract: ${contractName}] ${desc}`, () => {
      // We define a fixture to reuse the same setup in every test.
      // We use loadFixture to run this setup once, snapshot that state,
      // and reset Hardhat Network to that snapshot in every test.
      async function deploy() {
        // Contracts are deployed using the first signer/account by default
        const allSigners = await ethers.getSigners();
        const owner = allSigners[0];

        const TBenchmark = await ethers.getContractFactory(contractName);
        const benchmark = (await TBenchmark.deploy(...deployArgs)) as IBenchmark;

        return {benchmark, owner, allSigners};
      }

      for (const tc of tableTests) {
        it(`${tc.desc}`, async () => {
          const {benchmark, owner, allSigners} = await loadFixture(deploy);

          if ("expectedPrompt" in tc) {
            expect(await benchmark.prompt()).to.equal(tc.expectedPrompt);
          }

          if ("expectedDescription" in tc) {
            expect(await benchmark.description()).to.equal(tc.expectedDescription);
          }

          if ("prompt" in tc) {
            expect(await benchmark.evaluate(tc.prompt, tc.response)).to.equal(tc.expectedScore);
          }
        });
      }
    })
  }

  describe("Integration", function () {
      // We define a fixture to reuse the same setup in every test.
      // We use loadFixture to run this setup once, snapshot that state,
      // and reset Hardhat Network to that snapshot in every test.
      async function deploy() {
        // Contracts are deployed using the first signer/account by default
        const allSigners = await ethers.getSigners();
        const owner = allSigners[0];

        const AgentOracle = await ethers.getContractFactory("ChatOracle");
        const oracle = await AgentOracle.deploy();
        // Add owner to whitelist for these tests
        await oracle.updateWhitelist(owner.address, true);

        const LLMDrift = await ethers.getContractFactory("LLMDrift");
        const llmDrift = (await LLMDrift.deploy(oracle.target));

        return {llmDrift, oracle, owner, allSigners};
      }

    it("should run benchmarks", async () => {
      const {llmDrift, oracle, owner, allSigners} = await loadFixture(deploy);

        const TBenchmark = await ethers.getContractFactory("PrimeBenchmark");
        const prime11Benchmark = (await TBenchmark.deploy(11, true)) as IBenchmark;
        const prime12Benchmark = (await TBenchmark.deploy(12, false)) as IBenchmark;

        await llmDrift.addBenchmarkGroup({
          name: "test",
          description: "test benchmark group",
          benchmarks: [
            await prime11Benchmark.getAddress(),
            await prime12Benchmark.getAddress(),
          ],
          results: {
            runs: [],
            scoreSum: 0
          }
        })

        await llmDrift.fireBenchmarks();

        const oracleAccount = allSigners[6];
        await oracle.updateWhitelist(oracleAccount, true);

        await oracle.connect(oracleAccount).addResponse(0, 0, "[Yes]", "");

        let bgs = await llmDrift.getBenchmarkGroups();
        expect(bgs).to.have.length(1);
        expect(bgs[0].results.runs).to.have.length(1);
        expect(bgs[0].results.scoreSum).to.equal(100n);
        expect(bgs[0].results.runs[0].prompt).to.equal(`Is 11 a prime number? Think step by step and then answer "[Yes]" or "[No]".`);
        expect(bgs[0].results.runs[0].response).to.equal(`[Yes]`);
        expect(bgs[0].results.runs[0].score).to.equal(100n);
        expect(bgs[0].results.runs[0].blockTimestamp).to.be.greaterThan(1710630414n);

        await oracle.connect(oracleAccount).addResponse(1, 1, "[No]", "");
        bgs = await llmDrift.getBenchmarkGroups();
        expect(bgs).to.have.length(1);
        expect(bgs[0].results.runs).to.have.length(2);
        expect(bgs[0].results.scoreSum).to.equal(200n);
        expect(bgs[0].results.runs[1].prompt).to.equal(`Is 12 a prime number? Think step by step and then answer "[Yes]" or "[No]".`);
        expect(bgs[0].results.runs[1].response).to.equal(`[No]`);
        expect(bgs[0].results.runs[1].score).to.equal(100n);
        expect(bgs[0].results.runs[1].blockTimestamp).to.be.greaterThan(1710630414n);

        await llmDrift.addPrimeBenchmarks();
        bgs = await llmDrift.getBenchmarkGroups();
        expect(bgs).to.have.length(2);
        expect(bgs[1].benchmarks).to.have.length(7);
    });
  });

});