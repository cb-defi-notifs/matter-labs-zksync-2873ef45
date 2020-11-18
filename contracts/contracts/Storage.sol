// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./Governance.sol";
import "./Verifier.sol";
import "./Operations.sol";


/// @title zkSync storage contract
/// @author Matter Labs
contract Storage {

    /// @notice Flag indicates that upgrade preparation status is active
    /// @dev Will store false in case of not active upgrade mode
    bool public upgradePreparationActive;

    /// @notice Upgrade preparation activation timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint public upgradePreparationActivationTime;

    /// @dev Verifier contract. Used to verify block proof and exit proof
    Verifier public verifier;

    /// @dev Governance contract. Contains the governor (the owner) of whole system, validators list, possible tokens list
    Governance public governance;

    struct BalanceToWithdraw {
        uint128 balanceToWithdraw;
        uint8 gasReserveValue; // gives user opportunity to fill storage slot with nonzero value
    }

    /// @notice Root-chain balances (per owner and token id, see packAddressAndTokenId) to withdraw
    mapping(bytes22 => BalanceToWithdraw) public balancesToWithdraw;

    // @dev Pending withdrawals are not used in this version
    struct PendingWithdrawal_DEPRECATED {
        address to;
        uint16 tokenId;
    }
    mapping(uint32 => PendingWithdrawal_DEPRECATED) public pendingWithdrawals_DEPRECATED;
    uint32 public firstPendingWithdrawalIndex_DEPRECATED;
    uint32 public numberOfPendingWithdrawals_DEPRECATED;

    /// @notice Total number of verified blocks i.e. blocks[totalBlocksVerified] points at the latest verified block (block 0 is genesis)
    uint32 public totalBlocksVerified;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @Old rollup block stored data - not used in current version
    /// @member validator Block producer
    /// @member committedAtBlock ETH block number at which this block was committed
    /// @member cumulativeOnchainOperations Total number of operations in this and all previous blocks
    /// @member priorityOperations Total number of priority operations for this block
    /// @member commitment Hash of the block circuit commitment
    /// @member stateRoot New tree root hash
    ///
    /// Consider memory alignment when changing field order: https://solidity.readthedocs.io/en/v0.4.21/miscellaneous.html
    struct Block_DEPRECATED {
        uint32 committedAtBlock;
        uint64 priorityOperations;
        uint32 chunks;
        bytes32 withdrawalsDataHash; // can be restricted to 16 bytes to reduce number of required storage slots
        bytes32 commitment;
        bytes32 stateRoot;
    }
    mapping(uint32 => Block_DEPRECATED) public blocks_DEPRECATED;

    /// @notice Onchain operations - operations processed inside rollup blocks
    /// @member opType Onchain operation type
    /// @member amount Amount used in the operation
    /// @member pubData Operation pubdata
    struct OnchainOperation {
        Operations.OpType opType;
        bytes pubData;
    }

    /// @notice Flag indicates that a user has exited certain token balance (per account id and tokenId)
    mapping(uint32 => mapping(uint16 => bool)) public exited;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @notice Priority Operation container
    /// @member opType Priority operation type
    /// @member pubData Priority operation public data
    /// @member expirationBlock Expiration block number (ETH block) for this request (must be satisfied before)
    struct PriorityOperation {
        Operations.OpType opType;
        bytes pubData;
        uint256 expirationBlock;
    }

    /// @notice Priority Requests mapping (request id - operation)
    /// @dev Contains op type, pubdata and expiration block of unsatisfied requests.
    /// @dev Numbers are in order of requests receiving
    mapping(uint64 => PriorityOperation) public priorityRequests;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    /// @notice Packs address and token id into single word to use as a key in balances mapping
    function packAddressAndTokenId(address _address, uint16 _tokenId) internal pure returns (bytes22) {
        return bytes22((uint176(_address) | (uint176(_tokenId) << 160)));
    }

    /// @notice Gets value from balancesToWithdraw
    function getBalanceToWithdraw(address _address, uint16 _tokenId) public view returns (uint128) {
        return balancesToWithdraw[packAddressAndTokenId(_address, _tokenId)].balanceToWithdraw;
    }

    /// @Rollup block stored data - not used in current version
    struct StoredBlockInfo {
        uint32 blockNumber;
        uint64 priorityOperations;
        bytes32 processableOnchainOperationsHash;
        uint256 timestamp;
        bytes32 stateHash;
        bytes32 commitment;
    }

    /// @notice Hash StoredBlockInfo
    function hashStoredBlockInfo(StoredBlockInfo memory _storedBlockInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBlockInfo));
    }

    /// @notice Stored hashed StoredBlockInfo for some block number
    mapping(uint32 => bytes32) public hashedBlocks;

    /// @notice Stores verified commitments hashed in one slot.
    mapping(bytes32 => bool) public hashedVerifiedCommitments;
}
