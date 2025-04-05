// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AccessControl
 * @dev 基本的訪問控制合約，允許角色管理
 */
contract AccessControl is Ownable {
    // 角色映射：地址 => 角色 => 是否擁有權限
    mapping(address => mapping(bytes32 => bool)) private _roles;
    
    // 角色事件
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    // 常用角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    
    /**
     * @dev 建構函數
     */
    constructor() {
        // 預設授予管理員角色給合約擁有者
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev 修飾符：檢查調用者是否擁有指定角色
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: account does not have role");
        _;
    }
    
    /**
     * @dev 檢查地址是否擁有指定角色
     * @param role 角色識別符
     * @param account 要檢查的地址
     * @return 是否擁有該角色
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[account][role];
    }
    
    /**
     * @dev 授予地址指定角色（僅管理員或擁有者）
     * @param role 角色識別符
     * @param account 要授予的地址
     */
    function grantRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
    }
    
    /**
     * @dev 撤銷地址的指定角色（僅管理員或擁有者）
     * @param role 角色識別符
     * @param account 要撤銷的地址
     */
    function revokeRole(bytes32 role, address account) public onlyOwner {
        _revokeRole(role, account);
    }
    
    /**
     * @dev 內部函數：授予角色
     */
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[account][role] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }
    
    /**
     * @dev 內部函數：撤銷角色
     */
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[account][role] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}
