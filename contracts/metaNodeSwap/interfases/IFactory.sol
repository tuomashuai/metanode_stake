// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IFactory {

    struct Parameters {
        address factory; //工厂地址
        address tokenA; //A地址
        address tokenB; //B地址
        int24 tickLower; //价格下限
        int24 tickUpper; //价格上限
        uint24 fee;  //费率
    }

    //获取临时参数函数
    function parameters()
        external
        view
        returns (
            address factory,
            address tokenA,
            address tokenB,
            int24 tickLower,
            int24 tickUpper,
            uint24 fee
        );

    event PoolCreated(
        address token0,
        address token1,
        uint32 index,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee,
        address pool
    );

    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view returns (address pool);

    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external returns (address pool);


}