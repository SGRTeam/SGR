// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
interface relationship {
    function defultFather() external returns(address);
    function father(address _addr) external returns(address);
    function grandFather(address _addr) external returns(address);
    function otherCallSetRelationship(address _son, address _father) external;
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
interface Ipair{
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}
// 合约设置了三个超级管理员和owner两个权限，三个超级管理员投票可以修改owner。
// 这里设计的目的是不管那个地址被盗，都不至于让项目瘫痪
contract ownable{

    struct superOwner{
        bool isSuperOwner; //地址是否是超级管理员
        bool hasVote; // 是否已经投票了
        address newOwner; //新的owner地址是
    }

    address public owner;
    mapping(address => superOwner) public superOwners;

    modifier onlyOwner() {
        require(msg.sender == owner,"only owner can call!");
        _;
    }
    
    modifier onlySuperOwner(){
        require(superOwners[msg.sender].isSuperOwner, "only SuperOwner can call!");
        _;
    }
    
    constructor(){
        owner = msg.sender;
        superOwners[0xeaa8553841244b86Ab849F53460A4cd1bC4Fa9B3].isSuperOwner = true;//TODO 添加superowner！！！！
        superOwners[0x70369c1C51A2452da7695F3356DDAde901f11cF1].isSuperOwner = true;
        superOwners[0xa8E2a5F46f0e85640546AbEf319F4dBc5b2131fD].isSuperOwner = true;
    }

    function VoteNewOwner(address _addr) public onlySuperOwner {
        superOwner storage _superOwner = superOwners[msg.sender];

        require(_superOwner.hasVote == false, "superOwner has vote!");
        _superOwner.newOwner = _addr;
        _superOwner.hasVote = true;
    }

    function transferOwner(address _SO1, address _SO2, address _SO3) public {
        superOwner storage _superOwner1 = superOwners[_SO1];
        superOwner storage _superOwner2 = superOwners[_SO2];
        superOwner storage _superOwner3 = superOwners[_SO3];

        //检查三个地址是否都已经投过票
        require(_superOwner1.hasVote, "superOwner1 not vote!");
        require(_superOwner2.hasVote, "superOwner2 not vote!");
        require(_superOwner3.hasVote, "superOwner3 not vote!");

        //检查三个地址的投票是否是用一个
        require(_superOwner1.newOwner == _superOwner2.newOwner, "newOwner not same!");
        require(_superOwner2.newOwner == _superOwner3.newOwner, "newOwner not same!");
        
        //修改owner
        owner = _superOwner3.newOwner;

        //还原超级地址的投票状态
        _superOwner1.hasVote = false;
        _superOwner2.hasVote = false;
        _superOwner3.hasVote = false;
    }

    function giveupOwner() external onlySuperOwner {
        superOwner storage _superOwner = superOwners[msg.sender];

        _superOwner.isSuperOwner = false;
    }
}
contract ERC20 {

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    //from白名单，to白名单和黑名单
    mapping (address => bool) public fromWriteList;
    mapping (address => bool) public toWriteList;
    mapping (address => bool) public blackList;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "SGR TEMP";//TODO：需要确认代币名称，符号和精度
        _symbol = "SGRT";
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(blackList[msg.sender] == false && blackList[sender] == false && blackList[recipient] == false, "ERC20: is black List !");//黑名单检查

        uint256 trueAmount = _beforeTokenTransfer(sender, recipient, amount);


        _balances[sender] = _balances[sender] - trueAmount;
        _balances[recipient] = _balances[recipient] + trueAmount;
        emit Transfer(sender, recipient, trueAmount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual  returns (uint256) { } 
}
contract SGTTemp is ERC20, ownable{
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

    relationship public RP;//绑定关系的合约
    mapping(address => bool) public isPair;//记录pair地址
    Ipair public pair_USDT; // USDT的交易对
    uint256 public startTradeTime; //开始交易时间
    uint256 public shareRate = 1; //分享比例 1
    uint256 public devRate = 1; //开发者比例 1
    uint256 public buyRate = 14; //购买时的手续费比例 14
    uint256 public sellRate = 14; //卖出时的手续费比例 14

    address public devAddr; //开发者地址
    address public mintPoolAddr; //挖矿池地址
    

    constructor (
        address _RP,
        uint256 _startTradeTime,
        address _devAddr,
        address _mintPoolAddr
    ) {
        RP = relationship(_RP);
        _mint(msg.sender, 18000 * 10**18);//初始铸币18000个
        startTradeTime =_startTradeTime;
        devAddr = _devAddr;
        mintPoolAddr = _mintPoolAddr;

        fromWriteList[msg.sender] = true;
        toWriteList[msg.sender] = true;
    }

    function _beforeTokenTransfer(
        address _from, 
        address _to, 
        uint256 _amount
        )internal override returns (uint256){
            
        if (RP.father(_to) == address(0)){//检查to地址没有推荐人
            sendReff(_to, _from);//TODO：需要将本合约设置为可以绑定关系的合约！！！
        }

        if (fromWriteList[_from] || toWriteList[_to]){//白名单检查
            return _amount;
        }
        
        uint256 _trueAmount;
        
        if (isPair[_from]){//从池子流出 也就是买
            require(block.timestamp >= startTradeTime,"not start exchange");//开始交易前不能够买卖
            _trueAmount = _amount * (100 - (shareRate + devRate + buyRate)) / 100;
            _balances[RP.getFather(_to)] = _balances[RP.getFather(_to)] + (_amount * shareRate / 100);//给这个地址的推荐人这么多
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100 );
            _balances[mintPoolAddr] = _balances[mintPoolAddr] + (_amount * buyRate / 100);
            
            require(balanceOf(_to) + _trueAmount <= getMaxHoldAMount(), "you cant get more token");
            
        } else if (isPair[_to]) {//卖
            require(block.timestamp >= startTradeTime,"not start exchange");
            _trueAmount = _amount * (100 - (shareRate + devRate + sellRate)) / 100;
            _balances[RP.getFather(_from)] = _balances[RP.getFather(_from)] + (_amount * shareRate / 100);//给这个地址的推荐人这么多
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100);//todo:回流地址是指什么地址？？
            _balances[mintPoolAddr] = _balances[mintPoolAddr] + (_amount * sellRate / 100);
        } else{
            _trueAmount = _amount * (100 - (shareRate + devRate + sellRate)) / 100;
            _balances[RP.getFather(_to)] = _balances[RP.getFather(_to)] + (_amount * shareRate / 100);//给这个地址的推荐人这么多
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100);
            _balances[mintPoolAddr] = _balances[mintPoolAddr] + (_amount * sellRate / 100);
            
            require(balanceOf(_to) + _trueAmount <= getMaxHoldAMount(), "you cant get more token");
        }

