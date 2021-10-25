// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;
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
    
    constructor() public{
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
contract relationship is ownable{
    
    address public defultFather;
    mapping(address => address) public father;
    mapping(address => address) public grandFather;
    mapping(address => bool) public callSetRelationshipAddress;//可以设置除自己外地址的推荐人的特权地址
    
    modifier callSetRelationship(){
        require(callSetRelationshipAddress[msg.sender] == true,"can't set relationship!");
        _;
    }

    function init(address _defultFather, address _airDrop, address _buy) public onlyOwner(){
        defultFather = _defultFather;//默认推荐人，在没有其他推荐人的情况下，一二代推荐人都是他
        setCallSetRelationshipAddress(_airDrop, true);
        setCallSetRelationshipAddress(_buy, true);
    }
    
    function _setRelationship(address _son, address _father) internal {
        require(_son != _father,"Father cannot be himself!");//推荐人不能是他自己
        if (father[_son] != address(0)){//推荐人如果已经存在 直接返回，这里是为了满足购买调用时绑定推荐人关系，如果推荐人已经存在了，就直接返回，不做任何操作
            return;
        }
        address _grandFather = getFather(_father);
        
        father[_son] = _father;
        grandFather[_son] = _grandFather;
    }

    function setRelationship(address _father) public {
        _setRelationship(msg.sender, _father);
    }

    function otherCallSetRelationship(address _son, address _father) public callSetRelationship() {
        _setRelationship(_son, _father);
    }
    
    function getFather(address _addr) public view returns(address){
        return father[_addr] != address(0) ? father[_addr] : defultFather;
    }
    function getGrandFather(address _addr) public view returns(address){
        return grandFather[_addr] != address(0) ? grandFather[_addr] : defultFather;
    }
    
    //****************************************//
    //*
    //* admin function
    //*
    //****************************************//
    
    function setDefultFather(address _addr) public onlyOwner() {
        require(msg.sender == defultFather);
        defultFather = _addr;
    }

    function setCallSetRelationshipAddress(address _addr, bool no_yes) public onlyOwner(){
        callSetRelationshipAddress[_addr] = no_yes;
    }
}