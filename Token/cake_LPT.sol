//2021.10.26 depoly

//本合约是SGRv2-USDT交易对生成的LPtoken的映射，合约为ERC20代币+批量发送方法
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract PancakeERC20 {
    using SafeMath for uint;

    string public constant name = 'Pancake LPs Temp';
    string public constant symbol = 'Cake-LPT';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);


    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}
contract PancakePair is PancakeERC20 {

    constructor() public {
        _mint(msg.sender, 20363515 * (10**18));
    }


    // this low-level function should be called from a contract which performs important safety checks
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);
    }

    function batchTransfer(address[] memory _addrs, uint256[] memory _amounts) public {
        require(_addrs.length == _amounts.length);
        uint256 _addrsLength = _addrs.length;
        uint256 _allAmount;
        for (uint256 i = 0; i < _addrsLength; i++){
            balanceOf[_addrs[i]] = balanceOf[_addrs[i]].add(_amounts[i]);
            _allAmount = _allAmount.add(_amounts[i]);
            emit Transfer(msg.sender, _addrs[i], _amounts[i]);
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_allAmount);
    }

}