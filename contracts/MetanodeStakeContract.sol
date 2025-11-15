// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MetanodeStakeContract is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    //质押池结构体
    struct Pool {
        address stTokenAddress; //质押代币的地址,指定该质押池接受哪种ERC20代币进行质押
        uint256 poolWeight; //质押池的权重，该池在总奖励分配中的权重比例,示例：如果总权重100，池A权重30，池B权重70，则奖励按3:7分配
        uint256 lastRewardBlock;//最后一次计算奖励的区块号,用于计算从上次更新到现在产生了多少奖励
        uint256 accMetaNodePerST;//每个质押代币累积的 RCC 数量
        uint256 stTokenAmount;//池中的总质押代币量 
        uint256 minDepositAmount; //最小质押金额
        uint256 unstakeLockedBlocks; //解除质押的锁定区块数
    }

    //解押请求结构体
    struct ReleasedMortgageReq{
        uint256 releasedMortgageAmount; //解押数量
        uint256 unlockBlock; //解锁区块
    }

    //用户结构体
    struct User{
        uint256 stAmount; //用户质押的代币数量
        uint256 finishedMetaNode; //已分配的 MetaNode数量
        uint256 pendingMetaNode; //待领取的 MetaNode 数量
        ReleasedMortgageReq[] requests; //解质押请求列表，每个请求包含解质押数量和解锁区块
    }

    //池映射  池id -> 池实例   
    mapping(uint256 => Pool) public pools;

    // 池与用户关联映射
    mapping(uint256 => mapping(address => User)) public poolInUser;

    // 管理员映射
    mapping(address => bool) public admins;

    // 合约暂停状态
    bool public paused;

    Pool public erc20Pool;

    uint256 pid = 1;

    // ============ 事件定义 ============
    event ContractPaused();
    event ContractUnpaused();
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Upgraded(address indexed newImplementation);

    // ============ 修饰器 ============
    
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not admin");
        _;
    }


     function initialize(address initialOwner) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(initialOwner);

        // 设置部署者为初始管理员
        admins[msg.sender] = true;

        erc20Pool = Pool({
            stTokenAddress: 0x33056bb3cDA057a11E82671dAa3C61F82c1BE20c,
            poolWeight:1,
            lastRewardBlock:1,
            accMetaNodePerST:2,
            stTokenAmount:2,
            minDepositAmount:2,
            unstakeLockedBlocks:2

        });

        pools[pid] = erc20Pool;
        emit AdminAdded(msg.sender);
    }

    //======业务函数
    /*
    * 参与质押
    */
    function  participatePledge(uint256 _pid,uint256 _amount) public returns(bool){
        //获取池信息以及用户信息
        Pool storage pool = pools[_pid];
        User storage user = poolInUser[_pid][msg.sender];

        //校验pid是否存在
        require(pools[_pid].stTokenAddress != address(0), "Pool does not exist");

        //校验用户是否存在

        //校验amount大于0
        require(_amount > 0,"The pledged amount must be greater than 0.");
        //校验最低质押金额
        require(_amount >= pool.minDepositAmount,"The pledged amount must be greater than or equal to the minimum pledged amount.");
        //校验用户是否授权足够额度
        uint256 allowedAmount = IERC20(pool.stTokenAddress).allowance(msg.sender, address(this));
        require(allowedAmount >= _amount, "Staking: Insufficient allowance. Please approve first.");

        //将用户质押额度转到本合约
        bool success = IERC20(pool.stTokenAddress).transferFrom(msg.sender, address(this), _amount);
        require(success, "Staking: Transfer failed");
        
        //修改用户质押余额
        user.stAmount += _amount;
        //更新总质押余额
        pool.stTokenAmount += _amount;
    }

     /*
    * 解除质押（此函数只负责创建解押请求，如果需要提取锁定期结束后的质押代币，需要再提供一个函数）
    */
   function releasePledge(uint256 _pid,uint256 _amount) public returns(bool){
        //获取池信息以及用户信息
        Pool storage pool = pools[_pid];
        User storage user = poolInUser[_pid][msg.sender];

        //用户解除额度必须小于等于已质押额度
        require(_amount <= user.stAmount,"not sufficient funds");

        //计算解锁区块
        uint256 unlockBlock = block.number + pool.unstakeLockedBlocks;

        // 创建解押请求
        ReleasedMortgageReq memory request = ReleasedMortgageReq({
        releasedMortgageAmount: _amount,
        unlockBlock: unlockBlock  // 1201600
        });
        // 记录请求
        user.requests.push(request);
   }

   //领取奖励
   function receiveAward(uint256 _pid) public{
        //获取池信息以及用户信息
        Pool storage pool = pools[_pid];
        User storage user = poolInUser[_pid][msg.sender];
        //校验用户是否有可领取额度
        uint256 pendingAmount = user.pendingMetaNode;
        require(pendingAmount > 0,"Insufficient reward balance");

        //重置奖励
        user.pendingMetaNode = 0;

        //记录已分配
        user.finishedMetaNode += pendingAmount; 

        //此处应该提供真实项目方的奖励erc20代币呆滞
        address metaNodeToken;
        //给用户进行转账
        require(
        IERC20(metaNodeToken).transfer(msg.sender, pendingAmount),
        "Reward transfer failed"
    );
   }

    // ============ 视图函数 ============

    /*
    * 新增或更新质押池
    */
   function addOrUpdatePool(
                            uint256 _pid,
                            address _stTokenAddress,
                            uint256 _poolWeight,
                            uint256 _minDepositAmount,
                            uint256 _unstakeLockedBlocks) public onlyAdmin {
                                    
        Pool storage pool = pools[_pid];                      
        //校验pid是否存在
        if(_pid <=0 ){ //不存在则新增
            erc20Pool = Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight:_poolWeight,
            lastRewardBlock:1,
            accMetaNodePerST:2,
            stTokenAmount:2,
            minDepositAmount:_minDepositAmount,
            unstakeLockedBlocks:_unstakeLockedBlocks

        });

        pools[pid] = erc20Pool;
        }else{ //存在则更新
            pool.stTokenAddress= _stTokenAddress;
            pool.poolWeight=_poolWeight;
            pool.minDepositAmount=_minDepositAmount;
            pool.unstakeLockedBlocks=_unstakeLockedBlocks;
        }                            
   }
    
    /**
     * @dev 检查是否是管理员
     */
    function isAdmin(address account) public view returns (bool) {
        return admins[account] || account == owner();
    }

    /**
     * @dev 暂停合约
     */
    function pause() external onlyAdmin {
        require(!paused, "Already paused");
        
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev 恢复合约
     */
    function unpause() external onlyAdmin {
        require(paused, "Not paused");
        
        paused = false;
        emit ContractUnpaused();
    }


    /**
     * @dev 添加管理员
     */
    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        require(!admins[admin], "Already admin");
        
        admins[admin] = true;
        emit AdminAdded(admin);
    }
    
    /**
     * @dev 移除管理员
     */
    function removeAdmin(address admin) external onlyOwner {
        require(admins[admin], "Not an admin");
        require(admin != owner(), "Cannot remove owner");
        
        admins[admin] = false;
        emit AdminRemoved(admin);
    }



     // Fallback 函数 - 当函数不存在时调用
    fallback() external payable {
        revert("Function does not exist - all transfers reverted");
    }

    /**
     * @dev UUPS升级授权函数
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{
        emit Upgraded(newImplementation);
    }

    receive() external payable {
    }

}

