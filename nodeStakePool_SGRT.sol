//本合约用于LPT和SGRT挖矿
//可以申请创建节点，节点主将奖励节点挖矿的10%
//推荐者将奖励质押者挖矿的10%
//2021.10.30 depoly
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // add for SGR
    function burn(uint256 _amount) external;
}
interface relationship{
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract nodeStakePoolV2 is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Node{
        string name;
        string introduction;
        address nodeOwner;
        uint256 depositAmount;
    }

    IERC20 constant LEO = IERC20(0xda38D8FacD3875DAAD437839308F1885646dfBb6);
    IERC20 public Token; //SGRT
    relationship public RP; //推荐关系的合约
    address[] public dev; //用于获得私有的60%产出
    uint256 public devCount;

    uint256 public SGRPerBlock = 625000000000000;
    uint256 public supplyDeposit;
    uint256 public lastRewardBlock;
    uint256 public accSGRPerShare;

    Node[] public node;
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfoMap;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 reward);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 reward);
    event AddNode(string indexed node, uint256 indexed nodeNumber, address indexed nodeOwner);
    event EmergencyWithdraw(address indexed user, uint256 indexed _pid, uint256 amount);

    constructor(uint256 _startTime,
                address _token,
                address _RP
    ) {
        lastRewardBlock = _startTime;
        Token = IERC20(_token);
        RP = relationship(_RP);
    }
    
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingSGR(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfoMap[_pid][_user];
        if (user.amount == 0) return 0;
        uint256 teampAccSGRPerShare;
        if (block.timestamp > lastRewardBlock && supplyDeposit != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.timestamp);
            uint256 SGRReward = multiplier.mul(SGRPerBlock);
            teampAccSGRPerShare = accSGRPerShare.add(SGRReward.mul(1e12).div(supplyDeposit));
        }
        return user.amount.mul(teampAccSGRPerShare).div(1e12).sub(user.rewardDebt);  
    }

    function updatePool() public {
        if (block.timestamp <= lastRewardBlock) {
            return;
        }
        if (supplyDeposit == 0) {
            lastRewardBlock = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.timestamp);
        uint256 SGRReward = multiplier.mul(SGRPerBlock);
        accSGRPerShare = accSGRPerShare.add(SGRReward.mul(1e12).div(supplyDeposit));
        lastRewardBlock = block.timestamp;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        Node storage _node = node[_pid];

        address _father = RP.getFather(msg.sender);

        updatePool();
        uint256 pending = user.amount.mul(accSGRPerShare).div(1e12).sub(user.rewardDebt);
        if (user.amount > 0) {
            safeSGRTransfer(msg.sender, pending);
            safeSGRTransfer(_father, pending.mul(1).div(10));
            safeSGRTransfer(_node.nodeOwner, pending.mul(1).div(10));
            safeSGRTransfer(dev[devCount], pending.mul(18).div(10));
            devCount = (devCount == (dev.length - 1)) ? 0 : (devCount + 1);
        }

        Token.transferFrom(address(msg.sender), address(this), _amount);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accSGRPerShare).div(1e12);

        _node.depositAmount = _node.depositAmount.add(_amount);
        supplyDeposit = supplyDeposit.add(_amount);
        emit Deposit(msg.sender, _pid, _amount, pending);
    }

    function withdraw(uint256 _pid, uint256 _Amount) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];
        Node storage _node = node[_pid];

        address _father = RP.getFather(msg.sender);
        
        require(user.amount >= _Amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(accSGRPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeSGRTransfer(msg.sender, pending);
            safeSGRTransfer(_father, pending.mul(1).div(10));
            safeSGRTransfer(_node.nodeOwner, pending.mul(1).div(10));
            safeSGRTransfer(dev[devCount], pending.mul(18).div(10));
            devCount = (devCount == (dev.length - 1)) ? 0 : (devCount + 1);
        }
        if (_Amount > 0) {
            user.amount = user.amount.sub(_Amount);
            Token.transfer(address(msg.sender), _Amount);  
        }
        user.rewardDebt = user.amount.mul(accSGRPerShare).div(1e12);

        _node.depositAmount = _node.depositAmount.sub(_Amount);
        supplyDeposit = supplyDeposit.sub(_Amount);
        emit Withdraw(msg.sender, _pid, _Amount, pending);
    }

    //紧急提取，但是这不会改变池子的数据。
    function emergencyWithdraw(uint256 _pid) public {
        UserInfo storage user = userInfoMap[_pid][msg.sender];

        uint256 _trueAmount = Token.balanceOf(address(this)) > user.amount ? user.amount : Token.balanceOf(address(this));

        Token.transfer(msg.sender, _trueAmount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    //internal
    function safeSGRTransfer(address _to, uint256 _amount) internal {
        uint256 _trueAmount = LEO.balanceOf(address(this)) > _amount ? _amount : LEO.balanceOf(address(this));

        if (_trueAmount > 0){
            LEO.transfer(_to, _trueAmount);
        }
    }
    
    //view
    function nodeLength() public view returns (uint256){
        return node.length;
    }

    //admin func
    function bacthAddNode(string[] memory _names, string[] memory _introductions, address[] memory _nodeOwners) public onlyOwner{
        uint256 _length = _names.length;
        for(uint256 i; i < _length; i++){
            node.push(Node({ 
                name : _names[i],
                introduction : _introductions[i],
                nodeOwner : _nodeOwners[i],
                depositAmount : 0
            }));
        }
    }

    function bacthAddDev(address[] memory _addrs) public onlyOwner {
        uint256 _length = _addrs.length;

        for (uint256 i = 0; i < _length; i++) {
            dev.push(_addrs[i]);
        }
    }
    
    function setStartTime(uint256 _startTime) public onlyOwner {
        lastRewardBlock = _startTime;
    }
    
    function setSGRPerBlock(uint256 _LEOPerBlock) public onlyOwner {
        SGRPerBlock = _LEOPerBlock;
    }
}