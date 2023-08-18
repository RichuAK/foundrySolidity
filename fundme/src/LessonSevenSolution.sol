// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LessonSeven {
    function solveChallenge(
        uint256 valueAtStorageLocationSevenSevenSeven,
        string memory yourTwitterHandle
    ) external {}
}

contract LessonSevenSolution {
    function solveLessonSeven() public {
        uint256 value = uint256(
            readStorage(0xD7D127991c6A89Df752FC3daeC17540aE8B86101, 777)
        );
        LessonSeven lessonSeven = LessonSeven(
            0xD7D127991c6A89Df752FC3daeC17540aE8B86101
        );
        // assembly {
        //     value := sload(777)
        // }
        lessonSeven.solveChallenge(value, "richuak");
    }

    function readStorage(
        address _target,
        uint256 _location
    ) public view returns (bytes32) {
        bytes32 result;

        assembly {
            // Get the code hash of the target contract
            let codeHash := extcodehash(_target)

            // If the code hash is zero, the contract doesn't exist or has no code
            if iszero(codeHash) {
                revert(0, 0)
            }

            // Copy the contract's code to memory
            let codeSize := extcodesize(_target)
            let codeBuffer := mload(0x40) // Get empty storage location
            extcodecopy(_target, add(codeBuffer, 0x20), 0, codeSize)

            // Calculate the storage slot using the transformed _location
            let slot := div(_location, 32)

            // Load the storage variable from the contract's storage
            result := sload(add(codeBuffer, slot))
        }

        return result;
    }

    // function readStorage(address _target, uint256 _location) public view returns (uint256) {
    //     uint256 result;

    //     assembly {
    //         // Calculate the storage slot using the keccak256 hash of the _location and _target
    //         let slot := keccak256(abi.encodePacked(_target, _location))

    //         // Load the storage variable from the calculated slot of the target contract
    //         result := sload(slot)
    //     }

    //     return result;
    // }
}
