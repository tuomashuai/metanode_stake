// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2; // 启用新的 ABI 编码器  在V1中，不支持

import "./IFactory.sol";

interface IPoolManager is IFactory {
    struct PoolInfo {
        address pool;
        address token0;
        address token1;
        uint32 index;
        uint24 fee;
        uint8 feeProtocol; //控制协议手续费比例  用于平台和LP的手续费分成
        int24 tickLower;
        int24 tickUpper;
        int24 tick;
        uint160 sqrtPriceX96; //价格平方根 精确表示交易对价格
        uint128 liquidity; //表示可用流动性深度
    }

    struct Pair {
        address token0;
        address token1;
    }

    //获取交易对
    //✅ 返回结构体数组 - 需要 abicoder v2
    function getPairs() external view returns (Pair[] memory);

    //获取所有交易池信息
    // ✅ 返回复杂结构体数组 - 需要 abicoder v2
    function getAllPools() external view returns (PoolInfo[] memory poolsInfo);

    struct CreateAndInitializeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
    }

    // ✅ 结构体作为参数 - 需要 abicoder v2
    function createAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable returns (address pool);
}
