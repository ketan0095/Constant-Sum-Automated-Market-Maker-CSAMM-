// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "./IERC20.sol";

contract CSAMM {

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public reserve0; // to keep track of balance of token0
    uint public reserve1; // to keep track of balance of token1

    uint public TotalSupply; // to keep track of total tokes supply
    mapping(address => uint) public BalanceOf; // keep track of any users token balance

    // intitalize contract with tokens addresses
    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }


    // to mint the tokens for any user
    function _mint(address _to, uint _amount) private {
        BalanceOf[_to] += _amount;
        TotalSupply += _amount;
    }

    // to burn the tokens for any user
    function _burn(address _from, uint _amount) private {
        BalanceOf[_from] -= _amount;
        TotalSupply -= _amount;
    }

    // to update reserve vals
    function _update(uint _res0,uint _res1) private {
        reserve0 =_res0;
        reserve1 =_res1;

    }

    // used to trade 1-1 Tokens
    // function swap(address _tokenIn, uint amountIn) external returns (uint amountOut) {
    //     require (_tokenIn == address(token0) ||_tokenIn == address(token1),"Invalid Token !");

    //     // steps :
    //     // 1. transfer the token in amount into contract
    //     if (_tokenIn==address(token0)){
    //         token0.transferFrom(msg.sender,address(this),amountIn);
    //         amountIn = token0.balanceOf(address(this))-reserve0;  // current balance - last observed balance
    //     }else{
    //         token1.transferFrom(msg.sender,address(this),amountIn);
    //         amountIn = token1.balanceOf(address(this))-reserve1;  // current balance - last observed balance
    //     }
    //     // 2. cal. token out amount (including fees)
    //     // if no trading fees then amountOut == amountIn
    //     // considering 0.3% fees here
    //     amountOut =(amountIn * 997)/1000;

    //     // 3. update reserve vars
    //     if (_tokenIn == address(token0)){
    //         _update(reserve0 + amountIn,reserve1-amountOut);
    //     }else{
    //         _update(reserve0 - amountOut,reserve1+amountIn);
    //     }


    //     // 4. transfer respective token out
    //     if (_tokenIn == address(token0)){
    //         token0.transfer(msg.sender,amountOut);
    //     }else{
    //         token1.transfer(msg.sender,amountOut);
    //     }


    // }

    // to optimize the gas fees
    function swap(address _tokenIn,uint _amountIn) external returns (uint amountOut) {

        require (_tokenIn == address(token0) ||_tokenIn == address(token1),"Invalid Token !");

        bool isTaken0 = _tokenIn ==address(token0);
        (IERC20 tokenIn,IERC20 tokenOut,uint resIn,uint resOut)= isTaken0 ? (token0,token1,reserve0,reserve1) : (token1,token0,reserve1,reserve0); // ? is a ternary operator used for if-else here

        // steps :
        // 1. transfer the token in amount into contract
        tokenIn.transferFrom(msg.sender,address(this),_amountIn);
        uint amountIn = tokenIn.balanceOf(address(this))-resIn;  // current balance - last observed balance

        // 2. cal. token out amount (including fees)
        // if no trading fees then amountOut == amountIn
        // considering 0.3% fees here
        amountOut =(amountIn * 997)/1000;

        // 3. update reserve vars

        (uint res0, uint res1) = isTaken0 ? (resIn + amountIn,resOut-amountOut) :  (resOut - amountOut,resIn+amountIn);
        _update(res0,res1);

        // 4. transfer respective token out
        tokenOut.transfer(msg.sender,amountOut);

    }

    // to add tokens
    function addLiquidity(uint amount0, uint amount1) external returns(uint shares){
        token0.transferFrom(msg.sender,address(this),amount0);
        token1.transferFrom(msg.sender,address(this),amount1);

        // to calulate amount coming in
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        uint b0 =bal0 - reserve0;
        uint b1 =bal1 - reserve1;

        /*
        a = amountIn
        L = Total Liquidity
        s = shares to mint
        T = total supply

        (L+a)/L = (T+S)/T
        s =a * T/L

        */

        if (TotalSupply==0){
            // if first time adding tokens
            shares = b0 + b1;
        }else{
            shares =((b0 + b1)*TotalSupply)/(reserve0+reserve1);
        }

        require(shares >0,"shares =0");
        _mint(msg.sender,shares);

        _update(bal0,bal1);


    }

    // to remove tokens
    // users will burn the shares lockd in contract & get back those shares
    function removeLiquidity(uint _shares) external returns(uint d0,uint d1) {
        /*
        a = amountIn
        L = Total Liquidity
        s = shares to mint
        T = total supply

        a/L= s/T
        a = L * s/T
        a = (reserve0+reserve1) * s/T

        */

        d0 =(reserve0 * _shares)/TotalSupply;
        d1 =(reserve1 * _shares)/TotalSupply;

        _burn(msg.sender,_shares);

        _update(reserve0-d0,reserve1-d1);

        if (d0>0){
            token0.transfer(msg.sender,d0);
        }

        if (d1>0){
            token1.transfer(msg.sender,d1);
        }
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}