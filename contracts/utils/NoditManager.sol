// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../core/RentalDeposit.sol";

/**
 * @title NoditManager
 * @dev 整合Nodit去中心化webhook平台，用於定時觸發如到期檢查、自動結算等動作
 */
contract NoditManager is Ownable, ReentrancyGuard {
    // 租賃押金合約實例
    RentalDeposit public rentalDeposit;
    
    // Nodit觸發者地址
    address public noditTrigger;
    
    // 計劃任務結構
    struct ScheduledTask {
        uint256 rentalId;
        uint256 executeAt;
        TaskType taskType;
        bool executed;
    }
    
    // 任務類型列舉
    enum TaskType {
        RENTAL_EXPIRY_CHECK,  // 租賃到期檢查
        AUTO_RELEASE_DEPOSIT, // 自動釋放押金
        INTEREST_WITHDRAWAL   // 利息提取
    }
    
    // 任務映射
    mapping(uint256 => ScheduledTask) public scheduledTasks;
    uint256 public taskCount;
    
    // 事件定義
    event TaskScheduled(uint256 indexed taskId, uint256 indexed rentalId, TaskType taskType, uint256 executeAt);
    event TaskExecuted(uint256 indexed taskId, uint256 indexed rentalId, TaskType taskType);
    event NoditTriggerUpdated(address indexed oldTrigger, address indexed newTrigger);
    
    /**
     * @dev 限制只有Nodit觸發者可以調用
     */
    modifier onlyNoditTrigger() {
        require(msg.sender == noditTrigger, "NoditManager: caller is not the nodit trigger");
        _;
    }
    
    /**
     * @dev 構造函數
     * @param _rentalDeposit 租賃押金合約地址
     * @param _noditTrigger 初始Nodit觸發者地址
     */
    constructor(address _rentalDeposit, address _noditTrigger) {
        rentalDeposit = RentalDeposit(_rentalDeposit);
        noditTrigger = _noditTrigger;
    }
    
    /**
     * @dev 安排新任務
     * @param _rentalId 租賃ID
     * @param _executeAt 執行時間戳
     * @param _taskType 任務類型
     * @return 任務ID
     */
    function scheduleTask(
        uint256 _rentalId,
        uint256 _executeAt,
        TaskType _taskType
    ) public onlyOwner returns (uint256) {
        require(_executeAt > block.timestamp, "NoditManager: execution time must be in the future");
        
        uint256 taskId = taskCount;
        taskCount++;
        
        scheduledTasks[taskId] = ScheduledTask({
            rentalId: _rentalId,
            executeAt: _executeAt,
            taskType: _taskType,
            executed: false
        });
        
        emit TaskScheduled(taskId, _rentalId, _taskType, _executeAt);
        
        return taskId;
    }
    
    /**
     * @dev 執行計劃任務
     * @param _taskId 任務ID
     */
    function executeTask(uint256 _taskId) external onlyNoditTrigger nonReentrant {
        ScheduledTask storage task = scheduledTasks[_taskId];
        
        require(!task.executed, "NoditManager: task already executed");
        require(block.timestamp >= task.executeAt, "NoditManager: too early to execute");
        
        task.executed = true;
        
        if (task.taskType == TaskType.RENTAL_EXPIRY_CHECK) {
            // 檢查租賃是否到期，但不採取行動
            // 這個主要是為了記錄檢查已完成
        } else if (task.taskType == TaskType.AUTO_RELEASE_DEPOSIT) {
            // 嘗試自動釋放押金
            try rentalDeposit.endRental(task.rentalId) {
                // 成功釋放押金
            } catch {
                // 押金釋放失敗，可能正在爭議中
            }
        } else if (task.taskType == TaskType.INTEREST_WITHDRAWAL) {
            // 提取利息邏輯，實際實現會在RentalDeposit合約中
            // 這裡僅作為提醒
        }
        
        emit TaskExecuted(_taskId, task.rentalId, task.taskType);
    }
    
    /**
     * @dev 更新Nodit觸發者地址
     * @param _newTrigger 新的觸發者地址
     */
    function updateNoditTrigger(address _newTrigger) external onlyOwner {
        require(_newTrigger != address(0), "NoditManager: invalid trigger address");
        
        address oldTrigger = noditTrigger;
        noditTrigger = _newTrigger;
        
        emit NoditTriggerUpdated(oldTrigger, _newTrigger);
    }
    
    /**
     * @dev 批量安排任務
     * @param _rentalIds 租賃ID數組
     * @param _executeTimes 執行時間戳數組
     * @param _taskTypes 任務類型數組
     * @return 任務ID數組
     */
    function batchScheduleTasks(
        uint256[] calldata _rentalIds,
        uint256[] calldata _executeTimes,
        TaskType[] calldata _taskTypes
    ) external onlyOwner returns (uint256[] memory) {
        require(
            _rentalIds.length == _executeTimes.length && _executeTimes.length == _taskTypes.length,
            "NoditManager: array lengths mismatch"
        );
        
        uint256[] memory taskIds = new uint256[](_rentalIds.length);
        
        for (uint256 i = 0; i < _rentalIds.length; i++) {
            taskIds[i] = scheduleTask(_rentalIds[i], _executeTimes[i], _taskTypes[i]);
        }
        
        return taskIds;
    }
    
    /**
     * @dev 取消計劃任務
     * @param _taskId 任務ID
     */
    function cancelTask(uint256 _taskId) external onlyOwner {
        require(!scheduledTasks[_taskId].executed, "NoditManager: task already executed");
        
        delete scheduledTasks[_taskId];
    }
    
    /**
     * @dev 獲取任務狀態
     * @param _taskId 任務ID
     * @return 任務信息
     */
    function getTaskInfo(uint256 _taskId) external view returns (ScheduledTask memory) {
        return scheduledTasks[_taskId];
    }
}
