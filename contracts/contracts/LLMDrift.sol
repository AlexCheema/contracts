// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IOracle {
    function createLlmCall(
        uint promptId
    ) external returns (uint);

    function createFunctionCall(
        uint functionCallbackId,
        string memory functionType,
        string memory functionInput
    ) external returns (uint i);
}

interface IBenchmark {
    function prompt() external view returns (string memory);
    function evaluate(string memory prompt, string memory response) external view returns (uint32);
    function description() external view returns (string memory);
    function id() external view returns (string memory);
}

struct BenchmarkRun {
    string prompt;
    string response;
    uint32 score;
    uint32 blockTimestamp;
}
struct BenchmarkResults {
    BenchmarkRun[] runs;
    uint64 scoreSum;
}
struct BenchmarkGroup {
    string name;
    string description;
    IBenchmark[] benchmarks;
    BenchmarkResults results;
}

contract LLMDrift {
    BenchmarkGroup[] benchmarkGroups;

    address private owner;
    address public oracleAddress;

    event OracleAddressUpdated(address indexed newOracleAddress);
    event BenchmarkResultAdded(uint benchmarkGroupId, string prompt, string response, uint32 score, uint32 blockTimestamp, uint64 scoreSum);

    constructor(
        address initialOracleAddress
    ) {
        owner = msg.sender;
        oracleAddress = initialOracleAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not oracle");
        _;
    }

    function setOracleAddress(address newOracleAddress) public onlyOwner {
        oracleAddress = newOracleAddress;
        emit OracleAddressUpdated(newOracleAddress);
    }

    function addPrimeBenchmarks() public onlyOwner {
        IBenchmark primeBenchmark7 = new PrimeBenchmark(7, true);
        IBenchmark primeBenchmark8 = new PrimeBenchmark(8, false);
        IBenchmark primeBenchmark11 = new PrimeBenchmark(11, true);
        IBenchmark primeBenchmark13 = new PrimeBenchmark(13, true);
        IBenchmark primeBenchmark12421 = new PrimeBenchmark(12421, true);
        IBenchmark primeBenchmark51763 = new PrimeBenchmark(51763, false);
        IBenchmark primeBenchmark86677 = new PrimeBenchmark(86677, true);

        // Create a new BenchmarkGroup directly in storage
        BenchmarkGroup storage newGroup = benchmarkGroups.push();

        // Initialize the BenchmarkResults struct within the new storage element
        newGroup.name = "Prime";
        newGroup.description = "Test the LLMs ability to check if a number is prime.";
        newGroup.results.scoreSum = 0;

        // Allocate space for benchmarks in storage
        newGroup.benchmarks.push(primeBenchmark7);
        newGroup.benchmarks.push(primeBenchmark8);
        newGroup.benchmarks.push(primeBenchmark11);
        newGroup.benchmarks.push(primeBenchmark13);
        newGroup.benchmarks.push(primeBenchmark12421);
        newGroup.benchmarks.push(primeBenchmark51763);
        newGroup.benchmarks.push(primeBenchmark86677);
    }


    function addBenchmarkGroup(BenchmarkGroup calldata benchmarkGroup) public onlyOwner {
        benchmarkGroups.push(benchmarkGroup);
    }
    function getBenchmarkGroups() public view returns (BenchmarkGroup[] memory) {
        return benchmarkGroups;
    }

    function onOracleLlmResponse(
        uint promptId,
        string memory response,
        string memory errorMessage
    ) public onlyOracle {
        uint i = promptId / 2153;
        uint j = promptId % 2153;

        IBenchmark benchmark = benchmarkGroups[i].benchmarks[j];

        uint32 score = benchmark.evaluate(benchmark.prompt(), response);

        BenchmarkRun memory newRun = BenchmarkRun(benchmark.prompt(), response, score, uint32(block.timestamp));
        benchmarkGroups[i].results.runs.push(newRun);
        benchmarkGroups[i].results.scoreSum += score;
    }

    function getSystemPrompt() public view returns (string memory) {
        return "You are a helpful assistant.";
    }

    function getMessageHistoryContents(uint chatId) public view returns (string[] memory) {
        string[] memory messages = new string[](1);

        uint i = chatId / 2153;
        uint j = chatId % 2153;

        messages[0] = benchmarkGroups[i].benchmarks[j].prompt();

        return messages;
    }

    function getMessageHistoryRoles(uint chatId) public view returns (string[] memory) {
        string[] memory messages = new string[](1);
        messages[0] = "user";
        return messages;
    }

    function fireBenchmarks() public returns (bool) {
        for (uint i = 0; i < benchmarkGroups.length; i++) {
            BenchmarkGroup memory group = benchmarkGroups[i];
            for (uint j = 0; j < group.benchmarks.length; j++) {
                IOracle(oracleAddress).createLlmCall(2153 * i + j);
            }
        }

        return false;
    }
}

