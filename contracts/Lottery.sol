// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

/**
* @title  Random Number Generator
* @author Carson Case (carsonpcase@gmail.com)
* @dev creates a random number based off a nonce. Must wait a block vest period to get the number,
* as randomness comes from future blockhashes. NOTE the longer the block vesting period, the more secure
*/
contract RandomNumberGenerator{

    uint internal BLOCK_VEST_PERIOD;

    struct guess{
        bytes32 guess;
        uint128 blockSubmited;
        uint128 vestEnd;
    }

    mapping(address => guess) entry;

    /**
    * @param _blockVestPeriod see function `setVestPeriod`
     */
    constructor(uint _blockVestPeriod){
        setVestPeriod(_blockVestPeriod);
    }

    /**
    * @dev submit an entry, and block vest number of blocks later you can claim it. Entries are tied to addresses
    * @param _x is the nonce used in case multiple entries are submitted in one block
     */
    function submitEntry(uint _x) external virtual{
        entry[msg.sender] = guess(
            {guess: keccak256(abi.encodePacked(_x)),           //guess is stored as the hash of the number entry
            blockSubmited: uint128(block.number),
            vestEnd: uint128(block.number + BLOCK_VEST_PERIOD)}
        );
    }

    /**
    * @dev getRandomNum returns a random number based off the guess and blocks passed
    * @return a random 256b number
    */
    function getRandomNum()external virtual returns(uint){
        guess memory _entry = entry[msg.sender];
        require(_entry.vestEnd != 0, "No entry recorded");
        require(block.number >= _entry.vestEnd && block.number - _entry.vestEnd < 256, "cannot claimEntry if less than vest period or more than 255 blocks have passed");

        //First reset the entry
        entry[msg.sender] = guess(0,0,0);

        bytes32 hash = _entry.guess;
        // Hash from most recent to oldest so miners have as little controll as possible
        for(uint128 i = 0; i < BLOCK_VEST_PERIOD; i++){
            hash = keccak256(abi.encodePacked(
                hash,
                blockhash(_entry.vestEnd - i)
                ));
        }

        return(uint(hash));
    }

    /**
    * @param _blockVestPeriod period between submit entry and getRandomNum. The larger this is the more secure the random generation is
     */

    function setVestPeriod(uint _blockVestPeriod) internal virtual{
        require(_blockVestPeriod < 256, "Vest period cannot be greater than 255");
        BLOCK_VEST_PERIOD = _blockVestPeriod;
    }

}