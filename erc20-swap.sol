// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapERC20 is Ownable {

  ERC20 public paymentToken;
  ERC20 public contractToken;
  // token price for PTN
  uint256 public tokensPerPTN;

  // Event that log buy operation
  event BuyTokens(address buyer, uint256 amountOfPTN, uint256 amountOfTokens);
  event withdrawTokens(address receiver, uint256 amountOfTokens);

  constructor(ERC20 _paymentToken, ERC20 _contractToken) {
    paymentToken = _paymentToken;
    contractToken = _contractToken;
  }

  /**
  * @notice Allow users to buy token for PTN
  */
  function buyTokens(uint256 amount) external {
    require(amount > 0, "Send payment tokens to buy some tokens");
    
    uint8 contractTokenDecimals = contractToken.decimals();
    uint256 totalPaymentAmount = (amount * tokensPerPTN) / (10 ** contractTokenDecimals);

    // check if the Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = contractToken.balanceOf(address(this));
    require(vendorBalance >= amount, "Vendor contract has not enough tokens in its balance");

    (bool received) = paymentToken.transferFrom(msg.sender, address(this), totalPaymentAmount);
    if(received) {
        // Transfer token to the msg.sender
        (bool sent) = contractToken.transfer(msg.sender, amount);
        require(sent, "Failed to transfer token to user");
    } else {
        revert("Failed to transfer tokens from user");
    }

    // emit the event
    emit BuyTokens(msg.sender, totalPaymentAmount, amount);
  }

  function setSwapPrice(uint256 newPrice) external onlyOwner {
      require(newPrice > 0, "Price cannot be zero");
      tokensPerPTN = newPrice;
  }

  function getSwapPrice() external view returns(uint256) {
      return tokensPerPTN;
  }

  /**
  * @notice Allow the owner of the contract to withdraw PTN
  */
  function withdraw() public onlyOwner {
    uint256 contractBalance = contractToken.balanceOf(address(this));
    require(contractBalance > 0, "Owner has not balance to withdraw");

    (bool sent) = contractToken.transfer(owner(), contractBalance);
    require(sent, "Failed to transfer token to user");

    emit withdrawTokens(msg.sender, contractBalance);
  }
}
