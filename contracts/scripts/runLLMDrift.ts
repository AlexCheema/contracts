const addPrimeBenchmarks = process.env.ADD_PRIME_BENCHMARKS == "true";
const addCountingHappyNumbersBenchmarks = process.env.ADD_COUNTING_HAPPY_NUMBERS_BENCHMARKS == "true";
const fireBenchmarks = process.env.FIRE_BENCHMARKS == "true";


async function runLLMDrift() {
    // const oracleContractAddress = "0xACB8a1fcC06f1a199C1782414E39BdB4A8238e69";
    const llmDriftContractAddress = "0xc38Dc0b25E3Ad903C3620E3005765c6c2D95710C";
    const llmDriftContractABI = [
        "function fireBenchmarks()",
        "event BenchmarkResultAdded(uint benchmarkGroupId, string prompt, string response, uint32 score, uint32 blockTimestamp, uint64 scoreSum)",
        "function getBenchmarkGroups() external view returns ((string name, string description, address[] benchmarks,((string prompt, string response, uint32 score, uint32 blockTimestamp)[] runs, uint64 scoreSum) results)[])",
        "function addPrimeBenchmarks()",
        "function addCountingHappyNumbersBenchmarks()",
    ];

    const [signer] = await ethers.getSigners();

    const llmDriftContract = new ethers.Contract(llmDriftContractAddress, llmDriftContractABI, signer);

    if (addPrimeBenchmarks) {
        const txResponse1 = await llmDriftContract.addPrimeBenchmarks();
        const receipt1 = await txResponse1.wait();
        console.log(`Add benchmark group tx, hash: ${receipt1.hash}.\nExplorer: https://explorer.galadriel.com/transaction/${receipt1.hash}`)
    }

    if (addCountingHappyNumbersBenchmarks) {
        const txResponse2 = await llmDriftContract.addCountingHappyNumbersBenchmarks();
        const receipt2 = await txResponse2.wait();
        console.log(`Add benchmark group tx, hash: ${receipt2.hash}.\nExplorer: https://explorer.galadriel.com/transaction/${receipt2.hash}`)
    }

    if (fireBenchmarks) {
        const txResponse3 = await llmDriftContract.fireBenchmarks();
        const receipt3 = await txResponse3.wait();
        console.log(`Fire benchmarks tx, hash: ${receipt3.hash}.\nExplorer: https://explorer.galadriel.com/transaction/${receipt3.hash}`)
    }

    // console.log(llmDriftContract.filters.BenchmarkResultAdded());
    const filter = llmDriftContract.filters.BenchmarkResultAdded();
    const logs = await llmDriftContract.queryFilter(filter);
    for (const log of logs) {
        const result = llmDriftContract.interface.parseLog(log);
        console.log(result);
    }


    while (true) {
        const bgs = await llmDriftContract.getBenchmarkGroups();
        for (const bg of bgs) {
            console.log(`Name: ${bg.name}`);
            console.log(`Description: ${bg.description}`);
            console.log(`Score sum: ${bg.results.scoreSum}`)
            console.log(`Runs: ${bg.results.runs.length}`)
            const accuracy = Number(bg.results.scoreSum) / bg.results.runs.length;
            const roundedAccuracy = Math.round(accuracy * 100) / 100;
            console.log(`Accuracy: ${roundedAccuracy}%`);

            for (const run of bg.results.runs) {
                console.log(`Run prompt: ${run.prompt}`)
                console.log(`Run response: ${run.response}`)
                console.log(`Run score: ${run.score}`)
                console.log(`Run timestamp: ${run.blockTimestamp}`)
            }
        }
        await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    // console.log("Fired benchmarks", transactionResponse);
}

runLLMDrift()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
