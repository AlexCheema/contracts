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
    function evaluate(string memory prompt, string memory response) external view returns (uint);
    function description() external view returns (string memory);
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

    function evaluate(string memory prompt, string memory response) external view override returns (uint) {
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
