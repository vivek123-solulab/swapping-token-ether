//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract UniswapExample {
  
  IUniswapV2Router02 public uniswapRouter;

  mapping(address => uint256) private balances;
  mapping(address => User) private user;
  
  constructor(address router) {

    uniswapRouter = IUniswapV2Router02(router);

  }

  event claim(address token, uint256 amount);

  struct User{
    address userAddress;
    address token;
    bool userCanClaim;
    bool userClaimed;
  }

  function addEthLiquidity(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) public payable {
    TransferHelper.safeTransferFrom(token,msg.sender, address(this), amountTokenDesired);
    TransferHelper.safeApprove(token, address(uniswapRouter), amountTokenDesired);

    uniswapRouter.addLiquidityETH{value:msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin,to, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
    user[token].userCanClaim = false;
  }

  function convertTokenToEth(address token,uint amountIn,uint amountOutMin,uint deadline) public {
    TransferHelper.safeTransferFrom(token,msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(token, address(uniswapRouter), amountIn);

    uniswapRouter.swapExactTokensForETH(amountIn, amountOutMin, getPathForTokenToETH(token), address(this), deadline);

    balances[token] = address(this).balance;
    user[token].userAddress = msg.sender;
    user[token].userClaimed = false;
    user[token].userCanClaim = true;
  }

  function getEstimatedETHforDAIAmountsIn(address token,uint amountOut) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(amountOut,getPathForTokenToETH(token));
  }

  function claim_Eth(address token) public {
    require(user[token].userClaimed == false, "Already Claimed !!!");
    require(user[token].userAddress == msg.sender, 'You are not token owner');
    require(user[token].userCanClaim == true, "Token owner cannot claim their ETH");
    user[token].userClaimed = true;
    user[token].userCanClaim = false;
    payable(msg.sender).transfer(balances[token]);
    balances[token] = 0;
    emit claim(token,balances[token]);
  }

  function getPathForTokenToETH(address token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = uniswapRouter.WETH();
    
    return path;
  }

  function getEstimatedETHforDAIAmountsOut(address token,uint amountIn) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsOut(amountIn,getPathForTokenToETH(token));
  }

  function getContractBalance(address token) public view returns(uint256){
    return balances[token];
  }

  function getTokenOwnerClaimStatus(address token) public view returns(bool){
    // require(user[token].userAddress == msg.sender, 'You are not token owner');
    return user[token].userCanClaim;
  }

  function getTokenOwnerAlreadyClaimedStatus(address token) public view returns(bool){
    // require(user[token].userAddress == msg.sender, 'You are not token owner');
    return user[token].userClaimed;
  }
  
  // important to receive ETH
  receive() payable external {}
}