        return _trueAmount;   
    }
    
    //绑定关系
    function sendReff(
        address _son,
        address _father
    ) internal {
        if(!isPair[_son] && !isPair[_father]){
            RP.otherCallSetRelationship(_son, _father);
        }
    }

    function getMaxHoldAMount() public view returns(uint256){
        uint256 price = getPrice();

        uint256 result;
        if(price <= 1000 * (10**18)){
            result = price / (100 * (10**18)) + 1;
        }else{
            result = 18000;
        }

        return result * 10 **18;
    }

    function getPrice() internal view returns(uint256){
        
        uint256 amountA;
        uint256 amountB;
        if (pair_USDT.token0() == USDT){
            (amountA, amountB,) = pair_USDT.getReserves();
        }
        else{
            (amountB, amountA,) = pair_USDT.getReserves();
        }
        uint256 price = (10**18) * amountA /amountB;
        return price;
    }
    
    //admin func///////////////////////////////////////////////////////////////
    
    //修改交易对地址
    function setPair(
        address _addr,
        bool _YorN, //true是新增，false是消除
        bool _isUSDT
    ) external onlyOwner{
        isPair[_addr] = _YorN;
        if(_isUSDT){
            pair_USDT = Ipair(_addr);
        }
    }
    
    //设置白名单地址
    function setWhiteList(
        address _addr, 
        uint256 _type, // 0是from白名单，1是to白名单 
        bool _YorN // true是新增 false是消除
        ) external onlyOwner{
        
        if (_type == 0){
            fromWriteList[_addr] = _YorN;
        }else if (_type == 1){
            toWriteList[_addr] = _YorN;
        }
        else{
        }
    }
    
    //设置黑名单
    function setBlackList(
        address _addr,
        bool _YorN
    ) external onlyOwner{   
        blackList[_addr] = _YorN;
    }

    function setRate(
        uint256 _shareRate, 
        uint256 _devRate, 
        uint256 _buyRate, 
        uint256 _sellRate
    ) external onlyOwner{
        shareRate = _shareRate;
        devRate = _devRate;
        buyRate = _buyRate;
        sellRate = _sellRate;
    }

    function setAddr(
        address _devAddr,
        address _mintPoolAddr
    ) external onlyOwner{
        devAddr = _devAddr;
        mintPoolAddr = _mintPoolAddr;
    }


// for test need delete begin start
    function testSetStartTime(
        uint256 _time
    ) external onlyOwner{
        startTradeTime = _time;
    }
}