contract PrimeBenchmark is IBenchmark {
    uint32 private n;
    bool private isPrime;

    constructor(uint32 _n, bool _isPrime) {
        n = _n;
        isPrime = _isPrime;
    }

    function prompt() external view override returns (string memory) {
        return string(abi.encodePacked("Is ", uintToString(n), " a prime number? Think step by step and then answer \"[Yes]\" or \"[No]\"."));
    }

    function description() external view override returns (string memory) {
        return string(abi.encodePacked("Evaluates the LLM to check that ", uintToString(n), isPrime ? " is" : " is not", " prime."));
    }

    function id() external view override returns (string memory) {
        return string(abi.encodePacked("PrimeBenchmark", uintToString(n), isPrime ? "Is" : "IsNot", "Prime"));
    }

    function evaluate(string memory prompt, string memory response) external view override returns (uint32) {
        bool containsYes = contains(response, "[Yes]");
        bool containsNo = contains(response, "[No]");

        if (isPrime && containsYes && !containsNo) {
            return 100;
        }
        if (!isPrime && containsNo && !containsYes) {
            return 100;
        }

        return 0;
    }

    function uintToString(uint v) private pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function contains(string memory haystack, string memory needle) private pure returns (bool) {
        bytes memory b = bytes(haystack);
        bytes memory a = bytes(needle);
        if(a.length > b.length) {
            return false;
        }
        for(uint i = 0; i <= b.length - a.length; i++) {
            bool found = true;
            for(uint j = 0; j < a.length; j++) {
                if(b[i + j] != a[j]) {
                    found = false;
                    break;
                }
            }
            if(found) {
                return true;
            }
        }
        return false;
    }
}

contract CountingHappyNumbersBenchmark is IBenchmark {
    uint public startN;
    uint public endN;
    uint public numHappyNumbers;

    constructor(uint _startN, uint _endN, uint _numHappyNumbers) {
        startN = _startN;
        endN = _endN;
        numHappyNumbers = _numHappyNumbers;
    }

    function prompt() public view returns (string memory) {
        return string(abi.encodePacked("How many happy numbers are there between ", uintToString(startN), " and ", uintToString(endN), "? Think step by step and then answer within \"\\boxed\" (e.g, \\boxed{10})."));
    }

    function description() external view override returns (string memory) {
        return string(abi.encodePacked("Evaluates the LLM to count the number of happy numbers between ", uintToString(startN), " and ", uintToString(endN), "."));
    }

    function id() external view override returns (string memory) {
        return string(abi.encodePacked("CountingHappyNumbersBenchmark", uintToString(startN), "To", uintToString(endN), "Is", uintToString(numHappyNumbers)));
    }

    function evaluate(string memory prompt, string memory response) public view returns (uint32) {
        if (contains(response, string(abi.encodePacked("\\boxed{", uintToString(numHappyNumbers), "}")))) {
            return 100;
        }
        return 0;
    }

    function uintToString(uint v) private pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function contains(string memory haystack, string memory needle) private pure returns (bool) {
        bytes memory b = bytes(haystack);
        bytes memory a = bytes(needle);
        if(a.length > b.length) {
            return false;
        }
        for(uint i = 0; i <= b.length - a.length; i++) {
            bool found = true;
            for(uint j = 0; j < a.length; j++) {
                if(b[i + j] != a[j]) {
                    found = false;
                    break;
                }
            }
            if(found) {
                return true;
            }
        }
        return false;
    }
}
