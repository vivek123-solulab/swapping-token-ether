//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

///Importing transferHelper and IUniswapV2Router02 from the uniswap github
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract UniswapExample {
  
  ///Making object of uniswap router
  IUniswapV2Router02 public uniswapRouter;

  ///Creating mapping of balances and user
  mapping(address => uint256) private balances;
  mapping(address => User) private user;
  
  ///Creating constructor
  constructor(address router) {

    ///Mapping router address with router interface
    uniswapRouter = IUniswapV2Router02(router);

  }

  ///Creating event
  event claim(address token, uint256 amount);

  ///Creating struct
  struct User{
    address userAddress;
    address token;
    bool userCanClaim;
    bool userClaimed;
  }

  ///Defining of the functions
  function addEthLiquidity(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) public payable {

    ///Transfering the token amount to the user and giving approval of router contract in the token contract
    TransferHelper.safeTransferFrom(token,msg.sender, address(this), amountTokenDesired);
    TransferHelper.safeApprove(token, address(uniswapRouter), amountTokenDesired);

    /***
      Calling the addLiquidityETH function to add the liquidity in the contract.
      As the amountTokenDesired and msg.value should be same.
      Make sure that the deadline should be equal or greater than current block.timestamp
    */
    uniswapRouter.addLiquidityETH{value:msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin,to, deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
    user[token].userCanClaim = false;
  }
  /***
    This function swaps the token to eth by giving the descired amountIn.
    Also it needs approval of router contract before swapping.
  */
  function convertTokenToEth(address token,uint amountIn,uint amountOutMin,uint deadline) public {
    TransferHelper.safeTransferFrom(token,msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(token, address(uniswapRouter), amountIn);

    ///Calling the swapExactTokensForEth from the uniswap router interface.
    uniswapRouter.swapExactTokensForETH(amountIn, amountOutMin, getPathForTokenToETH(token), address(this), deadline);

    ///Storing the balance of the contract into the mapping
    balances[token] = address(this).balance;

    ///Giving the status of the user from teh user struct
    user[token].userAddress = msg.sender;
    user[token].userClaimed = false;
    user[token].userCanClaim = true;
  }

  function getEstimatedETHforDAIAmountsIn(address token,uint amountOut) public view returns (uint[] memory) {

    ///Calling the view function to check the amountsIn amount user will get
    return uniswapRouter.getAmountsIn(amountOut,getPathForTokenToETH(token));
  }

  /***
    User will claim the ETH from its respective account only.
    Claim function will be run when the swap function is being executed.
    If once claimed then the user cannot claim again, the user can only be able to claim again when the swap functions executes.
  */
  function claim_Eth(address token) public {

    ///Require conditions
    require(user[token].userClaimed == false, "Already Claimed !!!");
    require(user[token].userAddress == msg.sender, 'You are not token owner');
    require(user[token].userCanClaim == true, "Token owner cannot claim their ETH");

    //Giving the status of the user
    user[token].userClaimed = true;
    user[token].userCanClaim = false;
    payable(msg.sender).transfer(balances[token]);
    balances[token] = 0;

    ///Emitting the claim event
    emit claim(token,balances[token]);
  }

  ///Internal functions for the path of WETH & token contract address  
  function getPathForTokenToETH(address token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = uniswapRouter.WETH();
    
    return path;
  }

  function getEstimatedETHforDAIAmountsOut(address token,uint amountIn) public view returns (uint[] memory) {

    ///Calling the view function to check the amountsOut amount user will get
    return uniswapRouter.getAmountsOut(amountIn,getPathForTokenToETH(token));
  }

  ///Geting the contract balance
  function getContractBalance(address token) public view returns(uint256){
    return balances[token];
  }

  ///Getting the status of claim of the user
  function getTokenOwnerClaimStatus(address token) public view returns(bool){
    // require(user[token].userAddress == msg.sender, 'You are not token owner');
    return user[token].userCanClaim;
  }

  ///Getting the status of claim of the user
  function getTokenOwnerAlreadyClaimedStatus(address token) public view returns(bool){
    // require(user[token].userAddress == msg.sender, 'You are not token owner');
    return user[token].userClaimed;
  }
  
  // important to receive ETH
  receive() payable external {}
}