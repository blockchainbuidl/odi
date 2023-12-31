// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ODIVault.sol";

contract VaultOwner is Ownable {
    using SafeERC20 for IERC20;

    ODIVault public immutable ODIvault;

    /**
     * @notice Constructor
     * @param _ODIVaultAddress: ODIVault contract address
     */
    constructor(address _ODIVaultAddress) public {
        ODIvault = ODIVault(_ODIVaultAddress);
    }

    /**
     * @notice Sets admin address to this address
     * @dev Only callable by the contract owner.
     * It makes the admin == owner.
     */
    function setAdmin() external onlyOwner {
        ODIvault.setAdmin(address(this));
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        ODIvault.setTreasury(_treasury);
    }

    /**
     * @notice Sets performance fee
     * @dev Only callable by the contract owner.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        ODIvault.setPerformanceFee(_performanceFee);
    }

    /**
     * @notice Sets call fee
     * @dev Only callable by the contract owner.
     */
    function setCallFee(uint256 _callFee) external onlyOwner {
        ODIvault.setCallFee(_callFee);
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        ODIvault.setWithdrawFee(_withdrawFee);
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyOwner {
        ODIvault.setWithdrawFeePeriod(_withdrawFeePeriod);
    }

    /**
     * @notice Withdraw unexpected tokens sent to the ODI Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        ODIvault.inCaseTokensGetStuck(_token);
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner {
        ODIvault.pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner {
        ODIvault.unpause();
    }
}
